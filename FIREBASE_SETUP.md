# Firebase Setup Guide

This guide will help you set up Firebase Authentication and other services for the Sports App.

## Prerequisites

1. A Google account
2. Flutter development environment set up
3. Go development environment set up

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `sports-app-firebase`
4. Enable Google Analytics (recommended)
5. Choose or create a Google Analytics account
6. Click "Create project"

## Step 2: Configure Flutter App

### Android Setup

1. In Firebase Console, click "Add app" and select Android
2. Enter package name: `com.example.sports_app`
3. Download `google-services.json`
4. Replace the existing `android/app/google-services.json` with the downloaded file

### iOS Setup

1. In Firebase Console, click "Add app" and select iOS
2. Enter bundle ID: `com.example.sportsApp`
3. Download `GoogleService-Info.plist`
4. Replace the existing `ios/Runner/GoogleService-Info.plist` with the downloaded file

## Step 3: Enable Authentication

1. In Firebase Console, go to "Authentication" > "Sign-in method"
2. Enable "Email/Password" provider
3. Optionally enable "Anonymous" for testing

## Step 4: Configure Go API

1. In Firebase Console, go to "Project Settings" > "Service accounts"
2. Click "Generate new private key"
3. Download the JSON file
4. Rename it to `service-account-key.json`
5. Place it in the `sports_app_api` directory

## Step 5: Environment Configuration

### Flutter App

Create a `.env` file in the Flutter app root:

```env
API_BASE_URL=http://localhost:8080/api/v1
FIREBASE_PROJECT_ID=your-project-id
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true
```

### Go API

Create a `.env` file in the API root:

```env
PORT=8080
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_SERVICE_ACCOUNT_PATH=./service-account-key.json
JWT_SECRET=your-super-secret-jwt-key
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

## Step 6: Install Dependencies

### Flutter App

```bash
cd sports_app
flutter pub get
```

### Go API

```bash
cd sports_app_api
go mod tidy
```

## Step 7: Run the Applications

### Start the API Server

```bash
cd sports_app_api
go run main.go
```

### Start the Flutter App

```bash
cd sports_app
flutter run
```

## Security Features Implemented

- Firebase Authentication with email/password
- JWT token refresh mechanism
- CORS protection
- Rate limiting
- Security headers
- Input validation
- Request compression
- Error logging and monitoring

## Troubleshooting

### Common Issues

1. **Firebase initialization fails**: Check that the configuration files are in the correct locations
2. **Authentication errors**: Verify that the Firebase project has email/password authentication enabled
3. **API connection issues**: Ensure the API server is running and the correct port is configured

### Debug Mode

To enable debug mode, set the following environment variables:

```bash
export DEBUG_MODE=true
export LOG_LEVEL=debug
```

## Production Deployment

1. Update Firebase configuration files with production values
2. Set secure JWT secrets
3. Configure proper CORS origins
4. Enable all security features
5. Set up monitoring and logging
6. Use HTTPS in production
