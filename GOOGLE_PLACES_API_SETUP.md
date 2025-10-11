# Google Places API Setup Guide

This Flutter app uses the Google Places API for location autocomplete and place details. Follow this guide to properly configure the API key.

## 🔑 1. Create & Configure Google Places API Key

### Step 1: Enable APIs in Google Cloud Console
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create a new one)
3. Enable the following APIs:
   - **Places API** (required)
   - **Maps SDK for Android** (if using maps)
   - **Maps SDK for iOS** (if using maps)
   - *(New Places)* Enable the **Place Autocomplete** use case under the Places API configuration

### Step 2: Create an API Key
1. Navigate to **APIs & Services** > **Credentials**
2. Click **+ CREATE CREDENTIALS** > **API key**
3. Copy the generated API key

### Step 3: Secure the API Key
1. Click on the API key to edit it
2. **API restrictions**: Select "Restrict key" and choose:
   - Places API
   - Maps SDK for Android (if using maps)
   - Maps SDK for iOS (if using maps)
3. **Application restrictions**:
   - **Android**: Add package name `com.talent.talent` and your SHA-1 certificate fingerprint
   - **iOS**: Add bundle ID `com.talent.talent`

### Step 4: Enable Billing
- Billing must be enabled for your Google Cloud project
- The Places API has usage limits and costs

### Step 5: Hook up the key on every platform
- **Android**
  - `android/app/build.gradle.kts` now bumps `minSdk` to **21** and feeds the key to the manifest placeholder `GOOGLE_PLACES_API_KEY`.
  - The manifest reads the value via `<meta-data android:name="com.google.android.geo.API_KEY" android:value="${GOOGLE_PLACES_API_KEY}"/>`. Export the key as an env var before release builds or update the fallback in Gradle.
- **iOS**
  - `ios/Podfile` targets platform **14.0** to satisfy the latest Google Maps SDK requirements.
  - `AppDelegate.swift` imports `GoogleMaps` and calls `GMSServices.provideAPIKey`, pulling the value from `Info.plist` (`GMSApiKey`).
- **Web**
  - `web/index.html` injects the Maps JavaScript API script. Set `window.__flutterGoogleMapsApiKey` ahead of bootstrapping (or edit the embedded fallback) so maps load in web builds.

## 🚀 2. Configure the Flutter App

### Option A: Using env.json (Recommended for Development)
1. Update the `env.json` file in the project root:
```json
{
  "GOOGLE_PLACES_API_KEY": "YOUR_ACTUAL_API_KEY_HERE"
}
```

2. Run the app with:
```bash
flutter run --dart-define-from-file=env.json
```

### Option B: Direct dart-define
Run the app with the API key directly:
```bash
flutter run --dart-define=GOOGLE_PLACES_API_KEY=YOUR_ACTUAL_API_KEY_HERE
```

### Option C: VS Code Configuration
The project includes pre-configured launch configurations in `.vscode/launch.json`:
- **Debug with Places API**: Uses `env.json` file
- **Debug (Manual API Key)**: Uses direct API key (update the configuration)
- **Release with Places API**: Release build with `env.json`

## 🔨 3. Build Commands

### Debug Builds
```bash
# Using env.json file (recommended)
flutter run --dart-define-from-file=env.json

# Direct API key
flutter run --dart-define=GOOGLE_PLACES_API_KEY=YOUR_API_KEY
```

### Release Builds
```bash
# Android APK
flutter build apk --release --dart-define-from-file=env.json

# Android App Bundle
flutter build appbundle --release --dart-define-from-file=env.json

# iOS (from macOS)
flutter build ios --release --dart-define-from-file=env.json
```

## 🔧 4. How It Works

### Dart Code
The app reads the API key using:
```dart
const String.fromEnvironment('GOOGLE_PLACES_API_KEY', defaultValue: '')
```

This is implemented in `lib/core/services/google_places_service.dart`.

### Platform Configuration
- **Android**: The API key is passed to native code via `AndroidManifest.xml` manifest placeholders
- **iOS**: The API key is passed via `Info.plist` environment variable substitution

## 🔍 5. Troubleshooting

### "Google Places API key missing" Error
- Ensure you're running with `--dart-define` or `--dart-define-from-file`
- Check that your `env.json` file has the correct key name
- Verify the API key is valid and not empty

### API Errors
- **INVALID_REQUEST**: Check that the API key is correct
- **REQUEST_DENIED**: Verify API restrictions and billing
  - In the new Places API console, make sure the **Place Autocomplete** use case is enabled for this key
- **OVER_QUERY_LIMIT**: Check your API usage and billing limits

### Platform-Specific Issues
- **Android**: Ensure SHA-1 fingerprint is added to API key restrictions
- **iOS**: Ensure bundle ID is added to API key restrictions

## 📝 6. Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GOOGLE_PLACES_API_KEY` | Yes | Google Places API key for autocomplete and place details |

## 🔒 7. Security Notes

- **Never commit real API keys to version control**
- The `env.json` file should be added to `.gitignore` in production
- Use different API keys for development, staging, and production
- Regularly rotate API keys
- Monitor API usage in Google Cloud Console

## 🎯 8. Testing

To test if the API key is working:
1. Run the app with the API key configured
2. Navigate to the work location picker
3. Try typing in the location search field
4. You should see autocomplete suggestions

If you see a banner about missing API key, the configuration is not working properly.
