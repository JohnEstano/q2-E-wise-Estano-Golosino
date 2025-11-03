# Firebase Web Configuration Guide

## The Issue

You're seeing this error:
```
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()
```

This happens because **Firebase requires different configuration for web vs mobile**. On web, you need to provide Firebase configuration options explicitly.

## Quick Fix - Get Your App Running

### Step 1: Create Firebase Project (if not done)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select existing project
3. Name it "ewise" or similar

### Step 2: Register Web App

1. In Firebase Console, click the **Web icon** (`</>`) to add a web app
2. Register app with nickname: "E-Wise Web"
3. **Copy the Firebase configuration code** that appears (important!)

It will look like this:
```javascript
const firebaseConfig = {
  apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef123456"
};
```

### Step 3: Add Configuration to Your App

Open `lib/main.dart` and update the Firebase initialization:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with your web config
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "YOUR_API_KEY_HERE",              // <- Paste from Firebase Console
        authDomain: "your-project.firebaseapp.com",  // <- Paste from Firebase Console
        projectId: "your-project-id",              // <- Paste from Firebase Console
        storageBucket: "your-project.appspot.com", // <- Paste from Firebase Console
        messagingSenderId: "123456789012",         // <- Paste from Firebase Console
        appId: "1:123456789012:web:abcdef",       // <- Paste from Firebase Console
      ),
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Rest of your code...
  await dotenv.load(fileName: ".env");
  runApp(const EcoWasteIntroApp());
}
```

### Step 4: Enable Authentication

1. In Firebase Console → **Authentication** → **Sign-in method**
2. Enable **Email/Password**
3. Enable **Google** (enter your support email)

### Step 5: Hot Restart

In the terminal where Flutter is running, press:
- **`R`** (capital R) for hot restart
- Or stop and run `flutter run` again

## Example with Real Values

Here's what it looks like with example values:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "AIzaSyBq8X9kF2v3pL7mN4oT6rY8hU9jK1sD3fG",
    authDomain: "ewise-app.firebaseapp.com",
    projectId: "ewise-app",
    storageBucket: "ewise-app.appspot.com",
    messagingSenderId: "987654321098",
    appId: "1:987654321098:web:abc123def456",
  ),
);
```

## Testing the Fix

1. Save the changes
2. Hot restart the app (**R** in terminal)
3. Click "Get Started"
4. Try signing in with email/password
5. The Firebase error should be gone! ✅

## Alternative: Test Without Firebase First

If you want to test the UI without Firebase:

1. Comment out Firebase initialization in `main.dart`
2. Skip the authentication screens for now
3. Add Firebase configuration later

To do this, temporarily update `main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Add Firebase configuration (see FIREBASE_WEB_SETUP.md)
  // Firebase initialization commented out for now
  
  await dotenv.load(fileName: ".env");
  runApp(const EcoWasteIntroApp());
}
```

And in the intro screen, make the "Get Started" button go directly to HomePage:

```dart
FilledButton(
  onPressed: () {
    // Skip auth for now, go straight to home
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  },
  child: const Text('Get Started'),
),
```

## Important Notes

- ⚠️ **Never commit your Firebase API keys to public repositories**
- For production, use environment variables or secure storage
- The API key shown above is for **web client** and is meant to be public
- Use Firebase Security Rules to protect your data

## Platform-Specific Configuration

### Web (Current Issue)
- Requires `FirebaseOptions` in `Firebase.initializeApp()`
- Get config from Firebase Console → Project Settings → Your apps → Web app

### Android
- Uses `google-services.json` file (already set up in code)
- Place in `android/app/google-services.json`

### iOS
- Uses `GoogleService-Info.plist` file
- Place in `ios/Runner/GoogleService-Info.plist`

## Next Steps

1. ✅ Get Firebase web config from console
2. ✅ Add to `lib/main.dart`
3. ✅ Hot restart app
4. ✅ Test authentication
5. ✅ Celebrate! 🎉

## Troubleshooting

### Still seeing the error?
- Make sure you copied ALL fields from Firebase Console
- Check that you hot restarted (press `R`) or restarted the app
- Verify your Firebase project has Authentication enabled

### "Invalid API key"?
- Double-check you copied the API key correctly
- Make sure there are no extra spaces or quotes

### Google Sign-In not working?
- For web, Google Sign-In requires additional setup
- You may need to configure OAuth consent screen in Google Cloud Console

## Support

For more details:
- [Firebase Flutter Setup](https://firebase.flutter.dev/docs/overview)
- [FlutterFire Web](https://firebase.flutter.dev/docs/installation/web)
- Main setup guide: `FIREBASE_SETUP.md`
