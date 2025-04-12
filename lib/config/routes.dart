import 'package:flutter/material.dart';
import 'package:wisbaj/features/alarm_management/presentation/pages/add_alarm_page.dart';
import 'package:wisbaj/features/alarm_management/presentation/pages/alarm_details_page.dart';
import 'package:wisbaj/features/bluetooth_connection/presentation/pages/connection_page.dart';
import 'package:wisbaj/features/home/presentation/pages/home_page.dart';

class AppRouter {
  static const String home = '/';
  static const String connection = '/connection';
  static const String addAlarm = '/add-alarm';
  static const String alarmDetails = '/alarm-details';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case connection:
        return MaterialPageRoute(builder: (_) => const ConnectionPage());
      case addAlarm:
        return MaterialPageRoute(builder: (_) => const AddAlarmPage());
      case alarmDetails:
        final args = settings.arguments as Map<String, dynamic>;
        final alarmId = args['alarmId'] as String;
        return MaterialPageRoute(
          builder: (_) => AlarmDetailsPage(alarmId: alarmId),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Aucune route définie pour ${settings.name}'),
            ),
          ),
        );
    }
  }
}