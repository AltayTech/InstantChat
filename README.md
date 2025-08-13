# Real-Time Chat Application (Flutter)

A production-ready, MVVM + Feature-based Flutter chat app using Bloc, Firebase (Auth, Firestore, FCM), Hive offline cache, DI with get_it, and Material 3.

## Features
- User Authentication: Email register/login, onboarding, logout
- User List: Firestore users, status, avatar placeholder
- Real-Time Messaging: Two-way text + emoji, timestamps
- Message History: Loads previous messages and caches locally via Hive
- Notifications: FCM + local notifications; tapping opens chat
- State Management: Bloc for auth, users, chat
- UI/UX: Material 3, dark/light themes, responsive

## Architecture
- MVVM + Feature-based modules: `features/auth`, `features/users`, `features/chat`
- Domain-driven separation: `data` (repositories), `domain` (use-cases), `presentation` (bloc + pages)
- DI via `get_it` in `lib/core/di/injector.dart`
- Offline cache in `lib/core/local/hive_manager.dart`
- Notifications in `lib/core/notifications/notification_service.dart`

```
lib/
  core/
    di/
      injector.dart
    local/
      hive_manager.dart
    notifications/
      notification_service.dart
  features/
    auth/
      data/ | domain/ | presentation/
    users/
      data/ | domain/ | presentation/
    chat/
      data/ | domain/ | presentation/
  app.dart
  main.dart
```

## Packages
- firebase_core, firebase_auth, cloud_firestore, firebase_messaging: Backend
- flutter_bloc, bloc, equatable: State management
- hive, hive_flutter, path_provider: Offline cache
- flutter_local_notifications: Local notifications
- get_it: Dependency injection
- cached_network_image, intl, emoji_picker_flutter, google_fonts: UX utils

## Setup
1) Prerequisites
- Flutter SDK 3.22+
- Android Studio and/or Xcode

2) Add Firebase to the app (one-time)
- Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
- Login: `firebase login`
- Configure: `flutterfire configure --project <your-firebase-project-id>`
  - Select platforms you will run on (Android, iOS, optionally Web, macOS, Windows)
  - This generates `lib/firebase_options.dart` (already present) and links your app(s)

3) Initialize Firebase in code
- This app already calls `Firebase.initializeApp()` in `lib/app.dart`. If you used FlutterFire CLI, prefer initializing with generated options:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

4) Run
```bash
flutter pub get
flutter run
```

## Firebase Console setup (what to configure in Firebase)
Follow these steps in the Firebase Console for the services this app uses: Authentication, Firestore, and Cloud Messaging (FCM).

### 1) Create project and add apps
- Create a new Firebase project (or use an existing one).
- Add Android app:
  - Package name: use your app id (current default is `com.example.rezatestoctapullapp`).
  - Download `google-services.json` and place it at `android/app/google-services.json` (already present in this repo as a placeholder – replace with yours).
- Add iOS app (if building for iOS):
  - Bundle ID: your Runner bundle id from Xcode.
  - Download `GoogleService-Info.plist` and add it to the iOS Runner target in Xcode.
- Optional: Add Web app if you plan to run on web; FlutterFire CLI will embed the web config into `firebase_options.dart`.

### 2) Enable Authentication
- Go to Firebase Console > Build > Authentication > Sign-in method.
- Enable Email/Password provider (the app uses email registration/login).
  - No OAuth keys or SHA certs are needed for email/password.

### 3) Create Firestore database
- Go to Build > Firestore Database and create a database.
- Choose your preferred location. Start in test mode for local development, then tighten rules for production.
- Collections this app expects:
  - `users/{uid}` docs with fields: `uid`, `email`, `name`, `photoUrl`, `isOnline`, `fcmToken`, `createdAt`, `updatedAt`.
  - `chats/{chatId}/messages/{messageId}` docs with fields: your message payload plus `createdAt`, `isDeleted`.

Recommended minimal security rules (adjust for production):
```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null;
    }

    match /users/{userId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && request.auth.uid == userId;
      allow update: if isSignedIn() && request.auth.uid == userId;
    }

    match /chats/{chatId}/messages/{messageId} {
      allow read, create: if isSignedIn();
      allow update, delete: if false; // prevent edits/deletes for now
    }
  }
}
```

Notes on indexes:
- Current queries do not require composite indexes (simple `where` and `orderBy createdAt`). If you later add compound queries, create indexes when Firestore prompts you.

### 4) Configure Cloud Messaging (FCM)
- FCM is enabled by default for Firebase projects. No extra enable/disable switch is needed.
- Get your device tokens by running the app; the app saves the token to `users/{uid}.fcmToken` on registration.
- You can send test messages from Firebase Console > Engage > Messaging.

iOS-specific (required if you ship to iOS):
- In Apple Developer, create an APNs Auth Key (.p8) and note your Team ID and Key ID.
- In Firebase Console > Project Settings > Cloud Messaging, upload the APNs Auth Key and fill Team ID and Key ID.
- In Xcode, enable Push Notifications and Background Modes > Remote notifications for the Runner target.

Android-specific:
- Ensure `android/app/google-services.json` matches your Firebase Android app.
- `POST_NOTIFICATIONS` runtime permission is requested in-app for Android 13+ (already handled by the app).

Optional (server sending):
- If you plan to send notifications from your backend, create a service account and use the FCM HTTP v1 API with your project's credentials.

Example HTTP v1 message (data payload opens a chat):
```json
{
  "message": {
    "token": "<device_fcm_token>",
    "notification": { "title": "New message", "body": "Tap to view" },
    "data": { "chatId": "<chat-id>" }
  }
}
```

### 5) Verify initialization
- Run the app and check logs for successful Firebase initialization and FCM token retrieval.
- Create a test user via the app; verify `users/{uid}` doc appears in Firestore with `fcmToken`.

### 6) Production hardening checklist
- Tighten Firestore rules to restrict chat access to conversation participants.
- Set up Analytics, Crashlytics (optional) and monitoring.
- Rotate API keys if you committed sample keys; rely on `firebase_options.dart` generated by FlutterFire.

## Notes
- Firestore security rules should restrict chat access to participants.
- For production, handle FCM background click navigation via native intent handlers and `onDidReceiveNotificationResponse` in `flutter_local_notifications`.
- Optional: Implement image/file messages and soft delete via `isDeleted` flag.

# rezatestoctapullapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
