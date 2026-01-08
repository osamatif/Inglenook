/// Environment configuration for the user application
/// This file contains non-sensitive configuration that can be committed to git
/// For sensitive data, use secrets.dart which is gitignored

class Environment {
  static const String appName = 'Inglenook';
  static const String appVersion = '1.5.0';

  // Firebase configuration - public values only
  static const String firebaseProjectId = 'inglenook-e5595';

  // API endpoints (should be backend URLs)
  static const String apiBaseUrl = 'https://your-backend-url.com/api/v1';

  // Feature flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableDebugLogging = false;
  static const bool enableFacebookAuth = true;
  static const bool enableGoogleAuth = true;
  static const bool enableAppleAuth = false;

  // Pagination settings
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Timeout settings (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  // Storage paths
  static const String profileImagesPath = 'user_profiles';
  static const String productImagesPath = 'products';

  // Validation rules
  static const int minPasswordLength = 8;
  static const int maxImageSizeMB = 5;

  // Cart settings
  static const int maxCartItems = 50;
  static const double minOrderAmount = 10.0;

  // Get environment-specific configuration
  static bool get isProduction => const String.fromEnvironment('ENV') == 'production';
  static bool get isDevelopment => const String.fromEnvironment('ENV') == 'development';
  static bool get isStaging => const String.fromEnvironment('ENV') == 'staging';
}
