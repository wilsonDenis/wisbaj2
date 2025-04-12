import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisbaj/core/models/connection_status.dart';

class ConnectionStatusBar extends StatelessWidget {
  final ConnectionStatus status;
  
  const ConnectionStatusBar({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    String statusText;
    IconData icon;
    
    switch (status) {
      case ConnectionStatus.connected:
        backgroundColor = Colors.green;
        statusText = 'Connecté';
        icon = Icons.bluetooth_connected;
        break;
      case ConnectionStatus.connecting:
        backgroundColor = Colors.orange;
        statusText = 'Connexion en cours...';
        icon = Icons.bluetooth_searching;
        break;
      case ConnectionStatus.disconnected:
        backgroundColor = Colors.grey;
        statusText = 'Déconnecté';
        icon = Icons.bluetooth_disabled;
        break;
      case ConnectionStatus.error:
        backgroundColor = Colors.red;
        statusText = 'Erreur de connexion';
        icon = Icons.error_outline;
        break;
      default:
        backgroundColor = Colors.blue;
        statusText = 'Initialisation...';
        icon = Icons.bluetooth;
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      color: backgroundColor,
      child: Row(
        children: [
          status == ConnectionStatus.connecting
            ? SizedBox(
                width: 24.w,
                height: 24.h,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.w,
                ),
              )
            : Icon(
                icon,
                color: Colors.white,
                size: 24.sp,
              ),
          SizedBox(width: 8.w),
          Text(
            statusText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}