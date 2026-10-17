class AppConstants {
  AppConstants._();

  /// App name
  static const String appName = 'Campster';

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

  /// Public base URL for the R2 bucket (e.g. https://pub-xxxx.r2.dev or a
  /// custom domain). The S3 API endpoint returned by uploads is NOT publicly
  /// viewable without auth, so uploaded images (covers, products, avatars) do
  /// not render. When this is set, [R2StorageService] builds the object's
  /// public URL from it instead of the private S3 endpoint.
  static const String r2PublicUrl = String.fromEnvironment(
    'R2_PUBLIC_URL',
    defaultValue: '',
  );

  /// Validates R2 storage credentials at startup.
  /// In debug mode, throws AssertionError if credentials are missing.
  /// In release mode, logs a warning instead.
  static void validateR2Config() {
    final missing = r2AccessKeyId.isEmpty ||
        r2SecretAccessKey.isEmpty ||
        r2AccountId.isEmpty ||
        r2BucketName.isEmpty;
    if (missing) {
      assert(
        false,
        'R2 credentials not provided via --dart-define. Image uploads will fail.',
      );
      // In release mode, assert is a no-op — log warning instead.
      // ignore: avoid_print
      print('[AppConstants] WARNING: R2 credentials not provided. Image uploads will fail.');
    }
  }

  /// Firebase Cloud Messaging configuration (server-side credentials)
  static const String fcmProjectId = String.fromEnvironment(
    'FCM_PROJECT_ID',
    defaultValue: '',
  );

  static const String fcmClientEmail = String.fromEnvironment(
    'FCM_CLIENT_EMAIL',
    defaultValue: '',
  );

  // FCM private key must only be used server-side (Supabase Edge Function).
  // It has been removed from the client bundle for security reasons.

  /// Support contact email (used in Help & Support screen).
  /// NOTE: Admin access is determined from the database `users.role` field,
  /// NOT from this email. This is purely a contact address.
  static const String supportEmail = 'rexoagency.in@gmail.com';

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
