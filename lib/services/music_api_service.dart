import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class MusicApiService {
  // Multiple JioSaavn API endpoints to try - updated with more reliable endpoints
  static const List<String> _saavnBaseUrls = [
    'https://saavn.dev/api',
    'https://jio-saavn-api-tau.vercel.app/api',
    'https://jiosaavn-api-ts.vercel.app/api',
    'https://jiosaavn-api-2-harsh-xl.vercel.app/api',
    'https://jiosaavn-api-privatecvc2.vercel.app',
    'https://saavn.me/api',
  ];
  
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
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response status: ${response.statusCode}');
        return data;
      }
    } catch (e) {
      print('Request failed for $url: $e');
    }
    return null;
  }

  // Try multiple JioSaavn API endpoints
  Future<Map<String, dynamic>?> _fetchFromSaavn(String endpoint) async {
    for (final baseUrl in _saavnBaseUrls) {
      final url = '$baseUrl$endpoint';
      final data = await _fetchJson(url);
      if (data != null) {
        // Check for success in different API response formats
        if (data['success'] == true || data['status'] == 'SUCCESS' || data['data'] != null || data['results'] != null) {
          print('SUCCESS: Got data from $baseUrl');
          return data;
        }
      }
    }
    print('JioSaavn API returned no data or failed. Response: null');
    return null;
  }

  // Parse songs from different API response formats
  List<SongModel> _parseSaavnResults(Map<String, dynamic> data) {
    List<dynamic> results = [];
    
    // Try different response structures
    if (data['data'] != null) {
      if (data['data'] is List) {
        results = data['data'];
      } else if (data['data']['results'] != null) {
        results = data['data']['results'];
      } else if (data['data']['songs'] != null) {
        results = data['data']['songs'];
      }
    } else if (data['results'] != null) {
      results = data['results'];
    } else if (data['songs'] != null) {
      results = data['songs'];
    }
    
    print('Parsing ${results.length} results from JioSaavn');
    
    if (results.isEmpty) return [];
    
    final songs = <SongModel>[];
    for (final song in results) {
      try {
        final parsed = SongModel.fromJioSaavnJson(song);
        if (parsed.streamUrl != null && parsed.streamUrl!.isNotEmpty) {
          songs.add(parsed);
        }
      } catch (e) {
        print('Error parsing song: $e');
      }
    }
    
    print('Successfully parsed ${songs.length} songs with valid URLs');
    return songs;
  }

  // Search for songs using JioSaavn API (full songs)
  Future<List<SongModel>> searchSongs(String query) async {
    if (query.isEmpty) return [];
    
    try {
      // Try JioSaavn APIs first for full songs
      final saavnData = await _fetchFromSaavn(
        '/search/songs?query=${Uri.encodeComponent(query)}&limit=30'
      );
      
      if (saavnData != null) {
        final songs = _parseSaavnResults(saavnData);
        if (songs.isNotEmpty) {
          return songs;
        }
      }
      
      // Try alternative endpoint format
      final altData = await _fetchFromSaavn(
        '/search?query=${Uri.encodeComponent(query)}'
      );
      
      if (altData != null) {
        final songs = _parseSaavnResults(altData);
        if (songs.isNotEmpty) {
          return songs;
        }
      }
      
      print('JioSaavn APIs failed, falling back to iTunes (30-sec previews only)');
      
      // Fallback to iTunes if JioSaavn fails (30-sec previews)
      final itunesData = await _fetchJson(
        '$_itunesBaseUrl/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=30'
      );
      
      if (itunesData != null && itunesData['results'] != null) {
        final List<dynamic> results = itunesData['results'] ?? [];
        print('Found ${results.length} songs from iTunes (30-sec previews)');
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
      final data = await _fetchFromSaavn('/songs/$songId');
      
      if (data != null) {
        final songs = _parseSaavnResults(data);
        if (songs.isNotEmpty) {
          return songs.first;
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
      final data = await _fetchFromSaavn('/songs?ids=$ids');
      
      if (data != null) {
        return _parseSaavnResults(data);
      }
    } catch (e) {
      print('Get songs by IDs error: $e');
    }
    return [];
  }

  // Get trending/top songs
  Future<List<SongModel>> getTrendingSongs() async {
    try {
      final data = await _fetchFromSaavn('/search/songs?query=bollywood hits 2024&limit=30');
      
      if (data != null) {
        final songs = _parseSaavnResults(data);
        if (songs.isNotEmpty) return songs;
      }
    } catch (e) {
      print('Trending songs error: $e');
    }
    return searchSongs('top hits 2024');
  }

  // Get new releases
  Future<List<SongModel>> getNewReleases() async {
    try {
      final data = await _fetchFromSaavn('/search/songs?query=new hindi songs 2024&limit=30');
      
      if (data != null) {
        final songs = _parseSaavnResults(data);
        if (songs.isNotEmpty) return songs;
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
      final data = await _fetchFromSaavn('/albums?id=$albumId');
      
      if (data != null) {
        return _parseSaavnResults(data);
      }
    } catch (e) {
      print('Album songs error: $e');
    }
    return [];
  }

  // Get artist's top songs
  Future<List<SongModel>> getArtistSongs(String artistId) async {
    try {
      final data = await _fetchFromSaavn('/artists/$artistId/songs?page=0');
      
      if (data != null) {
        return _parseSaavnResults(data);
      }
    } catch (e) {
      print('Artist songs error: $e');
    }
    return [];
  }

  // Get playlist songs
  Future<List<SongModel>> getPlaylistSongs(String playlistId) async {
    try {
      final data = await _fetchFromSaavn('/playlists?id=$playlistId');
      
      if (data != null) {
        return _parseSaavnResults(data);
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
      final data = await _fetchFromSaavn(
        '/search/songs?query=${Uri.encodeComponent(query)}&limit=5'
      );
      
      if (data != null) {
        List<dynamic> results = [];
        if (data['data']?['results'] != null) {
          results = data['data']['results'];
        } else if (data['results'] != null) {
          results = data['results'];
        }
        return results.map((song) => (song['name'] ?? song['title'] ?? '') as String).where((s) => s.isNotEmpty).toList();
      }
    } catch (e) {
      print('Suggestions error: $e');
    }
    return [];
  }
}
