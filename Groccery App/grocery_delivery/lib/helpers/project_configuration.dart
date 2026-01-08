import 'package:delivery/config/environment.dart';
import 'package:delivery/config/secrets.dart';

class ProjectConfiguration {
  static final List<String> svgImages = [
    'images/empty_cart.svg',
    'images/error.svg',
    'images/nothing_found.svg',
    'images/reminder.svg',
    'images/success.svg',
    'images/success.svg',
    'images/map.svg'
  ];

  static final List<String> pngImages = [
    'images/logo.png',
    'images/upload_image.png',
    'images/profile.png'
  ];

  static final String logo = 'images/logo.png';

  // Use secrets for sensitive configuration
  static String get notificationsApi => Secrets.notificationsApi;

  // Application settings from environment
  static String get appName => Environment.appName;
  static String get appVersion => Environment.appVersion;
  static int get defaultPageSize => Environment.defaultPageSize;
}
