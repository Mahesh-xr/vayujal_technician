import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';

class FirebaseProfileActions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;


  /// Complete profile setup with working image upload
  static Future<Map<String, dynamic>> completeProfileSetup({
    required String name,
    required String employeeId,
    required String mobileNumber,
    required String email,
    required String designation,
    required String profileImage,
  }) async {
    try {
     
      
      print('Saving profile data...');
      final bool success = await saveTechnicianProfile(
        name: name,
        employeeId: employeeId,
        mobileNumber: mobileNumber,
        email: email,
        designation: designation,
        profileImageUrl:profileImage ,
      );
      
      if (success) {
        print('Profile setup completed successfully');
        return {
          'success': true,
          'message': 'Profile setup completed successfully',
          'imageUrl':profileImage ,
        };
      } else {
        print('Failed to save profile data');
        return {
          'success': false,
          'message': 'Failed to save profile data. Please try again.',
        };
      }
    } catch (e) {
      print('Error in completeProfileSetup: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Save technician profile data to Firestore
  static Future<bool> saveTechnicianProfile({
    required String name,
    required String employeeId,
    required String mobileNumber,
    required String email,
    required String designation,
    String? profileImageUrl,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final Map<String, dynamic> profileData = {
        'uid': user.uid,
        'name': name.trim(),
        'employeeId': employeeId.trim(),
        'mobileNumber': mobileNumber.trim(),
        'email': email.trim(),
        'designation': designation.trim(),
        'profileImageUrl': profileImageUrl,
        'isProfileComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(AppConstants.techniciansCollection)
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      print('Profile data saved successfully');
      return true;
    } catch (e) {
      print('Error saving technician profile: $e');
      return false;
    }
  }

}