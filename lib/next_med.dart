import 'package:flutter/material.dart';
import 'package:medicine_reminder/models/med_model.dart';

Widget buildNextMedicineCard(Med nextMed) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: nextMed.color.withOpacity(0.15),
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
            color: nextMed.color,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: nextMed.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getMedicineIcon(nextMed.type),
                color: nextMed.color,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nextMed.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${nextMed.quantity} dose • ${nextMed.repeatReminderTime}',
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
              _formatTime(nextMed.time),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: nextMed.color,
              ),
            ),
            Text(
              'Ringtone: ${nextMed.ringtone}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ],
    ),
  );
}

/// 🔹 ICON MAPPING BASED ON MEDICINE TYPE
// IconData _getMedicineIcon(String type) {
//   switch (type.toLowerCase()) {
//     case 'tablet':
//     case 'capsule':
//       return Icons.medication;        // 💊 Capsule/Tablet
//     case 'injection':
//       return Icons.medical_services;  // 💉 Injection
//     case 'syrup':
//       return Icons.local_drink;       // 🧴 Syrup
//     default:
//       return Icons.medication;
//   }
// }

String _formatTime(TimeOfDay time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
// IconData _getMedicineIcon(String type) {
//   switch (type.toLowerCase()) {
//     case 'tablet':
//     case 'capsule':
//       return Icons.local_pharmacy; // 💊 SAFE ICON
//     case 'injection':
//       return Icons.medical_services; // 💉
//     case 'syrup':
//       return Icons.local_drink; // 🧴
//     default:
//       return Icons.local_pharmacy;
//   }
// }

IconData _getMedicineIcon(String type) {
  final t = type.toLowerCase();

  if (t == 'tablet' || t == 'capsule') {
    return Icons.local_pharmacy;   // 💊 works on ALL devices
  } else if (t == 'injection') {
    return Icons.medical_services; // 💉
  } else if (t == 'syrup') {
    return Icons.local_drink;      // 🧴
  } else {
    return Icons.local_pharmacy;   // fallback
  }
}
