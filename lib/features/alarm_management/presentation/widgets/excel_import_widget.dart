import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisbaj/core/utils/excel_service.dart';
import 'package:wisbaj/shared/providers/alarm_provider.dart';
import 'package:wisbaj/shared/widgets/app_button.dart';

class ExcelImportWidget extends ConsumerWidget {
  const ExcelImportWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.file_present,
                  color: Theme.of(context).primaryColor,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Import/Export Excel',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              'Importez des alarmes depuis un fichier Excel ou exportez vos alarmes actuelles.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Importer',
                    icon: Icons.file_upload,
                    onPressed: () => _importExcel(context, ref),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: AppButton(
                    label: 'Exporter',
                    icon: Icons.file_download,
                    onPressed: () => _exportExcel(context, ref),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _importExcel(BuildContext context, WidgetRef ref) async {
    final excelService = ExcelService();
    
    try {
      final alarms = await excelService.importAlarmsFromExcel();
      
      if (alarms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune alarme trouvée dans le fichier')),
        );
        return;
      }
      
      // Utiliser le notifier pour importer les alarmes
      await ref.read(alarmsNotifierProvider.notifier).importAlarms(alarms);
      
      // Plus besoin d'appeler refresh
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${alarms.length} alarmes importées avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'importation: $e')),
      );
    }
  }
  
  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    final excelService = ExcelService();
    
    // Utiliser le nouveau provider
    final alarms = ref.watch(alarmsNotifierProvider);
    
    if (alarms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune alarme à exporter')),
      );
      return;
    }
    
    try {
      final filePath = await excelService.exportAlarmsToExcel(alarms);
      
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alarmes exportées vers: $filePath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de l\'exportation')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'exportation: $e')),
      );
    }
  }
}