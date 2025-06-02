import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vayujal_technician/functions/firebase_profile_action.dart';
import 'package:vayujal_technician/screens/dashboard_screen.dart';
import 'profile_setup_screen.dart';
import 'package:vayujal_technician/screens/login_screen.dart';
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
          // User is logged in, check if profile is complete
          return FutureBuilder<bool>(
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

              if (!isProfileComplete) {
                // Profile not complete, show profile setup
                return ProfileSetupScreen(
                  onProfileComplete: () {
                    // Refresh the auth wrapper to check profile status again
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const AuthWrapper(),
                      ),
                    );
                  },
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

// Example Home Screen (replace with your actual home screen)


// Example Login Screen (replace with your actual login screen)
