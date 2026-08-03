# ChoSV Flutter

## Runtime configuration

Override the development API endpoint with
`--dart-define=API_BASE_URL=https://example.com/api`. The current HTTP server is
kept only as the development fallback.

The current fallback API is `http://161.118.247.84:8000/api`.

QR donation tracking links use `APP_PUBLIC_URL`. Set it to the deployed Flutter
web origin, for example `--dart-define=APP_PUBLIC_URL=https://app.chosv.vn`.

Push notification runtime registration is implemented for Android and iOS. Add
the Firebase client files (`android/app/google-services.json` and
`ios/Runner/GoogleService-Info.plist`) before running it; without those files the
app keeps FCM disabled and does not register a placeholder token.

The Android Firebase app package must match `com.example.project_chosv`, and
the iOS bundle identifier must match `com.example.project4Chosv`, unless those
application identifiers are changed before downloading the Firebase files.

Chat image sending is disabled in the UI because the backend does not yet link
uploaded media to a chat message.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
