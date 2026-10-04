import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

fun signingValue(propertyName: String, environmentName: String): String? =
    keystoreProperties.getProperty(propertyName)?.takeIf { it.isNotBlank() }
        ?: System.getenv(environmentName)?.takeIf { it.isNotBlank() }

val releaseStoreFilePath = signingValue("storeFile", "FINZO_KEYSTORE_FILE")
val releaseStorePassword = signingValue("storePassword", "FINZO_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "FINZO_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "FINZO_KEY_PASSWORD")
val hasReleaseSigning =
    releaseStoreFilePath != null &&
        releaseStorePassword != null &&
        releaseKeyAlias != null &&
        releaseKeyPassword != null

android {
    namespace = "com.ahsmobilelabs.finzo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.ahsmobilelabs.finzo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = rootProject.file(releaseStoreFilePath!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

gradle.taskGraph.whenReady {
    val releaseTaskRequested = allTasks.any { task ->
        task.path.endsWith(":app:assembleRelease") ||
            task.path.endsWith(":app:bundleRelease") ||
            task.name == "packageRelease"
    }

    if (releaseTaskRequested && !hasReleaseSigning) {
        throw GradleException(
            "Release signing is not configured. Create android/key.properties " +
                "from android/key.properties.example or set FINZO_KEYSTORE_FILE, " +
                "FINZO_KEYSTORE_PASSWORD, FINZO_KEY_ALIAS, and FINZO_KEY_PASSWORD."
        )
    }
}

dependencies {
    implementation("androidx.core:core:1.13.1")
}

flutter {
    source = "../.."
}
