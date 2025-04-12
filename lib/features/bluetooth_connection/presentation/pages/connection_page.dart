import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:wisbaj/core/models/connection_status.dart';
import 'package:wisbaj/features/bluetooth_connection/presentation/widgets/device_list.dart';
import 'package:wisbaj/shared/providers/bluetooth_provider.dart';

class ConnectionPage extends ConsumerStatefulWidget {
  const ConnectionPage({super.key});

  @override
  ConsumerState<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends ConsumerState<ConnectionPage> {
  bool _isScanning = false;
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    // Initialiser Bluetooth
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Utiliser le provider
      ref.read(bluetoothNotifierProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatusAsync = ref.watch(bluetoothConnectionProvider);
    final devicesAsync = ref.watch(bluetoothDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios), // Icône de style iOS
          onPressed: () {
            Navigator.of(context).pop(); // Retour à la page précédente
          },
        ),
        title: const Text('Connexion Bluetooth'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              // Ouvrir les paramètres Bluetooth
              await FlutterBluetoothSerial.instance.openSettings();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Animation de statut
          Container(
            height: 200.h,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.8),
                  Theme.of(context).primaryColor.withOpacity(0.2),
                ],
              ),
            ),
            child: Center(
              child: connectionStatusAsync.when(
                data: (status) => _buildStatusAnimation(status),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => _buildStatusAnimation(ConnectionStatus.error),
              ),
            ),
          ),

          // Texte de statut
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: connectionStatusAsync.when(
              data: (status) => Text(
                _getStatusText(status),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(status),
                ),
              ),
              loading: () => Text(
                'Chargement...',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              error: (_, __) => Text(
                'Erreur',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),

          // Boutons de scan
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning || _isDiscovering
                        ? null
                        : () {
                            setState(() => _isScanning = true);
                            ref
                                .read(bluetoothNotifierProvider.notifier)
                                .startScan()
                                .then(
                                    (_) => setState(() => _isScanning = false));
                          },
                    icon: Icon(_isScanning
                        ? Icons.hourglass_top
                        : Icons.bluetooth_connected),
                    label: Text(_isScanning ? 'Recherche...' : 'Appareils'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning || _isDiscovering
                        ? null
                        : () {
                            setState(() => _isDiscovering = true);
                            ref
                                .read(bluetoothNotifierProvider.notifier)
                                .startDiscovery()
                                .then((_) =>
                                    setState(() => _isDiscovering = false));
                          },
                    icon: Icon(
                        _isDiscovering ? Icons.hourglass_top : Icons.search),
                    label: Text(_isDiscovering ? 'Découverte...' : 'Découvrir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste des appareils
          Expanded(
            child: devicesAsync.when(
              data: (devices) => DeviceList(
                devices: devices,
                onDeviceSelected: (BluetoothDevice device) {
                  // Arrêter la découverte avant la connexion
                  if (_isDiscovering) {
                    ref
                        .read(bluetoothNotifierProvider.notifier)
                        .stopDiscovery();
                    setState(() => _isDiscovering = false);
                  }

                  // Utiliser le provider pour se connecter
                  ref
                      .read(bluetoothNotifierProvider.notifier)
                      .connectToDevice(device);
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'Erreur lors de la recherche d\'appareils',
                  style: TextStyle(color: Colors.red, fontSize: 16.sp),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          _buildFloatingActionButton(connectionStatusAsync.value),
    );
  }

  Widget? _buildFloatingActionButton(ConnectionStatus? status) {
    // Si on est connecté, afficher un bouton de déconnexion
    if (status == ConnectionStatus.connected) {
      return FloatingActionButton(
        onPressed: () {
          ref.read(bluetoothNotifierProvider.notifier).disconnect();
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.bluetooth_disabled),
      );
    }

    return null;
  }

  Widget _buildStatusAnimation(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Lottie.asset(
          'assets/animations/connection_success.json',
          width: 150.w,
          height: 150.h,
          repeat: false,
        );
      case ConnectionStatus.connecting:
        return Lottie.asset(
          'assets/animations/connection_loading.json',
          width: 150.w,
          height: 150.h,
        );
      case ConnectionStatus.error:
        return Lottie.asset(
          'assets/animations/connection_error.json',
          width: 300.w,
          height: 300.h,
        );
      default:
        return Lottie.asset(
          'assets/animations/bluetooth_scan.json',
          width: 150.w,
          height: 150.h,
        );
    }
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connecté à l\'appareil';
      case ConnectionStatus.connecting:
        return 'Connexion en cours...';
      case ConnectionStatus.scanning:
        return 'Recherche d\'appareils...';
      case ConnectionStatus.scanned:
        return 'Appareils trouvés';
      case ConnectionStatus.disconnected:
        return 'Déconnecté';
      case ConnectionStatus.error:
        return 'Erreur de connexion';
      default:
        return 'Initialisation du Bluetooth';
    }
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
      case ConnectionStatus.scanning:
        return Colors.orange;
      case ConnectionStatus.scanned:
        return Colors.blue;
      case ConnectionStatus.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
