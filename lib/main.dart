import 'package:flutter/material.dart';
import 'med_cards.dart';
import '/models/med_model.dart';
import 'add_medicine_page.dart';
import 'next_med.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'services/alarm_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await AlarmService.initialize(navigatorKey);
  runApp(const VelocityApp());
}

class VelocityApp extends StatelessWidget {
  const VelocityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Meditor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFFF0F4FF),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _refreshCounter = 0;

  void _refreshMedicineList() {
    setState(() {
      _refreshCounter++;
    });
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Velocity',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Stay on track with your health',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),

                // Low Stock Notification
                FutureBuilder<List<Med>>(
                  key: ValueKey('low_stock_$_refreshCounter'),
                  future: MedicineDatabase.getLowStockMedicines(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final lowStockMeds = snapshot.data!;
                    final now = DateTime.now();
                    return Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: Colors.orange.shade600,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange.shade700, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Running low on medication',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...lowStockMeds.map((med) {
                                  final daysLeft =
                                      med.duration.difference(now).inDays;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '• ${med.name}: ${med.quantity} left, $daysLeft days remaining',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Next Medicine Card
                FutureBuilder<Med?>(
                  future: MedicineDatabase.getNextMedicine(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: buildNextMedicineCard(snapshot.data!),
                    );
                  },
                ),

                // All Medications Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Medications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Calendar view coming soon...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(Icons.calendar_today,
                          color: Colors.purple.shade600, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Medicine List
                FutureBuilder<List<Med>>(
                  key: ValueKey(_refreshCounter),
                  future: MedicineDatabase.getAllMedicines(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No medicines added yet'));
                    }
                    return buildMedicationsSection(
                      medicines: snapshot.data!,
                      onMedicineListChanged: _refreshMedicineList,
                      context: context,
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Disclaimer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Important: Press "Med Taken" only when you\'ve actually taken it. This is for your health.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMedicinePage(
                onAdded: _refreshMedicineList,
              ),
            ),
          );
        },
        backgroundColor: Colors.purple.shade600,
        icon: const Icon(Icons.add, size: 28),
        label: const Text('Add',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        elevation: 8,
      ),
    );
  }
}