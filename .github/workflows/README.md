# 🚀 GitHub Actions - Rexo Marketplace

## Single Unified Workflow

**File:** `build-apk.yml`

### Features:
- ✅ Automatic builds on push to `Rexo-Kotlin` or `main`
- ✅ Debug APK generation
- ✅ All dependencies auto-installed (JDK 17, Android SDK API 34, NDK)
- ✅ Works with or without GitHub secrets
- ✅ APK artifact upload (30 days retention)
- ✅ Build summary with size & info

### Triggers:
- Push to `Rexo-Kotlin` or `main` branch
- Pull requests
- Manual trigger (workflow_dispatch)

### Requirements:
**Optional GitHub Secrets:**
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_ANON_KEY` - Supabase anonymous key

(Workflow uses placeholder values if secrets are missing)

## 📱 How to Download APK

1. Go to [Actions tab](https://github.com/indee289/Rexo-store-/actions)
2. Click on latest **green checkmark** workflow run
3. Scroll down to **Artifacts** section
4. Download `Rexo-APK-{commit-sha}.zip`
5. Extract ZIP file
6. Install APK on Android device

## 🔧 Build Process

```
1. Checkout code
2. Create google-services.json (before Gradle!)
3. Setup Java JDK 17
4. Setup Android SDK
5. Install NDK 26.1.10909125
6. Create local.properties
7. Grant gradlew permissions
8. Cache Gradle dependencies
9. Build Debug APK
10. Package & rename APK
11. Upload as artifact
12. Generate summary
```

## ✅ Build Success Indicators

- Green checkmark in Actions tab
- APK artifact available for download
- Summary shows APK size and details

## 📊 Typical Build Time

- **First build:** 5-7 minutes (downloading dependencies)
- **Cached builds:** 2-3 minutes

---

**Note:** Old workflows have been removed to keep things simple and clean. One workflow to rule them all! 🎯
