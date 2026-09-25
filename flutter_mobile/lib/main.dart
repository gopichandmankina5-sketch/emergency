import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/emergency_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/simulation_provider.dart';
import 'services/fcm_service.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FcmService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => SimulationProvider()),
      ],
      child: const EmergencyCorridorApp(),
    ),
  );
}

class EmergencyCorridorApp extends StatelessWidget {
  const EmergencyCorridorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Emergency Corridor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          surface: Color(0xFF0F172A),
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
