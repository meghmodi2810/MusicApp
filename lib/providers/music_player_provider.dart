import 'dart:async';
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
  AudioPlayerHandler? _audioHandler;
  
  // Stream subscriptions for cleanup
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _processingStateSubscription;
  
  // PERFORMANCE OPTIMIZATION: Throttle timer for position updates
  Timer? _positionThrottleTimer;
  Duration _lastEmittedPosition = Duration.zero;
  static const _positionUpdateInterval = Duration(milliseconds: 200); // 5 updates/sec instead of 60
  
  SongModel? _currentSong;
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
  
  // Volume normalization
  bool _volumeNormalization = false;
  double _normalizedVolume = 1.0;

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
          androidNotificationOngoing: false, // FIX: Changed to false to work with androidStopForegroundOnPause
          androidShowNotificationBadge: true,
          androidStopForegroundOnPause: true,
          artDownscaleWidth: 200,
          artDownscaleHeight: 200,
          fastForwardInterval: const Duration(seconds: 10),
          rewindInterval: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error configuring audio session: $e');
    }

    _setupPlayerListeners(_audioPlayer);
  }

  void _setupPlayerListeners(AudioPlayer player) {
    // Cancel existing subscriptions
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _processingStateSubscription?.cancel();
    _positionThrottleTimer?.cancel();

    _playerStateSubscription = player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      playingNotifier.value = state.playing;
      notifyListeners();
    });

    // PERFORMANCE FIX: Throttle position updates
    _positionSubscription = player.positionStream.listen((pos) {
      _position = pos;
      positionNotifier.value = pos;
      
      // Only notify listeners every 200ms instead of 60fps
      if (_positionThrottleTimer == null || !_positionThrottleTimer!.isActive) {
        if ((pos - _lastEmittedPosition).abs() > const Duration(milliseconds: 200)) {
          _lastEmittedPosition = pos;
          notifyListeners();
          
          _positionThrottleTimer = Timer(_positionUpdateInterval, () {});
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
      _duration = dur ?? Duration.zero;
      durationNotifier.value = dur ?? Duration.zero;
      
      // Update notification
      _audioHandler?.updateDuration(dur);
      
      notifyListeners();
    });

    _processingStateSubscription = player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handleSongComplete();
      }
      _isLoading = state == ProcessingState.loading || 
                   state == ProcessingState.buffering;
      notifyListeners();
    });
  }

  Future<void> _startCrossfade() async {
    if (_isCrossfading || _loopMode == LoopMode.one) return;
    
    final nextSong = _getNextSongForCrossfade();
    if (nextSong == null) return;

    _isCrossfading = true;
    
    try {
      // Create secondary player for crossfade
      _crossfadePlayer = AudioPlayer();
      
      final url = nextSong.playableUrl;
      if (url.isEmpty) {
        _isCrossfading = false;
        return;
      }

      if (nextSong.isLocal) {
        await _crossfadePlayer!.setFilePath(url);
      } else {
        await _crossfadePlayer!.setUrl(url);
      }

      // Start at 0 volume
      await _crossfadePlayer!.setVolume(0);
      await _crossfadePlayer!.play();

      // Animate volume crossfade
      final steps = _crossfadeDuration * 10; // 10 steps per second
      const stepDuration = Duration(milliseconds: 100);
      
      for (int i = 0; i <= steps; i++) {
        if (!_isCrossfading) break;
        
        final progress = i / steps;
        final fadeOutVolume = _volume * (1 - progress);
        final fadeInVolume = _volume * progress;
        
        await _audioPlayer.setVolume(fadeOutVolume);
        await _crossfadePlayer?.setVolume(fadeInVolume);
        
        await Future.delayed(stepDuration);
      }

      // Complete the crossfade - swap the players
      if (_isCrossfading && _crossfadePlayer != null) {
        // Store reference to old player for disposal
        final oldPlayer = _audioPlayer;
        
        // Swap to the new player
        _audioPlayer = _crossfadePlayer!;
        _crossfadePlayer = null;
        
        // Update current song and playlist state
        _currentSong = nextSong;
        if (_queue.isNotEmpty) {
          _queue.removeAt(0);
        } else if (_playlist.isNotEmpty) {
          _currentIndex = (_currentIndex + 1) % _playlist.length;
        }
        
        // Ensure volume is set correctly
        if (_volumeNormalization) {
          _applyVolumeNormalization();
        } else {
          await _audioPlayer.setVolume(_volume);
        }
        
        // Setup listeners on the new player
        _setupPlayerListeners(_audioPlayer);
        
        // Stop and dispose old player
        await oldPlayer.stop();
        await oldPlayer.dispose();
      }
    } catch (e) {
      debugPrint('Crossfade error: $e');
      _crossfadePlayer?.dispose();
      _crossfadePlayer = null;
    } finally {
      _isCrossfading = false;
      notifyListeners();
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

  Future<void> playSong(SongModel song, {List<SongModel>? playlist}) async {
    try {
      // Cancel any ongoing crossfade
      _isCrossfading = false;
      _crossfadePlayer?.stop();
      _crossfadePlayer?.dispose();
      _crossfadePlayer = null;
      
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

      // Update notification with song info
      await _audioHandler?.updateSongMediaItem(
        song.title,
        song.artist,
        song.albumArt,
        _duration,
      );

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
      final current = _playlist[_currentIndex];
      _playlist.shuffle();
      _currentIndex = _playlist.indexOf(current);
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
    if (_crossfadeEnabled && !_isCrossfading) {
      // Crossfade should have already handled this
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
      await playSong(nextSong);
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
      await playSong(_playlist[_currentIndex]);
      return;
    }

    // Priority 3: Load smart recommendations based on current song
    await _loadSmartRecommendations();
  }

  // Load recommendations based on current song's artist (FAST version)
  Future<void> _loadSmartRecommendations() async {
    if (_currentSong == null) return;

    try {
      final recommendationService = RecommendationService();
      
      // FAST: Get similar artists instantly (no API calls)
      final similarArtists = await recommendationService.getContextForArtist(_currentSong!.artist);
      
      if (similarArtists.isEmpty) {
        debugPrint('No similar artists found for autoplay');
        return;
      }

      debugPrint('🎵 Loading similar songs for: ${_currentSong!.artist}');
      debugPrint('🎯 Similar artists: ${similarArtists.take(3).join(", ")}');

      // Use MusicApiService to search for songs from similar artists
      final musicApiService = MusicApiService();
      final recommendedSongs = <SongModel>[];
      
      // Get songs from top 2 similar artists only (faster)
      for (final artist in similarArtists.take(2)) {
        try {
          final songs = await musicApiService.searchSongs(artist)
            .timeout(const Duration(seconds: 5), onTimeout: () => <SongModel>[]);
          recommendedSongs.addAll(songs.take(5));
          
          // Break early if we have enough songs
          if (recommendedSongs.length >= 10) break;
        } catch (e) {
          debugPrint('Error fetching songs for $artist: $e');
        }
      }

      if (recommendedSongs.isNotEmpty) {
        // Update playlist with recommendations (no sorting for speed)
        _playlist = recommendedSongs.take(15).toList();
        _currentIndex = 0;
        
        // Play first recommended song
        await playSong(_playlist[0]);
        
        debugPrint('✅ Autoplay: ${_playlist[0].title} by ${_playlist[0].artist}');
      }
    } catch (e) {
      debugPrint('Error loading smart recommendations for autoplay: $e');
    }
  }

  // Play song with smart context awareness
  Future<void> playSongWithContext(SongModel song, {List<SongModel>? playlist, String? context}) async {
    try {
      // Cancel any ongoing crossfade
      _isCrossfading = false;
      _crossfadePlayer?.stop();
      _crossfadePlayer?.dispose();
      _crossfadePlayer = null;
      
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

      // Update notification with song info
      await _audioHandler?.updateSongMediaItem(
        song.title,
        song.artist,
        song.albumArt,
        _duration,
      );

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
    _positionThrottleTimer?.cancel();
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _processingStateSubscription?.cancel();
    _crossfadePlayer?.dispose();
    _audioPlayer.dispose();
    positionNotifier.dispose();
    durationNotifier.dispose();
    playingNotifier.dispose();
    super.dispose();
  }
}
