import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 全アプリ共通のアップロードキー(あれば、リリースビルドをこれで署名する)
val uploadKeyFile = file(System.getProperty("user.home") + "/.private_keys/play-upload.properties")
val uploadKey = Properties().apply { if (uploadKeyFile.exists()) uploadKeyFile.inputStream().use { load(it) } }

android {
    namespace = "com.okinnnikudekao.italianbrainrot"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.okinnnikudekao.italianbrainrot"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (uploadKeyFile.exists()) {
            create("upload") {
                storeFile = file(uploadKey.getProperty("storeFile"))
                storePassword = uploadKey.getProperty("storePassword")
                keyAlias = uploadKey.getProperty("keyAlias")
                keyPassword = uploadKey.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (uploadKeyFile.exists()) signingConfigs.getByName("upload") else signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
