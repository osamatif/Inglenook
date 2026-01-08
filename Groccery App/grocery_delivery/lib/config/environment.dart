/// Environment configuration for the delivery application
/// This file contains non-sensitive configuration that can be committed to git
/// For sensitive data, use secrets.dart which is gitignored

class Environment {
  static const String appName = 'Inglenook Delivery';
  static const String appVersion = '1.5.0';

  // Firebase configuration - public values only
  static const String firebaseProjectId = 'inglenook-e5595';

  // API endpoints (should be backend URLs)
  static const String apiBaseUrl = 'https://your-backend-url.com/api/v1';

  // Feature flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableDebugLogging = false;

  // Pagination settings
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Timeout settings (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  // Storage paths
  static const String profileImagesPath = 'delivery_profiles';

  // Validation rules
  static const int minPasswordLength = 8;
  static const int maxImageSizeMB = 5;

  // Delivery settings
  static const int maxActiveDeliveries = 5;
  static const double deliveryRadiusKm = 50.0;

  // Get environment-specific configuration
  static bool get isProduction => const String.fromEnvironment('ENV') == 'production';
  static bool get isDevelopment => const String.fromEnvironment('ENV') == 'development';
  static bool get isStaging => const String.fromEnvironment('ENV') == 'staging';
}
