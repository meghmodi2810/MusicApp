import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Complete Spotify-style notification handler
/// Provides media controls in notification bar, lock screen, and Android Auto
class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _audioPlayer;
  late StreamSubscription<PlaybackEvent> _playbackEventSubscription;
  late StreamSubscription<Duration?> _durationSubscription;
  late StreamSubscription<int?> _currentIndexSubscription;
  
  // Callbacks for next/previous from notification
  final Future<void> Function()? onNext;
  final Future<void> Function()? onPrevious;
  final Future<void> Function()? onStop;
  
  AudioPlayerHandler(
    this._audioPlayer, {
    this.onNext,
    this.onPrevious,
    this.onStop,
  }) {
    // Broadcast playback state changes
    _playbackEventSubscription = _audioPlayer.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('Playback error: $e');
        }
      },
    );

    // Listen to duration changes
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current != null && duration != null) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });

    // Listen to queue index changes
    _currentIndexSubscription = _audioPlayer.currentIndexStream.listen((index) {
      if (index != null) {
        playbackState.add(playbackState.value.copyWith(queueIndex: index));
      }
    });
  }

  /// Broadcast the current state to notification bar
  Future<void> _broadcastState(PlaybackEvent event) async {
    final playing = _audioPlayer.playing;
    final processingState = _mapProcessingState(_audioPlayer.processingState);
    
    playbackState.add(playbackState.value.copyWith(
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
      },
      androidCompactActionIndices: const [0, 1, 2], // Show previous, play/pause, next in compact view
      processingState: processingState,
      playing: playing,
      updatePosition: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      speed: _audioPlayer.speed,
      queueIndex: _audioPlayer.currentIndex ?? 0,
    ));
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

  // ==========================================
  // NOTIFICATION CONTROLS
  // ==========================================

  @override
  Future<void> play() async {
    await _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (onNext != null) {
      await onNext!();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (onPrevious != null) {
      await onPrevious!();
    }
  }

  @override
  Future<void> stop() async {
    if (onStop != null) {
      await onStop!();
    }
    await _audioPlayer.stop();
    await _playbackEventSubscription.cancel();
    await _durationSubscription.cancel();
    await _currentIndexSubscription.cancel();
    await super.stop();
  }

  @override
  Future<void> fastForward() async {
    await _audioPlayer.seek(_audioPlayer.position + const Duration(seconds: 10));
  }

  @override
  Future<void> rewind() async {
    await _audioPlayer.seek(_audioPlayer.position - const Duration(seconds: 10));
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
  }

  // ==========================================
  // MEDIA ITEM UPDATES (Song Info in Notification)
  // ==========================================

  /// Update notification with current song details
  Future<void> updateSongMediaItem(
    String title,
    String artist,
    String? artUri,
    Duration? duration,
  ) async {
    mediaItem.add(MediaItem(
      id: title,
      title: title,
      artist: artist,
      duration: duration,
      artUri: artUri != null && artUri.isNotEmpty ? Uri.parse(artUri) : null,
      playable: true,
      album: artist,
      displayTitle: title,
      displaySubtitle: artist,
    ));
  }

  /// Update duration separately (when it becomes available)
  Future<void> updateDuration(Duration? duration) async {
    final current = mediaItem.value;
    if (current != null && duration != null) {
      mediaItem.add(current.copyWith(duration: duration));
    }
  }

  /// Update queue for better Android Auto support
  Future<void> updateQueue(List<MediaItem> queueItems) async {
    queue.add(queueItems);
  }
}
