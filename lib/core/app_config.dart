class AppConfig {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );
  
  static const int apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  // Firebase Configuration
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'sports-app-firebase',
  );

  // Security Configuration
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );
  
  static const bool enableCrashlytics = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS',
    defaultValue: true,
  );
  
  static const bool enableRemoteConfig = bool.fromEnvironment(
    'ENABLE_REMOTE_CONFIG',
    defaultValue: true,
  );

  // Development Settings
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: false,
  );
  
  static const String logLevel = String.fromEnvironment(
    'LOG_LEVEL',
    defaultValue: 'info',
  );

  // Feature Flags
  static const bool enablePoseDetection = bool.fromEnvironment(
    'ENABLE_POSE_DETECTION',
    defaultValue: true,
  );
  
  static const bool enableVideoUpload = bool.fromEnvironment(
    'ENABLE_VIDEO_UPLOAD',
    defaultValue: true,
  );
  
  static const bool enableDeveloperMode = bool.fromEnvironment(
    'ENABLE_DEVELOPER_MODE',
    defaultValue: false,
  );

  // Performance Settings
  static const int cacheSizeMB = int.fromEnvironment(
    'CACHE_SIZE_MB',
    defaultValue: 100,
  );
  
  static const int maxConcurrentRequests = int.fromEnvironment(
    'MAX_CONCURRENT_REQUESTS',
    defaultValue: 5,
  );

  // Environment detection
  static bool get isProduction => !debugMode;
  static bool get isDevelopment => debugMode;
  
  // API endpoints
  static String get authEndpoint => '$apiBaseUrl/auth';
  static String get profileEndpoint => '$apiBaseUrl/profile';
  static String get workoutsEndpoint => '$apiBaseUrl/workouts';
  static String get statsEndpoint => '$apiBaseUrl/stats';
}
