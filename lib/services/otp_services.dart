// services/otp_services.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class OtpService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;

  /// Send OTP to the provided phone number
  Future<void> sendOTP({
    required String phoneNumber,
    required VoidCallback onCodeSent,
    required Function(String) onError,
    required Function(PhoneAuthCredential) onVerificationCompleted,
  }) async {
    try {
      // Ensure phone number is in correct format
      String formattedPhoneNumber = _formatPhoneNumber(phoneNumber);
      
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-verification completed (mainly for Android)
          onVerificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = _getErrorMessage(e);
          onError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      onError('Failed to send OTP: $e');
    }
  }

  /// Verify the OTP entered by user
  Future<void> verifyOTP({
    required String otp,
    required Function(String) onError,
    required VoidCallback onSuccess,
  }) async {
    try {
      if (_verificationId == null) {
        onError('Verification ID not found. Please request OTP again.');
        return;
      }

      // Create credential from verification ID and OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Sign in with credential (this verifies the OTP)
      await _auth.signInWithCredential(credential);
      
      // OTP verification successful
      onSuccess();
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getErrorMessage(e);
      onError(errorMessage);
    } catch (e) {
      onError('Verification failed: $e');
    }
  }

  /// Format phone number to international format
  String _formatPhoneNumber(String phoneNumber) {
    // Remove any spaces, dashes, or brackets
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If it starts with +91, return as is
    if (cleaned.startsWith('+91')) {
      return cleaned;
    }
    
    // If it starts with 91, add +
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      return '+$cleaned';
    }
    
    // If it's a 10-digit number, add +91
    if (cleaned.length == 10) {
      return '+91$cleaned';
    }
    
    // Return as is if none of the above conditions match
    return cleaned;
  }

  /// Get user-friendly error messages
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number format is invalid.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check and try again.';
      case 'session-expired':
        return 'OTP has expired. Please request a new one.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed: ${e.message ?? 'Unknown error'}';
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Reset verification ID (useful for resending OTP)
  void resetVerification() {
    _verificationId = null;
    _resendToken = null;
  }
}