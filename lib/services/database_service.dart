import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/song_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    // Check if database is closed and reinitialize if needed
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDB('music_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add songs cache table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS songs_cache (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          artist TEXT NOT NULL,
          album TEXT,
          album_art TEXT,
          album_art_high TEXT,
          stream_url TEXT,
          duration INTEGER,
          artist_id TEXT,
          album_id TEXT,
          cached_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add user_settings table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER UNIQUE NOT NULL,
          notifications_enabled INTEGER DEFAULT 1,
          auto_play_enabled INTEGER DEFAULT 1,
          download_on_wifi_only INTEGER DEFAULT 1,
          audio_quality TEXT DEFAULT 'high',
          theme_mode TEXT DEFAULT 'dark',
          primary_color TEXT DEFAULT '#1DB954',
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        display_name TEXT NOT NULL,
        avatar_url TEXT,
        created_at TEXT NOT NULL,
        last_login TEXT
      )
    ''');

    // User settings table
    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE NOT NULL,
        notifications_enabled INTEGER DEFAULT 1,
        auto_play_enabled INTEGER DEFAULT 1,
        download_on_wifi_only INTEGER DEFAULT 1,
        audio_quality TEXT DEFAULT 'high',
        theme_mode TEXT DEFAULT 'dark',
        primary_color TEXT DEFAULT '#1DB954',
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Playlists table
    await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        cover_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Playlist songs table
    await db.execute('''
      CREATE TABLE playlist_songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        song_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        added_at TEXT NOT NULL,
        FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE
      )
    ''');

    // Songs cache table - stores song metadata for offline access
    await db.execute('''
      CREATE TABLE songs_cache (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT,
        album_art TEXT,
        album_art_high TEXT,
        stream_url TEXT,
        duration INTEGER,
        artist_id TEXT,
        album_id TEXT,
        cached_at TEXT NOT NULL
      )
    ''');

    // Liked songs table
    await db.execute('''
      CREATE TABLE liked_songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        song_id TEXT NOT NULL,
        liked_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(user_id, song_id)
      )
    ''');

    // Recently played table
    await db.execute('''
      CREATE TABLE recently_played (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        song_id TEXT NOT NULL,
        played_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // ============ SONG CACHE OPERATIONS ============
  
  Future<void> cacheSong(SongModel song) async {
    final db = await database;
    await db.insert(
      'songs_cache',
      {
        'id': song.id,
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
        'album_art': song.albumArt,
        'album_art_high': song.albumArtHigh,
        'stream_url': song.streamUrl,
        'duration': song.duration?.inSeconds,
        'artist_id': song.artistId,
        'album_id': song.albumId,
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> cacheSongs(List<SongModel> songs) async {
    final db = await database;
    final batch = db.batch();
    
    for (final song in songs) {
      batch.insert(
        'songs_cache',
        {
          'id': song.id,
          'title': song.title,
          'artist': song.artist,
          'album': song.album,
          'album_art': song.albumArt,
          'album_art_high': song.albumArtHigh,
          'stream_url': song.streamUrl,
          'duration': song.duration?.inSeconds,
          'artist_id': song.artistId,
          'album_id': song.albumId,
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<SongModel?> getCachedSong(String songId) async {
    final db = await database;
    final results = await db.query(
      'songs_cache',
      where: 'id = ?',
      whereArgs: [songId],
    );

    if (results.isNotEmpty) {
      return _songFromCache(results.first);
    }
    return null;
  }

  Future<List<SongModel>> getCachedSongs(List<String> songIds) async {
    if (songIds.isEmpty) return [];
    
    final db = await database;
    final placeholders = List.filled(songIds.length, '?').join(',');
    final results = await db.rawQuery(
      'SELECT * FROM songs_cache WHERE id IN ($placeholders)',
      songIds,
    );

    // Maintain order of songIds
    final songsMap = {for (var r in results) r['id'] as String: _songFromCache(r)};
    return songIds.where((id) => songsMap.containsKey(id)).map((id) => songsMap[id]!).toList();
  }

  SongModel _songFromCache(Map<String, dynamic> row) {
    return SongModel(
      id: row['id'] as String,
      title: row['title'] as String,
      artist: row['artist'] as String,
      album: row['album'] as String? ?? 'Unknown Album',
      albumArt: row['album_art'] as String?,
      albumArtHigh: row['album_art_high'] as String?,
      streamUrl: row['stream_url'] as String?,
      duration: row['duration'] != null ? Duration(seconds: row['duration'] as int) : null,
      artistId: row['artist_id'] as String?,
      albumId: row['album_id'] as String?,
    );
  }

  // ============ USER OPERATIONS ============
  
  Future<Map<String, dynamic>?> createUser({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    final db = await database;
    final passwordHash = _hashPassword(password);
    final now = DateTime.now().toIso8601String();

    try {
      final id = await db.insert('users', {
        'username': username,
        'email': email,
        'password_hash': passwordHash,
        'display_name': displayName,
        'created_at': now,
      });

      return {
        'id': id,
        'username': username,
        'email': email,
        'display_name': displayName,
        'created_at': now,
      };
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<bool> verifyPassword(String username, String password) async {
    final user = await getUserByUsername(username);
    if (user == null) return false;

    final passwordHash = _hashPassword(password);
    return user['password_hash'] == passwordHash;
  }

  Future<void> updateLastLogin(int userId) async {
    final db = await database;
    await db.update(
      'users',
      {'last_login': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<Map<String, dynamic>?> getUser(int userId) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> login(String usernameOrEmail, String password) async {
    final db = await database;
    final passwordHash = _hashPassword(password);
    
    final results = await db.query(
      'users',
      where: '(username = ? OR email = ?) AND password_hash = ?',
      whereArgs: [usernameOrEmail, usernameOrEmail, passwordHash],
    );

    if (results.isNotEmpty) {
      final user = results.first;
      await updateLastLogin(user['id'] as int);
      return user;
    }
    return null;
  }

  Future<void> updateUser(int userId, Map<String, dynamic> data) async {
    final db = await database;
    
    final updateData = Map<String, dynamic>.from(data);
    updateData.remove('id');
    updateData.remove('created_at');
    updateData.remove('password_hash');
    
    await db.update(
      'users',
      updateData,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<Map<String, dynamic>?> getUserSettings(int userId) async {
    final db = await database;
    final results = await db.query(
      'user_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<void> updateUserSettings(int userId, Map<String, dynamic> settings) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'user_settings',
      {
        'user_id': userId,
        ...settings,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ============ PLAYLIST OPERATIONS ============

  Future<int> createPlaylist({
    required int userId,
    required String name,
    String? description,
    String? coverUrl,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert('playlists', {
      'user_id': userId,
      'name': name,
      'description': description,
      'cover_url': coverUrl,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getUserPlaylists(int userId) async {
    final db = await database;
    final playlists = await db.query(
      'playlists',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );

    // Add song count to each playlist
    final result = <Map<String, dynamic>>[];
    for (final playlist in playlists) {
      final songCount = await getPlaylistSongCount(playlist['id'] as int);
      result.add({
        ...playlist,
        'song_count': songCount,
      });
    }
    return result;
  }

  Future<Map<String, dynamic>?> getPlaylist(int playlistId) async {
    final db = await database;
    final results = await db.query(
      'playlists',
      where: 'id = ?',
      whereArgs: [playlistId],
    );

    if (results.isNotEmpty) {
      final songCount = await getPlaylistSongCount(playlistId);
      return {
        ...results.first,
        'song_count': songCount,
      };
    }
    return null;
  }

  Future<void> updatePlaylist(int playlistId, {String? name, String? description, String? coverUrl}) async {
    final db = await database;
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (coverUrl != null) updateData['cover_url'] = coverUrl;

    await db.update(
      'playlists',
      updateData,
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<void> deletePlaylist(int playlistId) async {
    final db = await database;
    await db.delete(
      'playlists',
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<int> getPlaylistSongCount(int playlistId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM playlist_songs WHERE playlist_id = ?',
      [playlistId],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<void> addSongToPlaylist({
    required int playlistId,
    required SongModel song,
  }) async {
    final db = await database;
    
    // Cache the song first
    await cacheSong(song);
    
    // Check if song already in playlist
    final existing = await db.query(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, song.id],
    );
    
    if (existing.isNotEmpty) return; // Already in playlist
    
    final songs = await db.query(
      'playlist_songs',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );

    await db.insert('playlist_songs', {
      'playlist_id': playlistId,
      'song_id': song.id,
      'position': songs.length,
      'added_at': DateTime.now().toIso8601String(),
    });

    // Update playlist cover if first song
    if (songs.isEmpty && song.albumArt != null) {
      await updatePlaylist(playlistId, coverUrl: song.albumArt);
    }

    await db.update(
      'playlists',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<void> removeSongFromPlaylist({
    required int playlistId,
    required String songId,
  }) async {
    final db = await database;
    await db.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );

    await db.update(
      'playlists',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<List<String>> getPlaylistSongIds(int playlistId) async {
    final db = await database;
    final results = await db.query(
      'playlist_songs',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'position ASC',
    );

    return results.map((row) => row['song_id'] as String).toList();
  }

  Future<List<SongModel>> getPlaylistSongs(int playlistId) async {
    final songIds = await getPlaylistSongIds(playlistId);
    return getCachedSongs(songIds);
  }

  Future<bool> isSongInPlaylist(int playlistId, String songId) async {
    final db = await database;
    final results = await db.query(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
    return results.isNotEmpty;
  }

  // ============ LIKED SONGS OPERATIONS ============

  Future<void> likeSong(int userId, SongModel song) async {
    try {
      final db = await database;
      
      // Cache the song
      await cacheSong(song);
      
      await db.insert(
        'liked_songs',
        {
          'user_id': userId,
          'song_id': song.id,
          'liked_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error liking song: $e');
      // Re-throw to let caller handle it
      rethrow;
    }
  }

  Future<void> unlikeSong(int userId, String songId) async {
    try {
      final db = await database;
      await db.delete(
        'liked_songs',
        where: 'user_id = ? AND song_id = ?',
        whereArgs: [userId, songId],
      );
    } catch (e) {
      print('Error unliking song: $e');
      rethrow;
    }
  }

  Future<bool> isSongLiked(int userId, String songId) async {
    try {
      final db = await database;
      final results = await db.query(
        'liked_songs',
        where: 'user_id = ? AND song_id = ?',
        whereArgs: [userId, songId],
      );

      return results.isNotEmpty;
    } catch (e) {
      // Handle database closed error gracefully
      print('Error checking if song is liked: $e');
      return false;
    }
  }

  Future<List<String>> getLikedSongIds(int userId) async {
    try {
      final db = await database;
      final results = await db.query(
        'liked_songs',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'liked_at DESC',
      );

      return results.map((row) => row['song_id'] as String).toList();
    } catch (e) {
      print('Error getting liked song IDs: $e');
      return [];
    }
  }

  Future<List<SongModel>> getLikedSongs(int userId) async {
    final songIds = await getLikedSongIds(userId);
    return getCachedSongs(songIds);
  }

  Future<int> getLikedSongsCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM liked_songs WHERE user_id = ?',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }

  // ============ RECENTLY PLAYED OPERATIONS ============

  Future<void> addToRecentlyPlayed(int userId, SongModel song) async {
    final db = await database;
    
    // Cache the song
    await cacheSong(song);
    
    await db.insert('recently_played', {
      'user_id': userId,
      'song_id': song.id,
      'played_at': DateTime.now().toIso8601String(),
    });

    // Keep only last 50 recently played songs
    final allRecent = await db.query(
      'recently_played',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'played_at DESC',
    );

    if (allRecent.length > 50) {
      final toDelete = allRecent.skip(50).map((row) => row['id']).toList();
      await db.delete(
        'recently_played',
        where: 'id IN (${toDelete.join(',')})',
      );
    }
  }

  Future<List<SongModel>> getRecentlyPlayed(int userId, {int limit = 20}) async {
    final db = await database;
    final results = await db.query(
      'recently_played',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'played_at DESC',
      limit: limit,
    );

    final songIds = results.map((row) => row['song_id'] as String).toList();
    return getCachedSongs(songIds);
  }

  // ============ HELPER METHODS ============

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Remove or comment out the close() method to prevent database from being closed
  // Future<void> close() async {
  //   final db = await database;
  //   await db.close();
  // }
}
