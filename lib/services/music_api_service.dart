import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';
import '../models/album_model.dart';
import '../models/artist_model.dart';

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
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
    } catch (e) {
      debugPrint('Request failed for $url: $e');
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
          return data;
        }
      }
    }
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
    
    if (results.isEmpty) return [];
    
    final songs = <SongModel>[];
    for (final song in results) {
      try {
        final parsed = SongModel.fromJioSaavnJson(song);
        if (parsed.streamUrl != null && parsed.streamUrl!.isNotEmpty) {
          songs.add(parsed);
        }
      } catch (e) {
        debugPrint('Error parsing song: $e');
      }
    }
    
    return songs;
  }

  // Parse albums from different API response formats
  List<AlbumModel> _parseAlbumResults(Map<String, dynamic> data) {
    List<dynamic> results = [];
    
    // Try different response structures
    if (data['data'] != null) {
      if (data['data'] is List) {
        results = data['data'];
      } else if (data['data']['results'] != null) {
        results = data['data']['results'];
      } else if (data['data']['albums'] != null) {
        results = data['data']['albums'];
      }
    } else if (data['results'] != null) {
      results = data['results'];
    } else if (data['albums'] != null) {
      results = data['albums'];
    }
    
    if (results.isEmpty) return [];
    
    final albums = <AlbumModel>[];
    for (final album in results) {
      try {
        albums.add(AlbumModel.fromJioSaavnJson(album));
      } catch (e) {
        debugPrint('Error parsing album: $e');
      }
    }
    
    return albums;
  }

  // Parse artists from different API response formats
  List<ArtistModel> _parseArtistResults(Map<String, dynamic> data) {
    List<dynamic> results = [];
    
    // Try different response structures
    if (data['data'] != null) {
      if (data['data'] is List) {
        results = data['data'];
      } else if (data['data']['results'] != null) {
        results = data['data']['results'];
      } else if (data['data']['artists'] != null) {
        results = data['data']['artists'];
      }
    } else if (data['results'] != null) {
      results = data['results'];
    } else if (data['artists'] != null) {
      results = data['artists'];
    }
    
    if (results.isEmpty) return [];
    
    final artists = <ArtistModel>[];
    for (final artist in results) {
      try {
        artists.add(ArtistModel.fromJioSaavnJson(artist));
      } catch (e) {
        debugPrint('Error parsing artist: $e');
      }
    }
    
    return artists;
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
      
      // Fallback to iTunes if JioSaavn fails (30-sec previews)
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
      debugPrint('Search error: $e');
    }
    return [];
  }

  // Search for albums
  Future<List<AlbumModel>> searchAlbums(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final saavnData = await _fetchFromSaavn(
        '/search/albums?query=${Uri.encodeComponent(query)}&limit=20'
      );
      
      if (saavnData != null) {
        return _parseAlbumResults(saavnData);
      }
    } catch (e) {
      debugPrint('Album search error: $e');
    }
    return [];
  }

  // Search for artists
  Future<List<ArtistModel>> searchArtists(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final saavnData = await _fetchFromSaavn(
        '/search/artists?query=${Uri.encodeComponent(query)}&limit=20'
      );
      
      if (saavnData != null) {
        return _parseArtistResults(saavnData);
      }
    } catch (e) {
      debugPrint('Artist search error: $e');
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
      debugPrint('Get song error: $e');
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
      debugPrint('Get songs by IDs error: $e');
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
      debugPrint('Trending songs error: $e');
    }
    return searchSongs('top hits 2024');
  }

  // Get trending albums
  Future<List<AlbumModel>> getTrendingAlbums() async {
    try {
      final data = await _fetchFromSaavn('/search/albums?query=bollywood albums 2024&limit=20');
      
      if (data != null) {
        final albums = _parseAlbumResults(data);
        if (albums.isNotEmpty) return albums;
      }
    } catch (e) {
      debugPrint('Trending albums error: $e');
    }
    return searchAlbums('top albums 2024');
  }

  // Get trending artists
  Future<List<ArtistModel>> getTrendingArtists() async {
    try {
      final data = await _fetchFromSaavn('/search/artists?query=top bollywood artists&limit=20');
      
      if (data != null) {
        final artists = _parseArtistResults(data);
        if (artists.isNotEmpty) return artists;
      }
    } catch (e) {
      debugPrint('Trending artists error: $e');
    }
    return searchArtists('top artists');
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
      debugPrint('New releases error: $e');
    }
    return searchSongs('new songs 2024');
  }

  // Get songs by mood/genre
  Future<List<SongModel>> getSongsByMood(String mood) async {
    return searchSongs('$mood songs');
  }

  // Get album details and songs
  Future<List<SongModel>> getAlbumSongs(String albumId) async {
    try {
      final data = await _fetchFromSaavn('/albums?id=$albumId');
      
      if (data != null) {
        return _parseSaavnResults(data);
      }
    } catch (e) {
      debugPrint('Album songs error: $e');
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
      debugPrint('Artist songs error: $e');
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
      debugPrint('Playlist songs error: $e');
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
      debugPrint('Suggestions error: $e');
    }
    return [];
  }
}
