import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:wisbaj/config/constants.dart';
import 'package:wisbaj/core/models/alarm_model.dart';
import 'package:wisbaj/core/utils/alarm_service.dart';


final alarmServiceProvider = Provider<AlarmService>((ref) {
  final service = AlarmService();

  service.initialize();
  

  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});


class AlarmsNotifier extends StateNotifier<List<AlarmModel>> {
  final AlarmService _alarmService;
  final Box _alarmBox = Hive.box(AppConstants.alarmBoxName);
  
  AlarmsNotifier(this._alarmService) : super([]) {
  
    _loadAlarms();
  }
  
  
  void _loadAlarms() {
    final List<dynamic> alarmData = _alarmBox.values.toList();
    state = alarmData.map((data) => data as AlarmModel).toList();
  }
  
 
  Future<void> saveAlarm(AlarmModel alarm) async {
    await _alarmService.saveAlarm(alarm);
    _loadAlarms(); 
  }
  
 
  Future<void> deleteAlarm(String id) async {
    await _alarmService.deleteAlarm(id);
    _loadAlarms(); 
  }
  
  
  Future<void> updateAlarm(AlarmModel alarm) async {
    await _alarmService.saveAlarm(alarm);
    _loadAlarms(); 
  }
  
  
  Future<void> toggleAlarmActive(String id, bool isActive) async {

    final alarm = state.firstWhere(
      (a) => a.id == id,
      orElse: () => throw Exception('Alarme non trouvée'),
    );
    
    
    final updatedAlarm = alarm.copyWith(isActive: isActive);
    
    
    await saveAlarm(updatedAlarm);
  }
  
 
  Future<void> importAlarms(List<AlarmModel> alarms) async {
    for (var alarm in alarms) {
      await _alarmService.saveAlarm(alarm);
    }
    _loadAlarms(); 
  }
}


final alarmsNotifierProvider = StateNotifierProvider<AlarmsNotifier, List<AlarmModel>>((ref) {
  final alarmService = ref.watch(alarmServiceProvider);
  return AlarmsNotifier(alarmService);
});