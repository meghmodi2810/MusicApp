import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('music_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
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

    // Playlists table
    await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
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

  // User operations
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

  // Playlist operations
  Future<int> createPlaylist({
    required int userId,
    required String name,
    String? description,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert('playlists', {
      'user_id': userId,
      'name': name,
      'description': description,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getUserPlaylists(int userId) async {
    final db = await database;
    return await db.query(
      'playlists',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
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

  Future<void> addSongToPlaylist({
    required int playlistId,
    required String songId,
  }) async {
    final db = await database;
    final songs = await db.query(
      'playlist_songs',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );

    await db.insert('playlist_songs', {
      'playlist_id': playlistId,
      'song_id': songId,
      'position': songs.length,
      'added_at': DateTime.now().toIso8601String(),
    });

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
  }

  Future<List<String>> getPlaylistSongs(int playlistId) async {
    final db = await database;
    final results = await db.query(
      'playlist_songs',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'position ASC',
    );

    return results.map((row) => row['song_id'] as String).toList();
  }

  // Liked songs operations
  Future<void> likeSong(int userId, String songId) async {
    final db = await database;
    await db.insert(
      'liked_songs',
      {
        'user_id': userId,
        'song_id': songId,
        'liked_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> unlikeSong(int userId, String songId) async {
    final db = await database;
    await db.delete(
      'liked_songs',
      where: 'user_id = ? AND song_id = ?',
      whereArgs: [userId, songId],
    );
  }

  Future<bool> isSongLiked(int userId, String songId) async {
    final db = await database;
    final results = await db.query(
      'liked_songs',
      where: 'user_id = ? AND song_id = ?',
      whereArgs: [userId, songId],
    );

    return results.isNotEmpty;
  }

  Future<List<String>> getLikedSongs(int userId) async {
    final db = await database;
    final results = await db.query(
      'liked_songs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'liked_at DESC',
    );

    return results.map((row) => row['song_id'] as String).toList();
  }

  // Recently played operations
  Future<void> addToRecentlyPlayed(int userId, String songId) async {
    final db = await database;
    await db.insert('recently_played', {
      'user_id': userId,
      'song_id': songId,
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

  Future<List<String>> getRecentlyPlayed(int userId, {int limit = 20}) async {
    final db = await database;
    final results = await db.query(
      'recently_played',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'played_at DESC',
      limit: limit,
    );

    return results.map((row) => row['song_id'] as String).toList();
  }

  // Helper methods
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
