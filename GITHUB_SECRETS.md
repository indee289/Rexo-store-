# GitHub Secrets Configuration

This document lists all required GitHub Secrets for **Native Kotlin Android** CI/CD automation.

---

## 🔑 Required Secrets for Native Kotlin Android

### 1. Supabase Configuration
| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `SUPABASE_URL` | Supabase project URL | Dashboard → Project Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | Public API key | Dashboard → Project Settings → API → anon/public key |

**Example:**
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

### 2. Firebase Configuration
| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `GOOGLE_SERVICES_JSON` | Firebase config JSON | Firebase Console → Project Settings → Download google-services.json |

**How to add:**
1. Download `google-services.json` from Firebase Console
2. Copy the **entire JSON content** (not file path)
3. Paste into GitHub Secret

**Example format:**
```json
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "your-project-id",
    "storage_bucket": "your-project.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:abcdef",
        "android_client_info": {
          "package_name": "com.rexo.marketplace"
        }
      }
    }
  ]
}
```

---

### 3. Android Keystore (Release Builds)
| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `KEYSTORE_BASE64` | Base64 encoded keystore file | See instructions below |
| `KEYSTORE_PASSWORD` | Keystore password | Password used when creating keystore |
| `KEY_ALIAS` | Key alias name | Alias used when creating keystore |
| `KEY_PASSWORD` | Key password | Key password (can be same as store password) |

---

## 📦 Creating Android Keystore

If you don't have a release keystore yet, create one:

### Step 1: Generate Keystore
```bash
keytool -genkey -v \
  -keystore release.keystore \
  -alias rexo-release \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

**Prompts:**
```
Enter keystore password: [your-password]
Re-enter new password: [your-password]
What is your first and last name? [Your Name]
What is the name of your organizational unit? [Rexo Marketplace]
What is the name of your organization? [Rexo]
What is the name of your City or Locality? [Your City]
What is the name of your State or Province? [Your State]
What is the two-letter country code for this unit? [IN]
```

### Step 2: Convert to Base64
```bash
# macOS/Linux
base64 release.keystore | tr -d '\n' > keystore.base64.txt

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("release.keystore")) | Out-File keystore.base64.txt
```

### Step 3: Add to GitHub Secrets
1. Open `keystore.base64.txt`
2. Copy the entire content (single line)
3. Add to GitHub as `KEYSTORE_BASE64`

---

## ⚙️ How to Add Secrets to GitHub

### Method 1: GitHub Web UI
1. Go to your repository: https://github.com/indee289/Rexo-store-
2. Click **Settings** tab
3. In left sidebar, click **Secrets and variables → Actions**
4. Click **New repository secret**
5. Enter secret name (e.g., `SUPABASE_URL`)
6. Enter secret value
7. Click **Add secret**
8. Repeat for all secrets

### Method 2: GitHub CLI
```bash
# Install GitHub CLI if not already installed
# https://cli.github.com/

# Login
gh auth login

# Add secrets
gh secret set SUPABASE_URL -b "https://xxxxx.supabase.co"
gh secret set SUPABASE_ANON_KEY -b "eyJhbGci..."
gh secret set KEYSTORE_PASSWORD -b "your-password"
gh secret set KEY_ALIAS -b "rexo-release"
gh secret set KEY_PASSWORD -b "your-key-password"

# For GOOGLE_SERVICES_JSON (from file)
gh secret set GOOGLE_SERVICES_JSON < google-services.json

# For KEYSTORE_BASE64 (from file)
gh secret set KEYSTORE_BASE64 < keystore.base64.txt
```

---

## ✅ Verification Checklist

After adding all secrets, verify:

- [ ] `SUPABASE_URL` - Correct Supabase project URL
- [ ] `SUPABASE_ANON_KEY` - Valid anon key (starts with `eyJ...`)
- [ ] `GOOGLE_SERVICES_JSON` - Valid JSON format
- [ ] `KEYSTORE_BASE64` - Base64 encoded keystore (single line)
- [ ] `KEYSTORE_PASSWORD` - Correct keystore password
- [ ] `KEY_ALIAS` - Matches alias used in keytool
- [ ] `KEY_PASSWORD` - Correct key password

---

## 🔍 Testing Secrets

### Test Locally First
Before using in CI/CD, test locally:

```bash
# Create local.properties
cat > local.properties << EOF
sdk.dir=$ANDROID_HOME
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_key
EOF

# Copy google-services.json
cp path/to/google-services.json app/

# Copy keystore
cp path/to/release.keystore app/

# Test build
./gradlew assembleRelease
```

### Test in GitHub Actions
1. Push code to trigger workflow
2. Check **Actions** tab
3. View workflow logs
4. Verify secrets are loaded (they will show as `***`)

---

## 🚨 Security Best Practices

### DO ✅
- Store sensitive data only in GitHub Secrets
- Use different keys for dev/staging/prod
- Rotate keys periodically
- Use strong passwords for keystore
- Enable 2FA on GitHub account

### DON'T ❌
- Commit secrets to git
- Share secrets in plain text
- Use same passwords across environments
- Store secrets in code comments
- Push keystore files to repository

---

## 🔐 Secret Rotation

If a secret is compromised:

1. **Supabase Keys:**
   - Go to Supabase Dashboard → Project Settings → API
   - Click **Reset anon key**
   - Update GitHub Secret

2. **Keystore:**
   - Generate new keystore
   - Update all 4 keystore secrets
   - Re-sign all APKs

3. **Firebase:**
   - Regenerate google-services.json
   - Update GitHub Secret

---

## 📊 Secrets Summary

| Secret | Required For | Size Limit |
|--------|--------------|------------|
| `SUPABASE_URL` | ✅ All builds | ~50 chars |
| `SUPABASE_ANON_KEY` | ✅ All builds | ~200 chars |
| `GOOGLE_SERVICES_JSON` | ✅ All builds | ~2KB |
| `KEYSTORE_BASE64` | ✅ Release only | ~4KB |
| `KEYSTORE_PASSWORD` | ✅ Release only | ~50 chars |
| `KEY_ALIAS` | ✅ Release only | ~50 chars |
| `KEY_PASSWORD` | ✅ Release only | ~50 chars |

**Total:** 7 secrets required

---

## 🆘 Troubleshooting

### "Secret not found" Error
**Solution:** Verify secret name matches exactly (case-sensitive)

### "Invalid keystore format" Error
**Solution:** 
1. Verify Base64 encoding is correct
2. Ensure no line breaks in Base64 string
3. Test keystore locally first

### "Authentication failed" Error
**Solution:**
1. Check Supabase keys are correct
2. Verify keys haven't expired
3. Test keys with curl:
   ```bash
   curl "YOUR_SUPABASE_URL/rest/v1/" \
     -H "apikey: YOUR_ANON_KEY"
   ```

### "google-services.json not found" Error
**Solution:**
1. Verify JSON is valid (use jsonlint.com)
2. Ensure entire JSON content is in secret
3. Check package name matches

---

## 📚 Additional Resources

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Supabase API Keys](https://supabase.com/docs/guides/api/api-keys)
- [Firebase Setup](https://firebase.google.com/docs/android/setup)

---

**Last Updated:** December 2024  
**Status:** ✅ All secrets documented
