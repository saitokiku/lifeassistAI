plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kaizen.life_dashboard"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time — desugared so it
        // runs on every supported Android version.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.kaizen.life_dashboard"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release signing comes from android/key.properties when present
    // (gitignored — never commit a keystore or its passwords). Create it
    // alongside a keystore you keep safe:
    //
    //   keytool -genkey -v -keystore ~/lifeassist-release.jks \
    //     -keyalg RSA -keysize 2048 -validity 10000 -alias lifeassist
    //
    //   android/key.properties:
    //     storeFile=/Users/you/lifeassist-release.jks
    //     storePassword=...
    //     keyPassword=...
    //     keyAlias=lifeassist
    //
    // Why this matters beyond store distribution: CI runners are
    // ephemeral and cache nothing, so the debug fallback minted a NEW
    // random keystore on every build. Consecutive APKs were signed by
    // different identities, so installing an update over an existing
    // build failed with INSTALL_FAILED_UPDATE_INCOMPATIBLE and forced an
    // uninstall — which deletes the local database. A stable key makes
    // updates install in place and keeps user data.
    val keystoreProperties = java.util.Properties().apply {
        val file = rootProject.file("key.properties")
        if (file.exists()) file.inputStream().use { load(it) }
    }
    val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Falls back to debug signing only for local `flutter run
            // --release`; a distributable build needs key.properties.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
