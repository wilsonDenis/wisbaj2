import 'package:wisbaj/core/models/alarm_model.dart';

abstract class HomeRepository {
  Future<List<AlarmModel>> getAlarms();
  Future<void> saveAlarm(AlarmModel alarm);
  Future<void> deleteAlarm(String id);
}