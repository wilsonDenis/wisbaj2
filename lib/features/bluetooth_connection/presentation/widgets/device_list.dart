import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class DeviceList extends StatelessWidget {
  final List<BluetoothDevice> devices;
  final Function(BluetoothDevice) onDeviceSelected;
  
  const DeviceList({
    Key? key,
    required this.devices,
    required this.onDeviceSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 48.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              'Aucun appareil trouvé',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Appuyez sur le bouton de rafraîchissement pour rechercher des appareils',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return DeviceItem(
          device: device,
          onTap: () => onDeviceSelected(device),
        );
      },
    );
  }
}

class DeviceItem extends StatelessWidget {
  final BluetoothDevice device;
  final VoidCallback onTap;
  
  const DeviceItem({
    Key? key,
    required this.device,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getBondStateColor(device.bondState),
          child: Icon(
            Icons.bluetooth,
            color: Colors.white,
          ),
        ),
        title: Text(
          device.name ?? 'Appareil inconnu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adresse: ${device.address}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),
            Text(
              _getBondStateText(device.bondState),
              style: TextStyle(
                fontSize: 12.sp,
                color: _getBondStateColor(device.bondState),
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: onTap,
          child: const Text('Connecter'),
        ),
        onTap: onTap,
        isThreeLine: true,
      ),
    );
  }
  
  // Obtenir le texte d'état d'appairage
  String _getBondStateText(BluetoothBondState? state) {
    switch (state) {
      case BluetoothBondState.bonded:
        return 'Appareil appairé';
      case BluetoothBondState.bonding:
        return 'Appairage en cours...';
      case BluetoothBondState.none:
        return 'Non appairé';
      default:
        return 'État inconnu';
    }
  }
  
  // Obtenir la couleur d'état d'appairage
  Color _getBondStateColor(BluetoothBondState? state) {
    switch (state) {
      case BluetoothBondState.bonded:
        return Colors.green;
      case BluetoothBondState.bonding:
        return Colors.orange;
      case BluetoothBondState.none:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}