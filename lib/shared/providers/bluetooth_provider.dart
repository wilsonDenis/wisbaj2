import 'dart:async';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wisbaj/core/models/connection_status.dart';
import 'package:wisbaj/shared/providers/bluetooth_manager.dart';


class BluetoothNotifier extends StateNotifier<BluetoothManager> {

  final StreamController<ConnectionStatus> _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<List<BluetoothDevice>> _devicesController =
      StreamController<List<BluetoothDevice>>.broadcast();

  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;
  Stream<List<BluetoothDevice>> get devices => _devicesController.stream;

  BluetoothNotifier() : super(BluetoothManager()) {
   
    state.connectionStatus.listen((status) {
      _connectionStatusController.add(status);
    });

    state.devices.listen((deviceList) {
      _devicesController.add(deviceList);
    });
  }

  @override
  void dispose() {
    state.dispose();
    _connectionStatusController.close();
    _devicesController.close();
    super.dispose();
  }

  
  Future<bool> sendJsonAlarm(List<Map<String, dynamic>> horaires,
      {String? heure, int? duree}) async {

    return await state.sendJsonAlarm(horaires, heure: heure, duree: duree);
  }

  
  Future<bool> initialize() => state.initialize();
  Future<void> startScan() => state.startScan();
  Future<void> startDiscovery() => state.startDiscovery();
  Future<void> stopDiscovery() => state.stopDiscovery();
  Future<bool> connectToDevice(BluetoothDevice device) =>
      state.connectToDevice(device);
  Future<bool> sendAlarm(String alarmData) => state.sendAlarm(alarmData);
  Future<void> disconnect() => state.disconnect();
}

final bluetoothNotifierProvider =
    StateNotifierProvider<BluetoothNotifier, BluetoothManager>((ref) {
  return BluetoothNotifier();
});


final bluetoothConnectionProvider = StreamProvider<ConnectionStatus>((ref) {
  final manager = ref.watch(bluetoothNotifierProvider.notifier);
  return manager.connectionStatus;
});


final bluetoothDevicesProvider = StreamProvider<List<BluetoothDevice>>((ref) {
  final manager = ref.watch(bluetoothNotifierProvider.notifier);
  return manager.devices;
});
