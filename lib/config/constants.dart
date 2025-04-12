import 'package:flutter/material.dart';

class AppColors {
  // Couleurs du thème clair
  static const Color primary = Color(0xFF2F80ED);
  static const Color secondary = Color(0xFF2A9D8F);
  static const Color error = Color(0xFFE57373);
  static const Color textDark = Color(0xFF333333);
  
  // Couleurs du thème sombre
  static const Color primaryDark = Color(0xFF4D9BF3);
  static const Color secondaryDark = Color(0xFF3DAFB0);
  static const Color errorDark = Color(0xFFEF5350);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color textLight = Color(0xFFF5F5F5);
}

class AppConstants {

  static const double appBarHeight = 56.0;
  static const double pagePadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  
  
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration scanDuration = Duration(seconds: 15);
 
  

  static const String alarmBoxName = 'alarmBox';
  static const String settingsBoxName = 'settingsBox';
  static const String lastDeviceKey = 'lastDeviceId';
  static const String themePreferenceKey = 'themePreference';
}