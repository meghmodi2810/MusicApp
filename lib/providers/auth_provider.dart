import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? _userSettings;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get currentUser => _currentUser;
  Map<String, dynamic>? get userSettings => _userSettings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  int? get userId => _currentUser?['id'] as int?;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    
    if (userId != null) {
      final user = await _db.getUser(userId);
      if (user != null) {
        _currentUser = user;
        await _loadUserSettings();
        notifyListeners();
      }
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _db.createUser(
        username: username,
        email: email,
        password: password,
        displayName: displayName,
      );

      if (user != null) {
        _currentUser = user;
        await _saveLoginStatus(user['id'] as int);
        await _loadUserSettings();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = 'Failed to create user';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _db.login(usernameOrEmail, password);

      if (user != null) {
        _currentUser = user;
        await _saveLoginStatus(user['id'] as int);
        await _loadUserSettings();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = 'Invalid username/email or password';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    _currentUser = null;
    _userSettings = null;
    notifyListeners();
  }

  Future<void> _saveLoginStatus(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
  }

  Future<void> _loadUserSettings() async {
    if (_currentUser != null) {
      _userSettings = await _db.getUserSettings(_currentUser!['id'] as int);
      notifyListeners();
    }
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    if (_currentUser != null) {
      await _db.updateUserSettings(_currentUser!['id'] as int, settings);
      await _loadUserSettings();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser != null) {
      await _db.updateUser(_currentUser!['id'] as int, data);
      _currentUser = await _db.getUser(_currentUser!['id'] as int);
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
