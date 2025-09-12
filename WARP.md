# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a Flutter-based sports application that uses AI-powered pose detection for exercise tracking. The app specifically focuses on push-up counting using Google ML Kit's pose detection capabilities.

### Key Technologies
- **Flutter 3.35.3** with Dart 3.9.2
- **Google ML Kit Pose Detection** for real-time body pose analysis
- **Camera integration** for live video processing
- **Isolate-based architecture** for background AI processing
- **Multi-platform support** (Android, iOS, Web, macOS, Linux, Windows)

## Common Development Commands

### Build & Run
```bash
# Clean the project (recommended before builds)
flutter clean

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run on specific platforms
flutter run -d chrome                    # Web
flutter run -d macos                     # macOS desktop
flutter run -d "23076RN4BI"             # Specific Android device

# Build for different platforms
flutter build apk --debug               # Android debug APK
flutter build apk --release             # Android release APK
flutter build web                       # Web build
flutter build macos                     # macOS app

# Use the custom build fix script for Android issues
./fix_sports_app.sh                     # Fixes Gradle/Kotlin compatibility issues
```

### Testing & Analysis
```bash
# Run tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Analyze code quality
flutter analyze

# Check Flutter environment
flutter doctor
flutter doctor -v                       # Verbose output
```

### Development Utilities
```bash
# Format code
flutter format .

# Clean build artifacts completely
flutter clean && flutter pub get

# Check for outdated dependencies
flutter pub outdated

# Update dependencies
flutter pub upgrade
```

## Architecture Overview

### Core Structure
The app follows a feature-based architecture with clear separation of concerns:

```
lib/
├── main.dart                           # App entry point with dark theme
├── features/
│   └── pose_detector/                  # Main pose detection feature
│       ├── screens/
│       │   └── home_screen.dart        # Main UI with exercise tracking logic
│       ├── services/
│       │   └── pose_detector_service.dart  # Isolate-based AI processing service
│       ├── widgets/
│       │   └── camera_view.dart        # Camera preview widget
│       ├── painters/
│       │   ├── keypoint_painter.dart   # Custom painter for pose visualization
│       │   └── coordinates_translator.dart  # Camera coordinate translation
│       └── utils/
│           ├── angle_calculator.dart    # Joint angle calculations
│           └── distance_calculator.dart # Spatial distance utilities
└── test_code/                         # Debug/testing utilities (debug mode only)
    ├── video_test_screen.dart
    └── video_frame_processor.dart
```

### Key Architectural Patterns

#### 1. Isolate-Based AI Processing
- **PoseDetectorService** runs ML Kit pose detection on a separate isolate
- Prevents UI blocking during intensive AI computations
- Uses stream-based communication between main thread and isolate
- Includes serialization/deserialization for cross-isolate data transfer

#### 2. State-Based Exercise Tracking
The app implements a state machine for exercise tracking:
- `ExerciseState.initializing`: Service startup
- `ExerciseState.notReady`: Waiting for user to get into starting position
- `ExerciseState.inProgress`: Actively counting repetitions

#### 3. Pose Locking Mechanism
- Locks onto a specific person's pose to maintain consistent tracking
- Uses nose landmark distance calculation to identify the same person
- Implements lost-lock recovery with configurable thresholds

## Project-Specific Development Notes

### Debug Features
- **Video Test Screen**: Available in debug mode only (accessed via yellow button)
- Located in `lib/test_code/` - utilities for testing with video files
- Debug mode detection using `kDebugMode` from `package:flutter/foundation.dart`

### Android Build Issues
- **Known Issue**: Gradle/Kotlin compatibility problems
- **Solution**: Use `./fix_sports_app.sh` script to resolve build issues
- The script handles plugin compatibility and Kotlin daemon issues
- Updates Gradle configurations to use compatible versions

### Camera Permissions
- App requires camera permissions for pose detection
- Uses `permission_handler` package for runtime permission requests
- Supports both front and rear camera switching

### ML Kit Integration
- Uses Google ML Kit's pose detection with custom confidence thresholds
- Processes landmarks for specific joints (shoulder, elbow, wrist)
- Implements real-time angle calculations for exercise form analysis

### Performance Considerations
- AI processing runs on background isolate to maintain 60fps UI
- Stream-based architecture prevents blocking operations
- Custom painters for efficient pose overlay rendering

## Development Environment Requirements

### Flutter Setup
- Flutter 3.35.3+ (stable channel recommended)
- Dart 3.9.2+
- Platform-specific requirements vary:
  - **Android**: Android SDK 36.1.0-rc1, Java 21
  - **iOS/macOS**: Xcode installation required (currently incomplete in this env)
  - **Web**: Chrome browser for testing

### Key Dependencies
```yaml
# Core dependencies
camera: ^0.11.2                        # Camera access
google_mlkit_pose_detection: ^0.14.0   # AI pose detection
permission_handler: ^12.0.1            # Runtime permissions
shared_preferences: ^2.2.3             # Data persistence
google_fonts: ^6.2.1                   # Typography (Fira Code)

# Development dependencies
flutter_lints: ^6.0.0                  # Code quality rules
file_picker: ^10.3.2                   # File selection utilities
path_provider: ^2.1.3                  # File system access
```

### Code Style
- Uses `flutter_lints` for code quality enforcement
- Follows standard Flutter/Dart naming conventions
- Custom theme with dark mode and Fira Code font family
- Comments include personality/humor but maintain technical accuracy
