# 🏗️ Rexo Marketplace Architecture

## Tech Stack Overview

### Backend Services

#### 1. **Supabase** (Primary Backend)
- **Authentication** ✅
  - User signup/login
  - JWT tokens
  - Session management
  - Email verification
  
- **Database** ✅
  - PostgreSQL database
  - Real-time subscriptions
  - Row-level security
  - All app data storage

- **Realtime** ✅
  - Live chat messages
  - Order status updates
  - Campaign updates
  - User presence

#### 2. **Cloudflare R2** (Storage)
- **File Storage** ✅
  - Product images
  - User avatars
  - Campaign media
  - Shop banners
  - S3-compatible API

#### 3. **Firebase** (Notifications Only)
- **Cloud Messaging (FCM)** ✅
  - Push notifications
  - Order alerts
  - Chat notifications
  - Campaign updates
  - Device token management

**Note:** Firebase is ONLY used for push notifications. No Firebase Auth, No Firestore, No Firebase Storage.

---

## Configuration

### Firebase Setup (Notifications Only)

**Package Name:** `com.rexo.marketplace`

**google-services.json:**
```json
{
  "project_info": {
    "project_id": "rexowallet2026"
  },
  "client": [
    {
      "client_info": {
        "package_name": "com.rexo.marketplace",
        "mobilesdk_app_id": "1:621816896534:android:6bfc099c9685f8f2d8e937"
      },
      "api_key": [
        {
          "current_key": "AIzaSyD_EXy40wTJQKRJX-HS1YzeH1pC6Oo1Pak"
        }
      ]
    }
  ]
}
```

**Dependencies:**
```kotlin
// Firebase (Notifications only)
implementation("com.google.firebase:firebase-messaging-ktx")
implementation("com.google.firebase:firebase-analytics-ktx")
```

### Supabase Setup

**Environment Variables:**
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

**Dependencies:**
```kotlin
// Supabase (Auth, Database, Realtime)
implementation("io.github.jan-tennert.supabase:postgrest-kt")
implementation("io.github.jan-tennert.supabase:auth-kt")
implementation("io.github.jan-tennert.supabase:realtime-kt")
implementation("io.github.jan-tennert.supabase:storage-kt")
```

### Cloudflare R2 Setup

**Access via S3-compatible API:**
```kotlin
// R2 endpoint configuration
endpoint = "https://your-account.r2.cloudflarestorage.com"
accessKey = "your-access-key"
secretKey = "your-secret-key"
```

---

## Data Flow

### User Authentication Flow:
```
1. User enters email/password
2. Supabase Auth validates credentials
3. Returns JWT token
4. Store token in local preferences
5. Register FCM device token with Supabase
```

### Product Image Upload Flow:
```
1. User selects image
2. Compress image locally
3. Upload to Cloudflare R2
4. Get public URL
5. Store URL in Supabase database
```

### Push Notification Flow:
```
1. Event occurs (new order, message, etc.)
2. Backend server calls Firebase Admin SDK
3. FCM sends push notification
4. Android app receives notification
5. Display notification with action
```

### Real-time Chat Flow:
```
1. User sends message
2. Insert into Supabase messages table
3. Supabase realtime broadcasts to subscribers
4. Other user receives message instantly
5. UI updates automatically
```

---

## Why This Architecture?

### Supabase (Primary)
✅ **Open source** - No vendor lock-in  
✅ **PostgreSQL** - Powerful relational database  
✅ **Real-time** - Built-in subscriptions  
✅ **Auth** - Complete authentication system  
✅ **Free tier** - 500MB DB, 2GB bandwidth  

### Cloudflare R2 (Storage)
✅ **No egress fees** - Free bandwidth!  
✅ **S3 compatible** - Easy migration  
✅ **Fast CDN** - Cloudflare's global network  
✅ **Cheap** - $0.015/GB storage  

### Firebase (Notifications)
✅ **Best push notifications** - Reliable delivery  
✅ **Free** - Unlimited notifications  
✅ **Multi-platform** - iOS, Android, Web  
✅ **Analytics** - Built-in tracking  

---

## Security

### API Keys (Public - Safe in Code):
```kotlin
✅ Supabase Anon Key - Row-level security protects data
✅ Firebase API Key - Only for device registration
✅ R2 Read-only key - Public assets only
```

### Secrets (Private - Server Only):
```kotlin
❌ Supabase Service Key - Never in app!
❌ R2 Write key - Server-side only!
❌ Firebase Admin SDK - Backend only!
```

### Authentication:
```kotlin
✅ JWT tokens - Supabase handles validation
✅ Row-level security - Database-level protection
✅ Secure storage - Android Keystore
```

---

## Folder Structure

```
app/src/main/java/com/rexo/marketplace/
├── data/
│   ├── local/          # Room database (caching)
│   ├── remote/         # Supabase client
│   ├── repository/     # Data repositories
│   └── model/          # Data models
├── ui/
│   ├── screens/        # Compose screens
│   ├── components/     # Reusable UI components
│   └── theme/          # Material 3 theme
├── navigation/         # Navigation graph
├── utils/              # Helper functions
└── services/           # Firebase messaging service
```

---

## Performance Optimizations

### Local Caching:
```kotlin
✅ Room database for offline access
✅ DataStore for preferences
✅ Coil for image caching
✅ Retrofit for API response caching
```

### Image Optimization:
```kotlin
✅ Compress images before upload
✅ Use WebP format
✅ Generate thumbnails
✅ Lazy loading with Coil
```

### Network Optimization:
```kotlin
✅ OkHttp connection pooling
✅ Gzip compression
✅ Request deduplication
✅ Background sync with WorkManager
```

---

## Dependencies Summary

```kotlin
// Core
androidx.compose - UI framework
androidx.lifecycle - ViewModel, LiveData
androidx.navigation - Navigation

// Backend
Supabase Kotlin - Auth, DB, Realtime, Storage
Firebase Messaging - Push notifications
Retrofit - HTTP client (for Express API if needed)

// Storage
Cloudflare R2 - Image/file storage (S3-compatible)

// Local
Room - SQLite database
DataStore - Key-value storage

// Utils
Coil - Image loading
Gson - JSON parsing
Coroutines - Async operations
```

---

## Build Configuration

### Package Name:
```
com.rexo.marketplace
```

### Min SDK:
```
29 (Android 10)
```

### Target SDK:
```
35 (Android 15)
```

### Build Types:
```kotlin
debug {
    applicationIdSuffix = ".debug"
    isDebuggable = true
}

release {
    isMinifyEnabled = true
    isShrinkResources = true
    proguardFiles(...)
}
```

---

## CI/CD

### GitHub Actions Workflow:
```yaml
✅ Auto-build on push to Rexo-Kotlin
✅ JDK 17, Android SDK 35, NDK
✅ Debug APK generation
✅ Artifact upload (30 days)
✅ Gradle caching for speed
```

### Build Time:
```
First build: ~5-7 minutes
Cached builds: ~2-3 minutes
```

---

## Future Enhancements

### Planned Features:
```
🔜 Payment gateway integration
🔜 Order tracking with maps
🔜 AI-powered recommendations
🔜 Multi-language support
🔜 Dark mode themes
🔜 Social media sharing
```

### Performance Goals:
```
🎯 App size < 20MB
🎯 Cold start < 2s
🎯 Image load < 500ms
🎯 API response < 300ms
```

---

**Architecture:** Modern, Scalable, Cost-effective  
**Stack:** Supabase + R2 + Firebase  
**Approach:** Mobile-first, Offline-capable  
**Status:** Production-ready ✅
