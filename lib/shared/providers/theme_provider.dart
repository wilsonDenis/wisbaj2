import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:wisbaj/config/constants.dart';


final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});


class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Box _settingsBox = Hive.box(AppConstants.settingsBoxName);
  
  ThemeModeNotifier() : super(ThemeMode.system) {

    _loadThemePreference();
  }
  

  void _loadThemePreference() {
    final themeIndex = _settingsBox.get(
      AppConstants.themePreferenceKey,
      defaultValue: ThemeMode.system.index,
    ) as int;
    
    state = ThemeMode.values[themeIndex];
  }
  
 
  void setThemeMode(ThemeMode mode) {
    state = mode;
    _settingsBox.put(AppConstants.themePreferenceKey, mode.index);
  }
  

  void toggleTheme() {
    if (state == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.system);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}