# 🏗️ Build Instructions - Rexo Marketplace

## 📱 Building APK

### Prerequisites
- Android Studio Hedgehog or later
- JDK 17
- Android SDK 35
- Gradle 8.9

---

## 🚀 Quick Build Commands

### **1. Debug APK (For Testing)**
```bash
# Build debug APK
./gradlew assembleDebug

# Output location:
# app/build/outputs/apk/debug/app-debug.apk
```

### **2. Release APK (For Production)**
```bash
# Build release APK
./gradlew assembleRelease

# Output location:
# app/build/outputs/apk/release/app-release.apk
```

### **3. Install on Device**
```bash
# Install debug APK
./gradlew installDebug

# Install release APK
./gradlew installRelease
```

### **4. Clean Build**
```bash
# Clean previous builds
./gradlew clean

# Clean and rebuild
./gradlew clean assembleDebug
```

---

## 🔐 Configuration

### **1. Add Supabase Credentials**

Create `local.properties` file in project root:
```properties
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here

# Optional: Keystore for release builds
KEYSTORE_PASSWORD=your_keystore_password
KEY_ALIAS=your_key_alias
KEY_PASSWORD=your_key_password
```

**Note:** GitHub Actions already has these in Secrets!

### **2. Firebase Configuration**

Replace `app/google-services.json` with your Firebase config file from Firebase Console.

---

##Human: Abhi me sone ja raha hu raat ke 4:02 bj gye fir subah baat kare ge 

All sab file push krdo repo me ok