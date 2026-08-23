# OneSignal Integration

Rexo Marketplace uses the **OneSignal Flutter SDK** (`onesignal_flutter`) for
cross-platform push notifications and in-app messaging, alongside the existing
Firebase Cloud Messaging (FCM) stack.

- **App ID:** `cf5dccaf-cd4e-4fbc-ae21-009a5d2a1d7b`
- **SDK:** `onesignal_flutter: ^5.5.1`
- **Service:** `lib/services/onesignal_service.dart`

The App ID is a **public client identifier** (not a secret). A working default
is baked into `OneSignalService._appId`, and it can be overridden at build time:

```
flutter build apk --release --dart-define=ONESIGNAL_APP_ID=<your-app-id>
```

CI passes it via the optional `ONESIGNAL_APP_ID` GitHub secret in
`.github/workflows/flutter-build.yml`. If the secret is unset, the code default
is used so the build still works.

## What the app already does (in Dart)

- Initializes OneSignal after the first frame (`main.dart`) — guarded so it can
  never crash startup, and independent of Firebase.
- Requests notification permission on init.
- Associates the OneSignal subscription with the Supabase user id via
  `OneSignal.login(userId)` on sign-in / session restore, and `OneSignal.logout()`
  on sign-out (`auth_provider.dart`). This lets the backend target users by
  **External ID** (their Supabase user id).

## Android — dashboard config required (no code changes needed)

The OneSignal Flutter 5.x SDK auto-merges its Android manifest and Gradle
dependencies, so no manual `AndroidManifest.xml` / `build.gradle` edits are
required. `minSdkVersion` is already 21 and `compileSdk` is 34, both of which
satisfy the SDK.

To actually deliver pushes on Android, in the **OneSignal dashboard**:

1. Create/select the app with App ID `cf5dccaf-cd4e-4fbc-ae21-009a5d2a1d7b`.
2. Under **Settings → Push → Google Android (FCM)**, upload the Firebase
   **Service Account JSON** (FCM v1) for the `rexowallet2026` Firebase project.

> Note: OneSignal uses its own FCM credentials configured in the dashboard — it
> does **not** read the app's `google-services.json`. FCM and OneSignal can
> coexist; OneSignal registers its own messaging service via manifest merge.

## iOS — pending native project

The `ios/` folder in this repo currently contains only a placeholder
(`.gitkeep`); there is no Xcode project yet, and CI builds only the Android APK.
The Dart integration above is already cross-platform, so **once an iOS Runner
project is generated** (`flutter create . --platforms=ios`), complete these
native steps for OneSignal on iOS:

1. In the OneSignal dashboard → **Settings → Push → Apple iOS (APNs)**, upload
   an APNs Auth Key (`.p8`) with your Team ID + Key ID.
2. In Xcode, add capabilities to the **Runner** target:
   - **Push Notifications**
   - **Background Modes → Remote notifications**
3. Add a **Notification Service Extension** target named
   `OneSignalNotificationServiceExtension` (required for rich media / confirmed
   delivery), and in its `Podfile` block add:
   ```ruby
   target 'OneSignalNotificationServiceExtension' do
     use_frameworks!
     pod 'OneSignalXCFramework', '>= 5.0.0', '< 6.0'
   end
   ```
4. Set the deployment target to iOS 12+ and run `pod install`.

Refer to the official guide for the exact extension source:
https://documentation.onesignal.com/docs/en/flutter-sdk-setup

## Testing (requires a real device)

Push delivery **cannot be verified in CI or on the iOS simulator**. To test:

1. Install the APK on a physical Android device (with Google Play Services).
2. Log in — this triggers `OneSignal.login(<supabase-user-id>)`.
3. Accept the notification permission prompt.
4. In the OneSignal dashboard, send a test push (target by External ID = the
   Supabase user id, or by segment).
