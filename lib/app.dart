import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisbaj/config/routes.dart';
import 'package:wisbaj/config/themes.dart';
import 'package:wisbaj/features/home/presentation/pages/home_page.dart';
import 'package:wisbaj/shared/providers/theme_provider.dart';

class WisbajApp extends ConsumerWidget {
  const WisbajApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return ScreenUtilInit(
      designSize: const Size(390, 844), // Dimensions iPhone 13
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Wisbaj',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeMode,
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const HomePage(),
        );
      },
    );
  }
}