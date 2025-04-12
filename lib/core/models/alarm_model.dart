
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';


@HiveType(typeId: 0)
class AlarmModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final int hour;
  
  @HiveField(2)
  final int minute;
  
  @HiveField(3)
  final List<bool> activeDays;
  
  @HiveField(4)
  final String label;
  
  @HiveField(5)
  final bool isActive;
  
  @HiveField(6)
  final bool vibrate;
  
  @HiveField(7)
  final String soundPath;

  AlarmModel({
      required this.id,
      required TimeOfDay time,
      required this.activeDays,
      this.label = '',
      this.isActive = true,
      this.vibrate = true,
      this.soundPath = 'default',
    }) : hour = time.hour, minute = time.minute;
  

  factory AlarmModel.fromHourMinute({
    required String id,
    required int hour,
    required int minute,
    required List<bool> activeDays,
    String label = '',
    bool isActive = true,
    bool vibrate = true,
    String soundPath = 'default',
  }) {
    return AlarmModel(
      id: id,
      time: TimeOfDay(hour: hour, minute: minute),
      activeDays: activeDays,
      label: label,
      isActive: isActive,
      vibrate: vibrate,
      soundPath: soundPath,
    );
  }
  

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);
  
 
  String get timeString => 
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  

  AlarmModel copyWith({
    String? id,
    TimeOfDay? time,
    List<bool>? activeDays,
    String? label,
    bool? isActive,
    bool? vibrate,
    String? soundPath,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      time: time ?? this.time,
      activeDays: activeDays ?? this.activeDays,
      label: label ?? this.label,
      isActive: isActive ?? this.isActive,
      vibrate: vibrate ?? this.vibrate,
      soundPath: soundPath ?? this.soundPath,
    );
  }
  
  
  @override
  List<Object?> get props => [id, hour, minute, activeDays, label, isActive, vibrate, soundPath];
}


