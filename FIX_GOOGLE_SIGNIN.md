# 🔧 FINAL FIX - Google Sign-In Error 10

## Problem
Your `google-services.json` has an empty `oauth_client` array, which means Google Sign-In can't work. You need to add your SHA-1 certificate to Firebase.

## Solution - Follow These Steps:

### Step 1: Get Your SHA-1 Certificate

**Option A: Using Android Studio (EASIEST)**
1. Open Android Studio
2. Open your project folder: `C:\MyProjects\q2-E-wise-Estano-Golosino`
3. On the right side, click **Gradle** tab
4. Navigate: `android` → `Tasks` → `android` → **`signingReport`**
5. Double-click `signingReport`
6. In the "Run" window at the bottom, look for:
   ```
   Variant: debug
   Config: debug
   Store: C:\Users\YourName\.android\debug.keystore
   Alias: androiddebugkey
   SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
   ```
7. **COPY the SHA1 value** (it's a long string with colons like `A1:B2:C3:...`)

**Option B: Using Command (if Java is in PATH)**
Open PowerShell and run:
```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -alias androiddebugkey -keystore $env:USERPROFILE\.android\debug.keystore -storepass android
```
Look for the SHA1 line and copy it.

---

### Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **ewise-e5ff8**
3. Click the ⚙️ **Settings** gear icon → **Project settings**
4. Scroll down to **Your apps** section
5. Find your Android app: `com.example.ewasteapp`
6. Scroll down to **SHA certificate fingerprints** section
7. Click **"Add fingerprint"**
8. Paste your SHA1 certificate
9. Click **Save**

---

### Step 3: Download New google-services.json

⚠️ **IMPORTANT:** After adding SHA-1, you MUST download a new config file!

1. Still in Firebase Console → Project settings → Your apps
2. Find your Android app: `com.example.ewasteapp`
3. Click **"google-services.json"** download button
4. Save it
5. **REPLACE** the old file at:
   ```
   C:\MyProjects\q2-E-wise-Estano-Golosino\android\app\google-services.json
   ```

The new file will have OAuth client entries (not empty anymore).

---

### Step 4: Enable Google Sign-In in Firebase

1. In Firebase Console, go to **Authentication** (left sidebar)
2. Click **"Get started"** if you haven't already
3. Go to **Sign-in method** tab
4. Click **Google** in the list
5. Toggle **"Enable"** to ON
6. Enter a support email (your email)
7. Click **Save**

---

### Step 5: Rebuild and Test

1. In VS Code, stop the app (if running)
2. Run in terminal:
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

---

## ✅ Success Indicators

After these steps:
- Google Sign-In will show account picker
- Clicking an account will sign you in (not close immediately)
- You'll see your profile with Google photo and name
- No more "ApiException: 10" error

---

## 🆘 Still Not Working?

**Check these:**
1. Make sure you downloaded the NEW `google-services.json` AFTER adding SHA-1
2. Verify the file has OAuth clients:
   ```json
   "oauth_client": [
     {
       "client_id": "...",
       "client_type": 3
     }
   ]
   ```
   (Should NOT be empty `[]`)
3. Make sure Google Sign-In is **Enabled** in Firebase Console → Authentication
4. Try uninstalling the app from your phone and reinstalling

---

## Quick Summary

❌ **Current Issue:** Empty oauth_client in google-services.json  
✅ **Solution:** Add SHA-1 → Download new config → Replace file → Rebuild

**The key is downloading the NEW google-services.json file after adding SHA-1!**
