# Android Release Signing Configuration

## Overview

This guide explains how to configure proper release signing for the Android apps. Currently, all apps use **debug signing in release mode**, which is a **CRITICAL SECURITY ISSUE**.

⚠️ **NEVER** deploy to production with debug signing!

---

## Step 1: Generate Release Keystore

Run this command ONCE for each app (or use same keystore for all three):

```bash
# Navigate to your home directory or secure location
cd ~

# Generate keystore
keytool -genkey -v -keystore inglenook-release.keystore \
  -alias inglenook \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# You'll be prompted for:
# - Keystore password (SAVE THIS SECURELY!)
# - Key password (SAVE THIS SECURELY!)
# - Your name/organization details
```

**CRITICAL: Save these passwords securely!** Store them in a password manager. If you lose them, you'll never be able to update your app on Google Play.

---

## Step 2: Create key.properties File

For **each app** (admin, user, delivery), create a `key.properties` file:

### Admin App

```bash
nano "Groccery App/grocery-admin/android/key.properties"
```

Add:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=inglenook
storeFile=/home/youruser/inglenook-release.keystore
```

### User App

```bash
nano "Groccery App/grocery_user/android/key.properties"
```

Add:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=inglenook
storeFile=/home/youruser/inglenook-release.keystore
```

### Delivery App

```bash
nano "Groccery App/grocery_delivery/android/key.properties"
```

Add:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=inglenook
storeFile=/home/youruser/inglenook-release.keystore
```

⚠️ **These files are already in .gitignore - DO NOT commit them!**

---

## Step 3: Update build.gradle

The `build.gradle` files have already been prepared. Verify each app has this configuration:

### Check: `android/app/build.gradle`

Should have **before** the `android {` block:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

And inside `android {` block:

```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

---

## Step 4: Update build.gradle Files

For **each app**, add the signing configuration:

### Admin App

Edit: `Groccery App/grocery-admin/android/app/build.gradle`

Add at the top (after imports):

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Then update the `android {` section:

```gradle
android {
    // ... existing config ...

    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

Repeat for User and Delivery apps.

---

## Step 5: Build Release APK

```bash
cd "Groccery App/grocery_user"  # or grocery-admin, grocery_delivery

# Build release APK
flutter build apk --release

# Or build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

The signed APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

Or App Bundle at:
```
build/app/outputs/bundle/release/app-release.aab
```

---

## Step 6: Verify Signing

Verify the APK is properly signed:

```bash
# Check APK signature
jarsigner -verify -verbose -certs \
  build/app/outputs/flutter-apk/app-release.apk

# Should show "jar verified"
```

View certificate details:

```bash
keytool -list -v -keystore ~/inglenook-release.keystore \
  -alias inglenook
```

---

## Security Best Practices

### 1. **Keystore Storage**

- ✅ Store keystore in a secure location (not in project folder)
- ✅ Back up keystore to multiple secure locations
- ✅ Use a strong password (at least 16 characters)
- ❌ Never commit keystore to Git
- ❌ Never share keystore via email/chat

### 2. **CI/CD Setup** (for automated builds)

If using CI/CD (GitHub Actions, GitLab CI, etc.):

```yaml
# .github/workflows/build.yml
- name: Decode keystore
  run: |
    echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/keystore.jks

- name: Create key.properties
  run: |
    echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties
    echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
    echo "keyAlias=inglenook" >> android/key.properties
    echo "storeFile=keystore.jks" >> android/key.properties
```

Store keystore as Base64 in GitHub Secrets:

```bash
base64 -i ~/inglenook-release.keystore | pbcopy
# Then paste into GitHub Secrets as KEYSTORE_BASE64
```

### 3. **Google Play App Signing**

Enable Google Play App Signing (recommended):

1. Go to Google Play Console → Your App → Setup → App Integrity
2. Enable "Google Play App Signing"
3. Upload your keystore (Google will re-sign with their key)
4. Download new upload certificate

This provides:
- ✅ Key rotation capability
- ✅ Lost key recovery
- ✅ Smaller APK size

---

## Troubleshooting

### Error: "keystore not found"

Check `key.properties` path:
```bash
ls -la ~/inglenook-release.keystore
```

### Error: "password incorrect"

Double-check passwords in `key.properties`. Remember:
- `storePassword` = keystore password
- `keyPassword` = key password (often the same)

### Error: "minifyEnabled not working"

Make sure `proguard-rules.pro` exists in `android/app/`

### Build fails after adding signing

Check logs:
```bash
flutter build apk --release --verbose
```

---

## iOS Signing (Separate Process)

iOS signing is different and requires:
1. Apple Developer Account ($99/year)
2. Certificate from Apple Developer Portal
3. Provisioning Profile
4. Xcode configuration

See: https://flutter.dev/docs/deployment/ios

---

## Checklist

Before deploying to production:

- [ ] Generated release keystore
- [ ] Saved keystore passwords securely (password manager)
- [ ] Backed up keystore to multiple locations
- [ ] Created `key.properties` for each app
- [ ] Updated `build.gradle` for each app
- [ ] Built and verified signed APK
- [ ] Tested release build on real device
- [ ] Enabled Google Play App Signing (recommended)
- [ ] Set up CI/CD signing (if using automation)
- [ ] Documented keystore location for team

---

## Emergency Recovery

If you lose your keystore:

1. **Before Publishing**: Generate a new keystore, no problem
2. **After Publishing on Play Store**:
   - If using Google Play App Signing: Contact Google Support
   - If NOT using Google Play App Signing: You cannot update the app, must publish new app with different package name

**Prevention is key!** Back up your keystore NOW.

---

Last Updated: 2026-01-08
