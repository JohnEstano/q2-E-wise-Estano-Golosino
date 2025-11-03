# Firebase Setup Instructions

This guide will help you configure Firebase Authentication and Google Sign-In for your E-Wise app.

## Prerequisites
- A Google account
- Android Studio (for Android)
- Xcode (for iOS, if building for iOS)

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `ewise` (or your preferred name)
4. Follow the setup wizard (you can disable Google Analytics if not needed)
5. Click **"Create project"**

## Step 2: Add Android App to Firebase

### 2.1 Register Your Android App

1. In Firebase Console, click the Android icon (or **"Add app"** → **Android**)
2. Enter the following details:
   - **Android package name**: `com.example.ewasteapp` (found in `android/app/src/main/AndroidManifest.xml`)
   - **App nickname** (optional): E-Wise Android
   - **Debug signing certificate SHA-1**: **Leave empty for now** (you can add it later)
3. Click **"Register app"**

**Note**: You can skip the SHA-1 during initial setup. Email/Password authentication will work immediately. You only need SHA-1 for Google Sign-In, which you can add later.

### 2.2 Get SHA-1 Certificate

**EASIEST METHOD for Windows - No SHA-1 needed initially!**

Good news! You can configure Firebase without the SHA-1 certificate first, then add it later:

1. **Skip the SHA-1 for now** during app registration
2. Register your Android app with just the package name: `com.example.ewasteapp`
3. Download and add `google-services.json`
4. **Test the app** - Email/Password auth will work immediately!
5. **Add SHA-1 later** for Google Sign-In (see methods below)

---

**To get SHA-1 when you need it (for Google Sign-In):**

**Option A: Using keytool (if Java is installed)**
```powershell
# Find your Java installation first
where.exe javac

# Then run (replace path with your Java installation):
"C:\Program Files\Java\jdk-XX\bin\keytool.exe" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Option B: Build app first, then use Gradle**
```powershell
# This creates the Gradle wrapper files
flutter build apk --debug

# Then get SHA-1:
cd android
.\gradlew.bat signingReport
```

**Option C: Use Android Studio (Recommended)**
1. Open the `android` folder in Android Studio
2. Click on **Gradle** panel (right side)
3. Navigate to: `android` → `app` → `Tasks` → `android` → `signingReport`
4. Double-click `signingReport`
5. Copy the SHA1 value from the output

**Option D: Flutter Helper Command**
```powershell
# Build the app, which generates keys if needed
flutter build apk --debug

# The SHA-1 will be in the build output or use Option B after this
```

Look for the SHA-1 under `Task :app:signingReport` → `Variant: debug` → `SHA1`.

Copy this SHA-1 and add it in Firebase Console:
- Go to **Project Settings** → **Your apps** → **Android app**
- Scroll down to **SHA certificate fingerprints**
- Click **"Add fingerprint"** and paste the SHA-1

### 2.3 Download google-services.json

1. In Firebase Console, download the `google-services.json` file
2. Place it in: `android/app/google-services.json`

### 2.4 Update Android Configuration

The following files should already be configured, but verify:

**android/build.gradle.kts**:
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

**android/app/build.gradle.kts**:
```kotlin
plugins {
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
}
```

## Step 3: Enable Authentication Methods

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable **Email/Password**:
   - Click **"Email/Password"**
   - Toggle **"Enable"**
   - Click **"Save"**

3. Enable **Google**:
   - Click **"Google"**
   - Toggle **"Enable"**
   - Enter **Project support email** (your email)
   - Click **"Save"**

## Step 4: Configure Google Sign-In

### 4.1 Get OAuth 2.0 Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Navigate to **APIs & Services** → **Credentials**
4. You should see an automatically created **OAuth 2.0 Client ID** (type: Web application)
5. Copy the **Client ID** (ends with `.apps.googleusercontent.com`)

### 4.2 Update Android OAuth Client

Firebase should have auto-created an Android OAuth client. Verify:
- Go to **Credentials** in Google Cloud Console
- Find the **Android** OAuth client
- Ensure the package name matches: `com.example.ewasteapp`
- Ensure the SHA-1 certificate is added

## Step 5: iOS Configuration (Optional)

If building for iOS:

1. In Firebase Console, add an iOS app:
   - **iOS bundle ID**: `com.example.ewasteapp` (or your iOS bundle ID)
2. Download `GoogleService-Info.plist`
3. Place it in: `ios/Runner/GoogleService-Info.plist`
4. In Xcode, add the file to the Runner target
5. Update `ios/Runner/Info.plist` with the **REVERSED_CLIENT_ID** from GoogleService-Info.plist:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID_HERE</string>
        </array>
    </dict>
</array>
```

## Step 6: Install Dependencies

Run the following command in PowerShell from the project root:

```powershell
flutter pub get
```

## Step 7: Test the App

1. Build and run your app:
   ```powershell
   flutter run
   ```

2. Tap **"Get Started"** on the intro screen
3. Try **"Continue with Google"** to sign in
4. Or enter email/password and create an account

## Troubleshooting

### Google Sign-In not working
- Verify SHA-1 certificate is added in Firebase Console
- Ensure `google-services.json` is in the correct location
- Check that package name matches everywhere
- Try running `flutter clean` then `flutter pub get`

### Firebase initialization fails
- Ensure `google-services.json` exists in `android/app/`
- Check that Firebase plugins are added to `android/app/build.gradle.kts`
- Look at the debug console for specific error messages

### Email/Password sign-in fails
- Ensure Email/Password provider is enabled in Firebase Console
- Check that the email format is valid
- Password must be at least 6 characters

## Testing Users

For testing, you can create test users in Firebase Console:
- Go to **Authentication** → **Users**
- Click **"Add user"**
- Enter email and password

## Next Steps

- Add email verification
- Implement password reset
- Add more OAuth providers (Apple, Facebook, etc.)
- Set up Firestore for storing user profiles
- Configure Firebase Security Rules

## Support

For more information, see:
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Google Sign-In Plugin](https://pub.dev/packages/google_sign_in)
