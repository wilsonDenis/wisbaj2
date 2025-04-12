import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wisbaj/core/models/alarm_model.dart';
import 'package:wisbaj/features/alarm_management/presentation/widgets/time_picker_widget.dart';
import 'package:wisbaj/shared/providers/alarm_provider.dart';
import 'package:wisbaj/shared/widgets/app_button.dart';

class AddAlarmPage extends ConsumerStatefulWidget {
  const AddAlarmPage({super.key});

  @override
  ConsumerState<AddAlarmPage> createState() => _AddAlarmPageState();
}

class _AddAlarmPageState extends ConsumerState<AddAlarmPage> {
  final TextEditingController _labelController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<bool> _selectedDays = List.filled(7, false);
  bool _vibrate = true;
  
  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une alarme'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          
            TimePickerWidget(
              initialTime: _selectedTime,
              onTimeChanged: (newTime) {
                setState(() {
                  _selectedTime = newTime;
                });
              },
            ),
            
            SizedBox(height: 24.h),
       
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
              label: 'Enregistrer',
              icon: Icons.save,
              onPressed: _saveAlarm,
              fullWidth: true,
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
  
 void _saveAlarm() {
 
  if (!_selectedDays.contains(true)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veuillez sélectionner au moins un jour')),
    );
    return;
  }
  

  final newAlarm = AlarmModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    time: _selectedTime,
    activeDays: _selectedDays,
    label: _labelController.text.trim(),
    vibrate: _vibrate,
  );
  
  
  ref.read(alarmsNotifierProvider.notifier).saveAlarm(newAlarm);
  
 
  Navigator.pop(context);
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
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
