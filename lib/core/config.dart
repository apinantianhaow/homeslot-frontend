/// Build-time configuration passed with `--dart-define`.
///
/// ```
/// flutter run --dart-define=SERVER_URL=https://homeslot.example.com/ \
///   --dart-define=GOOGLE_CLIENT_ID=... \
///   --dart-define=GOOGLE_SERVER_CLIENT_ID=...
/// ```
///
/// Without SERVER_URL the app uses `assets/config.json` (`apiUrl`) or
/// `http://localhost:8080/` (`10.0.2.2` on the Android emulator).
abstract final class AppConfig {
  /// Google sign-in is shown only when the OAuth client ids are provided.
  static const googleEnabled = bool.hasEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// Scheme and host of invite deep links, e.g. `homeslot://app/join?code=123456`.
  static const deepLinkScheme = 'homeslot';

  static String inviteLink(String code) =>
      '$deepLinkScheme://app/join?code=$code';
}
