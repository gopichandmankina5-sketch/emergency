import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/emergency_provider.dart';
import 'services/fcm_service.dart';
import 'screens/emergency_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
      ],
      child: const EmergencyVehicleApp(),
    ),
  );

  try {
    await FcmService().initialize();
  } catch (e) {
    debugPrint('[main] FcmService initialization warning: $e');
  }
}

class EmergencyVehicleApp extends StatelessWidget {
  const EmergencyVehicleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Vehicle Dispatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFDC2626),
          surface: Color(0xFF0F172A),
        ),
        useMaterial3: true,
      ),
      home: const EmergencyDashboardScreen(),
    );
  }
}
