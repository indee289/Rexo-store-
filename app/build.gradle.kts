plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("com.google.devtools.ksp")
}

// Apply google-services plugin at the end of file
// This ensures it runs AFTER all configurations are set

android {
    namespace = "com.rexo.marketplace"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.rexo.marketplace"
        minSdk = 29  // Android 10
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        
        vectorDrawables {
            useSupportLibrary = true
        }

        // Supabase Configuration from local.properties or GitHub Secrets
        val supabaseUrl = project.findProperty("SUPABASE_URL") as String? 
            ?: System.getenv("SUPABASE_URL") 
            ?: System.getenv("VITE_SUPABASE_URL") 
            ?: ""
        val supabaseAnonKey = project.findProperty("SUPABASE_ANON_KEY") as String? 
            ?: System.getenv("SUPABASE_ANON_KEY") 
            ?: System.getenv("VITE_SUPABASE_ANON_KEY") 
            ?: ""
        
        buildConfigField("String", "SUPABASE_URL", "\"$supabaseUrl\"")
        buildConfigField("String", "SUPABASE_ANON_KEY", "\"$supabaseAnonKey\"")
    }
    
    signingConfigs {
        create("release") {
            // Check if keystore exists (for CI/CD)
            val keystoreFile = file("../keystore.jks")
            if (keystoreFile.exists()) {
                storeFile = keystoreFile
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD") 
                    ?: project.findProperty("KEYSTORE_PASSWORD") as String?
                keyAlias = System.getenv("ANDROID_KEY_ALIAS") 
                    ?: project.findProperty("KEY_ALIAS") as String?
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD") 
                    ?: project.findProperty("KEY_PASSWORD") as String?
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Use release signing if keystore exists, otherwise debug
            val releaseConfig = signingConfigs.findByName("release")
            signingConfig = if (releaseConfig?.storeFile?.exists() == true) {
                releaseConfig
            } else {
                println("⚠️  Release keystore not found, using debug signing")
                signingConfigs.getByName("debug")
            }
        }
        debug {
            isDebuggable = true
            applicationIdSuffix = ".debug"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs += listOf(
            "-opt-in=androidx.compose.material3.ExperimentalMaterial3Api",
            "-opt-in=androidx.compose.foundation.ExperimentalFoundationApi"
        )
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    // AndroidX Core
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.activity:activity-compose:1.9.3")
    
    // Jetpack Compose BOM (Stable version)
    implementation(platform("androidx.compose:compose-bom:2024.10.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    
    // Navigation Compose
    implementation("androidx.navigation:navigation-compose:2.8.4")
    
    // ViewModel & LiveData
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")
    
    // Coil for Image Loading
    implementation("io.coil-kt:coil-compose:2.7.0")
    
    // Supabase Kotlin Client
    implementation(platform("io.github.jan-tennert.supabase:bom:3.0.2"))
    implementation("io.github.jan-tennert.supabase:postgrest-kt")
    implementation("io.github.jan-tennert.supabase:auth-kt")
    implementation("io.github.jan-tennert.supabase:realtime-kt")
    implementation("io.github.jan-tennert.supabase:storage-kt")
    implementation("io.ktor:ktor-client-android:3.0.2")
    
    // Retrofit for Express API
    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.squareup.retrofit2:converter-gson:2.11.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    
    // Room Database for Caching
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    ksp("androidx.room:room-compiler:2.6.1")
    
    // Firebase Cloud Messaging (Notifications only)
    implementation(platform("com.google.firebase:firebase-bom:33.6.0"))
    implementation("com.google.firebase:firebase-messaging-ktx")
    implementation("com.google.firebase:firebase-analytics-ktx")
    
    // Kotlin Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.9.0")
    
    // DataStore for Preferences
    implementation("androidx.datastore:datastore-preferences:1.1.1")
    
    // Accompanist for System UI Controller
    implementation("com.google.accompanist:accompanist-systemuicontroller:0.36.0")
    
    // Gson for JSON parsing
    implementation("com.google.code.gson:gson:2.11.0")
    
    // Splash Screen API
    implementation("androidx.core:core-splashscreen:1.0.1")
    
    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
    androidTestImplementation(platform("androidx.compose:compose-bom:2024.10.01"))
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}

// Apply google-services plugin at the END if google-services.json exists
apply {
    val googleServicesFile = file("google-services.json")
    if (googleServicesFile.exists()) {
        plugin("com.google.gms.google-services")
        println("✅ google-services plugin applied (google-services.json found)")
    } else {
        println("⚠️  google-services.json not found at: ${googleServicesFile.absolutePath}")
        println("⚠️  Skipping google-services plugin - Firebase features disabled")
    }
}
