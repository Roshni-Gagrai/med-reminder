import 'package:flutter/material.dart';
import 'package:medicine_reminder/models/med_model.dart';

class NextMedicineCard extends StatefulWidget {
  final Med nextMed;
  final VoidCallback onMedTaken;

  const NextMedicineCard({
    super.key,
    required this.nextMed,
    required this.onMedTaken,
  });

  @override
  State<NextMedicineCard> createState() => _NextMedicineCardState();
}

class _NextMedicineCardState extends State<NextMedicineCard> {
  bool _isHovered = false;

  Future<void> _handleMedTaken() async {
    final med = widget.nextMed;
    if (med.id == null || med.quantity <= 0) return;

    final updated = Med(
      id: med.id,
      name: med.name,
      type: med.type,
      color: med.color,
      time: med.time,
      duration: med.duration,
      quantity: med.quantity - 1,
      ringtone: med.ringtone,
      repeatReminderTime: med.repeatReminderTime,
      note: med.note,
    );

    await MedicineDatabase.updateMedicine(updated);
    widget.onMedTaken();
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.nextMed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: med.color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT MEDICINE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: med.color,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: med.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getMedicineIcon(med.type),
                  color: med.color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${med.quantity} dose • ${med.repeatReminderTime}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(med.time),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: med.color,
                ),
              ),
              Text(
                'Ringtone: ${med.ringtone}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Med Taken button with hover effect
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _isHovered
                    ? med.color
                    : med.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _handleMedTaken,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: _isHovered ? Colors.white : med.color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Med Taken',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _isHovered ? Colors.white : med.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Keep this for backward compatibility anywhere else it's called
Widget buildNextMedicineCard(Med nextMed, {VoidCallback? onMedTaken}) {
  return NextMedicineCard(
    nextMed: nextMed,
    onMedTaken: onMedTaken ?? () {},
  );
}

String _formatTime(TimeOfDay time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

IconData _getMedicineIcon(String type) {
  final t = type.toLowerCase();
  if (t == 'tablet' || t == 'capsule') {
    return Icons.local_pharmacy;
  } else if (t == 'injection') {
    return Icons.medical_services;
  } else if (t == 'syrup') {
    return Icons.local_drink;
  } else {
    return Icons.local_pharmacy;
  }
}