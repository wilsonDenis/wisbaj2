import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisbaj/core/models/alarm_model.dart';
import 'package:wisbaj/core/models/connection_status.dart';
import 'package:wisbaj/features/alarm_management/presentation/widgets/time_picker_widget.dart';
import 'package:wisbaj/shared/providers/alarm_provider.dart';
import 'package:wisbaj/shared/providers/bluetooth_provider.dart';
import 'package:wisbaj/shared/widgets/app_button.dart';

class AlarmDetailsPage extends ConsumerStatefulWidget {
  final String alarmId;

  const AlarmDetailsPage({
    super.key,
    required this.alarmId,
  });

  @override
  ConsumerState<AlarmDetailsPage> createState() => _AlarmDetailsPageState();
}

class _AlarmDetailsPageState extends ConsumerState<AlarmDetailsPage> {
  late TextEditingController _labelController;
  late TimeOfDay _selectedTime;
  late List<bool> _selectedDays;
  late bool _vibrate;
  late bool _isActive;

  @override
  void initState() {
    super.initState();

   
    final alarms = ref.read(alarmsNotifierProvider);
    final alarm = alarms.firstWhere(
      (a) => a.id == widget.alarmId,
      orElse: () {
   
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pop(context);
        });
      
        return AlarmModel(
          id: "",
          time: TimeOfDay.now(),
          activeDays: List.filled(7, false),
        );
      },
    );

    // Initialiser les contrôleurs et variables d'état
    _labelController = TextEditingController(text: alarm.label);
    _selectedTime = alarm.time;
    _selectedDays = List.from(alarm.activeDays);
    _vibrate = alarm.vibrate;
    _isActive = alarm.isActive;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatusAsync = ref.watch(bluetoothConnectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'alarme'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // État de l'alarme
            SwitchListTile(
              title: Text(
                'Alarme activée',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),

            SizedBox(height: 16.h),

         
            TimePickerWidget(
              initialTime: _selectedTime,
              onTimeChanged: (newTime) {
                setState(() {
                  _selectedTime = newTime;
                });
              },
            ),

            SizedBox(height: 24.h),

            // Libellé
            Text(
              'Libellé',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                hintText: 'Ex: Réveil',
                prefixIcon: Icon(Icons.label),
              ),
            ),

            SizedBox(height: 24.h),

           
            Text(
              'Répéter',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            _buildDaySelector(),

            SizedBox(height: 24.h),

            // Vibration
            SwitchListTile(
              title: Text(
                'Vibration',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              value: _vibrate,
              onChanged: (value) {
                setState(() {
                  _vibrate = value;
                });
              },
            ),

            SizedBox(height: 32.h),

           
            AppButton(
              label: 'Enregistrer les modifications',
              icon: Icons.save,
              onPressed: _updateAlarm,
              fullWidth: true,
            ),

            SizedBox(height: 16.h),

           
            connectionStatusAsync.when(
              data: (status) {
                if (status == ConnectionStatus.connected) {
                  return Column(
                    children: [
                      SizedBox(height: 16.h),
                      AppButton(
                        label: 'Envoyer à l\'Arduino',
                        icon: Icons.bluetooth_audio,
                        onPressed: _sendToArduino,
                        fullWidth: true,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    const List<String> days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        return _DayButton(
          day: days[index],
          isSelected: _selectedDays[index],
          onTap: () {
            setState(() {
              _selectedDays[index] = !_selectedDays[index];
            });
          },
        );
      }),
    );
  }

  void _updateAlarm() {
 
    if (!_selectedDays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un jour')),
      );
      return;
    }

    // Mettre à jour l'alarme
    final updatedAlarm = AlarmModel(
      id: widget.alarmId,
      time: _selectedTime,
      activeDays: _selectedDays,
      label: _labelController.text.trim(),
      vibrate: _vibrate,
      isActive: _isActive,
    );

    ref.read(alarmsNotifierProvider.notifier).updateAlarm(updatedAlarm);

   
    Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'alarme'),
        content:
            const Text('Êtes-vous sûr de vouloir supprimer cette alarme ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAlarm();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _deleteAlarm() {
    
    ref.read(alarmsNotifierProvider.notifier).deleteAlarm(widget.alarmId);

 
    Navigator.pop(context);
  }

void _sendToArduino() {
 
  final String heureFormatee = "${_selectedTime.hour}:${_selectedTime.minute}";
  const int dureeDefaut = 5; // Durée en secondes (à ajuster selon vos besoins)
  

  final List<Map<String, dynamic>> horaires = [];

  
  // Envoyer à l'Arduino au format JSON
  ref.read(bluetoothNotifierProvider.notifier).sendJsonAlarm(
    horaires,
    heure: heureFormatee,
    duree: dureeDefaut
  ).then((success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success 
            ? 'Alarme envoyée avec succès' 
            : 'Échec de l\'envoi de l\'alarme'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  });
}
}

class _DayButton extends StatelessWidget {
  final String day;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayButton({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
