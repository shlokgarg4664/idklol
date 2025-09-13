import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class FirebaseConfig {
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static FirebaseStorage? _storage;
  static FirebaseAnalytics? _analytics;
  static FirebaseCrashlytics? _crashlytics;
  static FirebaseRemoteConfig? _remoteConfig;

  // Getters for Firebase services
  static FirebaseAuth get auth => _auth!;
  static FirebaseFirestore get firestore => _firestore!;
  static FirebaseStorage get storage => _storage!;
  static FirebaseAnalytics get analytics => _analytics!;
  static FirebaseCrashlytics get crashlytics => _crashlytics!;
  static FirebaseRemoteConfig get remoteConfig => _remoteConfig!;

  /// Initialize Firebase services
  static Future<void> initialize() async {
    try {
      // Initialize Firebase Core
      await Firebase.initializeApp();
      
      // Initialize Firebase services
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Configure Firebase services
      await _configureFirestore();
      await _configureCrashlytics();
      await _configureRemoteConfig();
      
      print('Firebase initialized successfully');
    } catch (e) {
      print('Failed to initialize Firebase: $e');
      rethrow;
    }
  }

  /// Configure Firestore settings
  static Future<void> _configureFirestore() async {
    _firestore!.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Configure Crashlytics
  static Future<void> _configureCrashlytics() async {
    // Enable collection in debug mode for testing
    await _crashlytics!.setCrashlyticsCollectionEnabled(true);
  }

  /// Configure Remote Config
  static Future<void> _configureRemoteConfig() async {
    await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    
    // Set default values
    await _remoteConfig!.setDefaults({
      'api_base_url': 'https://your-api-domain.com/api/v1',
      'enable_analytics': true,
      'max_workout_duration': 3600,
      'pose_detection_confidence': 0.7,
    });
    
    // Fetch and activate
    await _remoteConfig!.fetchAndActivate();
  }

  /// Get current user ID
  static String? get currentUserId => _auth?.currentUser?.uid;

  /// Check if user is authenticated
  static bool get isAuthenticated => _auth?.currentUser != null;

  /// Get current user
  static User? get currentUser => _auth?.currentUser;
}
