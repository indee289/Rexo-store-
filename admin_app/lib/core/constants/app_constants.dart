import 'dart:convert';

class AppConstants {
  AppConstants._();

  /// App name
  static const String appName = 'Rexo Admin';

  /// Supabase configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Cloudflare R2 configuration
  static const String r2AccessKeyId = String.fromEnvironment(
    'R2_ACCESS_KEY_ID',
    defaultValue: '',
  );

  static const String r2SecretAccessKey = String.fromEnvironment(
    'R2_SECRET_ACCESS_KEY',
    defaultValue: '',
  );

  static const String r2AccountId = String.fromEnvironment(
    'R2_ACCOUNT_ID',
    defaultValue: '',
  );

  static const String r2BucketName = String.fromEnvironment(
    'R2_BUCKET_NAME',
    defaultValue: '',
  );

  /// Firebase Cloud Messaging configuration (server-side credentials)
  static const String fcmProjectId = String.fromEnvironment(
    'FCM_PROJECT_ID',
    defaultValue: '',
  );

  static const String fcmClientEmail = String.fromEnvironment(
    'FCM_CLIENT_EMAIL',
    defaultValue: '',
  );

  /// FCM private key is passed as base64-encoded via dart-define to avoid
  /// issues with newlines in PEM keys breaking the command line.
  static const String _fcmPrivateKeyEncoded = String.fromEnvironment(
    'FCM_PRIVATE_KEY',
    defaultValue: '',
  );

  /// Decoded FCM private key (base64 decoded at runtime).
  static String get fcmPrivateKey {
    if (_fcmPrivateKeyEncoded.isEmpty) return '';
    try {
      return utf8.decode(base64Decode(_fcmPrivateKeyEncoded));
    } catch (_) {
      // If decoding fails, return as-is (may already be plaintext in dev)
      return _fcmPrivateKeyEncoded;
    }
  }

  /// Gemini AI API Key
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Admin email
  static const String adminEmail = 'rexoagency.in@gmail.com';

  /// Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  /// Border radius values
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  /// Padding values
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
}
