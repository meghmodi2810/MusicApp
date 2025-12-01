import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _audioPlayer;
  late StreamSubscription<PlaybackEvent> _playbackEventSubscription;
  
  AudioPlayerHandler(this._audioPlayer) {
    // Broadcast playback state changes
    _playbackEventSubscription = _audioPlayer.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          print('Playback error: $e');
        }
      },
    );
  }

  // Broadcast the current state to all audio_service clients
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
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingState,
      playing: playing,
      updatePosition: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      speed: _audioPlayer.speed,
      queueIndex: 0,
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
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _playbackEventSubscription.cancel();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    // Handled by MusicPlayerProvider
  }

  @override
  Future<void> skipToPrevious() async {
    // Handled by MusicPlayerProvider
  }

  // Custom method to update media item (not overriding base class)
  Future<void> updateSongMediaItem(String title, String artist, String? artUri, Duration? duration) async {
    mediaItem.add(MediaItem(
      id: title,
      title: title,
      artist: artist,
      duration: duration,
      artUri: artUri != null ? Uri.parse(artUri) : null,
      playable: true,
    ));
  }

  // Update duration separately
  Future<void> updateDuration(Duration? duration) async {
    final current = mediaItem.value;
    if (current != null && duration != null) {
      mediaItem.add(current.copyWith(duration: duration));
    }
  }
}
