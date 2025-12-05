import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// Complete Spotify-style notification handler
class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  AudioPlayer _audioPlayer;
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  final Future<void> Function()? onNext;
  final Future<void> Function()? onPrevious;
  final Future<void> Function()? onStop;

  final Map<String, Uri> _artworkCache = {};
  static const int _maxCacheSize = 50;
  bool _isNotificationActive = false;

  AudioPlayerHandler(
    this._audioPlayer, {
    this.onNext,
    this.onPrevious,
    this.onStop,
  }) {
    _init();
  }

  void updateAudioPlayer(AudioPlayer newPlayer) {
    debugPrint('🔄 AudioHandler: Updating audio player reference');
    _cancelSubscriptions();
    _audioPlayer = newPlayer;
    _setupListeners();
    _broadcastState(_audioPlayer.playbackEvent);
  }

  void _cancelSubscriptions() {
    _playbackEventSubscription?.cancel();
    _durationSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _playerStateSubscription?.cancel();
  }

  void _setupListeners() {
    _playbackEventSubscription = _audioPlayer.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace st) {
        if (kDebugMode) debugPrint('❌ Playback error: $e');
      },
    );

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      debugPrint(
        '🎵 Player state: playing=${state.playing}, state=${state.processingState}',
      );
      _broadcastState(_audioPlayer.playbackEvent);
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current != null && duration != null) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });

    _currentIndexSubscription = _audioPlayer.currentIndexStream.listen((index) {
      if (index != null) {
        playbackState.add(playbackState.value.copyWith(queueIndex: index));
      }
    });
  }

  Future<void> _init() async {
    debugPrint('🔔 AudioHandler: Initializing...');

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.play,
          MediaAction.pause,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.stop,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );

    _setupListeners();
    debugPrint('✅ AudioHandler: Initialized');
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _audioPlayer.playing;
    final processingState = _mapProcessingState(_audioPlayer.processingState);

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.play,
          MediaAction.pause,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.stop,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: playing,
        updatePosition: _audioPlayer.position,
        bufferedPosition: _audioPlayer.bufferedPosition,
        speed: _audioPlayer.speed,
        queueIndex: _audioPlayer.currentIndex ?? 0,
      ),
    );

    if (playing && mediaItem.value != null && !_isNotificationActive) {
      _isNotificationActive = true;
      debugPrint('🔔 Notification should be visible now!');
    }
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() async {
    debugPrint('📱 Notification: PLAY');
    await _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    debugPrint('📱 Notification: PAUSE');
    await _audioPlayer.pause();
  }

  @override
  Future<void> seek(Duration position) async =>
      await _audioPlayer.seek(position);

  @override
  Future<void> skipToNext() async {
    debugPrint('📱 Notification: NEXT');
    if (onNext != null) await onNext!();
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('📱 Notification: PREVIOUS');
    if (onPrevious != null) await onPrevious!();
  }

  @override
  Future<void> stop() async {
    debugPrint('📱 Notification: STOP');
    _isNotificationActive = false;
    if (onStop != null) await onStop!();
    await _audioPlayer.stop();
    playbackState.add(
      PlaybackState(
        controls: [],
        systemActions: const {},
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  @override
  Future<void> fastForward() async {
    final newPos = _audioPlayer.position + const Duration(seconds: 10);
    final dur = _audioPlayer.duration ?? Duration.zero;
    await _audioPlayer.seek(newPos > dur ? dur : newPos);
  }

  @override
  Future<void> rewind() async {
    final newPos = _audioPlayer.position - const Duration(seconds: 10);
    await _audioPlayer.seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  @override
  Future<void> setSpeed(double speed) async =>
      await _audioPlayer.setSpeed(speed);

  @override
  Future<void> onTaskRemoved() async =>
      debugPrint('📱 App task removed - audio continues');

  @override
  Future<void> onNotificationDeleted() async {
    debugPrint('📱 Notification dismissed');
    _isNotificationActive = false;
    await stop();
  }

  Future<void> updateSongMediaItem(
    String title,
    String artist,
    String? artUri,
    Duration? duration,
  ) async {
    debugPrint('📱 Updating media item: $title by $artist');

    Uri? finalArtUri;
    if (artUri != null && artUri.isNotEmpty) {
      try {
        finalArtUri = await _getCachedArtwork(artUri);
      } catch (e) {
        debugPrint('⚠️ Artwork error: $e');
      }
    }

    final newMediaItem = MediaItem(
      id: '${title}_$artist',
      title: title,
      artist: artist,
      duration: duration ?? Duration.zero,
      artUri: finalArtUri,
      playable: true,
      album: artist,
      displayTitle: title,
      displaySubtitle: artist,
    );

    mediaItem.add(newMediaItem);
    debugPrint('✅ Media item added: ${newMediaItem.title}');
    
    // CRITICAL FIX: Force notification to show by updating playback state
    _isNotificationActive = true;
    _broadcastState(_audioPlayer.playbackEvent);
    
    // Extra nudge for Android to show the notification
    await Future.delayed(const Duration(milliseconds: 100));
    _broadcastState(_audioPlayer.playbackEvent);
    
    debugPrint('🔔 Notification should now be visible!');
  }

  Future<Uri?> _getCachedArtwork(String artUri) async {
    try {
      if (_artworkCache.containsKey(artUri)) return _artworkCache[artUri];

      if (artUri.startsWith('/') || artUri.startsWith('file://')) {
        final uri = artUri.startsWith('file://')
            ? Uri.parse(artUri)
            : Uri.file(artUri);
        _addToCache(artUri, uri);
        return uri;
      }

      if (artUri.startsWith('http')) {
        final uri = Uri.parse(artUri);
        _addToCache(artUri, uri);
        _downloadAndCacheArtwork(artUri);
        return uri;
      }

      return Uri.parse(artUri);
    } catch (e) {
      debugPrint('⚠️ Artwork cache error: $e');
      return artUri.isNotEmpty ? Uri.parse(artUri) : null;
    }
  }

  Future<File?> _downloadAndCacheArtwork(String url) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final file = File('${cacheDir.path}/artwork_${url.hashCode}.jpg');
      if (await file.exists()) return file;

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        _artworkCache[url] = Uri.file(file.path);
        return file;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to cache artwork: $e');
    }
    return null;
  }

  void _addToCache(String key, Uri uri) {
    if (_artworkCache.length >= _maxCacheSize) {
      final keysToRemove = _artworkCache.keys.take(10).toList();
      for (final k in keysToRemove) _artworkCache.remove(k);
    }
    _artworkCache[key] = uri;
  }

  Future<void> updateDuration(Duration? duration) async {
    final current = mediaItem.value;
    if (current != null && duration != null) {
      mediaItem.add(current.copyWith(duration: duration));
    }
  }

  void clearMediaItem() {
    _isNotificationActive = false;
    mediaItem.add(null);
  }

  Future<void> dispose() async {
    _cancelSubscriptions();
    _artworkCache.clear();
  }
}
