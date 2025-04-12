import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class PermissionService {
  final Logger _logger = Logger();

  // Méthode principale pour demander toutes les permissions nécessaires
  Future<bool> requestPermissions() async {
    _logger.i('Demande des permissions nécessaires...');
    
    // Sur Web ou iOS, les permissions sont demandées automatiquement au moment de l'utilisation
    if (kIsWeb) {
      _logger.i('Plateforme Web détectée, pas de permissions à demander manuellement.');
      return true;
    }
    
    List<Permission> permissionsToRequest = [];
    
    // Permissions Android
    if (Platform.isAndroid) {
      // Vérifier la version d'Android pour demander les bonnes permissions
      if (await _isAndroid12OrHigher()) {
        // Android 12+ (API niveau 31+)
        permissionsToRequest.add(Permission.bluetoothScan);
        permissionsToRequest.add(Permission.bluetoothConnect);
      } else {
        // Android 11 ou inférieur
        permissionsToRequest.add(Permission.bluetooth);
        
        // La localisation est requise pour la découverte Bluetooth sur Android <12
        permissionsToRequest.add(Permission.location);
      }
    }
    
    // Si aucune permission n'est requise, retourner true
    if (permissionsToRequest.isEmpty) {
      _logger.i('Aucune permission requise pour cette plateforme.');
      return true;
    }
    
    // Demander toutes les permissions requises
    Map<Permission, PermissionStatus> statuses = await permissionsToRequest.request();
    
    // Vérifier si toutes les permissions ont été accordées
    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        _logger.w('Permission $permission non accordée: $status');
        allGranted = false;
      } else {
        _logger.i('Permission $permission accordée.');
      }
    });
    
    return allGranted;
  }
  
  // Vérifier si l'appareil est sous Android 12 ou plus
  Future<bool> _isAndroid12OrHigher() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 31; // API 31 = Android 12
    }
    return false;
  }
}

// Classe factice pour éviter les erreurs de compilation si le package n'est pas disponible
// À remplacer par une véritable implémentation
class DeviceInfoPlugin {
  Future<AndroidInfo> get androidInfo async => AndroidInfo._();
}

class AndroidInfo {
  AndroidInfo._();
  AndroidVersion get version => AndroidVersion._();
}

class AndroidVersion {
  AndroidVersion._();
  int get sdkInt => 31; // Valeur par défaut pour éviter les erreurs
}