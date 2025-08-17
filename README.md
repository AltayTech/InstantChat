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

## Firebase Console setup (what to configure in Firebase)
Follow these steps in the Firebase Console for the services this app uses: Authentication, Firestore, Storage, and Cloud Messaging (FCM).

### 1) Create project and add apps
- Create a new Firebase project (or use an existing one).

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


Notes on indexes:
- Current queries do not require composite indexes (simple `where` and `orderBy createdAt`). If you later add compound queries, create indexes when Firestore prompts you.

### 4) Enable Cloud Storage
- Go to Firebase Console > Build > Storage and create a Storage bucket (choose your preferred location).
- Start in test mode for local development, then tighten rules for production.
- Suggested minimal Storage rules for user uploads (adjust for production):


### 5) Configure Cloud Messaging (FCM)
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
run this again(very important):
- Configure: `flutterfire configure --project <your-firebase-project-id>`

## Push notifications end-to-end (what's implemented, step by step)

1) Requirements
- Firebase project on Blaze plan (needed to deploy Cloud Functions Gen 2).
- Firestore enabled; Authentication (Email/Password) enabled.

2) iOS console and Xcode
- In Apple Developer, create an APNs Auth Key (.p8) and note Team ID & Key ID.
- In Firebase Console → Project Settings → Cloud Messaging, upload the APNs key.
- In Xcode (Runner target): enable Push Notifications and Background Modes → Remote notifications.
3) Deploy the function
```bash
cd functions
npm --prefix functions install
cd..
npm --prefix functions run build
firebase deploy --only functions:sendChatMessageNotification --project <PROJECT_ID>
```
- Logs (to verify triggers and errors):
```bash
firebase functions:log --only sendChatMessageNotification
```

4) App wiring (Flutter)( clarification step)
- `lib/main.dart`: initialize Firebase with `DefaultFirebaseOptions.currentPlatform` and register `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)`.
- `lib/core/notifications/notification_service.dart`:
  - Requests notification permission and sets foreground presentation (iOS banners off; we show our own local notifications).
  - Creates Android channel `chat_messages` and shows local notifications in foreground/background.
  - Suppresses foreground notifications when viewing the same chat (via `activeChatIdNotifier`).
  - Handles taps to navigate to `/chat` using `data.chatId`.
- `lib/core/navigation/app_navigator.dart`: adds `activeChatIdNotifier` and helpers to track the currently open chat.
- `lib/features/chat/presentation/pages/chat_page.dart`: sets/clears active chat on open/dispose.
- `lib/features/auth/data/auth_repository.dart`: saves `fcmToken` on register/login and updates it on token refresh.
- `lib/features/chat/data/chat_repository.dart`: ensures `chats/{chatId}` exists before writing a message and infers `participants` from the `chatId` (`uidA_uidB`).

5) Backend sender (Cloud Function)( clarification step)
- Trigger: `chats/{chatId}/messages/{messageId}` onCreate.
- Logic: fetches chat participants from `chats/{chatId}.participants`; if missing, infers from `chatId` split by `_`. Filters out the sender, fetches recipient `users/{uid}.fcmToken`, and calls FCM `sendEachForMulticast` with:
  - `notification.title/body` and `data.chatId` for navigation.
  - Android: `channelId: chat_messages`, `priority: high`.
  - APNs: default sound and alert.




### 5) Verify initialization
- Run the app and check logs for successful Firebase initialization and FCM token retrieval.
- Create a test user via the app; verify `users/{uid}` doc appears in Firestore with `fcmToken`.

## Notes
- Firestore security rules should restrict chat access to participants.
- For production, handle FCM background click navigation via native intent handlers and `onDidReceiveNotificationResponse` in `flutter_local_notifications`.

