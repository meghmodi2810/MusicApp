import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:permission_handler/permission_handler.dart';

class BackupService {
  static final BackupService instance = BackupService._init();
  BackupService._init();

  /// Export complete app data as a SQLite backup file to Downloads folder
  Future<Map<String, dynamic>> exportData() async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Try manageExternalStorage for Android 11+
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            return {
              'success': false,
              'message': 'Storage permission denied. Please grant permission in settings.',
            };
          }
        }
      }

      // Get the current database path
      final dbPath = await getDatabasesPath();
      final sourceDbPath = join(dbPath, 'music_app.db');
      
      // Check if database exists
      if (!await File(sourceDbPath).exists()) {
        if (kDebugMode) print('Database file not found');
        return {'success': false, 'message': 'No data to export'};
      }

      // Create backup file with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final backupFileName = 'pancake_tunes_backup_$timestamp.db';
      
      // Get Downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getDownloadsDirectory();
      }
      
      if (downloadsDir == null) {
        return {'success': false, 'message': 'Could not access Downloads folder'};
      }

      final backupPath = join(downloadsDir.path, backupFileName);
      
      // Copy database to Downloads folder
      await File(sourceDbPath).copy(backupPath);
      
      if (kDebugMode) print('Backup exported successfully: $backupPath');
      return {
        'success': true,
        'message': 'Backup saved to Downloads',
        'path': backupPath,
        'filename': backupFileName,
      };
    } catch (e) {
      if (kDebugMode) print('Error exporting data: $e');
      return {'success': false, 'message': 'Export failed: ${e.toString()}'};
    }
  }

  /// Import app data from a backup file
  Future<Map<String, dynamic>> importData() async {
    try {
      // Pick backup file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        dialogTitle: 'Select Pancake Tunes Backup File',
      );

      if (result == null || result.files.isEmpty) {
        return {'success': false, 'message': 'No file selected'};
      }

      final pickedFile = result.files.first;
      if (pickedFile.path == null) {
        return {'success': false, 'message': 'Invalid file path'};
      }

      // Validate the backup file
      final isValid = await _validateBackupFile(pickedFile.path!);
      if (!isValid) {
        return {'success': false, 'message': 'Invalid backup file'};
      }

      // Get current database path
      final dbPath = await getDatabasesPath();
      final targetDbPath = join(dbPath, 'music_app.db');
      
      // Close existing database connection
      final db = await openDatabase(targetDbPath);
      await db.close();
      
      // Create backup of current database (just in case)
      final currentBackupPath = join(dbPath, 'music_app_old.db');
      if (await File(targetDbPath).exists()) {
        await File(targetDbPath).copy(currentBackupPath);
      }
      
      // Copy imported file to database location
      await File(pickedFile.path!).copy(targetDbPath);
      
      // Delete old backup after successful import
      if (await File(currentBackupPath).exists()) {
        await File(currentBackupPath).delete();
      }
      
      if (kDebugMode) print('Backup imported successfully');
      return {'success': true, 'message': 'Backup restored successfully! Please restart the app.'};
    } catch (e) {
      if (kDebugMode) print('Error importing data: $e');
      return {'success': false, 'message': 'Failed to import backup: $e'};
    }
  }

  /// Validate that the file is a valid SQLite database
  Future<bool> _validateBackupFile(String filePath) async {
    try {
      final db = await openDatabase(filePath, readOnly: true);
      
      // Check if essential tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('users', 'playlists', 'liked_songs', 'songs_cache')"
      );
      
      await db.close();
      
      // Should have at least some core tables
      return tables.isNotEmpty;
    } catch (e) {
      if (kDebugMode) print('Invalid backup file: $e');
      return false;
    }
  }

  /// Get backup file size for display
  Future<String> getBackupSize() async {
    try {
      final dbPath = await getDatabasesPath();
      final sourceDbPath = join(dbPath, 'music_app.db');
      
      if (!await File(sourceDbPath).exists()) {
        return '0 MB';
      }
      
      final file = File(sourceDbPath);
      final sizeInBytes = await file.length();
      final sizeInMB = (sizeInBytes / (1024 * 1024)).toStringAsFixed(2);
      
      return '$sizeInMB MB';
    } catch (e) {
      if (kDebugMode) print('Error getting backup size: $e');
      return '0 MB';
    }
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final dbPath = await getDatabasesPath();
      final db = await openDatabase(join(dbPath, 'music_app.db'));
      
      final likedSongsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM liked_songs')
      ) ?? 0;
      
      final playlistsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM playlists')
      ) ?? 0;
      
      final cachedSongsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM songs_cache')
      ) ?? 0;
      
      final recentlyPlayedCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM recently_played')
      ) ?? 0;
      
      await db.close();
      
      return {
        'likedSongs': likedSongsCount,
        'playlists': playlistsCount,
        'cachedSongs': cachedSongsCount,
        'recentlyPlayed': recentlyPlayedCount,
      };
    } catch (e) {
      if (kDebugMode) print('Error getting database stats: $e');
      return {
        'likedSongs': 0,
        'playlists': 0,
        'cachedSongs': 0,
        'recentlyPlayed': 0,
      };
    }
  }
}
