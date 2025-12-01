import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/song_model.dart';

/// Smart recommendation engine that learns from user behavior
class RecommendationService {
  static const String _listeningHistoryKey = 'listening_history';
  static const String _artistPreferencesKey = 'artist_preferences';
  static const String _genrePreferencesKey = 'genre_preferences';

  // Track listening history
  Future<void> trackSongPlay(SongModel song) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing history
    final historyJson = prefs.getString(_listeningHistoryKey) ?? '[]';
    List<dynamic> history = json.decode(historyJson);
    
    // Add new entry with timestamp
    history.insert(0, {
      'songId': song.id,
      'title': song.title,
      'artist': song.artist,
      'artistId': song.artistId,
      'album': song.album,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Keep only last 100 plays
    if (history.length > 100) {
      history = history.sublist(0, 100);
    }
    
    await prefs.setString(_listeningHistoryKey, json.encode(history));
    
    // Update artist preferences
    await _updateArtistPreferences(song.artist, song.artistId);
  }

  Future<void> _updateArtistPreferences(String artist, String? artistId) async {
    final prefs = await SharedPreferences.getInstance();
    final prefsJson = prefs.getString(_artistPreferencesKey) ?? '{}';
    Map<String, dynamic> artistPrefs = json.decode(prefsJson);
    
    final key = artistId ?? artist;
    artistPrefs[key] = {
      'name': artist,
      'artistId': artistId,
      'playCount': (artistPrefs[key]?['playCount'] ?? 0) + 1,
      'lastPlayed': DateTime.now().millisecondsSinceEpoch,
    };
    
    await prefs.setString(_artistPreferencesKey, json.encode(artistPrefs));
  }

  // Get favorite artists based on listening history
  Future<List<String>> getFavoriteArtists({int limit = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final prefsJson = prefs.getString(_artistPreferencesKey) ?? '{}';
    Map<String, dynamic> artistPrefs = json.decode(prefsJson);
    
    // Sort by play count
    final sorted = artistPrefs.entries.toList()
      ..sort((a, b) => (b.value['playCount'] as int).compareTo(a.value['playCount'] as int));
    
    return sorted.take(limit).map((e) => e.value['name'] as String).toList();
  }

  // Get recently played songs
  Future<List<Map<String, dynamic>>> getRecentlyPlayed({int limit = 20}) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_listeningHistoryKey) ?? '[]';
    List<dynamic> history = json.decode(historyJson);
    
    return history.take(limit).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Check if user is new (less than 5 songs played)
  Future<bool> isNewUser() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_listeningHistoryKey) ?? '[]';
    List<dynamic> history = json.decode(historyJson);
    return history.length < 5;
  }

  // Get recommendation query based on user preferences
  Future<String> getPersonalizedQuery() async {
    final favoriteArtists = await getFavoriteArtists(limit: 3);
    
    if (favoriteArtists.isEmpty) {
      // New user - return trending
      return 'top hits 2024';
    }
    
    // Return query based on favorite artist
    return '${favoriteArtists.first} similar artists';
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_listeningHistoryKey);
    await prefs.remove(_artistPreferencesKey);
    await prefs.remove(_genrePreferencesKey);
  }
}
