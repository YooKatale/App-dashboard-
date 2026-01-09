plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services plugin for Firebase (REQUIRED for FCM)
    id("com.google.gms.google-services")
}

// Load keystore properties if file exists
import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.yookatale.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // Fix for fluttertoast compatibility
    buildFeatures {
        buildConfig = true
    }

    // Ensure R class generation
    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        // Unique Application ID for Play Store
        applicationId = "com.yookatale.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Google Maps API Key - can be set via gradle.properties or environment variable
        // Add to android/gradle.properties.local: MAPS_API_KEY=YOUR_ACTUAL_API_KEY
        // NEVER commit your actual API key to git!
        val mapsApiKey = project.findProperty("MAPS_API_KEY") as String? ?: ""
        if (mapsApiKey.isNotEmpty() && mapsApiKey != "YOUR_GOOGLE_MAPS_API_KEY_HERE") {
            manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
        } else {
            // Fallback to empty or placeholder - you should set this in gradle.properties
            manifestPlaceholders["MAPS_API_KEY"] = ""
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"]?.toString() ?: ""
                keyPassword = keystoreProperties["keyPassword"]?.toString() ?: ""
                // Keystore file is in android directory, not android/app directory
                val keystoreFileName = keystoreProperties["storeFile"]?.toString() ?: ""
                storeFile = if (keystoreFileName.isNotEmpty()) {
                    rootProject.file(keystoreFileName)
                } else {
                    file("")
                }
                storePassword = keystoreProperties["storePassword"]?.toString() ?: ""
            }
        }
    }

    buildTypes {
        release {
            // Use release signing config if available, otherwise fall back to debug
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Fallback to debug for development (will show warning)
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
