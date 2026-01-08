import 'package:grocery_admin/config/environment.dart';
import 'package:grocery_admin/config/secrets.dart';

class ProjectConfiguration {
  static final List<String> svgImages = [
    'images/empty_cart.svg',
    'images/error.svg',
    'images/nothing_found.svg',
    'images/reminder.svg',
    'images/success.svg',
    'images/success.svg',
    'images/category.svg',
    'images/no_delivery_found.svg',
    'images/map.svg'
  ];

  static final List<String> pngImages = [
    'images/logo.png',
    'images/upload_image.png',
    'images/stripe.png',
    'images/profile.png'
  ];

  static final String logo = 'images/logo.png';

  // Use secrets configuration for sensitive data
  static String get notificationsApi => Secrets.notificationsApi;

  // Application settings from environment
  static String get appName => Environment.appName;
  static String get appVersion => Environment.appVersion;
  static int get defaultPageSize => Environment.defaultPageSize;
}
