plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

// Release signing comes from the CI environment (see .github/workflows/native-apk.yml).
// Without it the release build falls back to the debug key, which is fine for local tests.
val panelKeystore: String? = System.getenv("PANEL_KEYSTORE")?.takeIf { file(it).exists() }

// Optional pre-filled connection defaults for the settings screen (gradle -PpanelDefaultHost=...).
fun prop(name: String): String = (project.findProperty(name) as String?).orEmpty()

android {
    namespace = "com.example.haade_panel_s504"
    compileSdk = 35

    defaultConfig {
        // Same id as the original Flutter app, so Home Assistant / Fully references keep working.
        applicationId = "com.example.haade_panel_s504"
        minSdk = 26
        targetSdk = 35
        versionCode = 200
        versionName = "2.0.0"
        ndk { abiFilters += listOf("arm64-v8a", "armeabi-v7a") }
        buildConfigField("String", "DEFAULT_HOST", "\"${prop("panelDefaultHost")}\"")
        buildConfigField("String", "DEFAULT_USER", "\"${prop("panelDefaultUser")}\"")
    }

    signingConfigs {
        create("release") {
            if (panelKeystore != null) {
                storeFile = file(panelKeystore)
                storeType = "pkcs12"
                storePassword = System.getenv("PANEL_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("PANEL_KEY_ALIAS")
                keyPassword = System.getenv("PANEL_KEYSTORE_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName(if (panelKeystore != null) "release" else "debug")
        }
    }

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    packaging {
        // Vendor JNI blobs: extract them like the original app did.
        jniLibs { useLegacyPackaging = true }
    }
}

dependencies {
    implementation("org.eclipse.paho:org.eclipse.paho.client.mqttv3:1.2.5")
}
