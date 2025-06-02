// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:vayujal_technician/firebase_options.dart';
// import 'package:vayujal_technician/screens/dashboard_screen.dart';
// import 'package:vayujal_technician/screens/splash_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   FlutterError.onError = (FlutterErrorDetails details) {
//     FlutterError.dumpErrorToConsole(details);
//   };

//   try {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//     runApp(const MyApp());
//   } catch (e, stackTrace) {
//     print('Error during initialization: $e');
//     print(stackTrace);
//   }
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Device Management',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: const SplashScreen(),
//       routes: {
//     '/home': (context) => const DashboardScreen(),
//     // '/alldevice': (context) => const DevicesScreen(),
//     // '/profile': (context) => const ProfileListScreen(),
//     // '/history': (context) => const HistoryScreen(),
//     // '/notifications': (context) => const NotificationScreen(),
//   },
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vayujal_technician/firebase_options.dart';
import 'screens/auth_wrapper.dart';
import 'utils/constants.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized(); // ✅ Required to initialize Flutter engine
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );

   
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Technician App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppConstants.textPrimaryColor,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: AppConstants.buttonBorderRadius,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
