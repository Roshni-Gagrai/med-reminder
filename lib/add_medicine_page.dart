import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medicine_reminder/models/med_model.dart';
import '../services/alarm_service.dart';

class AddMedicinePage extends StatefulWidget {
  final VoidCallback onAdded;

  const AddMedicinePage({super.key, required this.onAdded});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();

  String selectedType = 'tablet';
  Color selectedColor = const Color(0xFFFF6B6B);
  String selectedTiming = 'After Breakfast';
  TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
  DateTime? selectedDuration;

  final List<String> types = ['tablet', 'syrup', 'capsule', 'injection', 'other'];
  final List<Color> colors = [
    const Color(0xFFFF6B6B),
    const Color(0xFFFFD93D),
    const Color(0xFF6BCB77),
    const Color(0xFF4D96FF),
    const Color(0xFF9D84B7),
    const Color(0xFFFF9EAA),
  ];
  final List<String> timings = [
    'Before Breakfast',
    'After Breakfast',
    'Before Lunch',
    'After Lunch',
    'Before Dinner',
    'After Dinner',
    'Custom Time',
  ];

  void _submitForm() async {
    if (_nameController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final med = Med(
        name: _nameController.text,
        type: selectedType,
        color: selectedColor,
        time: selectedTime,
        duration: selectedDuration!,
        quantity: int.parse(_quantityController.text),
        ringtone: 'default',
        repeatReminderTime: selectedTiming,
        note: _noteController.text,
      );

      final medicineId = await MedicineDatabase.insertMedicine(med);

      final now = DateTime.now();
      DateTime scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        med.time.hour,
        med.time.minute,
      );

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await AlarmService.scheduleDailyAlarm(
        id: medicineId,
        time: scheduledTime,
        title: 'Medicine Reminder',
        body: 'Time to take ${med.name}',
      );

      widget.onAdded();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine added and alarm scheduled'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding medicine: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEBF4FF), Color(0xFFE8E0FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 28),
                    ),
                    const Text(
                      'Add Medicine',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medicine Name
                      _buildLabel('Medicine Name'),
                      TextField(
                        controller: _nameController,
                        decoration: _inputDecoration('e.g., Paracetamol'),
                      ),
                      const SizedBox(height: 20),

                      // Type
                      _buildLabel('Type'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: types.map((type) {
                          final isSelected = selectedType == type;
                          return InkWell(
                            onTap: () => setState(() => selectedType = type),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFF3E8FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.purple.shade600
                                      : const Color(0xFFE5E7EB),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                type[0].toUpperCase() + type.substring(1),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.purple.shade700
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Color Identifier
                      _buildLabel('Color Identifier'),
                      Row(
                        children: colors.map((color) {
                          final isSelected = selectedColor == color;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: InkWell(
                              onTap: () => setState(() => selectedColor = color),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.purple.shade300,
                                          width: 4,
                                        )
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Timing
                      _buildLabel('Timing'),
                      DropdownButtonFormField<String>(
                        initialValue: selectedTiming,
                        decoration: _inputDecoration(''),
                        items: timings.map((timing) {
                          return DropdownMenuItem(
                            value: timing,
                            child: Text(timing),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedTiming = value!);
                          if (value == 'Custom Time') {
                            _selectTime();
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Duration
                      _buildLabel('Duration (Until)'),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() => selectedDuration = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedDuration != null
                                    ? DateFormat('MMM dd, yyyy')
                                        .format(selectedDuration!)
                                    : 'Select date',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: selectedDuration != null
                                      ? const Color(0xFF1F2937)
                                      : const Color(0xFF9CA3AF),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF9CA3AF),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quantity
                      _buildLabel('Quantity Available'),
                      TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('e.g., 30'),
                      ),
                      const SizedBox(height: 20),

                      // Self Note
                      _buildLabel('Self Note (Optional)'),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          'Any special instructions...',
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Add Medicine',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (time != null) {
      setState(() => selectedTime = time);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}