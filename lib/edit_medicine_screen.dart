import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medicine_reminder/models/med_model.dart';

class EditMedicineScreen extends StatefulWidget {
  final Med? medicine; // Made nullable with ?
  final Function(Med) onSave;

  const EditMedicineScreen({
    super.key,
    this.medicine, // Now optional
    required this.onSave,
  });

  @override
  State<EditMedicineScreen> createState() => _EditMedicineScreenState();
}

class _EditMedicineScreenState extends State<EditMedicineScreen> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _noteController;
  late String _selectedType;
  late TimeOfDay _selectedTime;
  late Color _selectedColor;
  late DateTime _selectedDuration;
  late String _selectedTiming;

  final List<String> _medicineTypes = ['tablet', 'syrup', 'capsule', 'injection', 'other'];
  final List<Color> _availableColors = [
    const Color(0xFFFF6B6B),
    const Color(0xFFFFD93D),
    const Color(0xFF6BCB77),
    const Color(0xFF4D96FF),
    const Color(0xFF9D84B7),
    const Color(0xFFFF9EAA),
  ];
  final List<String> _timings = [
    'Before Breakfast',
    'After Breakfast',
    'Before Lunch',
    'After Lunch',
    'Before Dinner',
    'After Dinner',
    'Custom Time',
  ];

  @override
  void initState() {
    super.initState();
    // If medicine is null, use default values (for adding new medicine)
    _nameController = TextEditingController(text: widget.medicine?.name ?? '');
    _quantityController = TextEditingController(text: widget.medicine?.quantity.toString() ?? '');
    _noteController = TextEditingController(text: widget.medicine?.note ?? '');
    _selectedType = widget.medicine?.type ?? 'tablet';
    _selectedTime = widget.medicine?.time ?? const TimeOfDay(hour: 9, minute: 0);
    _selectedColor = widget.medicine?.color ?? const Color(0xFFFF6B6B);
    _selectedDuration = widget.medicine?.duration ?? DateTime.now().add(const Duration(days: 30));
    _selectedTiming = widget.medicine?.repeatReminderTime ?? 'After Breakfast';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple.shade600,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectDuration() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDuration,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple.shade600,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDuration = picked;
      });
    }
  }

  void _saveMedicine() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter medicine name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedMedicine = Med(
      id: widget.medicine?.id, // Preserve ID if editing
      name: _nameController.text.trim(),
      type: _selectedType,
      time: _selectedTime,
      quantity: quantity,
      color: _selectedColor,
      duration: _selectedDuration,
      ringtone: 'default',
      repeatReminderTime: _selectedTiming,
      note: _noteController.text.trim(),
    );

    widget.onSave(updatedMedicine);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're adding or editing
    final isEditing = widget.medicine != null;
    
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
                    Text(
                      isEditing ? 'Edit Medicine' : 'Add Medicine',
                      style: const TextStyle(
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
                        children: _medicineTypes.map((type) {
                          final isSelected = _selectedType == type;
                          return InkWell(
                            onTap: () => setState(() => _selectedType = type),
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
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.purple.shade600
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Color
                      _buildLabel('Color'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _availableColors.map((color) {
                          final isSelected = color == _selectedColor;
                          return InkWell(
                            onTap: () => setState(() => _selectedColor = color),
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
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Timing
                      _buildLabel('Timing'),
                      DropdownButtonFormField<String>(
                        value: _selectedTiming,
                        decoration: _inputDecoration(''),
                        items: _timings.map((timing) {
                          return DropdownMenuItem(
                            value: timing,
                            child: Text(timing),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedTiming = value!);
                          if (value == 'Custom Time') {
                            _selectTime();
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Duration
                      _buildLabel('Duration (Until)'),
                      InkWell(
                        onTap: _selectDuration,
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
                                DateFormat('MMM dd, yyyy').format(_selectedDuration),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1F2937),
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

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveMedicine,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            isEditing ? 'Save Changes' : 'Add Medicine',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
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
}
