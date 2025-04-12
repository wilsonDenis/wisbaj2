import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisbaj/config/routes.dart';
import 'package:wisbaj/core/models/alarm_model.dart';
import 'package:wisbaj/shared/providers/alarm_provider.dart';

class AlarmListWidget extends ConsumerWidget {
  const AlarmListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Utiliser le StateNotifierProvider au lieu du Provider simple
    final alarms = ref.watch(alarmsNotifierProvider);
    
    if (alarms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.alarm_off,
              size: 64.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              'Aucune alarme configurée',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.addAlarm);
              },
              child: const Text('Ajouter une alarme'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: alarms.length,
      itemBuilder: (context, index) {
        final alarm = alarms[index];
        return AlarmItem(alarm: alarm);
      },
    );
  }
}

class AlarmItem extends ConsumerWidget {
  final AlarmModel alarm;
  
  const AlarmItem({
    super.key,
    required this.alarm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmService = ref.read(alarmServiceProvider);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRouter.alarmDetails,
            arguments: {'alarmId': alarm.id},
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Heure
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.timeString,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (alarm.label.isNotEmpty)
                      Text(
                        alarm.label,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey,
                        ),
                      ),
                    SizedBox(height: 4.h),
                    Text(
                      alarmService.formatDays(alarm.activeDays),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Switch pour activer/désactiver
              Switch(
                value: alarm.isActive,
                onChanged: (value) {
                  // Utiliser le notifier directement
                  ref.read(alarmsNotifierProvider.notifier).toggleAlarmActive(
                    alarm.id,
                    value,
                  );
                  // Plus besoin d'appeler refresh !
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}