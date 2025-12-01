import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _audioPlayer;
  
  AudioPlayerHandler(this._audioPlayer) {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      playbackState.add(playbackState.value.copyWith(
        playing: state.playing,
        processingState: _mapProcessingState(state.processingState),
      ));
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      final oldState = playbackState.value;
      playbackState.add(oldState.copyWith(
        updatePosition: oldState.updatePosition,
      ));
    });
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
  Future<void> play() => _audioPlayer.play();

  @override
  Future<void> pause() => _audioPlayer.pause();

  @override
  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    // This will be handled by the provider
  }

  @override
  Future<void> skipToPrevious() async {
    // This will be handled by the provider
  }

  // Update the notification with current song info
  Future<void> updateSongMediaItem(String title, String artist, String? artUri, Duration? duration) async {
    mediaItem.add(MediaItem(
      id: title,
      title: title,
      artist: artist,
      duration: duration,
      artUri: artUri != null ? Uri.parse(artUri) : null,
    ));
  }
}
