import 'package:hive/hive.dart';
import 'package:wisbaj/config/constants.dart';
import 'package:wisbaj/core/models/alarm_model.dart';
import 'package:wisbaj/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final Box _alarmBox = Hive.box(AppConstants.alarmBoxName);
  
  @override
  Future<List<AlarmModel>> getAlarms() async {
    final List<dynamic> alarmData = _alarmBox.values.toList();
    return alarmData.map((data) => data as AlarmModel).toList();
  }
  
  @override
  Future<void> saveAlarm(AlarmModel alarm) async {
    await _alarmBox.put(alarm.id, alarm);
  }
  
  @override
  Future<void> deleteAlarm(String id) async {
    await _alarmBox.delete(id);
  }
}
