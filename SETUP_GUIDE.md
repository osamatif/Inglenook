# Inglenook Grocery App - Setup Guide

## Quick Start After Security Fixes

This guide helps you set up the application after the security fixes have been applied.

---

## Prerequisites

- Flutter 3.0.0 or higher
- Firebase account
- Android Studio / Xcode
- Node.js 18+ (for Cloud Functions)

---

## Step 1: Firebase Setup (30 minutes)

### 1.1 Create/Update Firebase Project

```bash
# If you don't have a Firebase project yet:
# 1. Go to https://console.firebase.google.com/
# 2. Create a new project (or use existing: inglenook-e5595)
# 3. Enable Authentication, Firestore, and Storage
```

### 1.2 Rotate Credentials (if exposed)

If your credentials were previously exposed:

1. Firebase Console → Project Settings → Service Accounts
2. Generate new private keys
3. Regenerate API keys
4. Update OAuth 2.0 Client IDs in Google Cloud Console

### 1.3 Download New google-services.json

For each app (Admin, User, Delivery):

1. Firebase Console → Project Settings → Your Apps
2. Download `google-services.json` for each Android app
3. Download `GoogleService-Info.plist` for each iOS app

```bash
# Place files in correct locations:
cp ~/Downloads/google-services.json "Groccery App/grocery-admin/android/app/"
cp ~/Downloads/google-services.json "Groccery App/grocery_user/android/app/"
cp ~/Downloads/google-services.json "Groccery App/grocery_delivery/android/app/"

# For iOS:
cp ~/Downloads/GoogleService-Info.plist "Groccery App/grocery-admin/ios/Runner/"
cp ~/Downloads/GoogleService-Info.plist "Groccery App/grocery_user/ios/Runner/"
cp ~/Downloads/GoogleService-Info.plist "Groccery App/grocery_delivery/ios/Runner/"
```

### 1.4 Enable Firebase App Check

```bash
# In Firebase Console:
# 1. Go to App Check section
# 2. Register each app (admin, user, delivery)
# 3. For debug builds, create debug tokens
# 4. Copy debug tokens for local development
```

---

## Step 2: Configure Secrets (20 minutes)

### 2.1 Admin App

```bash
cd "Groccery App/grocery-admin"

# Copy template
cp lib/config/secrets.dart.example lib/config/secrets.dart

# Edit secrets.dart and fill in:
# - fcmServerKey: Firebase Cloud Messaging key
# - notificationsApi: Your backend notification API URL
# - sentryDsn: (Optional) Sentry error reporting DSN
```

### 2.2 User App

```bash
cd "../grocery_user"

# Copy template
cp lib/config/secrets.dart.example lib/config/secrets.dart

# Edit secrets.dart and fill in:
# - stripePublishableKey: pk_test_... or pk_live_...
# - stripeMerchantId: Your Stripe merchant ID
# - facebookAppId: Facebook OAuth app ID
# - googleClientId: Google OAuth client ID
# - notificationsApi: Backend API URL
# - paymentApiUrl: Backend payment endpoint
```

### 2.3 Delivery App

```bash
cd "../grocery_delivery"

# Copy template
cp lib/config/secrets.dart.example lib/config/secrets.dart

# Edit secrets.dart and fill in:
# - notificationsApi: Backend API URL
# - paymentApiUrl: Payment verification endpoint
# - googleMapsApiKey: (If using maps)
```

---

## Step 3: Deploy Firebase Security Rules (15 minutes)

### 3.1 Initialize Firebase CLI

```bash
cd ../../firebase

# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize project
firebase init

# Select:
# - Firestore
# - Storage
# - Functions (optional, for backend)
# - Hosting (optional)

# When prompted for project, select: inglenook-e5595 (or your project)
```

### 3.2 Deploy Rules

```bash
# Deploy Firestore and Storage rules
firebase deploy --only firestore:rules,storage:rules

# Verify deployment
firebase firestore:rules get
```

### 3.3 Create Admin User

```javascript
// Run this in Firebase Console → Firestore
// Or create via Cloud Functions

// 1. Create user in Firebase Authentication
// 2. Add admin document:
{
  "admins/{adminUserId}": {
    "role": "admin",
    "email": "admin@inglenook.com",
    "createdAt": "2026-01-08T12:00:00Z"
  }
}
```

---

## Step 4: Install Dependencies (10 minutes)

```bash
cd "Groccery App/grocery-admin"
flutter pub get

cd "../grocery_user"
flutter pub get

cd "../grocery_delivery"
flutter pub get
```

---

## Step 5: Android Configuration (15 minutes)

### 5.1 Update SDK Versions

For each app, edit `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 33  // Update from 29

    defaultConfig {
        targetSdkVersion 33  // Update from 29
        minSdkVersion 24
    }
}
```

### 5.2 Create Release Signing (Optional, for production)

```bash
# Generate keystore
keytool -genkey -v -keystore ~/inglenook-release.keystore \
  -alias inglenook -keyalg RSA -keysize 2048 -validity 10000

# Create key.properties in each app's android folder
echo "storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=inglenook
storeFile=/path/to/inglenook-release.keystore" > \
  "Groccery App/grocery-admin/android/key.properties"

# Update android/app/build.gradle to use signing config
```

---

## Step 6: Test the Apps (30 minutes)

### 6.1 Run Admin App

```bash
cd "Groccery App/grocery-admin"

# For debugging
flutter run --debug

# Test:
# 1. Login with admin credentials
# 2. View products
# 3. Check Firebase connection
```

### 6.2 Run User App

```bash
cd "../grocery_user"

flutter run --debug

# Test:
# 1. User registration/login
# 2. Browse products
# 3. Add to cart
# 4. DO NOT test payment yet (needs backend)
```

### 6.3 Run Delivery App

```bash
cd "../grocery_delivery"

flutter run --debug

# Test:
# 1. Delivery person login
# 2. View orders
# 3. Update order status
```

---

## Step 7: Set Up Backend (Optional but Recommended)

### 7.1 Initialize Cloud Functions

```bash
cd ../../firebase/functions

# Install dependencies
npm install

# Install required packages
npm install firebase-functions firebase-admin stripe express cors
```

### 7.2 Create Payment Function

Create `firebase/functions/src/payments.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
const stripe = require('stripe')(functions.config().stripe.secret_key);

admin.initializeApp();

export const createPaymentIntent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const { orderId, amount } = data;

  // Validate order
  const orderDoc = await admin.firestore()
    .collection('orders')
    .doc(orderId)
    .get();

  if (!orderDoc.exists || orderDoc.data()?.userId !== context.auth.uid) {
    throw new functions.https.HttpsError('permission-denied', 'Invalid order');
  }

  if (orderDoc.data()?.total !== amount) {
    throw new functions.https.HttpsError('invalid-argument', 'Amount mismatch');
  }

  // Create Stripe payment intent
  const paymentIntent = await stripe.paymentIntents.create({
    amount: amount * 100,
    currency: 'usd',
    metadata: { orderId, userId: context.auth.uid }
  });

  return { clientSecret: paymentIntent.client_secret };
});
```

### 7.3 Configure and Deploy

```bash
# Set Stripe secret key
firebase functions:config:set stripe.secret_key="sk_test_YOUR_KEY"

# Deploy functions
firebase deploy --only functions

# Test function
curl -X POST https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/createPaymentIntent \
  -H "Content-Type: application/json" \
  -d '{"orderId": "test123", "amount": 29.99}'
```

---

## Step 8: Production Deployment Checklist

Before deploying to production:

- [ ] All secrets configured with production keys
- [ ] Firebase security rules deployed and tested
- [ ] Release signing configured for Android
- [ ] App Store/Play Store certificates configured
- [ ] Backend payment processing implemented and tested
- [ ] Error logging (Crashlytics/Sentry) configured
- [ ] Analytics configured
- [ ] Privacy policy and terms of service added
- [ ] App tested on real devices (Android + iOS)
- [ ] Security audit completed
- [ ] Backup strategy in place

---

## Troubleshooting

### Issue: "google-services.json not found"
**Solution:** Copy the file from Firebase Console to the correct location (see Step 1.3)

### Issue: "Secrets not configured" error
**Solution:** Copy `secrets.dart.example` to `secrets.dart` and fill in values

### Issue: "Permission denied" in Firestore
**Solution:** Deploy security rules with `firebase deploy --only firestore:rules`

### Issue: Build errors after dependency updates
**Solution:**
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
cd ../ios && pod install
```

### Issue: Payment processing fails
**Solution:** Implement backend Cloud Functions (see Step 7)

---

## Environment Variables

For different environments (dev/staging/prod):

```bash
# Build with environment
flutter build apk --dart-define=ENV=production
flutter build apk --dart-define=ENV=development
flutter build apk --dart-define=ENV=staging
```

In code:
```dart
if (Environment.isProduction) {
  // Use production config
} else if (Environment.isDevelopment) {
  // Use development config
}
```

---

## Additional Resources

- [Firebase Security Rules Documentation](https://firebase.google.com/docs/rules)
- [Flutter Deployment Guide](https://flutter.dev/docs/deployment)
- [Stripe Flutter Integration](https://stripe.com/docs/payments/accept-a-payment?platform=flutter)
- [Firebase App Check](https://firebase.google.com/docs/app-check)

---

## Support

For issues:
1. Check `SECURITY_FIXES_COMPLETED.md` for detailed fixes
2. Review `APPLICATION_PITFALLS_ANALYSIS.md` for known issues
3. Test in Firebase emulator before production

---

**Last Updated**: 2026-01-08
**Version**: 1.5.0 (Post Security Fixes)
