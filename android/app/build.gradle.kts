import java.util.Properties
import java.nio.charset.Charset

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charset.forName("UTF-8")).use { reader ->
        localProperties.load(reader)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"
val kotlin_version = "1.9.22" // Kotlin version - adjust as needed

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.yugioh_scanner"
    compileSdk = flutter.compileSdkVersion

    //Forzamos la versión de NDK compatible con CameraX y ML Kit
    ndkVersion = "27.0.12077973" // Make sure this NDK version is installed via Android Studio SDK Manager

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // --- You might need signingConfigs defined here if not using debug ---
    // signingConfigs {
    //     debug {
    //         // Default debug config
    //     }
    //     release {
    //         // Your release signing config
    //         // storeFile file(...)
    //         // storePassword "..."
    //         // keyAlias "..."
    //         // keyPassword "..."
    //     }
    // }
    // --- End signingConfigs ---


    defaultConfig {
        applicationId = "com.example.yugioh_scanner"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
        // Optional: Add multidex support if needed by large dependencies
        // multiDexEnabled true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug") // Change this to your release config when ready

            // --- ⬇️ CONFIGURACIÓN DE PRODUCCIÓN OPTIMIZADA ⬇️ ---
            isMinifyEnabled = false // Desactivado por problemas con Google ML Kit
            isShrinkResources = false // Desactivado junto con minifyEnabled
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // ) // Reglas de ProGuard desactivadas por conflictos con ML Kit
            // --- ⬆️ FIN DE CONFIGURACIÓN DE PRODUCCIÓN ⬆️ ---
        }
        // You might have a debug block here too, usually empty or with debug-specific settings
        // debug {
        //     signingConfig = signingConfigs.getByName("debug")
        // }
    }
}

flutter {
    source = "../.."
}

// Add dependencies block if missing (usually needed)
dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:$kotlin_version") // Example dependency
    // Add other dependencies here if needed
    // implementation("androidx.multidex:multidex:2.0.1") // If using multidex
}
