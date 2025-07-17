import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';

class FirebaseProfileActions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload profile image to Firebase Storage
  static Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      print('=== UPLOAD PROFILE IMAGE START ===');
      
      final User? user = _auth.currentUser;
      print('Current user: ${user?.uid}');
      if (user == null) {
        print('ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      // Create unique filename
      final String fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('Generated filename: $fileName');
      
      // Create storage reference with clean path
      final Reference storageRef = _storage.ref().child('profile_images/$fileName');
      print('Storage reference created: profile_images/$fileName');
      print('Storage bucket: ${_storage.bucket}');
      
      // Validate file
      final file = File(imageFile.path);
      print('File path: ${imageFile.path}');
      print('File exists: ${file.existsSync()}');
      
      if (!file.existsSync()) {
        print('ERROR: File not found at path: ${imageFile.path}');
        throw Exception('File not found at path: ${imageFile.path}');
      }

      // Check file size (max 5MB)
      final int fileSize = await file.length();
      print('File size: $fileSize bytes');
      
      if (fileSize > 5 * 1024 * 1024) {
        print('ERROR: File too large: $fileSize bytes');
        throw Exception('File too large. Maximum size is 5MB');
      }

      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'max-age=3600',
        customMetadata: {
          'uploaded_by': user.uid,
          'upload_time': DateTime.now().toIso8601String(),
        },
      );

      print('Starting upload task...');
      final UploadTask uploadTask = storageRef.putFile(file, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}% (${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes)');
      });

      // Wait for completion
      print('Waiting for upload to complete...');
      final TaskSnapshot snapshot = await uploadTask;
      print('Upload task completed. State: ${snapshot.state}');

      // Get the actual download URL
      print('Getting download URL...');
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Download URL obtained: $downloadUrl');
      print('=== UPLOAD PROFILE IMAGE SUCCESS ===');
      
      return downloadUrl;
      
    } on FirebaseException catch (e) {
      print('=== FIREBASE STORAGE ERROR ===');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
      print('Plugin: ${e.plugin}');
      
      // Handle specific errors
      switch (e.code) {
        case 'object-not-found':
          print('ERROR: Storage bucket not found. Check Firebase configuration.');
          break;
        case 'unauthorized':
          print('ERROR: Unauthorized. Check Firebase Storage rules.');
          break;
        case 'retry-limit-exceeded':
          print('ERROR: Upload failed after retries. Check internet connection.');
          break;
        case 'invalid-checksum':
          print('ERROR: File corrupted during upload.');
          break;
        default:
          print('ERROR: Unknown Firebase error: ${e.code}');
      }
      print('=== FIREBASE STORAGE ERROR END ===');
      return null;
      
    } catch (e) {
      print('=== GENERAL UPLOAD ERROR ===');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('=== GENERAL UPLOAD ERROR END ===');
      return null;
    }
  }

  /// Test Firebase Storage connectivity
  static Future<bool> testStorageConnectivity() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user for storage test');
        return false;
      }

      // Try to get a reference to test connectivity
      final Reference testRef = _storage.ref('test/connectivity_test.txt');
      
      // Try to get metadata (this will fail if storage isn't accessible)
      try {
        await testRef.getMetadata();
        print('Storage connectivity test: PASSED');
        return true;
      } catch (e) {
        if (e is FirebaseException && e.code == 'object-not-found') {
          // This is expected - the test file doesn't exist, but we can access storage
          print('Storage connectivity test: PASSED (storage accessible)');
          return true;
        }
        print('Storage connectivity test: FAILED - $e');
        return false;
      }
    } catch (e) {
      print('Storage connectivity test: ERROR - $e');
      return false;
    }
  }

  /// Complete profile setup with working image upload
  static Future<Map<String, dynamic>> completeProfileSetup({
    required String name,
    required String employeeId,
    required String mobileNumber,
    required String email,
    required String designation,
    XFile? profileImage,
  }) async {
    try {
      String? imageUrl;

      // Debug: Check if image is provided
      print('Profile image provided: ${profileImage != null}');
      if (profileImage != null) {
        print('Image path: ${profileImage.path}');
        print('Image name: ${profileImage.name}');
      }

      // Handle profile image upload if provided
      if (profileImage != null) {
       
        
        final bool isStorageAccessible = await testStorageConnectivity();
        print('Storage accessible: $isStorageAccessible');
        
        if (!isStorageAccessible) {
          print('Storage not accessible - returning error');
          return {
            'success': false,
            'message': 'Cannot access Firebase Storage. Please check your configuration.',
          };
        }

        print('Starting image upload...');
        
        // Upload the image and get the actual URL
        imageUrl = await uploadProfileImage(profileImage);
        print('Upload result: $imageUrl');
        
        if (imageUrl == null) {
          print('Image upload failed - returning error');
          return {
            'success': false,
            'message': 'Failed to upload profile image. Please check your internet connection and try again.',
          };
        }
        
        print('Image uploaded successfully: $imageUrl');
        print('=== IMAGE UPLOAD PROCESS COMPLETED ===');
      } else {
        print('No profile image provided - skipping upload');
      }

      // Save profile data with the actual image URL
      print('Saving profile data...');
      final bool success = await saveTechnicianProfile(
        name: name,
        employeeId: employeeId,
        mobileNumber: mobileNumber,
        email: email,
        designation: designation,
        profileImageUrl: imageUrl, // Use the actual URL, not hardcoded
      );
      
      if (success) {
        print('Profile setup completed successfully');
        return {
          'success': true,
          'message': 'Profile setup completed successfully',
          'imageUrl': imageUrl,
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
        'profileImageUrl': profileImageUrl ?? '',
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

/// Check if user profile is complete
static Future<bool> isProfileComplete() async {
  try {
    final User? user = _auth.currentUser;
    print('Current user: ${user?.uid}');
    
    if (user == null) {
      print('No user found - returning false');
      return false;
    }

    final DocumentSnapshot doc = await _firestore
        .collection(AppConstants.techniciansCollection)
        .doc(user.uid)
        .get();

    print('Document exists: ${doc.exists}');
    
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      print('Document data: $data');
      
      final isComplete = data?['isProfileComplete'] ?? false;
      print('Profile complete status: $isComplete');
      print('=== PROFILE COMPLETION CHECK END ===');
      
      return isComplete;
    }
    
    print('Document does not exist - returning false');
    print('=== PROFILE COMPLETION CHECK END ===');
    return false;
  } catch (e) {
    print('Error checking profile completion: $e');
    print('=== PROFILE COMPLETION CHECK END ===');
    return false;
  }
}

  /// Get technician profile data
  static Future<Map<String, dynamic>?> getTechnicianProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      final DocumentSnapshot doc = await _firestore
          .collection(AppConstants.techniciansCollection)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting technician profile: $e');
      return null;
    }
  }

  /// Update profile completion status
  static Future<bool> updateProfileCompletionStatus(bool isComplete) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection(AppConstants.techniciansCollection)
          .doc(user.uid)
          .update({
        'isProfileComplete': isComplete,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating profile completion status: $e');
      return false;
    }
  }
}