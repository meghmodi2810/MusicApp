import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/lyrics_model.dart';

/// Service to fetch synced lyrics from multiple sources
class LyricsService {
  // Cache for fetched lyrics to avoid repeated API calls
  // Only caches successful results, not failures
  static final Map<String, LyricsModel> _lyricsCache = {};
  
  // Track failed lookups with expiry (retry after 5 minutes)
  static final Map<String, DateTime> _failedLookups = {};
  static const Duration _failedLookupExpiry = Duration(minutes: 5);

  // LRCLIB API - Free synced lyrics API
  static const String _lrclibBaseUrl = 'https://lrclib.net/api';

  /// Fetch lyrics for a song by title and artist
  /// Returns null if lyrics are not available
  Future<LyricsModel?> getLyrics({
    required String songId,
    required String title,
    required String artist,
    Duration? duration,
  }) async {
    final cacheKey = '${artist.toLowerCase()}_${title.toLowerCase()}';
    
    // Check successful cache first
    if (_lyricsCache.containsKey(cacheKey)) {
      debugPrint('✅ Lyrics found in cache for: $title');
      return _lyricsCache[cacheKey];
    }
    
    // Check if we recently failed to find lyrics (avoid repeated failed requests)
    if (_failedLookups.containsKey(cacheKey)) {
      final failedTime = _failedLookups[cacheKey]!;
      if (DateTime.now().difference(failedTime) < _failedLookupExpiry) {
        debugPrint('⏳ Lyrics lookup skipped (recent failure): $title');
        return null;
      } else {
        // Expired, remove from failed lookups and retry
        _failedLookups.remove(cacheKey);
      }
    }

    debugPrint('🔍 Fetching lyrics for: $title by $artist');

    // Try multiple sources
    LyricsModel? lyrics;

    // Source 1: LRCLIB (synced lyrics)
    lyrics = await _fetchFromLrclib(
      songId: songId,
      title: title,
      artist: artist,
      duration: duration,
    );

    if (lyrics != null && lyrics.hasLyrics) {
      _lyricsCache[cacheKey] = lyrics;
      debugPrint('✅ Found synced lyrics from LRCLIB');
      return lyrics;
    }

    // Source 2: Try alternative search on LRCLIB
    lyrics = await _searchLrclib(
      songId: songId,
      title: title,
      artist: artist,
    );

    if (lyrics != null && lyrics.hasLyrics) {
      _lyricsCache[cacheKey] = lyrics;
      debugPrint('✅ Found lyrics from LRCLIB search');
      return lyrics;
    }

    // Mark as failed lookup (will retry after expiry)
    _failedLookups[cacheKey] = DateTime.now();
    debugPrint('❌ No lyrics found for: $title (will retry in 5 min)');
    return null;
  }

  /// Fetch from LRCLIB API using exact match
  Future<LyricsModel?> _fetchFromLrclib({
    required String songId,
    required String title,
    required String artist,
    Duration? duration,
  }) async {
    try {
      // Clean the title and artist for better matching
      final cleanTitle = _cleanSearchString(title);
      final cleanArtist = _cleanSearchString(artist);

      String url = '$_lrclibBaseUrl/get?'
          'track_name=${Uri.encodeComponent(cleanTitle)}'
          '&artist_name=${Uri.encodeComponent(cleanArtist)}';

      // Add duration if available for better matching
      if (duration != null && duration.inSeconds > 0) {
        url += '&duration=${duration.inSeconds}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'PancakeTunes/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseLrclibResponse(data, songId, title, artist);
      }
    } catch (e) {
      debugPrint('LRCLIB fetch error: $e');
    }
    return null;
  }

  /// Search LRCLIB API for lyrics
  Future<LyricsModel?> _searchLrclib({
    required String songId,
    required String title,
    required String artist,
  }) async {
    try {
      final cleanTitle = _cleanSearchString(title);
      final cleanArtist = _cleanSearchString(artist);

      // Try with combined search query
      final searchQuery = '$cleanArtist $cleanTitle';
      final url = '$_lrclibBaseUrl/search?q=${Uri.encodeComponent(searchQuery)}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'PancakeTunes/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        
        if (results.isNotEmpty) {
          // Find best match
          final bestMatch = _findBestMatch(results, title, artist);
          if (bestMatch != null) {
            return _parseLrclibResponse(bestMatch, songId, title, artist);
          }
        }
      }
    } catch (e) {
      debugPrint('LRCLIB search error: $e');
    }
    return null;
  }

  /// Find the best matching result from search results
  Map<String, dynamic>? _findBestMatch(
    List<dynamic> results,
    String title,
    String artist,
  ) {
    final cleanTitle = _cleanSearchString(title).toLowerCase();
    final cleanArtist = _cleanSearchString(artist).toLowerCase();

    // Score each result
    Map<String, dynamic>? bestMatch;
    int bestScore = 0;

    for (final result in results) {
      final resultTitle = _cleanSearchString(result['trackName'] ?? '').toLowerCase();
      final resultArtist = _cleanSearchString(result['artistName'] ?? '').toLowerCase();

      int score = 0;

      // Title matching
      if (resultTitle == cleanTitle) {
        score += 100;
      } else if (resultTitle.contains(cleanTitle) || cleanTitle.contains(resultTitle)) {
        score += 50;
      }

      // Artist matching
      if (resultArtist == cleanArtist) {
        score += 100;
      } else if (resultArtist.contains(cleanArtist) || cleanArtist.contains(resultArtist)) {
        score += 50;
      }

      // Prefer synced lyrics
      if (result['syncedLyrics'] != null && result['syncedLyrics'].toString().isNotEmpty) {
        score += 25;
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = result;
      }
    }

    // Only return if we have a reasonable match
    return bestScore >= 50 ? bestMatch : (results.isNotEmpty ? results.first : null);
  }

  /// Parse LRCLIB response into LyricsModel
  LyricsModel? _parseLrclibResponse(
    Map<String, dynamic> data,
    String songId,
    String title,
    String artist,
  ) {
    // Prefer synced lyrics, fall back to plain lyrics
    final syncedLyrics = data['syncedLyrics']?.toString();
    final plainLyrics = data['plainLyrics']?.toString();

    if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
      return LyricsModel.fromLrc(
        syncedLyrics,
        songId: songId,
        songTitle: title,
        artist: artist,
      );
    } else if (plainLyrics != null && plainLyrics.isNotEmpty) {
      return LyricsModel.fromPlainText(
        plainLyrics,
        songId: songId,
        songTitle: title,
        artist: artist,
      );
    }

    return null;
  }

  /// Clean search string by removing special characters and extra info
  String _cleanSearchString(String input) {
    return input
        // Remove content in parentheses (feat., remix info, etc.)
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        // Remove content in brackets
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        // Remove "feat.", "ft.", "featuring"
        .replaceAll(RegExp(r'\s*(feat\.?|ft\.?|featuring)\s*.*', caseSensitive: false), '')
        // Remove extra spaces
        .replaceAll(RegExp(r'\s+'), ' ')
        // Remove leading/trailing spaces
        .trim();
  }

  /// Clear the lyrics cache
  void clearCache() {
    _lyricsCache.clear();
    _failedLookups.clear();
    debugPrint('🗑️ Lyrics cache and failed lookups cleared');
  }

  /// Pre-fetch lyrics for a song (call when song starts playing)
  Future<void> prefetchLyrics({
    required String songId,
    required String title,
    required String artist,
    Duration? duration,
  }) async {
    // Don't await, just fire and forget
    getLyrics(
      songId: songId,
      title: title,
      artist: artist,
      duration: duration,
    );
  }
}
