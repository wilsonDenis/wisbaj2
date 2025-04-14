import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:logger/logger.dart';

import 'package:wisbaj/core/models/connection_status.dart';
import 'package:wisbaj/core/utils/permission_handler.dart';

class BluetoothManager {
  final Logger _logger = Logger();
  final PermissionService _permissionService = PermissionService();
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  final StreamController<ConnectionStatus> _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<List<BluetoothDevice>> _devicesController =
      StreamController<List<BluetoothDevice>>.broadcast();
  final StreamController<Map<String, dynamic>> _arduinoResponseController =
      StreamController<Map<String, dynamic>>.broadcast();

  BluetoothDevice? _connectedDevice;
  BluetoothConnection? _connection;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _discoverySubscription;

  List<BluetoothDevice> _discoveredDevices = [];

  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;
  Stream<List<BluetoothDevice>> get devices => _devicesController.stream;
  Stream<Map<String, dynamic>> get arduinoResponses =>
      _arduinoResponseController.stream;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<bool> initialize() async {
    try {
      bool permissionsGranted = await _permissionService.requestPermissions();
      if (!permissionsGranted) {
        _logger.w(
            '⚠️ Certaines permissions n\'ont pas été accordées. La fonctionnalité Bluetooth peut être limitée.');
      }

      _stateSubscription =
          _bluetooth.onStateChanged().listen((BluetoothState state) {
        _logger.i('État Bluetooth: $state');

        if (state == BluetoothState.STATE_ON) {
          _logger.i('Bluetooth est maintenant activé.');
          if (_status == ConnectionStatus.disconnected ||
              _status == ConnectionStatus.error) {
            _updateConnectionStatus(ConnectionStatus.initialized);
          }
        } else if (state == BluetoothState.STATE_OFF) {
          _logger.w('Bluetooth est maintenant désactivé.');
          _updateConnectionStatus(ConnectionStatus.disconnected);
          _disconnectCurrentDevice();
        }
      });

      bool? isEnabled = await _bluetooth.isEnabled;
      if (isEnabled == true) {
        _updateConnectionStatus(ConnectionStatus.initialized);
      } else {
        try {
          await _bluetooth.requestEnable();
          _logger.i('✅ Bluetooth activé avec succès');
        } catch (e) {
          _logger.w('⚠️ Impossible d\'activer Bluetooth automatiquement: $e');
        }
      }

      return true;
    } catch (e) {
      _logger.e('❌ Erreur d\'initialisation Bluetooth: $e');
      _updateConnectionStatus(ConnectionStatus.error);
      return false;
    }
  }

  Future<void> startScan() async {
    _updateConnectionStatus(ConnectionStatus.scanning);

    try {
      _logger.i('🔍 Récupération des appareils appairés...');

      List<BluetoothDevice> bondedDevices = await _bluetooth.getBondedDevices();
      _discoveredDevices = bondedDevices;

      for (var device in bondedDevices) {
        _logger.i(
            '📱 Appareil appairé: ${device.name ?? "Sans nom"} (${device.address})');
      }

      _devicesController.add(_discoveredDevices);

      _logger.i(
          '✅ Scan terminé: ${_discoveredDevices.length} appareils appairés trouvés');
      _updateConnectionStatus(ConnectionStatus.scanned);
    } catch (e) {
      _logger.e('❌ Exception lors du scan: $e');
      _updateConnectionStatus(ConnectionStatus.error);
    }
  }

  Future<void> startDiscovery() async {
    _updateConnectionStatus(ConnectionStatus.scanning);

    try {
      if (_discoverySubscription != null) {
        await _discoverySubscription!.cancel();
        _discoverySubscription = null;
      }

      _logger.i('🔍 Démarrage de la découverte des appareils Bluetooth...');

      List<BluetoothDevice> bondedDevices = await _bluetooth.getBondedDevices();
      _discoveredDevices = [...bondedDevices];
      _devicesController.add(_discoveredDevices);

      _discoverySubscription = _bluetooth.startDiscovery().listen((result) {
        final existingIndex = _discoveredDevices
            .indexWhere((d) => d.address == result.device.address);

        if (existingIndex >= 0) {
          _discoveredDevices[existingIndex] = result.device;
        } else {
          _discoveredDevices.add(result.device);
        }

        _logger.i(
            '📱 Appareil découvert: ${result.device.name ?? "Sans nom"} (${result.device.address}) - RSSI: ${result.rssi}');

        _devicesController.add(_discoveredDevices);
      });

      _discoverySubscription!.onDone(() {
        _logger.i(
            '✅ Découverte terminée: ${_discoveredDevices.length} appareils trouvés');
        _updateConnectionStatus(ConnectionStatus.scanned);
      });
    } catch (e) {
      _logger.e('❌ Exception lors de la découverte: $e');
      _updateConnectionStatus(ConnectionStatus.error);
    }
  }

  Future<void> stopDiscovery() async {
    try {
      await _bluetooth.cancelDiscovery();
    } catch (e) {
      _logger.w('⚠️ Erreur lors de l\'arrêt de la découverte: $e');
    }

    if (_status == ConnectionStatus.scanning) {
      _updateConnectionStatus(ConnectionStatus.scanned);
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    _updateConnectionStatus(ConnectionStatus.connecting);

    try {
      await _disconnectCurrentDevice();

      String deviceName = device.name ?? "Appareil inconnu";
      String deviceAddress = device.address;
      _logger.i('🔌 Tentative de connexion à $deviceName ($deviceAddress)');

      bool connected = false;
      int attempts = 0;
      const maxAttempts = 3;
      Exception? lastException;

      while (!connected && attempts < maxAttempts) {
        attempts++;
        _logger.i('Tentative de connexion ${attempts}/${maxAttempts}...');

        try {
          await stopDiscovery();

          _connection = await BluetoothConnection.toAddress(device.address)
              .timeout(const Duration(seconds: 15));

          if (_connection != null && _connection!.isConnected) {
            connected = true;

            _connectionSubscription =
                _connection!.input!.listen((Uint8List data) {
              String message = utf8.decode(data);
              _logger.i('📥 Données reçues: $message');

              try {
                Map<String, dynamic> response = jsonDecode(message);
                _logger.i('📊 Réponse JSON de l\'Arduino: $response');
                _arduinoResponseController.add(response);
              } catch (e) {
                _logger.w('⚠️ Réception de données non-JSON: $message');
              }
            }, onDone: () {
              _logger.w('⚠️ Connexion fermée par l\'appareil distant');
              _updateConnectionStatus(ConnectionStatus.disconnected);
              _connectedDevice = null;
            }, onError: (error) {
              _logger.e('❌ Erreur lors de la réception des données: $error');
            });

            _logger.i('✅ Connexion établie!');
          }
        } catch (e) {
          lastException = e as Exception;
          _logger.w('⚠️ Échec de la tentative $attempts: $e');

          if (attempts < maxAttempts) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }

      if (!connected) {
        throw lastException ??
            Exception(
                'Impossible de se connecter après $maxAttempts tentatives');
      }

      _connectedDevice = device;
      _updateConnectionStatus(ConnectionStatus.connected);

      return true;
    } catch (e) {
      _logger.e('❌ Erreur lors de la connexion: $e');
      _updateConnectionStatus(ConnectionStatus.error);
      return false;
    }
  }

  Future<bool> sendData(String data) async {
    if (_connectedDevice == null ||
        _connection == null ||
        !_connection!.isConnected) {
      _logger.e('❌ Impossible d\'envoyer des données: non connecté');
      return false;
    }

    try {
      Uint8List bytes = Uint8List.fromList(utf8.encode("$data\n"));

      _logger.i('📤 Envoi de données: $data');
      _connection!.output.add(bytes);
      await _connection!.output.allSent;
      _logger.i('✅ Données envoyées avec succès');
      return true;
    } catch (e) {
      _logger.e('❌ Erreur lors de l\'envoi des données: $e');
      return false;
    }
  }

  Future<bool> sendAlarm(String alarmData) async {
    return sendData(alarmData);
  }

  Future<bool> sendJsonAlarm(List<Map<String, dynamic>> horaires,
      {String? heure, int? duree}) async {
    try {
      final Map<String, dynamic> jsonData = {
        'horaires': horaires,
      };

      if (heure != null) {
        // Extraire les parties de l'heure
        List<String> parts = heure.split(':');
        if (parts.length == 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);
          // Reformater avec les zéros initiaux
          jsonData['heure'] =
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        } else {
          jsonData['heure'] = heure;
        }
      }

      if (duree != null) jsonData['duree'] = duree;

      final String jsonString = jsonEncode(jsonData);

      _logger.i('📤 Envoi d\'alarme au format JSON: $jsonString');

      bool success = await sendData(jsonString);
      if (!success) {
        return false;
      }

      _logger.i('⏳ Attente de la confirmation de l\'Arduino...');

      try {
        Completer<bool> responseCompleter = Completer<bool>();

        late StreamSubscription subscription;
        subscription = arduinoResponses.listen((response) {
          if (response.containsKey('status')) {
            String status = response['status'];
            if (status == 'received' || status == 'configured') {
              if (!responseCompleter.isCompleted) {
                responseCompleter.complete(true);
              }
              subscription.cancel();
            } else if (status == 'error') {
              if (!responseCompleter.isCompleted) {
                responseCompleter.complete(false);
              }
              subscription.cancel();
            }
          }
        });

        bool received = await responseCompleter.future
            .timeout(const Duration(seconds: 3), onTimeout: () {
          _logger.w('⚠️ Timeout en attente de confirmation de l\'Arduino');
          subscription.cancel();
          return false;
        });

        if (received) {
          _logger.i('✅ Confirmation reçue de l\'Arduino');
        } else {
          _logger.w('⚠️ Pas de confirmation valide reçue');
        }

        return received;
      } catch (e) {
        _logger.e('❌ Erreur en attendant la confirmation: $e');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Erreur lors de la construction du JSON d\'alarme: $e');
      return false;
    }
  }

  Future<void> _disconnectCurrentDevice() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    if (_connection != null && _connection!.isConnected) {
      try {
        await _connection!.close();
        _logger.i('✅ Connexion fermée');
      } catch (e) {
        _logger.w('⚠️ Erreur lors de la fermeture de la connexion: $e');
      }
    }

    _connectedDevice = null;
    _connection = null;
  }

  Future<void> disconnect() async {
    await _disconnectCurrentDevice();
    _updateConnectionStatus(ConnectionStatus.disconnected);
  }

  void _updateConnectionStatus(ConnectionStatus status) {
    _status = status;
    _connectionStatusController.add(status);
  }

  void dispose() {
    stopDiscovery();
    _discoverySubscription?.cancel();
    _connectionSubscription?.cancel();
    _stateSubscription?.cancel();
    _disconnectCurrentDevice();
    _connectionStatusController.close();
    _devicesController.close();
    _arduinoResponseController.close();
  }
}
