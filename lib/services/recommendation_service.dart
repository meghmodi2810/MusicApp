import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../models/album_model.dart';
import '../models/artist_model.dart';

/// Production Recommendation Engine - Uses only JioSaavn data
/// NO clustering, NO external APIs, only user's listening history
class RecommendationService {
  static const String _listeningHistoryKey = 'listening_history';
  static const String _artistPreferencesKey = 'artist_preferences';
  static const String _cachedRecommendationsKey = 'cached_recommendations';
  static const String _lastUpdateKey = 'recommendations_last_update';
  
  // Cache recommendations for 1 hour
  static const Duration _cacheExpiry = Duration(hours: 1);

  // ==========================================
  // LISTENING HISTORY TRACKING
  // ==========================================
  
  Future<void> trackSongPlay(SongModel song) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final historyJson = prefs.getString(_listeningHistoryKey) ?? '[]';
      List<dynamic> history = json.decode(historyJson);
      
      history.insert(0, {
        'songId': song.id,
        'title': song.title,
        'artist': song.artist,
        'artistId': song.artistId,
        'album': song.album,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      if (history.length > 100) {
        history = history.sublist(0, 100);
      }
      
      await prefs.setString(_listeningHistoryKey, json.encode(history));
      await _updateArtistPreferences(song.artist, song.artistId);
      
      // Clear cached recommendations when user plays new song
      await clearCachedRecommendations();
      
      debugPrint('📊 Tracked: ${song.title} by ${song.artist}');
    } catch (e) {
      debugPrint('Error tracking song: $e');
    }
  }

  Future<void> _updateArtistPreferences(String artist, String? artistId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_artistPreferencesKey) ?? '{}';
      Map<String, dynamic> artistPrefs = json.decode(prefsJson);
      
      final key = artistId ?? artist.toLowerCase();
      artistPrefs[key] = {
        'name': artist,
        'artistId': artistId,
        'playCount': (artistPrefs[key]?['playCount'] ?? 0) + 1,
        'lastPlayed': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(_artistPreferencesKey, json.encode(artistPrefs));
    } catch (e) {
      debugPrint('Error updating preferences: $e');
    }
  }

  // ==========================================
  // GET USER'S FAVORITE ARTISTS
  // ==========================================
  
  Future<List<String>> getFavoriteArtists({int limit = 10}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_artistPreferencesKey) ?? '{}';
      Map<String, dynamic> artistPrefs = json.decode(prefsJson);
      
      if (artistPrefs.isEmpty) return [];
      
      final sorted = artistPrefs.entries.toList()
        ..sort((a, b) => (b.value['playCount'] as int).compareTo(a.value['playCount'] as int));
      
      final favorites = sorted.take(limit).map((e) => e.value['name'] as String).toList();
      
      debugPrint('🎵 Favorite artists: ${favorites.take(3).join(", ")}');
      return favorites;
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // CACHED RECOMMENDATIONS
  // ==========================================
  
  /// Get personalized artist queries (CACHED for consistency)
  Future<List<String>> getPersonalizedQueries({int count = 5}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if cache is still valid
      final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - lastUpdate;
      
      if (cacheAge < _cacheExpiry.inMilliseconds) {
        // Return cached recommendations (no switching!)
        final cachedJson = prefs.getString(_cachedRecommendationsKey);
        if (cachedJson != null) {
          final cached = List<String>.from(json.decode(cachedJson));
          if (cached.isNotEmpty) {
            debugPrint('📦 Using cached recommendations: ${cached.take(3).join(", ")}');
            return cached.take(count).toList();
          }
        }
      }
      
      // Generate new recommendations from user's taste
      final favoriteArtists = await getFavoriteArtists(limit: count * 2);
      
      if (favoriteArtists.isEmpty) {
        return []; // Return empty - home screen will show trending
      }
      
      // Cache the recommendations
      await prefs.setString(_cachedRecommendationsKey, json.encode(favoriteArtists));
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('💾 Cached new recommendations: ${favoriteArtists.take(3).join(", ")}');
      return favoriteArtists.take(count).toList();
    } catch (e) {
      debugPrint('Error getting personalized queries: $e');
      return [];
    }
  }

  /// Clear cached recommendations (when user plays new song)
  Future<void> clearCachedRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedRecommendationsKey);
      await prefs.remove(_lastUpdateKey);
      debugPrint('🗑️ Cleared recommendation cache');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // ==========================================
  // AUTOPLAY CONTEXT (For Search Fix)
  // ==========================================
  
  /// Get similar artists for autoplay after search
  Future<List<String>> getContextForArtist(String artist) async {
    // Return user's favorite artists for autoplay
    final favorites = await getFavoriteArtists(limit: 10);
    
    // Remove the current artist from recommendations
    favorites.remove(artist);
    
    if (favorites.isEmpty) {
      // If no favorites, return the current artist only
      return [artist];
    }
    
    debugPrint('🔄 Autoplay context for $artist: ${favorites.take(3).join(", ")}');
    return favorites;
  }

  // ==========================================
  // SEARCH OPTIMIZATION
  // ==========================================
  
  /// Sort search results by user's music taste
  Future<List<SongModel>> sortSearchResultsByTaste(List<SongModel> songs) async {
    if (songs.isEmpty) return songs;
    
    try {
      final favoriteArtists = await getFavoriteArtists(limit: 50);
      final favoriteArtistsLower = favoriteArtists.map((a) => a.toLowerCase()).toSet();
      
      // Score each song based on artist preference
      final scoredSongs = songs.map((song) {
        final artistLower = song.artist.toLowerCase();
        int score = 0;
        
        // Exact match with favorite artist
        if (favoriteArtistsLower.contains(artistLower)) {
          score = favoriteArtists.indexWhere((a) => a.toLowerCase() == artistLower);
          score = favoriteArtists.length - score; // Higher score for more played artists
        }
        
        return MapEntry(song, score);
      }).toList();
      
      // Sort by score (descending)
      scoredSongs.sort((a, b) => b.value.compareTo(a.value));
      
      final sortedSongs = scoredSongs.map((e) => e.key).toList();
      
      debugPrint('🎯 Sorted ${songs.length} songs by taste (favorites first)');
      return sortedSongs;
    } catch (e) {
      debugPrint('Error sorting by taste: $e');
      return songs;
    }
  }

  /// Sort album search results by user's music taste
  Future<List<AlbumModel>> sortAlbumResultsByTaste(List<AlbumModel> albums) async {
    if (albums.isEmpty) return albums;
    
    try {
      final favoriteArtists = await getFavoriteArtists(limit: 50);
      final favoriteArtistsLower = favoriteArtists.map((a) => a.toLowerCase()).toSet();
      
      final scoredAlbums = albums.map((album) {
        final artistLower = album.artist.toLowerCase();
        int score = 0;
        
        if (favoriteArtistsLower.contains(artistLower)) {
          score = favoriteArtists.indexWhere((a) => a.toLowerCase() == artistLower);
          score = favoriteArtists.length - score;
        }
        
        return MapEntry(album, score);
      }).toList();
      
      scoredAlbums.sort((a, b) => b.value.compareTo(a.value));
      return scoredAlbums.map((e) => e.key).toList();
    } catch (e) {
      return albums;
    }
  }

  /// Sort artist search results by user's music taste
  Future<List<ArtistModel>> sortArtistResultsByTaste(List<ArtistModel> artists) async {
    if (artists.isEmpty) return artists;
    
    try {
      final favoriteArtists = await getFavoriteArtists(limit: 50);
      final favoriteArtistsLower = favoriteArtists.map((a) => a.toLowerCase()).toSet();
      
      final scoredArtists = artists.map((artist) {
        final artistLower = artist.name.toLowerCase();
        int score = 0;
        
        if (favoriteArtistsLower.contains(artistLower)) {
          score = favoriteArtists.indexWhere((a) => a.toLowerCase() == artistLower);
          score = favoriteArtists.length - score;
        }
        
        return MapEntry(artist, score);
      }).toList();
      
      scoredArtists.sort((a, b) => b.value.compareTo(a.value));
      return scoredArtists.map((e) => e.key).toList();
    } catch (e) {
      return artists;
    }
  }

  // ==========================================
  // USER STATUS
  // ==========================================
  
  Future<bool> isNewUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_listeningHistoryKey) ?? '[]';
      List<dynamic> history = json.decode(historyJson);
      
      final isNew = history.length < 5;
      debugPrint(isNew ? '👤 New user (${history.length} songs played)' : '✅ Returning user (${history.length} songs played)');
      
      return isNew;
    } catch (e) {
      return true;
    }
  }

  Future<List<SongModel>> sortByPopularity(List<SongModel> songs) async {
    // Just return as-is (no sorting needed)
    return songs;
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_listeningHistoryKey);
    await prefs.remove(_artistPreferencesKey);
    await prefs.remove(_cachedRecommendationsKey);
    await prefs.remove(_lastUpdateKey);
    debugPrint('🗑️ Cleared all recommendation data');
  }
}
