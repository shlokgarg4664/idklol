import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sports_app/core/firebase_config.dart';
import 'package:sports_app/core/models/user_model.dart' as app_models;

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final firebase_auth.FirebaseAuth _auth = FirebaseConfig.auth;
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  final FirebaseAnalytics _analytics = FirebaseConfig.analytics;
  final FirebaseCrashlytics _crashlytics = FirebaseConfig.crashlytics;

  /// Stream of authentication state changes
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// Current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Sign in with email and password
  Future<firebase_auth.UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Log analytics event
      await _analytics.logLogin(loginMethod: 'email');

      // Update user last login
      await _updateLastLogin(credential.user!.uid);

      return credential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      await _crashlytics.recordError(e, StackTrace.current);
      rethrow;
    }
  }

  /// Create user with email and password
  Future<firebase_auth.UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _createUserDocument(credential.user!.uid, userData);

      // Log analytics event
      await _analytics.logSignUp(signUpMethod: 'email');

      return credential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      await _crashlytics.recordError(e, StackTrace.current);
      rethrow;
    }
  }

  /// Sign in anonymously (for testing/demo purposes)
  Future<firebase_auth.UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      
      // Log analytics event
      await _analytics.logLogin(loginMethod: 'anonymous');
      
      return credential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      await _crashlytics.recordError(e, StackTrace.current);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      
      // Log analytics event
      await _analytics.logEvent(name: 'user_sign_out');
    } catch (e) {
      await _crashlytics.recordError(e, StackTrace.current);
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      
      // Log analytics event
      await _analytics.logEvent(name: 'password_reset_requested');
    } on firebase_auth.FirebaseAuthException catch (e) {
      await _crashlytics.recordError(e, StackTrace.current);
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user signed in');

      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
        'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await _crashlytics.recordError(e, StackTrace.current);
      rethrow;
    }
  }

  /// Get user data from Firestore
  Future<app_models.User?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return app_models.User.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      await _crashlytics.recordError(e, StackTrace.current);
      return null;
    }
  }

  /// Update user data in Firestore
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await _crashlytics.recordError(e, StackTrace.current);
      rethrow;
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': userData['email'],
        'username': userData['username'],
        'height': userData['height'] ?? 0.0,
        'weight': userData['weight'] ?? 0.0,
        'nationality': userData['nationality'] ?? '',
        'age': userData['age'] ?? 0,
        'gender': userData['gender'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await _crashlytics.recordError(e, StackTrace.current);
      rethrow;
    }
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't throw error for this, just log it
      await _crashlytics.recordError(e, StackTrace.current);
    }
  }

  /// Get Firebase ID token for API authentication
  Future<String?> getIdToken() async {
    try {
      return await currentUser?.getIdToken();
    } catch (e) {
      await _crashlytics.recordError(e, StackTrace.current);
      return null;
    }
  }

  /// Refresh Firebase ID token
  Future<String?> refreshIdToken() async {
    try {
      return await currentUser?.getIdToken(true);
    } catch (e) {
      await _crashlytics.recordError(e, StackTrace.current);
      return null;
    }
  }
}
