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
- Android Studio/Xcode

2) Firebase project
- Create a Firebase project.
- Add apps for Android and iOS.

3) Android config
- Download `google-services.json` and place at `android/app/google-services.json`.
- In `android/build.gradle` add Google services classpath (if not present):
  ```gradle
  buildscript { dependencies { classpath 'com.google.gms:google-services:4.4.2' } }
  ```
- In `android/app/build.gradle` apply plugin:
  ```gradle
  plugins { id 'com.google.gms.google-services' }
  ```

4) iOS config
- Download `GoogleService-Info.plist` and add to Xcode under Runner.
- Enable Push Notifications and Background Modes (Remote notifications).

5) Initialize Firebase
- Ensure `Firebase.initializeApp()` is called. This app calls it in `AppRoot`.

6) Run
```bash
flutter pub get
flutter run
```

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
