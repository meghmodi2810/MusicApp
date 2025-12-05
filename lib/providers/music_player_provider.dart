import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song_model.dart';
import '../services/recommendation_service.dart';
import '../services/audio_handler_service.dart';
import '../services/music_api_service.dart';

class MusicPlayerProvider extends ChangeNotifier {
  AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer? _crossfadePlayer; // Secondary player for crossfade
  AudioPlayer? _precachePlayer; // Player for pre-caching next song
  AudioPlayerHandler? _audioHandler;

  // Stream subscriptions for cleanup
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _processingStateSubscription;

  // PERFORMANCE OPTIMIZATION: Throttle timer for position updates
  Timer? _positionThrottleTimer;
  Duration _lastEmittedPosition = Duration.zero;

  SongModel? _currentSong;
  SongModel? _precachedSong; // Track which song is pre-cached
  List<SongModel> _playlist = [];
  List<SongModel> _queue = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffleOn = false;
  LoopMode _loopMode = LoopMode.off;
  double _volume = 1.0;

  // Crossfade settings
  bool _crossfadeEnabled = false;
  int _crossfadeDuration = 5;
  bool _isCrossfading = false;
  bool _crossfadeJustCompleted =
      false; // Track if crossfade just finished to ignore stale completion events
  CrossfadeCurve _crossfadeCurve =
      CrossfadeCurve.equalPower; // Spotify-style default

  // Pre-cache lock to prevent multiple concurrent pre-cache operations
  bool _isPrecaching = false;

  // Volume normalization
  bool _volumeNormalization = false;
  double _normalizedVolume = 1.0;

  // Track if provider is disposed
  bool _isDisposed = false;

  // PERFORMANCE: ValueNotifier for position (avoids full widget rebuilds)
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> playingNotifier = ValueNotifier(false);

  // Getters
  SongModel? get currentSong => _currentSong;
  List<SongModel> get playlist => _playlist;
  List<SongModel> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isShuffleOn => _isShuffleOn;
  LoopMode get loopMode => _loopMode;
  double get volume => _volume;
  AudioPlayer get audioPlayer => _audioPlayer;
  bool get hasQueue => _queue.isNotEmpty;
  int get queueLength => _queue.length;
  bool get crossfadeEnabled => _crossfadeEnabled;
  int get crossfadeDuration => _crossfadeDuration;
  bool get volumeNormalization => _volumeNormalization;
  CrossfadeCurve get crossfadeCurve => _crossfadeCurve;

  MusicPlayerProvider() {
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Initialize audio service for notifications WITH CALLBACKS
      _audioHandler = await AudioService.init(
        builder: () => AudioPlayerHandler(
          _audioPlayer,
          onNext: () async => await playNext(),
          onPrevious: () async => await playPrevious(),
          onStop: () async => await stop(),
        ),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.pancaketunes.app.channel.audio',
          androidNotificationChannelName: 'Pancake Tunes',
          androidNotificationChannelDescription: 'Pancake Tunes music playback',
          // CRITICAL: Set to false to keep notification visible when paused
          androidNotificationOngoing: false,
          androidShowNotificationBadge: true,
          // CRITICAL: Must be true when androidNotificationOngoing is false
          androidStopForegroundOnPause: true,
          artDownscaleWidth: 300,
          artDownscaleHeight: 300,
          fastForwardInterval: Duration(seconds: 10),
          rewindInterval: Duration(seconds: 10),
          // CRITICAL: Keep notification when app is swiped away
          androidNotificationClickStartsActivity: true,
          androidResumeOnClick: true,
        ),
      );
      debugPrint('✅ Audio service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error configuring audio session: $e');
    }

    _setupPlayerListeners(_audioPlayer);
  }

  void _setupPlayerListeners(AudioPlayer player) {
    // Cancel existing subscriptions first
    _cancelPlayerSubscriptions();

    _playerStateSubscription = player.playerStateStream.listen((state) {
      if (_isDisposed) return;
      _isPlaying = state.playing;
      playingNotifier.value = state.playing;
      // PERFORMANCE FIX: Only notify for state changes, not position
      notifyListeners();
    });

    // PERFORMANCE FIX: Drastically reduce position update frequency
    _positionSubscription = player.positionStream.listen((pos) {
      if (_isDisposed) return;
      _position = pos;
      positionNotifier.value = pos;

      // CRITICAL FIX: Only notify listeners every 500ms instead of 60fps (16ms)
      // This reduces UI rebuilds from 3600/min to 120/min (30x improvement!)
      if (_positionThrottleTimer == null || !_positionThrottleTimer!.isActive) {
        if ((pos - _lastEmittedPosition).abs() >
            const Duration(milliseconds: 500)) {
          _lastEmittedPosition = pos;
          notifyListeners(); // Only call this 2 times per second

          _positionThrottleTimer = Timer(
            const Duration(milliseconds: 500),
            () {},
          );
        }
      }

      // Pre-cache next song when 60% through current song (with lock check)
      // FIX: Changed from 80% to 60% to give more time for buffering/loading
      if (_duration.inSeconds > 0 && !_isPrecaching) {
        final progress = pos.inSeconds / _duration.inSeconds;
        if (progress >= 0.6 && _precachedSong == null && !_isCrossfading) {
          _precacheNextSong();
        }
      }

      // Check for crossfade trigger
      if (_crossfadeEnabled && !_isCrossfading && _duration.inSeconds > 0) {
        final remaining = _duration.inSeconds - pos.inSeconds;
        if (remaining <= _crossfadeDuration && remaining > 0) {
          _startCrossfade();
        }
      }
    });

    _durationSubscription = player.durationStream.listen((dur) {
      if (_isDisposed) return;
      _duration = dur ?? Duration.zero;
      durationNotifier.value = dur ?? Duration.zero;

      // Update notification
      _audioHandler?.updateDuration(dur);

      notifyListeners(); // This is fine, only called once per song
    });

    _processingStateSubscription = player.processingStateStream.listen((state) {
      if (_isDisposed) return;
      if (state == ProcessingState.completed) {
        _handleSongComplete();
      }

      final wasLoading = _isLoading;
      _isLoading =
          state == ProcessingState.loading ||
          state == ProcessingState.buffering;

      // PERFORMANCE FIX: Only notify if loading state actually changed
      if (wasLoading != _isLoading) {
        notifyListeners();
      }
    });
  }

  // Helper method to cancel all player subscriptions
  void _cancelPlayerSubscriptions() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _processingStateSubscription?.cancel();
    _positionThrottleTimer?.cancel();

    _playerStateSubscription = null;
    _positionSubscription = null;
    _durationSubscription = null;
    _processingStateSubscription = null;
  }

  Future<void> _startCrossfade() async {
    if (_isCrossfading || _loopMode == LoopMode.one || _isDisposed) return;

    final nextSong = _getNextSongForCrossfade();
    if (nextSong == null) {
      debugPrint('❌ No next song available for crossfade');
      return;
    }

    _isCrossfading = true;

    // Calculate actual remaining time for crossfade
    final remainingSeconds = _duration.inMilliseconds > 0
        ? (_duration.inMilliseconds - _position.inMilliseconds) / 1000.0
        : _crossfadeDuration.toDouble();

    // Use the smaller of configured duration or remaining time (minus a small buffer)
    final actualCrossfadeDuration = math.min(
      _crossfadeDuration.toDouble(),
      math.max(
        remainingSeconds - 0.5,
        1.0,
      ), // At least 1 second, leave 0.5s buffer
    );

    debugPrint(
      '🎵 Starting crossfade to: ${nextSong.title} (${actualCrossfadeDuration.toStringAsFixed(1)}s)',
    );

    // Store reference to old player BEFORE any async operations
    final oldPlayer = _audioPlayer;
    AudioPlayer? newPlayer;

    try {
      // Use pre-cached player if available, otherwise create new one
      if (_precachePlayer != null && _precachedSong?.id == nextSong.id) {
        debugPrint('✅ Using pre-cached song for crossfade: ${nextSong.title}');
        newPlayer = _precachePlayer;
        _precachePlayer = null;
        _precachedSong = null;
      } else {
        debugPrint('⚠️ Pre-cache miss, loading song: ${nextSong.title}');
        newPlayer = AudioPlayer();

        final url = nextSong.playableUrl;
        if (url.isEmpty) {
          debugPrint('❌ No playable URL for crossfade song');
          newPlayer.dispose();
          _isCrossfading = false;
          return;
        }

        try {
          if (nextSong.isLocal) {
            await newPlayer.setFilePath(url);
          } else {
            await newPlayer.setUrl(url);
          }
        } catch (e) {
          debugPrint('❌ Failed to load crossfade song: $e');
          newPlayer.dispose();
          _isCrossfading = false;
          return;
        }
      }

      if (newPlayer == null || _isDisposed) {
        _isCrossfading = false;
        return;
      }

      // IMPORTANT: Store newPlayer in a local variable and DON'T use _crossfadePlayer during the loop
      final crossfadeNewPlayer = newPlayer;

      // Start playback at 0 volume
      await crossfadeNewPlayer.setVolume(0);
      await crossfadeNewPlayer.play();

      debugPrint('▶️ Crossfade player started playing');

      // Spotify-style crossfade with smooth curves
      // Use 10 steps/sec for stability, but adapt to actual duration
      final totalSteps = (actualCrossfadeDuration * 10).round();
      const stepDuration = Duration(milliseconds: 100);

      for (int i = 0; i <= totalSteps; i++) {
        // Check if we should stop
        if (_isDisposed) {
          debugPrint('⚠️ Crossfade interrupted - disposed at step $i');
          crossfadeNewPlayer.dispose();
          _isCrossfading = false;
          return;
        }

        final progress = totalSteps > 0 ? i / totalSteps : 1.0; // 0.0 to 1.0

        // Apply smooth volume curve
        final volumes = _calculateCrossfadeVolumes(progress);

        // Set volumes - use try-catch for each to handle disposed players
        try {
          oldPlayer.setVolume(volumes.fadeOut * _volume);
        } catch (e) {
          // Old player might be completed/disposed - that's OK
        }

        try {
          crossfadeNewPlayer.setVolume(volumes.fadeIn * _volume);
        } catch (e) {
          // New player issue - this is a problem, abort
          debugPrint('❌ New player volume error: $e');
          break;
        }

        await Future.delayed(stepDuration);
      }

      debugPrint('🔄 Crossfade loop complete, swapping players...');

      // Check if still valid
      if (_isDisposed) {
        crossfadeNewPlayer.dispose();
        _isCrossfading = false;
        return;
      }

      // Cancel subscriptions on old player BEFORE swapping
      _cancelPlayerSubscriptions();

      // Swap to the new player
      _audioPlayer = crossfadeNewPlayer;

      // Update current song and playlist state
      _currentSong = nextSong;
      if (_queue.isNotEmpty) {
        _queue.removeAt(0);
      } else if (_playlist.isNotEmpty) {
        _currentIndex = (_currentIndex + 1) % _playlist.length;
      }

      // Clear pre-cache state (will re-cache at 80% of new song)
      _precachedSong = null;
      _isPrecaching = false;

      // Ensure volume is set correctly on new player
      try {
        if (_volumeNormalization) {
          _applyVolumeNormalization();
        } else {
          await _audioPlayer.setVolume(_volume);
        }
      } catch (e) {
        debugPrint('Error setting volume on new player: $e');
      }

      // Setup listeners on the new player
      _setupPlayerListeners(_audioPlayer);

      // Update duration from new player
      _duration = _audioPlayer.duration ?? Duration.zero;
      durationNotifier.value = _duration;

      // Reset position
      _position = _audioPlayer.position;
      positionNotifier.value = _position;

      // Update notification with new song info
      try {
        await _audioHandler?.updateSongMediaItem(
          nextSong.title,
          nextSong.artist,
          nextSong.albumArt,
          _duration,
        );
      } catch (e) {
        debugPrint('Error updating notification: $e');
      }

      debugPrint('✅ Crossfade complete: ${nextSong.title}');

      // Now it's safe to set _isCrossfading to false
      _isCrossfading = false;
      _crossfadeJustCompleted =
          true; // Set flag to ignore stale completion events
      notifyListeners();

      // Stop and dispose old player in background (don't await)
      _disposeOldPlayer(oldPlayer);
    } catch (e) {
      debugPrint('❌ Crossfade error: $e');
      _isCrossfading = false;
      notifyListeners();

      // Fallback: try to play next song normally
      if (!_isDisposed) {
        debugPrint('🔄 Falling back to normal playback');
        await _playNextWithSmartAutoplay();
      }
    }
  }

  // Dispose old player in background to avoid blocking
  Future<void> _disposeOldPlayer(AudioPlayer player) async {
    try {
      await player.stop();
      await Future.delayed(const Duration(milliseconds: 200));
      await player.dispose();
      debugPrint('🗑️ Old player disposed');
    } catch (e) {
      debugPrint('Error disposing old player: $e');
    }
  }

  /// Calculate crossfade volumes using smooth curves (Spotify-style)
  /// Returns (fadeOut, fadeIn) volume multipliers between 0.0 and 1.0
  ({double fadeOut, double fadeIn}) _calculateCrossfadeVolumes(
    double progress,
  ) {
    switch (_crossfadeCurve) {
      case CrossfadeCurve.linear:
        // Simple linear crossfade (not recommended - sounds abrupt)
        return (fadeOut: 1.0 - progress, fadeIn: progress);

      case CrossfadeCurve.equalPower:
        // Equal power crossfade (Spotify default) - maintains constant perceived loudness
        // Uses sine/cosine curves: sqrt behavior for equal power
        final fadeOut = math.cos(progress * math.pi / 2);
        final fadeIn = math.sin(progress * math.pi / 2);
        return (fadeOut: fadeOut, fadeIn: fadeIn);

      case CrossfadeCurve.quadratic:
        // Quadratic ease - smooth acceleration/deceleration
        final fadeOut = 1.0 - (progress * progress);
        final fadeIn = progress * progress;
        return (fadeOut: fadeOut, fadeIn: fadeIn);

      case CrossfadeCurve.logarithmic:
        // Logarithmic curve - more natural for human hearing (dB scale)
        // Slower fade at the start, faster at the end
        final fadeOut = progress < 1.0
            ? math.pow(1.0 - progress, 2).toDouble()
            : 0.0;
        final fadeIn = progress > 0.0
            ? (1.0 - math.pow(1.0 - progress, 0.5)).toDouble()
            : 0.0;
        return (fadeOut: fadeOut, fadeIn: fadeIn);

      case CrossfadeCurve.sCurve:
        // S-curve (smoothstep) - very smooth transition, Spotify-like
        // Slow start, fast middle, slow end
        final t = progress * progress * (3.0 - 2.0 * progress); // smoothstep
        return (fadeOut: 1.0 - t, fadeIn: t);
    }
  }

  SongModel? _getNextSongForCrossfade() {
    if (_queue.isNotEmpty) {
      return _queue.first;
    }
    if (_playlist.isEmpty) return null;

    final nextIndex = (_currentIndex + 1) % _playlist.length;
    if (nextIndex == 0 && _loopMode == LoopMode.off) return null;

    return _playlist[nextIndex];
  }

  // Pre-cache the next song for gapless playback and crossfade
  Future<void> _precacheNextSong() async {
    // Prevent concurrent pre-cache operations
    if (_isPrecaching || _isDisposed) return;
    _isPrecaching = true;

    try {
      final nextSong = _getNextSongForCrossfade();
      if (nextSong == null) {
        return; // No next song
      }

      // Check if already cached
      if (nextSong.id == _precachedSong?.id) {
        return; // Already cached
      }

      debugPrint('🎵 Pre-caching next song: ${nextSong.title}');

      // Dispose old pre-cache player if exists
      final oldPrecachePlayer = _precachePlayer;
      _precachePlayer = null;

      if (oldPrecachePlayer != null) {
        try {
          await oldPrecachePlayer.dispose();
        } catch (e) {
          debugPrint('Error disposing old precache player: $e');
        }
      }

      // Create new pre-cache player
      final newPrecachePlayer = AudioPlayer();

      final url = nextSong.playableUrl;
      if (url.isEmpty) {
        debugPrint('❌ No playable URL for next song: ${nextSong.title}');
        newPrecachePlayer.dispose();
        return;
      }

      // Load the audio file (but don't play)
      try {
        // CRITICAL: Add preload to start buffering immediately
        if (nextSong.isLocal) {
          await newPrecachePlayer.setFilePath(url);
        } else {
          await newPrecachePlayer.setUrl(url);
        }
      } catch (e) {
        debugPrint('❌ Failed to load precache song: $e');
        newPrecachePlayer.dispose();
        return;
      }

      // Check if we're still in a valid state
      if (_isDisposed || _isCrossfading) {
        newPrecachePlayer.dispose();
        return;
      }

      // Set volume to 0 (ready for instant playback)
      await newPrecachePlayer.setVolume(0);

      // Store the pre-cached player and song
      _precachePlayer = newPrecachePlayer;
      _precachedSong = nextSong;

      debugPrint(
        '✅ Pre-cached, buffered & ready for INSTANT gapless playback: ${nextSong.title}',
      );
    } catch (e) {
      debugPrint('Error pre-caching next song: $e');
      _precachePlayer?.dispose();
      _precachePlayer = null;
      _precachedSong = null;
    } finally {
      _isPrecaching = false;
    }
  }

  /// CRITICAL FIX: Play next song using pre-cached player if available (INSTANT playback)
  Future<void> _playNextSongOptimized(SongModel nextSong) async {
    try {
      // Check if we have this song pre-cached
      if (_precachePlayer != null && _precachedSong?.id == nextSong.id) {
        debugPrint(
          '✅ INSTANT GAPLESS playback using pre-cached player: ${nextSong.title}',
        );

        // Store old player for cleanup
        final oldPlayer = _audioPlayer;

        // Swap to pre-cached player (already loaded and buffered!)
        _audioPlayer = _precachePlayer!;
        _precachePlayer = null;
        _precachedSong = null;

        // Update state IMMEDIATELY
        _currentSong = nextSong;
        _isPrecaching = false;

        // CRITICAL: Set volume to playing level and start IMMEDIATELY
        final targetVolume = _volumeNormalization ? _normalizedVolume : _volume;

        // Use a single atomic operation - set volume and play together
        await Future.wait([
          _audioPlayer.setVolume(targetVolume),
          _audioPlayer.play(),
        ]);

        debugPrint(
          '🚀 TRUE GAPLESS - Audio decoder already initialized, playing instantly!',
        );

        // NOW setup listeners and update UI (after audio is already playing)
        _cancelPlayerSubscriptions();
        _setupPlayerListeners(_audioPlayer);

        // Get duration
        _duration = _audioPlayer.duration ?? Duration.zero;
        durationNotifier.value = _duration;
        _position = Duration.zero;
        positionNotifier.value = Duration.zero;

        // Update notification in background (don't block!)
        _audioHandler?.updateSongMediaItem(
          nextSong.title,
          nextSong.artist,
          nextSong.albumArt,
          _duration,
        );

        // Dispose old player in background (don't block)
        _disposeOldPlayer(oldPlayer);

        notifyListeners();
        return;
      }

      // Pre-cache not available - fall back to normal loading
      debugPrint(
        '⚠️ Pre-cache not available for ${nextSong.title} - loading normally',
      );
      await playSong(nextSong);
    } catch (e) {
      debugPrint('Error in optimized playback: $e');
      // Fallback to normal playback
      await playSong(nextSong);
    }
  }

  Future<void> playSong(SongModel song, {List<SongModel>? playlist}) async {
    try {
      // Cancel any ongoing crossfade
      _isCrossfading = false;
      _crossfadePlayer?.stop();
      _crossfadePlayer?.dispose();
      _crossfadePlayer = null;

      // Clear pre-cache when manually changing songs
      _precachePlayer?.dispose();
      _precachePlayer = null;
      _precachedSong = null;

      _isLoading = true;
      notifyListeners();

      if (playlist != null) {
        _playlist = List.from(playlist);
        _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
        if (_currentIndex == -1) _currentIndex = 0;
      }

      _currentSong = song;

      final url = song.playableUrl;
      if (url.isEmpty) {
        debugPrint('No playable URL for song: ${song.title}');
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (song.isLocal) {
        await _audioPlayer.setFilePath(url);
      } else {
        await _audioPlayer.setUrl(url);
      }

      if (_volumeNormalization) {
        _applyVolumeNormalization();
      }

      // CRITICAL FIX: Update notification BEFORE starting playback
      // This ensures the notification appears immediately
      await _audioHandler?.updateSongMediaItem(
        song.title,
        song.artist,
        song.albumArt,
        _audioPlayer.duration ?? Duration.zero,
      );

      // Now start playback - notification will be visible
      await _audioPlayer.play();

      // Track song play for recommendations
      try {
        final recommendationService = RecommendationService();
        await recommendationService.trackSongPlay(song);
      } catch (e) {
        debugPrint('Error tracking song play: $e');
      }
    } catch (e) {
      debugPrint('Error playing song: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // Queue management
  void addToQueue(SongModel song) {
    _queue.add(song);
    notifyListeners();
  }

  void addToQueueNext(SongModel song) {
    _queue.insert(0, song);
    notifyListeners();
  }

  void addAllToQueue(List<SongModel> songs) {
    _queue.addAll(songs);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      notifyListeners();
    }
  }

  void removeFromQueueBySong(SongModel song) {
    _queue.removeWhere((s) => s.id == song.id);
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final song = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, song);
    notifyListeners();
  }

  bool isInQueue(SongModel song) => _queue.any((s) => s.id == song.id);

  Future<void> playNext() async {
    await _playNextWithSmartAutoplay();
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;

    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_loopMode == LoopMode.all) {
      _currentIndex = _playlist.length - 1;
    } else {
      await seek(Duration.zero);
      return;
    }

    await playSong(_playlist[_currentIndex]);
  }

  void toggleShuffle() {
    _isShuffleOn = !_isShuffleOn;
    if (_isShuffleOn && _playlist.isNotEmpty) {
      // FIX: Create a copy of the playlist and shuffle it completely
      // Don't preserve the current song position - shuffle everything including first song
      final shuffledPlaylist = List<SongModel>.from(_playlist)..shuffle();
      _playlist = shuffledPlaylist;
      // Reset to first song of shuffled playlist
      _currentIndex = 0;
      debugPrint(
        '🔀 Shuffle enabled - playlist shuffled, starting from: ${_playlist[0].title}',
      );
    }
    notifyListeners();
  }

  void toggleLoopMode() {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        _audioPlayer.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
    }
    notifyListeners();
  }

  void _handleSongComplete() {
    // If crossfade is actively running, it will handle the transition
    if (_isCrossfading) {
      debugPrint(
        '🔄 Song completed during crossfade - crossfade will handle transition',
      );
      return;
    }

    // If crossfade just completed, ignore this stale completion event from the old player
    if (_crossfadeJustCompleted) {
      debugPrint('🔄 Ignoring stale completion event after crossfade');
      _crossfadeJustCompleted = false; // Reset the flag
      return;
    }

    if (_loopMode == LoopMode.one) {
      seek(Duration.zero);
      _audioPlayer.play();
    } else {
      _playNextWithSmartAutoplay();
    }
  }

  // Smart autoplay: plays from queue first, then recommendations
  Future<void> _playNextWithSmartAutoplay() async {
    // Skip if crossfade is handling transition
    if (_isCrossfading) return;

    // Priority 1: Queue
    if (_queue.isNotEmpty) {
      final nextSong = _queue.removeAt(0);
      notifyListeners();
      // FIX: Use pre-cached player if available instead of reloading
      await _playNextSongOptimized(nextSong);
      return;
    }

    // Priority 2: Playlist
    if (_playlist.isNotEmpty) {
      if (_isShuffleOn) {
        _currentIndex = (_currentIndex + 1) % _playlist.length;
      } else if (_currentIndex < _playlist.length - 1) {
        _currentIndex++;
      } else if (_loopMode == LoopMode.all) {
        _currentIndex = 0;
      } else {
        // Playlist ended, load recommendations
        await _loadSmartRecommendations();
        return;
      }
      // FIX: Use pre-cached player if available
      await _playNextSongOptimized(_playlist[_currentIndex]);
      return;
    }

    // Priority 3: Load smart recommendations based on current song
    await _loadSmartRecommendations();
  }

  // Load recommendations based on current song's artist (FAST version)
  Future<void> _loadSmartRecommendations() async {
    if (_currentSong == null) return;

    try {
      debugPrint('🎵 Loading similar songs for: ${_currentSong!.artist}');

      // Use MusicApiService to search for songs from SAME artist + similar style
      final musicApiService = MusicApiService();
      final recommendedSongs = <SongModel>[];

      // Priority 1: Get more songs from SAME artist (similar to current song)
      try {
        final artistSongs = await musicApiService
            .searchSongs(_currentSong!.artist)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => <SongModel>[],
            );

        // Remove the current song from recommendations
        artistSongs.removeWhere((song) => song.id == _currentSong!.id);

        recommendedSongs.addAll(artistSongs.take(10));
        debugPrint(
          '✅ Found ${artistSongs.length} songs from ${_currentSong!.artist}',
        );
      } catch (e) {
        debugPrint('Error fetching songs for ${_currentSong!.artist}: $e');
      }

      // Priority 2: If from search context, add songs from user's favorite artists
      if (recommendedSongs.length < 10) {
        final recommendationService = RecommendationService();
        final similarArtists = await recommendationService.getContextForArtist(
          _currentSong!.artist,
        );

        for (final artist in similarArtists.take(2)) {
          if (artist == _currentSong!.artist) continue; // Skip same artist

          try {
            final songs = await musicApiService
                .searchSongs(artist)
                .timeout(
                  const Duration(seconds: 5),
                  onTimeout: () => <SongModel>[],
                );
            recommendedSongs.addAll(songs.take(5));

            if (recommendedSongs.length >= 15) break;
          } catch (e) {
            debugPrint('Error fetching songs for $artist: $e');
          }
        }
      }

      if (recommendedSongs.isNotEmpty) {
        // Update playlist with recommendations
        _playlist = recommendedSongs.take(15).toList();
        _currentIndex = 0;

        // Play first recommended song
        await playSong(_playlist[0]);

        debugPrint(
          '✅ Autoplay: ${_playlist[0].title} by ${_playlist[0].artist}',
        );
      }
    } catch (e) {
      debugPrint('Error loading smart recommendations for autoplay: $e');
    }
  }

  // Play song with smart context awareness
  Future<void> playSongWithContext(
    SongModel song, {
    List<SongModel>? playlist,
    String? context,
  }) async {
    try {
      // Cancel any ongoing crossfade
      _isCrossfading = false;
      _crossfadePlayer?.stop();
      _crossfadePlayer?.dispose();
      _crossfadePlayer = null;

      // Clear pre-cache when manually changing songs
      _precachePlayer?.dispose();
      _precachePlayer = null;
      _precachedSong = null;

      _isLoading = true;
      notifyListeners();

      // FIX: If from search, DON'T use search results as playlist
      if (context == 'search') {
        _playlist = [song]; // Only current song
        _currentIndex = 0;
        debugPrint('🔍 Search context: Will play similar songs after this');
      } else if (playlist != null) {
        _playlist = List.from(playlist);
        _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
        if (_currentIndex == -1) _currentIndex = 0;
      } else {
        _playlist = [song];
        _currentIndex = 0;
      }

      _currentSong = song;

      final url = song.playableUrl;
      if (url.isEmpty) {
        debugPrint('No playable URL for song: ${song.title}');
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (song.isLocal) {
        await _audioPlayer.setFilePath(url);
      } else {
        await _audioPlayer.setUrl(url);
      }

      if (_volumeNormalization) {
        _applyVolumeNormalization();
      }

      // CRITICAL FIX: Update notification BEFORE starting playback
      // This ensures the notification appears immediately
      await _audioHandler?.updateSongMediaItem(
        song.title,
        song.artist,
        song.albumArt,
        _audioPlayer.duration ?? Duration.zero,
      );

      // Now start playback - notification will be visible
      await _audioPlayer.play();

      // Track song play for recommendations
      try {
        final recommendationService = RecommendationService();
        await recommendationService.trackSongPlay(song);
      } catch (e) {
        debugPrint('Error tracking song play: $e');
      }
    } catch (e) {
      debugPrint('Error playing song: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    if (_volumeNormalization) {
      _applyVolumeNormalization();
    } else {
      await _audioPlayer.setVolume(volume);
    }
    notifyListeners();
  }

  // Configure crossfade
  void setCrossfade(bool enabled, int durationSeconds) {
    _crossfadeEnabled = enabled;
    _crossfadeDuration = durationSeconds.clamp(1, 12);
    notifyListeners();
  }

  // Configure crossfade curve type
  void setCrossfadeCurve(CrossfadeCurve curve) {
    _crossfadeCurve = curve;
    notifyListeners();
  }

  // Configure volume normalization
  void setVolumeNormalization(bool enabled) {
    _volumeNormalization = enabled;
    if (enabled) {
      _applyVolumeNormalization();
    } else {
      _audioPlayer.setVolume(_volume);
    }
    notifyListeners();
  }

  void _applyVolumeNormalization() {
    // Simple normalization - reduces loud peaks
    _normalizedVolume = _volume * 0.85;
    _audioPlayer.setVolume(_normalizedVolume);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSong = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isCrossfading = false;

    _cancelPlayerSubscriptions();

    // Dispose players safely
    try {
      _crossfadePlayer?.dispose();
    } catch (e) {
      debugPrint('Error disposing crossfade player: $e');
    }

    try {
      _precachePlayer?.dispose();
    } catch (e) {
      debugPrint('Error disposing precache player: $e');
    }

    try {
      _audioPlayer.dispose();
    } catch (e) {
      debugPrint('Error disposing audio player: $e');
    }

    positionNotifier.dispose();
    durationNotifier.dispose();
    playingNotifier.dispose();
    super.dispose();
  }
}

/// Crossfade curve types for different transition styles
enum CrossfadeCurve {
  /// Linear crossfade - simple but can sound abrupt
  linear,
  
  /// Equal power crossfade (Spotify default) - maintains constant perceived loudness
  equalPower,

  /// Quadratic ease - smooth acceleration/deceleration
  quadratic,

  /// Logarithmic curve - more natural for human hearing (follows dB scale)
  logarithmic,

  /// S-curve (smoothstep) - very smooth transition with slow start/end
  sCurve,
}
