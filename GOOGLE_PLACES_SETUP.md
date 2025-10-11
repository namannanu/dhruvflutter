# Google Places API Setup Instructions

## Current Issue
The Google Places API key `AIzaSyDFdvCLMD2eSo3zGF3beVWtJjaCRJGmYgw` is not authorized, which is why location search returns empty results.

## Steps to Fix

### 1. Get a Valid Google Places API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable these APIs:
   - **Places API (New)**
   - **Places API**
   - **Maps SDK for iOS** (for iOS)
   - **Maps SDK for Android** (for Android)

### 2. Create API Key

1. Go to **APIs & Services > Credentials**
2. Click **+ CREATE CREDENTIALS > API key**
3. Copy the API key

### 3. Restrict API Key (Recommended)

1. Click on your API key to edit it
2. Under **Application restrictions**:
   - For iOS: Select "iOS apps" and add bundle ID: `com.mrmad.dhruv.talent`
   - For Android: Select "Android apps" and add:
     - Package name: `com.mrmad.dhruv.talent`
     - SHA-1 certificate fingerprint (get from your debug keystore)

### 4. Update Your Flutter App

Replace `YOUR_GOOGLE_PLACES_API_KEY_HERE` in these files with your actual API key:

1. **lib/core/config/environment_config.dart**
   ```dart
   static const String _embeddedPlacesKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```

2. **ios/Runner/Info.plist**
   ```xml
   <key>GMSApiKey</key>
   <string>YOUR_ACTUAL_API_KEY_HERE</string>
   ```

3. **android/app/build.gradle.kts**
   ```kotlin
   val embeddedMapsKey = "YOUR_ACTUAL_API_KEY_HERE"
   ```

### 5. Test the API Key

Test your API key with curl:
```bash
curl -X GET "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=New%20York&key=YOUR_ACTUAL_API_KEY_HERE"
```

Should return JSON with predictions array (not "REQUEST_DENIED").

### 6. Rebuild and Test

```bash
flutter clean
flutter pub get
flutter run
```

## Alternative: Use Environment Variable

Instead of hardcoding the API key, you can use an environment variable:

```bash
flutter run --dart-define=GOOGLE_PLACES_API_KEY=your_actual_api_key_here
```

This way your API key won't be committed to version control.