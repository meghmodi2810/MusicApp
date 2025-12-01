import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song_model.dart';
import '../services/recommendation_service.dart';
import '../services/audio_handler_service.dart';

class MusicPlayerProvider extends ChangeNotifier {
  AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer? _crossfadePlayer; // Secondary player for crossfade
  AudioPlayerHandler? _audioHandler;
  
  // Stream subscriptions for cleanup
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _processingStateSubscription;
  
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
      
      // Initialize audio service for notifications
      _audioHandler = await AudioService.init(
        builder: () => AudioPlayerHandler(_audioPlayer),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.pancaketunes.app.channel.audio',
          androidNotificationChannelName: 'Pancake Tunes',
          androidNotificationOngoing: true,
          androidShowNotificationBadge: true,
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

    _playerStateSubscription = player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _positionSubscription = player.positionStream.listen((pos) {
      _position = pos;
      
      // Check for crossfade trigger
      if (_crossfadeEnabled && !_isCrossfading && _duration.inSeconds > 0) {
        final remaining = _duration.inSeconds - pos.inSeconds;
        if (remaining <= _crossfadeDuration && remaining > 0) {
          _startCrossfade();
        }
      }
      
      notifyListeners();
    });

    _durationSubscription = player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
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
    // For true normalization, you'd analyze audio loudness (LUFS)
    _normalizedVolume = _volume * 0.85;
    _audioPlayer.setVolume(_normalizedVolume);
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
    // Skip if crossfade is handling transition
    if (_isCrossfading) return;
    
    if (_queue.isNotEmpty) {
      final nextSong = _queue.removeAt(0);
      notifyListeners();
      await playSong(nextSong);
      return;
    }

    if (_playlist.isEmpty) return;

    if (_isShuffleOn) {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    } else if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
    } else if (_loopMode == LoopMode.all) {
      _currentIndex = 0;
    } else {
      return;
    }

    await playSong(_playlist[_currentIndex]);
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
      playNext();
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

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSong = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _processingStateSubscription?.cancel();
    _crossfadePlayer?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
