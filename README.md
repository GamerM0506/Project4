# ChoSV Flutter

## Runtime configuration

Override the development API endpoint with
`--dart-define=API_BASE_URL=https://example.com/api`. The current HTTP server is
kept only as the development fallback.

Push notification runtime registration is not enabled yet. The repository and
device-token API contract are ready for a real FCM token, but this project has
no Firebase configuration files or credentials. Do not register a placeholder
token.

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
