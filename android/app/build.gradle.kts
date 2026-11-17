import groovy.json.JsonSlurper
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Use the project's local client configuration for ordinary Flutter/IDE builds too.
// Explicit client defines select their own environment (including intentionally empty keys).
val clientKeys = setOf("FIREBASE_PROJECT_ID", "FIREBASE_WEB_API_KEY", "FIREBASE_APP_ID", "ORS_API_KEY")
val configFile = rootProject.file("../config/local.defines.json")
if (configFile.isFile) {
    val explicit = (findProperty("dart-defines") as? String).orEmpty()
        .split(',').filter(String::isNotEmpty)
    val explicitKeys = explicit.map { String(Base64.getDecoder().decode(it), Charsets.UTF_8).substringBefore('=') }
    val local = JsonSlurper().parse(configFile) as Map<*, *>
    val firebaseOverride = explicitKeys.any { it.startsWith("FIREBASE_") }
    val defaults = clientKeys.filter { it !in explicitKeys && !(firebaseOverride && it.startsWith("FIREBASE_")) }
        .mapNotNull { key -> (local[key] as? String)?.trim()?.takeIf { it.isNotEmpty() }?.let { "$key=$it" } }
        .map { Base64.getEncoder().encodeToString(it.toByteArray(Charsets.UTF_8)) }
    extensions.extraProperties["dart-defines"] = (explicit + defaults).joinToString(",")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "de.jankilic.kaizen"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "de.jankilic.kaizen"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = file(storeFilePath)
            }
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            // Use release keystore when key.properties exists; otherwise debug for sideload installs.
            signingConfig = if (keystorePropertiesFile.exists() &&
                !keystoreProperties.getProperty("storeFile").isNullOrBlank()
            ) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Match health 13.3.1; used by the permission-minimal workout reader.
    implementation("androidx.health.connect:connect-client:1.2.0-alpha02")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
}
