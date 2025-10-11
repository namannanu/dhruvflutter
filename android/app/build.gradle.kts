plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mrmad.dhruv.talent"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mrmad.dhruv.talent"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Google Maps SDK for Android requires API level 21 or higher.
        minSdk = maxOf(21, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Set manifest placeholders for API keys. Prefer an environment variable so
        // release builds don't bake in the key, but keep the embedded key as a fallback
        // so debug builds continue to work out of the box.
        val embeddedMapsKey = "AIzaSyBYzLcIMOoqKPfuYtGU7WNj1Z54Efaq1o8"
        manifestPlaceholders["GOOGLE_PLACES_API_KEY"] =
            System.getenv("GOOGLE_PLACES_API_KEY") ?: embeddedMapsKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
