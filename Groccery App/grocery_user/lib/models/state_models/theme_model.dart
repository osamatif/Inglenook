import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModel with ChangeNotifier {
  late ThemeData theme;

  ThemeModel({required ThemeData theme}) {
    backgroundColor = theme.backgroundColor;

    if (theme.brightness == Brightness.dark) {
      secondBackgroundColor = Color(0xFF1F1F1F); // Slightly lighter dark
      textColor = Color(0xFFE3E3E3); // Softer white
      secondTextColor = Color(0xFF8C9196); // Shopify gray
    } else {
      secondBackgroundColor = Colors.white;
      textColor = Color(0xFF202223); // Shopify text dark
      secondTextColor = Color(0xFF6D7175); // Shopify secondary text
    }

    this.theme = theme;
  }

  ///Save theme name in local storage with shared prefs
  Future<void> setToStorage(bool isDark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
  }

  late Color secondBackgroundColor;
  late Color backgroundColor;
  late Color textColor;
  late Color secondTextColor;

  // Shopify-inspired color palette
  final Color shadowColor = Colors.black.withOpacity(0.08);
  final Color priceColor = Color(0xFF008060); // Shopify green for prices
  final Color accentColor = Color(0xFF008060); // Shopify primary green
  final Color borderColor = Color(0xFFE1E3E5); // Shopify border gray
  final Color successColor = Color(0xFF008060); // Shopify success green

  ///Update theme to dark or light
  Future<void> updateTheme() async {
    bool isDark = theme.brightness == Brightness.dark;
    if (isDark) {
      theme = light;
    } else {
      theme = dark;
    }

    backgroundColor = theme.backgroundColor;

    if (theme.brightness == Brightness.dark) {
      secondBackgroundColor = Color(0xFF1F1F1F); // Slightly lighter dark
      textColor = Color(0xFFE3E3E3); // Softer white
      secondTextColor = Color(0xFF8C9196); // Shopify gray
    } else {
      secondBackgroundColor = Colors.white;
      textColor = Color(0xFF202223); // Shopify text dark
      secondTextColor = Color(0xFF6D7175); // Shopify secondary text
    }

    await setToStorage(!isDark);
    notifyListeners();
  }

  static MaterialColor _primarySwatch(int color) {
    return MaterialColor(color, {
      50: Color.fromRGBO(0, 128, 96, .1),
      100: Color.fromRGBO(0, 128, 96, .2),
      200: Color.fromRGBO(0, 128, 96, .3),
      300: Color.fromRGBO(0, 128, 96, .4),
      400: Color.fromRGBO(0, 128, 96, .5),
      500: Color.fromRGBO(0, 128, 96, .6),
      600: Color.fromRGBO(0, 128, 96, .7),
      700: Color.fromRGBO(0, 128, 96, .8),
      800: Color.fromRGBO(0, 128, 96, .9),
      900: Color.fromRGBO(0, 128, 96, 1),
    });
  }

  static MaterialColor lightSwatch = _primarySwatch(0xFF008060);

  ///Light theme - Shopify-inspired clean design
  static final light = ThemeData(
      brightness: Brightness.light,
      primarySwatch: lightSwatch,
      primaryColor: lightSwatch,
      primaryColorDark: lightSwatch,
      accentColor: Color(0xFF008060),
      toggleableActiveColor: Color(0xFF008060),
      backgroundColor: Color(0xFFF6F6F7), // Light gray background
      scaffoldBackgroundColor: Colors.white, // Clean white background
      bottomSheetTheme:
          BottomSheetThemeData(backgroundColor: Colors.transparent),
      bottomNavigationBarTheme:
          BottomNavigationBarThemeData(backgroundColor: Colors.white),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Color(0xFF008060),
      ));

  ///Dark theme - Shopify-inspired dark mode
  static final dark = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: lightSwatch,
    primaryColor: lightSwatch,
    primaryColorDark: lightSwatch,
    accentColor: Color(0xFF008060),
    toggleableActiveColor: Color(0xFF008060),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Color(0xFF008060),
    ),
    backgroundColor: Color(0xFF1A1A1A), // Deep dark background
    scaffoldBackgroundColor: Color(0xFF111111), // Darker scaffold
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A1A), elevation: 0),
  );
}
