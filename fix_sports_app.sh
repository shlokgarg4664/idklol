#!/bin/bash

# Script to fix Gradle build issues in sports_app Flutter project (Kotlin DSL)
# Enforces JVM target 17 for all Kotlin compilations to resolve FlutterPlugin.kt errors

# Exit on any error
set -e

# Define project directory
PROJECT_DIR="$(pwd)"
ANDROID_DIR="$PROJECT_DIR/android"
GRADLE_PROPERTIES="$ANDROID_DIR/gradle.properties"
APP_BUILD_GRADLE_KTS="$ANDROID_DIR/app/build.gradle.kts"
LOCAL_PROPERTIES="$ANDROID_DIR/local.properties"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print messages
print_message() {
    echo -e "${2:-$GREEN}$1${NC}"
}

# Step 1: Check if Flutter is installed
if ! command -v flutter >/dev/null 2>&1; then
    echo -e "${RED}Error: Flutter is not installed or not in PATH. Add to ~/.zshrc: export PATH=\$PATH:/Users/lonely/development/flutter/bin${NC}"
    echo -e "${YELLOW}Then run: source ~/.zshrc && flutter --version${NC}"
    exit 1
fi

# Step 2: Check Flutter version and update if needed
print_message "Checking Flutter version..."
FLUTTER_VERSION=$(flutter --version | grep 'Flutter' | awk '{print $2}')
print_message "Current Flutter version: $FLUTTER_VERSION"
echo -e "${YELLOW}Updating to the latest stable version...${NC}"
flutter channel stable
flutter upgrade --force

# Step 3: Clean project
print_message "Cleaning Flutter project..."
flutter clean
rm -rf "$ANDROID_DIR/.gradle" "$ANDROID_DIR/build"

# Step 4: Update local.properties with Flutter SDK path
print_message "Updating $LOCAL_PROPERTIES..."
FLUTTER_PATH=$(dirname "$(dirname "$(which flutter)")")
if [ -f "$LOCAL_PROPERTIES" ]; then
    cp "$LOCAL_PROPERTIES" "$LOCAL_PROPERTIES.bak"
else
    echo -e "${YELLOW}Creating $LOCAL_PROPERTIES...${NC}"
fi
cat > "$LOCAL_PROPERTIES" << EOL
sdk.dir=/Users/lonely/Library/Android/sdk
flutter.sdk=$FLUTTER_PATH
flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=1
EOL
echo -e "${YELLOW}Updated $LOCAL_PROPERTIES. Verify paths:${NC}"
cat "$LOCAL_PROPERTIES"

# Step 5: Update gradle.properties to enforce JVM target 17
print_message "Updating $GRADLE_PROPERTIES to enforce JVM target 17..."
if [ -f "$GRADLE_PROPERTIES" ]; then
    cp "$GRADLE_PROPERTIES" "$GRADLE_PROPERTIES.bak"
else
    echo -e "${YELLOW}Creating $GRADLE_PROPERTIES...${NC}"
fi
cat > "$GRADLE_PROPERTIES" << EOL
org.gradle.jvmargs=-Xmx4g -Dkotlin.daemon.jvm.options="-Xmx4g -Djava.net.preferIPv4Stack=true"
kotlin.code.style=official
kotlin.incremental=true
kotlin.jvm.target=17
android.enableJetifier=false
android.useAndroidX=true
EOL
echo -e "${YELLOW}Updated $GRADLE_PROPERTIES. Verify the file:${NC}"
cat "$GRADLE_PROPERTIES"

# Step 6: Update app/build.gradle.kts with JVM target 17
print_message "Updating $APP_BUILD_GRADLE_KTS with JVM target 17..."
if [ -f "$APP_BUILD_GRADLE_KTS" ]; then
    cp "$APP_BUILD_GRADLE_KTS" "$APP_BUILD_GRADLE_KTS.bak"
    # Ensure JVM target is set to 17
    sed -i '' 's/jvmTarget = .*/jvmTarget = "17"/g' "$APP_BUILD_GRADLE_KTS" || \
    sed -i '' '/kotlinOptions {/a\        jvmTarget = "17"' "$APP_BUILD_GRADLE_KTS"
    sed -i '' 's/sourceCompatibility = .*/sourceCompatibility = JavaVersion.VERSION_17/g' "$APP_BUILD_GRADLE_KTS" || \
    sed -i '' '/compileOptions {/a\        sourceCompatibility = JavaVersion.VERSION_17' "$APP_BUILD_GRADLE_KTS"
    sed -i '' 's/targetCompatibility = .*/targetCompatibility = JavaVersion.VERSION_17/g' "$APP_BUILD_GRADLE_KTS" || \
    sed -i '' '/compileOptions {/a\        targetCompatibility = JavaVersion.VERSION_17' "$APP_BUILD_GRADLE_KTS"
    sed -i '' 's/minSdk = [0-9]*/minSdk = 21/g' "$APP_BUILD_GRADLE_KTS"
    sed -i '' 's/compileSdk = [0-9]*/compileSdk = 34/g' "$APP_BUILD_GRADLE_KTS"
    sed -i '' 's/targetSdk = [0-9]*/targetSdk = 34/g' "$APP_BUILD_GRADLE_KTS"
else
    echo -e "${YELLOW}Creating $APP_BUILD_GRADLE_KTS...${NC}"
    mkdir -p "$ANDROID_DIR/app"
    cat > "$APP_BUILD_GRADLE_KTS" << 'EOL'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sports_app"
    compileSdk = 34

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.sports_app"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.debug
        }
    }
}

flutter {
    source = "../.."
}

dependencies {}
EOL
fi
echo -e "${YELLOW}Updated $APP_BUILD_GRADLE_KTS. Verify the file:${NC}"
cat "$APP_BUILD_GRADLE_KTS"

# Step 7: Run Flutter pub get
print_message "Running flutter pub get..."
flutter pub get

# Step 8: Build the project
print_message "Building APK (debug mode)..."
if flutter build apk --debug --verbose; then
    print_message "SUCCESS! APK built at build/app/outputs/flutter-apk/app-debug.apk"
else
    echo -e "${RED}Build failed. Run 'flutter build apk --debug --verbose' for details.${NC}"
    exit 1
fi

print_message "Fixes complete! Test the app with 'flutter run'."