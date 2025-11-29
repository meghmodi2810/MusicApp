import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/database_service.dart';

class PlaylistModel {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final String? coverUrl;
  final int songCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlaylistModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.coverUrl,
    this.songCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      coverUrl: map['cover_url'] as String?,
      songCount: map['song_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class PlaylistProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  
  List<PlaylistModel> _playlists = [];
  List<SongModel> _likedSongs = [];
  List<SongModel> _recentlyPlayed = [];
  bool _isLoading = false;
  int? _userId;
  bool _isInitialized = false;

  List<PlaylistModel> get playlists => _playlists;
  List<SongModel> get likedSongs => _likedSongs;
  List<SongModel> get recentlyPlayed => _recentlyPlayed;
  bool get isLoading => _isLoading;
  int get likedSongsCount => _likedSongs.length;

  /// Called by ProxyProvider - doesn't notify during build
  void updateUserId(int? userId) {
    if (_userId == userId) return;
    
    _userId = userId;
    if (userId != null) {
      if (!_isInitialized) {
        _isInitialized = true;
        // Defer loading to after build phase
        Future.microtask(() => loadAll());
      } else {
        loadAll();
      }
    } else {
      _playlists = [];
      _likedSongs = [];
      _recentlyPlayed = [];
      _isInitialized = false;
      // Defer notification to after build phase
      Future.microtask(() => notifyListeners());
    }
  }

  void setUserId(int? userId) {
    updateUserId(userId);
  }

  Future<void> loadAll() async {
    if (_userId == null) return;
    
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      loadPlaylists(),
      loadLikedSongs(),
      loadRecentlyPlayed(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  // ============ PLAYLIST OPERATIONS ============

  Future<void> loadPlaylists() async {
    if (_userId == null) return;
    
    final playlistMaps = await _db.getUserPlaylists(_userId!);
    _playlists = playlistMaps.map((m) => PlaylistModel.fromMap(m)).toList();
    notifyListeners();
  }

  Future<PlaylistModel?> createPlaylist(String name, {String? description}) async {
    if (_userId == null) return null;

    final id = await _db.createPlaylist(
      userId: _userId!,
      name: name,
      description: description,
    );

    await loadPlaylists();
    return _playlists.firstWhere((p) => p.id == id);
  }

  Future<void> deletePlaylist(int playlistId) async {
    await _db.deletePlaylist(playlistId);
    _playlists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
  }

  Future<void> updatePlaylist(int playlistId, {String? name, String? description}) async {
    await _db.updatePlaylist(playlistId, name: name, description: description);
    await loadPlaylists();
  }

  Future<List<SongModel>> getPlaylistSongs(int playlistId) async {
    return await _db.getPlaylistSongs(playlistId);
  }

  Future<void> addSongToPlaylist(int playlistId, SongModel song) async {
    await _db.addSongToPlaylist(playlistId: playlistId, song: song);
    await loadPlaylists();
  }

  Future<void> removeSongFromPlaylist(int playlistId, String songId) async {
    await _db.removeSongFromPlaylist(playlistId: playlistId, songId: songId);
    await loadPlaylists();
  }

  Future<bool> isSongInPlaylist(int playlistId, String songId) async {
    return await _db.isSongInPlaylist(playlistId, songId);
  }

  // ============ LIKED SONGS OPERATIONS ============

  Future<void> loadLikedSongs() async {
    if (_userId == null) return;
    _likedSongs = await _db.getLikedSongs(_userId!);
    notifyListeners();
  }

  Future<void> toggleLikeSong(SongModel song) async {
    if (_userId == null) return;

    final isLiked = await _db.isSongLiked(_userId!, song.id);
    
    if (isLiked) {
      await _db.unlikeSong(_userId!, song.id);
      _likedSongs.removeWhere((s) => s.id == song.id);
    } else {
      await _db.likeSong(_userId!, song);
      _likedSongs.insert(0, song);
    }
    
    notifyListeners();
  }

  Future<bool> isSongLiked(String songId) async {
    if (_userId == null) return false;
    return await _db.isSongLiked(_userId!, songId);
  }

  bool isSongLikedSync(String songId) {
    return _likedSongs.any((s) => s.id == songId);
  }

  // ============ RECENTLY PLAYED OPERATIONS ============

  Future<void> loadRecentlyPlayed() async {
    if (_userId == null) return;
    _recentlyPlayed = await _db.getRecentlyPlayed(_userId!);
    notifyListeners();
  }

  Future<void> addToRecentlyPlayed(SongModel song) async {
    if (_userId == null) return;
    await _db.addToRecentlyPlayed(_userId!, song);
    
    // Update local list
    _recentlyPlayed.removeWhere((s) => s.id == song.id);
    _recentlyPlayed.insert(0, song);
    if (_recentlyPlayed.length > 20) {
      _recentlyPlayed = _recentlyPlayed.sublist(0, 20);
    }
    
    notifyListeners();
  }
}
