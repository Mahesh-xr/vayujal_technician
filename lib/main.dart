import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:vayujal_technician/firebase_options.dart';
import 'package:vayujal_technician/screens/dashboard_screen.dart';
import 'package:vayujal_technician/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Required to initialize Flutter engine
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      routes: {
    '/home': (context) => const DashboardScreen(),
    // '/alldevice': (context) => const DevicesScreen(),
    // '/profile': (context) => const ProfileListScreen(),
    // '/history': (context) => const HistoryScreen(),
    // '/notifications': (context) => const NotificationScreen(),
  },
      debugShowCheckedModeBanner: false,
    );
  }
}
