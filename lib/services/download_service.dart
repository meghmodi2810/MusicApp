import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

class DownloadedSong {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? albumArt;
  final String filePath;
  final int fileSize;
  final DateTime downloadedAt;

  DownloadedSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.albumArt,
    required this.filePath,
    required this.fileSize,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'albumArt': albumArt,
    'filePath': filePath,
    'fileSize': fileSize,
    'downloadedAt': downloadedAt.toIso8601String(),
  };

  factory DownloadedSong.fromJson(Map<String, dynamic> json) => DownloadedSong(
    id: json['id'],
    title: json['title'],
    artist: json['artist'],
    album: json['album'],
    albumArt: json['albumArt'],
    filePath: json['filePath'],
    fileSize: json['fileSize'],
    downloadedAt: DateTime.parse(json['downloadedAt']),
  );

  SongModel toSongModel() => SongModel(
    id: id,
    title: title,
    artist: artist,
    album: album,
    albumArt: albumArt,
    streamUrl: filePath,
    isLocal: true,
  );
}

class DownloadTask {
  final String songId;
  final String url;
  final String filePath;
  double progress;
  bool isCompleted;
  bool isFailed;
  String? error;

  DownloadTask({
    required this.songId,
    required this.url,
    required this.filePath,
    this.progress = 0.0,
    this.isCompleted = false,
    this.isFailed = false,
    this.error,
  });
}

class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Map<String, DownloadTask> _activeTasks = {};
  final List<DownloadedSong> _downloadedSongs = [];
  bool _isInitialized = false;

  List<DownloadedSong> get downloadedSongs => List.unmodifiable(_downloadedSongs);
  Map<String, DownloadTask> get activeTasks => Map.unmodifiable(_activeTasks);
  
  bool isDownloading(String songId) => _activeTasks.containsKey(songId);
  bool isDownloaded(String songId) => _downloadedSongs.any((s) => s.id == songId);
  
  double getProgress(String songId) => _activeTasks[songId]?.progress ?? 0.0;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadDownloadedSongs();
    _isInitialized = true;
  }

  Future<String> get _downloadPath async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<void> _loadDownloadedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsJson = prefs.getStringList('downloadedSongs') ?? [];
      
      _downloadedSongs.clear();
      for (final json in songsJson) {
        try {
          final song = DownloadedSong.fromJson(
            Map<String, dynamic>.from(
              Uri.splitQueryString(json).map((k, v) => MapEntry(k, _parseValue(v)))
            )
          );
          // Verify file exists
          if (await File(song.filePath).exists()) {
            _downloadedSongs.add(song);
          }
        } catch (e) {
          debugPrint('Error parsing downloaded song: $e');
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading downloaded songs: $e');
    }
  }

  dynamic _parseValue(String value) {
    if (int.tryParse(value) != null) return int.parse(value);
    if (value == 'null') return null;
    return value;
  }

  Future<void> _saveDownloadedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsJson = _downloadedSongs.map((s) {
        final json = s.toJson();
        return json.entries.map((e) => '${e.key}=${e.value}').join('&');
      }).toList();
      await prefs.setStringList('downloadedSongs', songsJson);
    } catch (e) {
      debugPrint('Error saving downloaded songs: $e');
    }
  }

  Future<bool> downloadSong(SongModel song) async {
    if (isDownloaded(song.id) || isDownloading(song.id)) {
      return false;
    }

    final url = song.playableUrl;
    if (url.isEmpty) {
      return false;
    }

    try {
      final path = await _downloadPath;
      final fileName = '${song.id}_${_sanitizeFileName(song.title)}.mp3';
      final filePath = '$path/$fileName';

      final task = DownloadTask(
        songId: song.id,
        url: url,
        filePath: filePath,
      );
      _activeTasks[song.id] = task;
      notifyListeners();

      // Download in background
      await _downloadFile(song, task);

      return true;
    } catch (e) {
      debugPrint('Download error: $e');
      _activeTasks.remove(song.id);
      notifyListeners();
      return false;
    }
  }

  Future<void> _downloadFile(SongModel song, DownloadTask task) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(task.url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to download: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final file = File(task.filePath);
      final sink = file.openWrite();

      int received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          task.progress = received / contentLength;
          notifyListeners();
        }
      }

      await sink.close();
      client.close();

      // Save to downloaded songs
      final downloadedSong = DownloadedSong(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        albumArt: song.albumArt,
        filePath: task.filePath,
        fileSize: received,
        downloadedAt: DateTime.now(),
      );

      _downloadedSongs.add(downloadedSong);
      await _saveDownloadedSongs();

      task.isCompleted = true;
      task.progress = 1.0;
      _activeTasks.remove(song.id);
      notifyListeners();
    } catch (e) {
      task.isFailed = true;
      task.error = e.toString();
      _activeTasks.remove(song.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelDownload(String songId) async {
    _activeTasks.remove(songId);
    notifyListeners();
  }

  Future<void> deleteDownload(String songId) async {
    final index = _downloadedSongs.indexWhere((s) => s.id == songId);
    if (index != -1) {
      final song = _downloadedSongs[index];
      try {
        final file = File(song.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }
      _downloadedSongs.removeAt(index);
      await _saveDownloadedSongs();
      notifyListeners();
    }
  }

  Future<void> deleteAllDownloads() async {
    for (final song in _downloadedSongs) {
      try {
        final file = File(song.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }
    }
    _downloadedSongs.clear();
    await _saveDownloadedSongs();
    notifyListeners();
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').substring(0, name.length.clamp(0, 50));
  }

  int get totalDownloadSize {
    return _downloadedSongs.fold(0, (sum, song) => sum + song.fileSize);
  }

  String get formattedTotalSize {
    final bytes = totalDownloadSize;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
