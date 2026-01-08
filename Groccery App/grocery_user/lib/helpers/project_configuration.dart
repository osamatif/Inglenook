import 'package:grocery/config/environment.dart';
import 'package:grocery/config/secrets.dart';

class ProjectConfiguration {
  // Logo path
  static final String logo = "images/logo.png";

  // Use secrets for sensitive configuration
  static String get notificationsApi => Secrets.notificationsApi;
  static String get stripePaymentApi => Secrets.paymentApiUrl;
  static String get stripePublishableKey => Secrets.stripePublishableKey;
  static String get stripeMerchantId => Secrets.stripeMerchantId;

  static final List<String> pngImages = [
    "images/logo.png",
    "images/settings/profile.png",
    "images/categories/vegetables.png",
  ];

  static final List<String> svgImages = [
    "images/sign_in/facebook.svg",
    "images/sign_in/google.svg",
    "images/sign_in/twitter.svg",
    "images/state_images/empty_cart.svg",
    "images/state_images/error.svg",
    "images/state_images/nothing_found.svg",
    "images/reminder.svg",
    "images/success.svg",
    "images/on_boarding/1.svg",
    "images/on_boarding/2.svg",
    "images/on_boarding/3.svg",
  ];
}
