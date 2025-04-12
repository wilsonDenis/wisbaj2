import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wisbaj/app.dart';
import 'package:wisbaj/core/models/alarm_model.dart';

 Future <void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
 
  Hive.registerAdapter(AlarmModelTypeAdapter());
  
 
  await Hive.openBox('alarmBox');
  await Hive.openBox('settingsBox');
  
  runApp(
    const ProviderScope(
      child: WisbajApp(),
    ),
  );
}

class AlarmModelTypeAdapter extends TypeAdapter<AlarmModel> {
  @override
  final int typeId = 0;

  @override
  AlarmModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmModel.fromHourMinute(
      id: fields[0] as String,
      hour: fields[1] as int,
      minute: fields[2] as int,
      activeDays: (fields[3] as List).cast<bool>(),
      label: fields[4] as String,
      isActive: fields[5] as bool,
      vibrate: fields[6] as bool,
      soundPath: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.hour)
      ..writeByte(2)
      ..write(obj.minute)
      ..writeByte(3)
      ..write(obj.activeDays)
      ..writeByte(4)
      ..write(obj.label)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.vibrate)
      ..writeByte(7)
      ..write(obj.soundPath);
  }
}
