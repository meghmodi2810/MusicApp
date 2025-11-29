import '../models/song_model.dart';

class LocalMusicService {
  // Local music scanning is disabled for now
  // The on_audio_query package has compatibility issues with newer Android
  
  // Get all local songs - returns empty for now
  Future<List<SongModel>> getLocalSongs() async {
    // TODO: Add local music scanning when package is fixed
    return [];
  }

  // Request storage permission
  Future<bool> requestPermission() async {
    // Permission handling disabled for now
    return false;
  }

  // Check permission status
  Future<bool> hasPermission() async {
    return false;
  }
}
