import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisbaj/core/models/connection_status.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final ConnectionStatus status;
  
  const ConnectionStatusWidget({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String statusText;
    Color color;
    
    switch (status) {
      case ConnectionStatus.connected:
        icon = Icons.bluetooth_connected;
        statusText = 'Connecté';
        color = Colors.green;
        break;
      case ConnectionStatus.connecting:
        icon = Icons.bluetooth_searching;
        statusText = 'Connexion...';
        color = Colors.orange;
        break;
      case ConnectionStatus.scanning:
        icon = Icons.search;
        statusText = 'Recherche...';
        color = Colors.blue;
        break;
      case ConnectionStatus.error:
        icon = Icons.error_outline;
        statusText = 'Erreur';
        color = Colors.red;
        break;
      case ConnectionStatus.disconnected:
        icon = Icons.bluetooth_disabled;
        statusText = 'Déconnecté';
        color = Colors.grey;
        break;
      default:
        icon = Icons.bluetooth;
        statusText = 'Initialisation';
        color = Colors.grey;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 8.w),
          Text(
            statusText,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}
