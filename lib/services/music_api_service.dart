import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class MusicApiService {
  // Using JioSaavn API for full songs (free, no API key required)
  static const String _saavnBaseUrl = 'https://saavn.dev/api';
  
  // Fallback to iTunes for search variety
  static const String _itunesBaseUrl = 'https://itunes.apple.com';

  // Make request with proper error handling
  Future<Map<String, dynamic>?> _fetchJson(String url) async {
    try {
      print('Fetching: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 20));
      
      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
    } catch (e) {
      print('Request failed for $url: $e');
    }
    return null;
  }

  // Search for songs using JioSaavn API (full songs)
  Future<List<SongModel>> searchSongs(String query) async {
    if (query.isEmpty) return [];
    
    try {
      // Try JioSaavn first for full songs
      final saavnData = await _fetchJson(
        '$_saavnBaseUrl/search/songs?query=${Uri.encodeComponent(query)}&limit=30'
      );
      
      if (saavnData != null && saavnData['success'] == true && saavnData['data'] != null) {
        final results = saavnData['data']['results'] as List<dynamic>? ?? [];
        print('Found ${results.length} songs from JioSaavn');
        if (results.isNotEmpty) {
          return results.map((song) => SongModel.fromJioSaavnJson(song)).toList();
        }
      }
      
      // Fallback to iTunes if JioSaavn fails (30-sec previews)
      print('Falling back to iTunes API...');
      final itunesData = await _fetchJson(
        '$_itunesBaseUrl/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=30'
      );
      
      if (itunesData != null && itunesData['results'] != null) {
        final List<dynamic> results = itunesData['results'] ?? [];
        return results
            .where((song) => song['kind'] == 'song')
            .map((song) => SongModel.fromItunesJson(song))
            .toList();
      }
    } catch (e) {
      print('Search error: $e');
    }
    return [];
  }

  // Get song details by ID (JioSaavn)
  Future<SongModel?> getSongById(String songId) async {
    try {
      final data = await _fetchJson('$_saavnBaseUrl/songs/$songId');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        final songs = data['data'] as List<dynamic>;
        if (songs.isNotEmpty) {
          return SongModel.fromJioSaavnJson(songs.first);
        }
      }
    } catch (e) {
      print('Get song error: $e');
    }
    return null;
  }

  // Get multiple songs by IDs
  Future<List<SongModel>> getSongsByIds(List<String> songIds) async {
    if (songIds.isEmpty) return [];
    
    try {
      final ids = songIds.join(',');
      final data = await _fetchJson('$_saavnBaseUrl/songs?ids=$ids');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        final songs = data['data'] as List<dynamic>;
        return songs.map((song) => SongModel.fromJioSaavnJson(song)).toList();
      }
    } catch (e) {
      print('Get songs by IDs error: $e');
    }
    return [];
  }

  // Get trending/top songs
  Future<List<SongModel>> getTrendingSongs() async {
    try {
      // Try to get trending from JioSaavn
      final data = await _fetchJson('$_saavnBaseUrl/search/songs?query=trending hits&limit=30');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        final results = data['data']['results'] as List<dynamic>? ?? [];
        if (results.isNotEmpty) {
          return results.map((song) => SongModel.fromJioSaavnJson(song)).toList();
        }
      }
    } catch (e) {
      print('Trending songs error: $e');
    }
    return searchSongs('top hits 2024');
  }

  // Get new releases
  Future<List<SongModel>> getNewReleases() async {
    try {
      final data = await _fetchJson('$_saavnBaseUrl/search/songs?query=new releases 2024&limit=30');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        final results = data['data']['results'] as List<dynamic>? ?? [];
        if (results.isNotEmpty) {
          return results.map((song) => SongModel.fromJioSaavnJson(song)).toList();
        }
      }
    } catch (e) {
      print('New releases error: $e');
    }
    return searchSongs('new songs 2024');
  }

  // Get songs by mood/genre
  Future<List<SongModel>> getSongsByMood(String mood) async {
    return searchSongs('$mood songs');
  }

  // Get album details
  Future<List<SongModel>> getAlbumSongs(String albumId) async {
    try {
      final data = await _fetchJson('$_saavnBaseUrl/albums?id=$albumId');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        final songs = data['data']['songs'] as List<dynamic>? ?? [];
        return songs.map((song) => SongModel.fromJioSaavnJson(song)).toList();
      }
    } catch (e) {
      print('Album songs error: $e');
    }
    return [];
  }

  // Get artist's top songs
  Future<List<SongModel>> getArtistSongs(String artistId) async {
    try {
      final data = await _fetchJson('$_saavnBaseUrl/artists/$artistId/songs?page=0');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        final songs = data['data']['songs'] as List<dynamic>? ?? [];
        return songs.map((song) => SongModel.fromJioSaavnJson(song)).toList();
      }
    } catch (e) {
      print('Artist songs error: $e');
    }
    return [];
  }

  // Get playlist songs
  Future<List<SongModel>> getPlaylistSongs(String playlistId) async {
    try {
      final data = await _fetchJson('$_saavnBaseUrl/playlists?id=$playlistId');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        final songs = data['data']['songs'] as List<dynamic>? ?? [];
        return songs.map((song) => SongModel.fromJioSaavnJson(song)).toList();
      }
    } catch (e) {
      print('Playlist songs error: $e');
    }
    return [];
  }

  // Search suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final data = await _fetchJson(
        '$_saavnBaseUrl/search/songs?query=${Uri.encodeComponent(query)}&limit=5'
      );
      
      if (data != null && data['success'] == true && data['data'] != null) {
        final results = data['data']['results'] as List<dynamic>? ?? [];
        return results.map((song) => song['name'] as String? ?? '').where((s) => s.isNotEmpty).toList();
      }
    } catch (e) {
      print('Suggestions error: $e');
    }
    return [];
  }
}
