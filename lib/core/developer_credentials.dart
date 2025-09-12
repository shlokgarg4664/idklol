/// Secret developer credentials for accessing developer mode
/// This allows uploading videos to test the AI model
class DeveloperCredentials {
  // Keep these credentials secure - they provide access to developer features
  static const String username = 'lonely';
  static const String password = 'k7';
  
  // Developer mode features that will be unlocked with these credentials
  static const List<String> developerFeatures = [
    'Video Upload for AI Testing',
    'Advanced Pose Detection Settings',
    'Model Performance Metrics',
    'Debug Overlays',
    'Export Training Data',
  ];
  
  /// Validates if the provided credentials match the developer credentials
  static bool validateCredentials(String inputUsername, String inputPassword) {
    return inputUsername == username && inputPassword == password;
  }
  
  /// Returns a masked version of the password for display purposes
  static String getMaskedPassword() {
    return '*' * password.length;
  }
}
