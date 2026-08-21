# GitHub Actions Workflows

This directory contains automated CI/CD workflows for the Rexo Marketplace native Kotlin Android app.

---

## 📋 Available Workflows

### 1. **CI/CD - Continuous Integration** (`ci-cd.yml`)
**Trigger:** Every push and pull request to `Rexo-Kotlin` or `main` branch

**Jobs:**
- 🔍 **Code Quality** - Lint checks
- 🧪 **Unit Tests** - Run all unit tests
- 🏗️ **Build Debug APK** - Automatic debug build
- 🔐 **Dependency Check** - Security analysis
- 📢 **Build Status** - Summary report

**Purpose:** Ensures code quality on every commit

---

### 2. **Build Kotlin Android APK** (`build-kotlin-android.yml`)
**Trigger:** 
- Push to branches
- Tags (v*)
- Manual dispatch

**Features:**
- ✅ Automatic Debug & Release builds
- ✅ APK signing with keystore
- ✅ Artifact uploads
- ✅ GitHub Releases for tags
- ✅ Build verification

**Build Types:**
- **Debug APK** - Unsigned, for testing
- **Release APK** - Signed with keystore, production-ready

---

## 🔑 Required GitHub Secrets

### Essential Secrets
All secrets must be configured in: **Settings → Secrets and variables → Actions**

#### 1. Supabase Configuration
```
SUPABASE_URL
SUPABASE_ANON_KEY
```

#### 2. Firebase Configuration
```
GOOGLE_SERVICES_JSON
```
Full content of `google-services.json` file

#### 3. Keystore (Release Builds)
```
KEYSTORE_BASE64
KEYSTORE_PASSWORD
KEY_ALIAS
KEY_PASSWORD
```

---

## 📦 How to Get Secrets

### Getting SUPABASE_URL and SUPABASE_ANON_KEY
1. Go to Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to **Settings → API**
4. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon/public key** → `SUPABASE_ANON_KEY`

### Getting GOOGLE_SERVICES_JSON
1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project
3. Go to **Project Settings** (⚙️ icon)
4. Select your Android app
5. Click **Download google-services.json**
6. Copy the **entire JSON content** (not the file, the content inside)

### Creating Release Keystore
If you don't have a keystore yet:

```bash
# Generate new keystore
keytool -genkey -v \
  -keystore release.keystore \
  -alias rexo-release \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# Convert to Base64
base64 release.keystore > keystore.base64.txt
```

Then add to GitHub Secrets:
- `KEYSTORE_BASE64` = content of `keystore.base64.txt`
- `KEYSTORE_PASSWORD` = password you set during keytool
- `KEY_ALIAS` = alias (e.g., `rexo-release`)
- `KEY_PASSWORD` = key password (can be same as store password)

---

## 🚀 How to Use

### Automatic Builds
1. **On every push to `Rexo-Kotlin` branch:**
   - CI/CD runs automatically
   - Builds debug APK
   - Runs tests
   - Uploads artifacts

2. **On tag push (e.g., `v1.0.0`):**
   - Builds release APK
   - Signs with keystore
   - Creates GitHub Release
   - Uploads APK as release asset

### Manual Builds
1. Go to **Actions** tab in GitHub
2. Select **Build Kotlin Android APK**
3. Click **Run workflow**
4. Choose:
   - Branch: `Rexo-Kotlin`
   - Version: `1.0.0`
   - Build Type: `release` or `debug`
5. Click **Run workflow**

---

## 📥 Downloading APKs

### From CI/CD Builds
1. Go to **Actions** tab
2. Click on a workflow run
3. Scroll to **Artifacts** section
4. Download APK

### From Releases
1. Go to **Releases** tab
2. Click on a release
3. Download APK from **Assets** section

---

## 🔧 Workflow Configuration

### Build Matrix (Optional)
You can add multiple Android API levels:

```yaml
strategy:
  matrix:
    api-level: [29, 30, 31, 34]
```

### Build Variants
Current configuration:
- **Debug**: `assembleDebug`
- **Release**: `assembleRelease`

Can be extended with:
- Staging: `assembleStaging`
- Production: `assembleProduction`

---

## 📊 Build Outputs

### Debug Build
```
output: app/build/outputs/apk/debug/app-debug.apk
renamed: Rexo-Marketplace-v1.0.0-debug-{commit}.apk
size: ~18-22 MB
signed: No
```

### Release Build
```
output: app/build/outputs/apk/release/app-release.apk
renamed: Rexo-Marketplace-v1.0.0-release-{commit}.apk
size: ~12-15 MB (ProGuard enabled)
signed: Yes (with keystore)
```

---

## 🔍 Troubleshooting

### Build Fails: Missing Secrets
**Error:** `SUPABASE_URL not found`

**Solution:**
1. Go to **Settings → Secrets → Actions**
2. Add all required secrets
3. Re-run workflow

### Build Fails: Keystore Issues
**Error:** `Keystore not found` or `Invalid keystore format`

**Solution:**
1. Verify keystore is valid:
   ```bash
   keytool -list -v -keystore release.keystore
   ```
2. Re-encode to Base64:
   ```bash
   base64 release.keystore | tr -d '\n' > keystore.base64.txt
   ```
3. Update `KEYSTORE_BASE64` secret

### Build Fails: Gradle Issues
**Error:** `Could not resolve dependencies`

**Solution:**
1. Clear cache and re-run
2. Check `build.gradle.kts` dependencies
3. Update Gradle version if needed

### APK Not Signed
**Issue:** Release APK shows as unsigned

**Solution:**
1. Verify all keystore secrets are set
2. Check `build.gradle.kts` signing config
3. Ensure `build_type` is set to `release`

---

## 📈 Performance Tips

### Speed Up Builds
1. **Enable Gradle Cache:**
   Already configured in workflows

2. **Parallel Builds:**
   Add to `gradle.properties`:
   ```properties
   org.gradle.parallel=true
   org.gradle.caching=true
   ```

3. **Incremental Builds:**
   Already enabled by default

### Reduce APK Size
1. **Enable ProGuard:**
   Already configured in `build.gradle.kts`

2. **Enable Resource Shrinking:**
   ```gradle
   buildTypes {
       release {
           shrinkResources true
           minifyEnabled true
       }
   }
   ```

3. **Split APKs by ABI:**
   ```gradle
   splits {
       abi {
           enable true
       }
   }
   ```

---

## 🎯 Best Practices

### Version Naming
Use semantic versioning:
- `v1.0.0` - Major release
- `v1.1.0` - Minor features
- `v1.0.1` - Bug fixes

### Commit Messages
For automatic changelog:
```
feat: Add new feature
fix: Fix bug
docs: Update documentation
chore: Update dependencies
```

### Branch Strategy
- `main` - Production releases
- `Rexo-Kotlin` - Development branch
- `feature/*` - Feature branches
- `hotfix/*` - Urgent fixes

---

## 📚 Additional Resources

### Documentation
- [GitHub Actions Docs](https://docs.github.com/actions)
- [Android Build Docs](https://developer.android.com/build)
- [Gradle Documentation](https://docs.gradle.org)

### Tools
- [Android Build Tools](https://developer.android.com/tools/releases/build-tools)
- [Java Development Kit](https://adoptium.net/)
- [Gradle Build Tool](https://gradle.org/)

---

## 🆘 Support

If you encounter issues:

1. Check workflow logs in **Actions** tab
2. Review error messages carefully
3. Verify all secrets are configured
4. Check `build.gradle.kts` configuration
5. Ensure local build works first

---

**Status:** ✅ All workflows configured and tested  
**Last Updated:** December 2024  
**Maintained by:** Rexo Development Team
