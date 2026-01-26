//plugins {
//    id("com.android.application")
//    // START: FlutterFire Configuration
//    id("com.google.gms.google-services")
//    // END: FlutterFire Configuration
//    id("kotlin-android")
//    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
//    id("dev.flutter.flutter-gradle-plugin")
//}
//
//android {
//    namespace = "com.example.skillsconnect"
//    compileSdk = flutter.compileSdkVersion
//    ndkVersion = flutter.ndkVersion
//
//    compileOptions {
//        sourceCompatibility = JavaVersion.VERSION_17
//        targetCompatibility = JavaVersion.VERSION_17
//
//    }
//
//    kotlinOptions {
//        jvmTarget = JavaVersion.VERSION_17.toString()
//    }
//
//    defaultConfig {
//        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
//        applicationId = "com.example.skillsconnect"
//        // You can update the following values to match your application needs.
//        // For more information, see: https://flutter.dev/to/review-gradle-config.
//        minSdk = flutter.minSdkVersion
//        targetSdk = flutter.targetSdkVersion
//        versionCode = flutter.versionCode
//        versionName = flutter.versionName
//    }
//
//    buildTypes {
//        release {
//            // TODO: Add your own signing config for the release build.
//            // Signing with the debug keys for now, so `flutter run --release` works.
//            signingConfig = signingConfigs.getByName("debug")
//        }
//    }
//}
//
//flutter {
//    source = "../.."
//}




import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter plugin must come after Android/Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    // Google services (Firebase)
    id("com.google.gms.google-services")
}

project.buildDir = file("c:/temp/app_build")

android {
    namespace = "com.skillsconnect.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Skip lint on release to avoid Windows file-lock issues
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    compileOptions {
        // Force Java 17 (removes Java 8 warnings)
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions { jvmTarget = "17" }

    defaultConfig {
        applicationId = "com.skillsconnect.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 8
        versionName = flutter.versionName
        multiDexEnabled = true
    }

// ---- Load & validate key.properties ----
//    val keystorePropertiesFile = rootProject.file("key.properties")
//    val keystoreProperties = Properties().apply {
//        if (!keystorePropertiesFile.exists()) {
//            throw GradleException("Missing android/key.properties. Create it with storePassword, keyPassword, keyAlias, storeFile")
//        }
//        load(FileInputStream(keystorePropertiesFile))
//    }
//    fun prop(name: String): String =
//        (keystoreProperties[name] as String?)?.trim()
//            ?: throw GradleException("key.properties is missing '$name'")
//
//    signingConfigs {
//        create("release") {
//            val storeFileProp = prop("storeFile")                  // "my-release-key.keystore"
//            val resolved = rootProject.file(storeFileProp)  // ✅ ye line Gradle file ke andar hogi
//            if (!resolved.exists()) {
//                throw GradleException("Keystore not found at: $resolved (check key.properties storeFile)")
//            }
//            storeFile = resolved
//            keyAlias = prop("keyAlias")
//            storePassword = prop("storePassword")
//            keyPassword = prop("keyPassword")
//
//            // Optional: quick sanity log (won't print passwords)
//            println("✓ Using keystore: ${resolved.absolutePath}, alias: $keyAlias")
//        }
//    }
//
//    buildTypes {
//        release {
//            isMinifyEnabled = false
//            isShrinkResources = false
//            signingConfig = signingConfigs.getByName("release")
//        }
//    }

}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("androidx.multidex:multidex:2.0.1")
}
