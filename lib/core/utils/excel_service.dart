import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wisbaj/core/models/alarm_model.dart';


class ExcelService {
  // Importer des alarmes depuis un fichier Excel
  Future<List<AlarmModel>> importAlarmsFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      
      if (result == null) {
        // L'utilisateur a annulé la sélection
        return [];
      }

      final bytes = File(result.files.single.path!).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      
      List<AlarmModel> alarms = [];
      
      // Parcourir les feuilles et les lignes pour extraire les alarmes
      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table]!;
        
        // Ignorer la première ligne (en-têtes)
        bool isFirstRow = true;
        
        for (var row in sheet.rows) {
          if (isFirstRow) {
            isFirstRow = false;
            continue;
          }
          
          // Vérifier si la ligne a suffisamment de cellules
          if (row.length >= 9) {
            try {
              // Format attendu: Heure, Minute, Lun, Mar, Mer, Jeu, Ven, Sam, Dim, Label, Vibration
              int hour = int.parse(row[0]?.value.toString() ?? '0');
              int minute = int.parse(row[1]?.value.toString() ?? '0');
              
              // Lire les jours actifs (valeurs booléennes)
              List<bool> activeDays = List.generate(7, (index) {
                var value = row[index + 2]?.value.toString().toLowerCase();
                return value == 'true' || value == '1' || value == 'oui';
              });
              
              String label = row[9]?.value.toString() ?? '';
              bool vibrate = row[10]?.value.toString().toLowerCase() == 'true';
              
              alarms.add(AlarmModel(
                id: DateTime.now().millisecondsSinceEpoch.toString() + alarms.length.toString(),
                time: TimeOfDay(hour: hour, minute: minute),
                activeDays: activeDays,
                label: label,
                vibrate: vibrate,
              ));
            } catch (e) {
              // Ignorer les lignes mal formatées
              print('Erreur lors de la lecture d\'une ligne: $e');
            }
          }
        }
      }
      
      return alarms;
    } catch (e) {
      print('Erreur lors de l\'importation Excel: $e');
      return [];
    }
  }
  
  // Exporter des alarmes vers un fichier Excel
  Future<String?> exportAlarmsToExcel(List<AlarmModel> alarms) async {
    try {
      var excel = Excel.createExcel();
      
      // Supprimer la feuille par défaut et en créer une nouvelle
      excel.delete('Sheet1');
      final sheet = excel['Alarmes'];
      
      // Ajouter les en-têtes
      final headers = [
        'Heure', 'Minute', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 
        'Vendredi', 'Samedi', 'Dimanche', 'Libellé', 'Vibration', 'Actif'
      ];
      
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = headers[i]
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      
      // Ajouter les données des alarmes
      for (int i = 0; i < alarms.length; i++) {
        final alarm = alarms[i];
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
          ..value = alarm.time.hour;
          
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
          ..value = alarm.time.minute;
        
        // Jours actifs
        for (int j = 0; j < alarm.activeDays.length; j++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: j + 2, rowIndex: i + 1))
            ..value = alarm.activeDays[j];
        }
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: i + 1))
          ..value = alarm.label;
          
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: i + 1))
          ..value = alarm.vibrate;
          
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: i + 1))
          ..value = alarm.isActive;
      }
      
      // Enregistrer le fichier Excel
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'wisbaj_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);
      
      return filePath;
    } catch (e) {
      print('Erreur lors de l\'exportation Excel: $e');
      return null;
    }
  }
}