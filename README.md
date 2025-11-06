# E-Wise E-waste Management App

An intelligent mobile application for electronic waste management and recycling, helping users identify, catalog, and responsibly dispose of electronic devices while building a community around sustainable e-waste practices.

This project was developed as part of the Mobile Development course requirements.

## About

E-Wise is a comprehensive e-waste management solution that uses AI-powered image recognition to identify electronic devices, estimate their recyclable material composition, and connect users with proper disposal channels. The app gamifies sustainable behavior through an eco-score system and fosters community engagement through a social feed where users can share their e-waste contributions.

Users can scan electronic devices using their phone camera, and the app automatically analyzes the device to provide detailed information including brand, model, estimated weight, material breakdown, and disposal recommendations. All scanned items are stored in a personal inventory that can be managed, shared with the community, or marked for pickup by recycling services.

The leaderboard system encourages sustainable practices by ranking users based on their eco-score, calculated from the number of devices scanned, posts shared, and total weight of e-waste processed. This creates a competitive yet collaborative environment where environmental responsibility is rewarded and celebrated.

**Programmer & UI/UX Design:** JohnEstano ❤️   
**Team Member / Presentor :** Nash Golosino

## Tech Stack

**Framework & Language:**
- Flutter (Dart)
- Material Design 3

**Backend & Database:**
- Firebase Authentication (Google Sign-In, Email/Password)
- Cloud Firestore (NoSQL Database)
- Firebase Storage (Image hosting)

**AI & Image Processing:**
- OpenAI Vision API (GPT-4 Vision)
- Camera & Image Picker
- Flutter Image Processing

**Key Packages:**
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- `google_sign_in`
- `camera`, `image_picker`
- `http` (OpenAI API integration)
- `flutter_dotenv` (Environment variables)
- `geolocator` (Location services)
- `qr_flutter` (QR code generation)
- `intl` (Date formatting)

**Development Tools:**
- Android Studio / VS Code
- Firebase Console
- Git & GitHub

## Features

- **AI-Powered Device Recognition** - Scan any electronic device and get instant analysis
- **Smart Inventory Management** - Track all your e-waste in one place
- **Community Feed** - Share your sustainable practices and discover others
- **Eco Score System** - Earn points and climb the leaderboard
- **Material Analysis** - View estimated recyclable material composition
- **Disposal Guidance** - Get recommendations for proper recycling
- **Location Services** - Find nearby recycling centers and service points
- **QR Code Generation** - Generate unique codes for each device
- **Real-time Updates** - Live feeds, likes, and comments
- **User Profiles** - Track your environmental impact over time

## Screenshots

![Screenshot 1](public/images/1.jpg)
![Screenshot 2](public/images/screenshots/2.jpg)
![Screenshot 3](public/images/screenshots/3.jpg)
![Screenshot 4](public/images/screenshots/4.jpg)
![Screenshot 5](public/images/screenshots/5.jpg)
![Screenshot 6](public/images/screenshots/6.jpg)
![Screenshot 7](public/images/screenshots/7.jpg)

## Setup Instructions

1. Clone the repository
2. Install Flutter SDK and dependencies
3. Copy `.env.example` to `.env` and add your OpenAI API key
4. Add your `google-services.json` to `android/app/` (see `SETUP_SENSITIVE_FILES.md`)
5. Run `flutter pub get`
6. Deploy Firestore rules and indexes:
   ```bash
   firebase deploy --only firestore:rules
   firebase deploy --only firestore:indexes
   ```
7. Run the app: `flutter run`

For detailed setup instructions for sensitive configuration files, see `SETUP_SENSITIVE_FILES.md`.

## Database Structure

**Collections:**
- `users/{userId}` - User profiles and settings
- `devices/{deviceId}` - All scanned devices (community-wide)
- `posts/{postId}` - Community posts with device shares
- `comments/{commentId}` - Comments on posts

**Security:**
- Firestore security rules implemented
- User authentication required for all operations
- Owner-based access control for personal data

## License

This project is developed for educational purposes as part of a Mobile Development course.

---
