import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

class Med {
  final int? id;
  final String name;
  final String type;
  final Color color; // Stored as hex string
  final TimeOfDay time;
  final DateTime duration; // When the medicine course ends
  final int quantity;
  final String ringtone;
  final String repeatReminderTime;
  final String note;
  final DateTime? lastTakenDate;

  Med({
    required this.name,
    required this.type,
    required this.color,
    required this.time,
    required this.quantity,
    required this.ringtone,
    required this.repeatReminderTime,
    required this.duration,
    this.note = '',
    this.id,
    this.lastTakenDate,
  });

  // Convert Med to JSON (excludes id for auto-increment on insert)
  Map<String, dynamic> toMap({bool includeId = false}) {
    final map = {
      'name': name,
      'type': type,
      'color': '0x${color.value.toRadixString(16)}', // Convert Color to hex string
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}', // Convert TimeOfDay to HH:mm
      'quantity': quantity,
      'ringtone': ringtone,
      'repeatReminderTime': repeatReminderTime,
      'duration': duration.toIso8601String(), // Store DateTime as ISO8601 string
      'note': note,
      'lastTakenDate': lastTakenDate?.toIso8601String(),
    };
    
    if (includeId && id != null) {
      map['id'] = id!;
    }
    
    return map;
  }

  // Create Med from JSON
  factory Med.fromMap(Map<String, dynamic> map) {
    // Parse color from hex string
    final colorValue = int.parse(map['color'] as String);
    final color = Color(colorValue);
    
    // Parse time from HH:mm string
    final timeParts = (map['time'] as String).split(':');
    final time = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
    
    // Parse duration from ISO8601 string
    final duration = DateTime.parse(map['duration'] as String);
    
    return Med(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      color: color,
      time: time,
      quantity: map['quantity'],
      ringtone: map['ringtone'],
      repeatReminderTime: map['repeatReminderTime'],
      duration: duration,
      note: map['note'] ?? '',
      lastTakenDate: map['lastTakenDate'] != null
    ? DateTime.parse(map['lastTakenDate'] as String)
    : null,
    );

    
  }
}

class MedicineDatabase {
  static const String tableName = 'medicines';
  static Database? _database;

// Get medicines with low stock (intelligent detection)
// Shows medicines if:
// - Quantity is less than 3 AND duration is still far away (more than 3 days remaining)
// This helps identify medicines that will run out before the treatment ends
static Future<List<Med>> getLowStockMedicines() async {
  final db = await getDatabase();
  
  // Get all medicines
  final List<Map<String, dynamic>> maps = await db.query(
    tableName,
    orderBy: 'quantity ASC',
  );

  // Filter medicines based on smart logic
  final lowStockMeds = <Med>[];
  final now = DateTime.now();
  
  for (var map in maps) {
    final med = Med.fromMap(map);
    final daysRemaining = med.duration.difference(now).inDays;
    
    // Only show if quantity is less than 5
    // AND quantity won't last the remaining days
    if (med.quantity < 5 && med.quantity < daysRemaining) {
      lowStockMeds.add(med);
    }
  }

  return lowStockMeds;
}
  // Get database instance
  static Future<Database> getDatabase() async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // Initialize database
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'medicines.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            color TEXT NOT NULL,
            time TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            ringtone TEXT NOT NULL,
            repeatReminderTime TEXT NOT NULL,
            duration TEXT NOT NULL,
            note TEXT,
            lastTakenDate TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN lastTakenDate TEXT'
          );
        }
      },
    );
  }

  // 1. Write (Create) medicine to database
  static Future<int> insertMedicine(Med medicine) async {
    final db = await getDatabase();
    return await db.insert(
      tableName,
      medicine.toMap(includeId: false),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 2. Update medicine in database
  static Future<int> updateMedicine(Med medicine) async {
    final db = await getDatabase();
    return await db.update(
      tableName,
      medicine.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  // 3. Delete medicine from database
  static Future<int> deleteMedicine(int id) async {
    final db = await getDatabase();
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 4. Get all medicines from database
  static Future<List<Med>> getAllMedicines() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(tableName);

    return List.generate(
      maps.length,
      (i) => Med.fromMap(maps[i]),
    );
  }

  // Additional helper function: Get medicine by ID
  static Future<Med?> getMedicineById(int id) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Med.fromMap(maps.first);
    }
    return null;
  }

  // Additional helper function: Delete all medicines
  static Future<int> deleteAllMedicines() async {
    final db = await getDatabase();
    return await db.delete(tableName);
  }

  // 5. Get next medicine to take based on current time
  static Future<Med?> getNextMedicine() async {
  final medicines = await getAllMedicines();
  if (medicines.isEmpty) return null;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final currentMinutes = now.hour * 60 + now.minute;

  print('--- getNextMedicine called ---');
  print('now: $now');
  for (final med in medicines) {
    print('${med.name} | lastTakenDate: ${med.lastTakenDate}');
  }

  final notYetTaken = medicines.where((med) {
    final takenToday = med.lastTakenDate != null &&
        DateTime(
          med.lastTakenDate!.year,
          med.lastTakenDate!.month,
          med.lastTakenDate!.day,
        ) == today;
    print('${med.name} takenToday: $takenToday');
    return !takenToday;
  }).toList();

  print('notYetTaken count: ${notYetTaken.length}');

  medicines.sort((a, b) => _compareTimeOfDay(a.time, b.time));

  if (notYetTaken.isEmpty) {
    print('returning medicines.first: ${medicines.first.name}');
    return medicines.first;
  }

  notYetTaken.sort((a, b) => _compareTimeOfDay(a.time, b.time));

  for (final med in notYetTaken) {
    final medMinutes = med.time.hour * 60 + med.time.minute;
    if (medMinutes >= currentMinutes) {
      print('returning: ${med.name}');
      return med;
    }
  }

  print('all times passed, returning: ${medicines.first.name}');
  return medicines.first;
}

  // Helper function to compare TimeOfDay
  static int _compareTimeOfDay(TimeOfDay time1, TimeOfDay time2) {
    final minutes1 = time1.hour * 60 + time1.minute;
    final minutes2 = time2.hour * 60 + time2.minute;
    return minutes1.compareTo(minutes2);
  }
}