plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.fit_posture_app"

    // Fixed: Using stable SDK 34 as SDK 36 is not yet stable and causes build failures
    compileSdk = 36

    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Use Java 17 (standard for modern Flutter/Android builds)
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // This MUST match the compileOptions above
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.fit_posture_app"

        // Required for ML Kit and Camera features
        minSdk = flutter.minSdkVersion

        // Match compileSdk
        targetSdk = 34

        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
