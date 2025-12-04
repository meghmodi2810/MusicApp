import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsProvider extends ChangeNotifier {
  // Playback settings
  bool _crossfadeEnabled = false;
  int _crossfadeDuration = 5; // seconds
  String _audioQuality = 'high'; // low, normal, high
  bool _volumeNormalization = false;
  bool _autoplay = true;
  bool _gaplessPlayback = true;
  bool _swipeGesturesEnabled = true; // NEW: Swipe gestures for like/queue

  // Download settings
  String _downloadQuality = 'high';
  bool _downloadOverWifiOnly = true;

  // UI settings
  bool _showGetStarted = true;
  bool _animationsEnabled = true;
  String _progressBarStyle = 'wavy2'; // straight, wavy1, wavy2, modern

  // NEW: Appearance settings
  String _fontSize = 'standard'; // small, standard, large
  bool _gridLayoutEnabled = false;

  // Cache
  int _cacheSize = 0; // in MB

  // Getters
  bool get crossfadeEnabled => _crossfadeEnabled;
  int get crossfadeDuration => _crossfadeDuration;
  String get audioQuality => _audioQuality;
  bool get volumeNormalization => _volumeNormalization;
  bool get autoplay => _autoplay;
  bool get gaplessPlayback => _gaplessPlayback;
  bool get swipeGesturesEnabled => _swipeGesturesEnabled; // NEW

  String get downloadQuality => _downloadQuality;
  bool get downloadOverWifiOnly => _downloadOverWifiOnly;
  bool get showGetStarted => _showGetStarted;
  bool get animationsEnabled => _animationsEnabled;
  String get progressBarStyle => _progressBarStyle;
  String get fontSize => _fontSize; // NEW
  bool get gridLayoutEnabled => _gridLayoutEnabled; // NEW
  int get cacheSize => _cacheSize;

  // Bitrate based on quality
  int get audioBitrate {
    switch (_audioQuality) {
      case 'low':
        return 96;
      case 'normal':
        return 160;
      case 'high':
      default:
        return 320;
    }
  }

  int get downloadBitrate {
    switch (_downloadQuality) {
      case 'low':
        return 96;
      case 'normal':
        return 160;
      case 'high':
      default:
        return 320;
    }
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _crossfadeEnabled = prefs.getBool('crossfadeEnabled') ?? false;
    _crossfadeDuration = prefs.getInt('crossfadeDuration') ?? 5;
    _audioQuality = prefs.getString('audioQuality') ?? 'high';
    _volumeNormalization = prefs.getBool('volumeNormalization') ?? false;
    _autoplay = prefs.getBool('autoplay') ?? true;
    _gaplessPlayback = prefs.getBool('gaplessPlayback') ?? true;
    _swipeGesturesEnabled = prefs.getBool('swipeGesturesEnabled') ?? true;

    _downloadQuality = prefs.getString('downloadQuality') ?? 'high';
    _downloadOverWifiOnly = prefs.getBool('downloadOverWifiOnly') ?? true;
    _showGetStarted = prefs.getBool('showGetStarted') ?? true;
    _animationsEnabled = prefs.getBool('animationsEnabled') ?? true;
    _progressBarStyle = prefs.getString('progressBarStyle') ?? 'wavy2';
    _fontSize = prefs.getString('fontSize') ?? 'standard'; // NEW
    _gridLayoutEnabled = prefs.getBool('gridLayoutEnabled') ?? false; // NEW
    _cacheSize = prefs.getInt('cacheSize') ?? 0;

    notifyListeners();
  }

  Future<void> setCrossfadeEnabled(bool value) async {
    _crossfadeEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('crossfadeEnabled', value);
    notifyListeners();
  }

  Future<void> setCrossfadeDuration(int seconds) async {
    _crossfadeDuration = seconds.clamp(1, 12);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('crossfadeDuration', _crossfadeDuration);
    notifyListeners();
  }

  Future<void> setAudioQuality(String quality) async {
    _audioQuality = quality;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audioQuality', quality);
    notifyListeners();
  }

  Future<void> setVolumeNormalization(bool value) async {
    _volumeNormalization = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('volumeNormalization', value);
    notifyListeners();
  }

  Future<void> setAutoplay(bool value) async {
    _autoplay = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoplay', value);
    notifyListeners();
  }

  Future<void> setGaplessPlayback(bool value) async {
    _gaplessPlayback = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gaplessPlayback', value);
    notifyListeners();
  }

  // NEW: Swipe gestures setting
  Future<void> setSwipeGesturesEnabled(bool value) async {
    _swipeGesturesEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('swipeGesturesEnabled', value);
    notifyListeners();
  }

  Future<void> setDownloadQuality(String quality) async {
    _downloadQuality = quality;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('downloadQuality', quality);
    notifyListeners();
  }

  Future<void> setDownloadOverWifiOnly(bool value) async {
    _downloadOverWifiOnly = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('downloadOverWifiOnly', value);
    notifyListeners();
  }

  Future<void> setShowGetStarted(bool value) async {
    _showGetStarted = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showGetStarted', value);
    notifyListeners();
  }

  Future<void> setAnimationsEnabled(bool value) async {
    _animationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('animationsEnabled', value);
    notifyListeners();
  }

  Future<void> setProgressBarStyle(String style) async {
    _progressBarStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('progressBarStyle', style);
    notifyListeners();
  }

  // NEW: Font size setting
  Future<void> setFontSize(String size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontSize', size);
    notifyListeners();
  }

  // NEW: Grid layout setting
  Future<void> setGridLayoutEnabled(bool value) async {
    _gridLayoutEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gridLayoutEnabled', value);
    notifyListeners();
  }

  Future<void> clearCache() async {
    _cacheSize = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cacheSize', 0);
    notifyListeners();
  }

  Future<void> updateCacheSize(int sizeInMB) async {
    _cacheSize = sizeInMB;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cacheSize', sizeInMB);
    notifyListeners();
  }

  Future<void> calculateCacheSize() async {
    try {
      final dir = await getTemporaryDirectory();
      int totalSize = 0;

      if (await dir.exists()) {
        await for (var entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            try {
              totalSize += await entity.length();
            } catch (e) {
              // Skip files that can't be read
            }
          }
        }
      }

      final sizeInMB = (totalSize / (1024 * 1024)).round();
      await updateCacheSize(sizeInMB);
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating cache size: $e');
      }
    }
  }
}
