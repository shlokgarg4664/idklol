import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  ThemeMode _themeMode = ThemeMode.dark;
  bool _isTransitioning = false;
  
  ThemeMode get themeMode => _themeMode;
  bool get isTransitioning => _isTransitioning;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    _isTransitioning = true;
    notifyListeners();
    
    // Small delay to show loading state
    await Future.delayed(const Duration(milliseconds: 150));
    
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _isTransitioning = false;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
  }
}
