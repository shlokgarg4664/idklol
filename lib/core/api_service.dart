import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sports_app/core/app_config.dart';
import 'package:sports_app/core/firebase_auth_service.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(seconds: AppConfig.apiTimeoutSeconds),
      receiveTimeout: Duration(seconds: AppConfig.apiTimeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // For now, skip Firebase token - we'll add it back later
        // final token = await FirebaseAuthService().getIdToken();
        // if (token != null) {
        //   options.headers['Authorization'] = 'Bearer $token';
        // }
        handler.next(options);
      },
      onError: (error, handler) async {
        // For now, just pass through errors
        handler.next(error);
      },
    ));
  }

  // Auth endpoints - temporarily simplified without Firebase
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      // For now, just return a mock response
      // TODO: Implement proper registration with backend API
      return {
        'message': 'Registration temporarily disabled - Firebase not configured',
        'token': 'mock_token',
        'user': {
          'uid': 'mock_uid',
          'email': userData['email'],
          'displayName': userData['username'],
          ...userData,
        }
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // For now, just return a mock response
      // TODO: Implement proper login with backend API
      return {
        'message': 'Login temporarily disabled - Firebase not configured',
        'token': 'mock_token',
        'user': {
          'uid': 'mock_uid',
          'email': email,
          'displayName': 'Mock User',
        }
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    // For now, just clear local state
    // TODO: Implement proper logout
    debugPrint('Logout called - Firebase not configured');
  }

  // User profile endpoints
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/profile');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _dio.put('/profile', data: profileData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Workout endpoints
  Future<Map<String, dynamic>> createWorkout(Map<String, dynamic> workoutData) async {
    try {
      final response = await _dio.post('/workouts', data: workoutData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getWorkouts() async {
    try {
      final response = await _dio.get('/workouts');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get('/stats');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data.containsKey('error')) {
        return data['error'];
      }
      return 'Server error: ${e.response!.statusCode}';
    } else if (e.type == DioExceptionType.connectionTimeout ||
               e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'Unable to connect to server. Please check if the API is running.';
    }
    return 'An unexpected error occurred';
  }
}
