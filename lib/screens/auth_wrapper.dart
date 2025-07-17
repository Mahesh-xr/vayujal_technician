import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vayujal_technician/functions/firebase_profile_action.dart';
import 'package:vayujal_technician/screens/dashboard_screen.dart';
import 'profile_setup_screen.dart';
import 'package:vayujal_technician/screens/login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // ✅ FIXED: Added a key to force rebuild when profile is completed
  Key _profileCheckKey = UniqueKey();

  void _onProfileComplete() {
    setState(() {
      _profileCheckKey = UniqueKey(); // Force rebuild
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder<bool>(
            key: _profileCheckKey, // ✅ FIXED: Added key for proper rebuild
            future: FirebaseProfileActions.isProfileComplete(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final bool isProfileComplete = profileSnapshot.data ?? false;
              
              print('Profile completion check: $isProfileComplete'); // Debug log

              if (!isProfileComplete) {
                // Profile not complete, show profile setup
                return ProfileSetupScreen(
                  onProfileComplete: _onProfileComplete, // ✅ FIXED: Use local callback
                );
              } else {
                // Profile complete, show main app
                return const DashboardScreen();
              }
            },
          );
        } else {
          // User not logged in, show login screen
          return const LoginScreen();
        }
      },
    );
  }
}