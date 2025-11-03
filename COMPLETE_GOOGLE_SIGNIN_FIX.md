# 🔴 COMPLETE GOOGLE SIGN-IN FIX - Error 10

## ⚠️ CRITICAL ISSUE FOUND
Your `google-services.json` file **STILL has empty oauth_client array**:
```json
"oauth_client": [],  ❌ THIS IS THE PROBLEM
```

It should look like this:
```json
"oauth_client": [
  {
    "client_id": "362094165207-xxxxxxxxxxxxx.apps.googleusercontent.com",
    "client_type": 3
  }
],
```

---

## 🎯 STEP-BY-STEP FIX (Follow EXACTLY)

### Step 1: Enable Google Sign-In in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **ewise-e5ff8**
3. Click **Authentication** in left sidebar
4. If you see "Get started", click it
5. Go to **Sign-in method** tab
6. Click **Google** in the provider list
7. Toggle **Enable** switch to ON 
8. Enter your support email (any email)
9. Click **Save**

⚠️ **DO THIS FIRST before downloading google-services.json!**

---

### Step 2: Verify SHA-1 is Added

1. Still in Firebase Console → Click ⚙️ **Settings** → **Project settings**
2. Scroll to **Your apps** section → Find Android app
3. Under **SHA certificate fingerprints**, verify your SHA-1 is there
4. If not there, add it now:
   - Open Android Studio
   - Right panel → **Gradle** → `android` → `Tasks` → `android` → **signingReport**
   - Copy the SHA1 value
   - Add it in Firebase Console

---

### Step 3: Download NEW google-services.json

**⚠️ CRITICAL: You MUST download AFTER enabling Google Sign-In and adding SHA-1**

1. In Firebase Console → **Project settings** → **Your apps**
2. Find your Android app: `com.example.ewasteapp`
3. Click **"google-services.json"** button to download
4. **REPLACE** the file at:
   ```
   C:\MyProjects\q2-E-wise-Estano-Golosino\android\app\google-services.json
   ```

---

### Step 4: Verify the New File

Open the new `google-services.json` and check:

```json
"oauth_client": [
  {
    "client_id": "362094165207-xxxxx.apps.googleusercontent.com",
    "client_type": 3
  }
]
```

✅ It should have at least ONE entry (not empty `[]`)

---

### Step 5: Clean and Rebuild

In VS Code terminal (PowerShell):

```powershell
# Clean everything
flutter clean

# Get dependencies
flutter pub get

# Rebuild and run
flutter run
```

---

## 🎯 Alternative: Add OAuth Client Manually in Google Cloud Console

If the oauth_client is still empty after downloading, you may need to create it manually:

### Option A: Via Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (same as Firebase)
3. Left menu → **APIs & Services** → **Credentials**
4. Click **"+ CREATE CREDENTIALS"** → **OAuth client ID**
5. Select **Application type**: **Android**
6. Enter:
   - **Name**: `Android client for com.example.ewasteapp`
   - **Package name**: `com.example.ewasteapp`
   - **SHA-1 certificate fingerprint**: (paste your SHA-1)
7. Click **Create**
8. **NOW** download new `google-services.json` from Firebase Console

---

### Option B: Check Web Client ID Exists

1. In Firebase Console → **Authentication** → **Sign-in method** → **Google**
2. Look for **Web SDK configuration**
3. You should see **Web client ID**: `362094165207-xxxxx.apps.googleusercontent.com`
4. If you see this but oauth_client is still empty, you need Option A above

---

## 📋 Checklist

Before running the app, verify:

- [ ] Google Sign-In is **ENABLED** in Firebase Console → Authentication
- [ ] SHA-1 certificate is **ADDED** in Firebase Console → Project settings
- [ ] You **DOWNLOADED NEW** google-services.json AFTER enabling Google Sign-In
- [ ] The new google-services.json has **oauth_client with at least one entry** (not empty)
- [ ] File is at correct location: `android/app/google-services.json`
- [ ] Ran `flutter clean` and `flutter pub get`

---

## ✅ How to Know It's Fixed

When it works:
1. Google Sign-In account picker appears ✅
2. You select an account ✅
3. App navigates to feature intro pages ✅
4. No error appears ✅
5. You see "Signing in..." then your profile ✅

---

## 🆘 Still Error 10?

If oauth_client is populated but still getting error 10:

### Check 1: Uninstall App Completely
```powershell
# Uninstall from device
adb uninstall com.example.ewasteapp

# Rebuild and reinstall
flutter run
```

The old OAuth config might be cached on device.

### Check 2: Verify Package Name Matches
- In `google-services.json`: `"package_name": "com.example.ewasteapp"`
- In `android/app/build.gradle.kts`: `applicationId = "com.example.ewasteapp"`
- In `AndroidManifest.xml`: `package="com.example.ewasteapp"`

All three MUST match exactly.

### Check 3: Use Different Google Account
Try signing in with a different Google account - sometimes the first account has cached credentials.

---

## 🎯 Summary

**Root Cause**: Firebase doesn't generate OAuth clients until:
1. Google Sign-In provider is enabled in Authentication
2. SHA-1 certificate is added to the project

**Solution**: Enable Google Sign-In → Add SHA-1 → Download fresh google-services.json → Rebuild

The oauth_client array in your current file is empty, proving you haven't completed these steps in the correct order.
