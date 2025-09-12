import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sports_app/core/api_service.dart';
import 'package:sports_app/core/models/user_model.dart';

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  UserStats? _userStats;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  UserStats? get userStats => _userStats;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasToken = prefs.containsKey('auth_token');
      
      if (hasToken) {
        await _loadUserProfile();
        _isLoggedIn = true;
      }
    } catch (e) {
      debugPrint('Failed to initialize user service: $e');
      await logout();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    try {
      final response = await _apiService.login(username, password);
      _currentUser = User.fromJson(response['user']);
      _isLoggedIn = true;
      await _loadUserStats();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    try {
      final response = await _apiService.register(userData);
      _currentUser = User.fromJson(response['user']);
      _isLoggedIn = true;
      await _loadUserStats();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _apiService.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _currentUser = null;
      _userStats = null;
      _isLoggedIn = false;
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    if (_currentUser == null) return false;
    
    _setLoading(true);
    try {
      final response = await _apiService.updateProfile(profileData);
      _currentUser = User.fromJson(response['user']);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Profile update failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createWorkout(Map<String, dynamic> workoutData) async {
    if (_currentUser == null) return false;
    
    _setLoading(true);
    try {
      await _apiService.createWorkout(workoutData);
      await _loadUserStats(); // Refresh stats
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Workout creation failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await _apiService.getProfile();
      _currentUser = User.fromJson(response['user']);
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
      throw e;
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final response = await _apiService.getStats();
      _userStats = UserStats.fromJson(response);
    } catch (e) {
      debugPrint('Failed to load user stats: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Helper methods
  String get displayName => _currentUser?.username ?? 'Guest';
  String get userInitials => _currentUser?.username.substring(0, 1).toUpperCase() ?? 'G';
  
  double get bmi {
    if (_currentUser == null || _currentUser!.height <= 0) return 0;
    final heightInMeters = _currentUser!.height / 100;
    return _currentUser!.weight / (heightInMeters * heightInMeters);
  }
  
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }
}
