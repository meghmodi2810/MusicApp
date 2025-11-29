import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class MusicApiService {
  // Using iTunes API - works globally without regional blocks
  static const String _itunesBaseUrl = 'https://itunes.apple.com';

  // Make request with proper error handling
  Future<Map<String, dynamic>?> _fetchJson(String url) async {
    try {
      print('Fetching: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      
      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Results count: ${data['resultCount']}');
        return data;
      }
    } catch (e) {
      print('Request failed for $url: $e');
    }
    return null;
  }

  // Search for songs using iTunes
  Future<List<SongModel>> searchSongs(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final data = await _fetchJson(
        '$_itunesBaseUrl/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=30'
      );
      
      if (data != null && data['results'] != null) {
        final List<dynamic> results = data['results'] ?? [];
        print('Found ${results.length} songs');
        return results
            .where((song) => song['kind'] == 'song')
            .map((song) => SongModel.fromItunesJson(song))
            .toList();
      }
    } catch (e) {
      print('iTunes search error: $e');
    }
    return [];
  }

  // Get trending/top songs
  Future<List<SongModel>> getTrendingSongs() async {
    // iTunes doesn't have a direct trending endpoint, so search for popular terms
    return searchSongs('top hits 2024');
  }

  // Get new releases
  Future<List<SongModel>> getNewReleases() async {
    return searchSongs('new songs 2024');
  }

  // Get songs by mood/genre
  Future<List<SongModel>> getSongsByMood(String mood) async {
    return searchSongs('$mood music');
  }
}
