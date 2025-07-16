import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ResolutionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload resolution image to Firebase Storage
  Future<String> uploadResolutionImage(String srNumber, File imageFile) async {
    try {
      // Create reference to storage location
      final storageRef = _storage.ref().child('service_requests/$srNumber/${srNumber}_resolution.jpg');
      
      // Upload file
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload resolution image: $e');
    }
  }

  // Update serviceHistory document with resolution data
  Future<void> updateServiceHistoryWithResolution({
    required String srNumber,
    required String serialNumber,
    required String issueIdentification,
    required String issueType,
    required String solutionProvided,
    required String partsReplaced,
    required String resolutionImageUrl,
    required DateTime nextServiceDate,
    required Map<String, bool> suggestions,
    required String customSuggestions,
    required String status,
  }) async {
    try {
      // Get current user (technician)
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Find the existing serviceHistory document
      final querySnapshot = await _firestore
          .collection('serviceHistory')
          .where('srNumber', isEqualTo: srNumber)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Service request not found');
      }

      final docId = querySnapshot.docs.first.id;

      // Update the document with resolution data
      await _firestore.collection('serviceHistory').doc(docId).update({
        'serialNumber': serialNumber,
        'issueIdentification': issueIdentification,
        'issueType': issueType,
        'solutionProvided': solutionProvided,
        'partsReplaced': partsReplaced,
        'resolutionImageUrl': resolutionImageUrl,
        'nextServiceDate': Timestamp.fromDate(nextServiceDate),
        'suggestions': suggestions,
        'customSuggestions': customSuggestions,
        'status': status,
        'resolutionTimestamp': FieldValue.serverTimestamp(),
        'resolvedBy': currentUser.uid,
      });
      await _firestore.collection('serviceRequests').doc(srNumber).update({
        'status': status,
        'resolvedBy': currentUser.uid,
        'resolutionTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update service history: $e');
    }
  }

  // Complete resolution process (upload image + update database)
  Future<void> completeResolution({
    required String srNumber,
    required String serialNumber,
    required String issueIdentification,
    required String issueType,
    required String solutionProvided,
    required String partsReplaced,
    required File? resolutionImage,
    required DateTime nextServiceDate,
    required Map<String, bool> suggestions,
    required String customSuggestions,
    required String status, required List<File> resolutionImages, File? resolutionVideo, required String issueOthers, required String partsOthers,
  }) async {
    try {
      String resolutionImageUrl = '';
      
      // Upload resolution image if provided
      if (resolutionImage != null) {
        resolutionImageUrl = await uploadResolutionImage(srNumber, resolutionImage);
      }

      // Update serviceHistory document
      await updateServiceHistoryWithResolution(
        srNumber: srNumber,
        serialNumber: serialNumber,
        issueIdentification: issueIdentification,
        issueType: issueType,
        solutionProvided: solutionProvided,
        partsReplaced: partsReplaced,
        resolutionImageUrl: resolutionImageUrl,
        nextServiceDate: nextServiceDate,
        suggestions: suggestions,
        customSuggestions: customSuggestions,
        status: status,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get image from camera or gallery
  Future<File?> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Get existing service request data
  Future<Map<String, dynamic>?> getServiceRequestData(String srNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('serviceHistory')
          .where('srNumber', isEqualTo: srNumber)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get service request data: $e');
    }
  }
}