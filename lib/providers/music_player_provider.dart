import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/song_model.dart';

class MusicPlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  SongModel? _currentSong;
  List<SongModel> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffleOn = false;
  LoopMode _loopMode = LoopMode.off;
  double _volume = 1.0;

  // Getters
  SongModel? get currentSong => _currentSong;
  List<SongModel> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isShuffleOn => _isShuffleOn;
  LoopMode get loopMode => _loopMode;
  double get volume => _volume;
  AudioPlayer get audioPlayer => _audioPlayer;

  MusicPlayerProvider() {
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // Configure audio session
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      print('Error configuring audio session: $e');
    }

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    // Listen to when song completes
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handleSongComplete();
      }
      _isLoading = state == ProcessingState.loading || 
                   state == ProcessingState.buffering;
      notifyListeners();
    });
  }

  // Play a song
  Future<void> playSong(SongModel song, {List<SongModel>? playlist}) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (playlist != null) {
        _playlist = playlist;
        _currentIndex = playlist.indexOf(song);
        if (_currentIndex == -1) _currentIndex = 0;
      }

      _currentSong = song;

      final url = song.playableUrl;
      if (url.isEmpty) {
        print('No playable URL for song: ${song.title}');
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (song.isLocal) {
        await _audioPlayer.setFilePath(url);
      } else {
        await _audioPlayer.setUrl(url);
      }

      await _audioPlayer.play();
    } catch (e) {
      print('Error playing song: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // Play next song
  Future<void> playNext() async {
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

  // Play previous song
  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;

    // If more than 3 seconds in, restart song
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

  // Toggle shuffle
  void toggleShuffle() {
    _isShuffleOn = !_isShuffleOn;
    if (_isShuffleOn && _playlist.isNotEmpty) {
      final current = _playlist[_currentIndex];
      _playlist.shuffle();
      _currentIndex = _playlist.indexOf(current);
    }
    notifyListeners();
  }

  // Toggle loop mode
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

  // Handle song completion
  void _handleSongComplete() {
    if (_loopMode == LoopMode.one) {
      seek(Duration.zero);
      _audioPlayer.play();
    } else {
      playNext();
    }
  }

  // Set volume
  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _audioPlayer.setVolume(volume);
    notifyListeners();
  }

  // Stop playback
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSong = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
