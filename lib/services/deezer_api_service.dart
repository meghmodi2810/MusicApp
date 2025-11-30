import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class DeezerApiService {
  static const String _baseUrl = 'https://api.deezer.com';

  // Search for tracks
  Future<List<SongModel>> searchTracks(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?q=${Uri.encodeComponent(query)}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> tracks = data['data'] ?? [];
        return tracks
            .where((track) => track['preview'] != null)
            .map((track) => SongModel.fromDeezerJson(track))
            .toList();
      }
    } catch (e) {
      debugPrint('Error searching tracks: $e');
    }
    return [];
  }

  // Get top charts
  Future<List<SongModel>> getTopCharts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chart/0/tracks'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> tracks = data['data'] ?? [];
        return tracks
            .where((track) => track['preview'] != null)
            .map((track) => SongModel.fromDeezerJson(track))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching charts: $e');
    }
    return [];
  }

  // Get tracks by genre
  Future<List<SongModel>> getTracksByGenre(int genreId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/genre/$genreId/artists'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> artists = data['data'] ?? [];
        
        if (artists.isNotEmpty) {
          // Get top tracks of the first artist
          final artistId = artists[0]['id'];
          return await getArtistTopTracks(artistId);
        }
      }
    } catch (e) {
      debugPrint('Error fetching genre tracks: $e');
    }
    return [];
  }

  // Get artist's top tracks
  Future<List<SongModel>> getArtistTopTracks(int artistId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/artist/$artistId/top?limit=25'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> tracks = data['data'] ?? [];
        return tracks
            .where((track) => track['preview'] != null)
            .map((track) => SongModel.fromDeezerJson(track))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching artist tracks: $e');
    }
    return [];
  }

  // Get available genres
  Future<List<Map<String, dynamic>>> getGenres() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/genre'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
    } catch (e) {
      debugPrint('Error fetching genres: $e');
    }
    return [];
  }
}
