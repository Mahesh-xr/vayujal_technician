import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks and updates service requests that have passed their deadline
  /// Updates status from 'pending' or 'in_progress' to 'delayed'
  static Future<void> checkAndUpdateDelayedServiceRequests(String employeeId) async {
    try {
      final DateTime now = DateTime.now();
      
      // Get all service requests for the employee that are not completed
      QuerySnapshot serviceRequestsSnapshot = await _firestore
          .collection('serviceRequests')
          .where('serviceDetails.assignedTo', isEqualTo: employeeId)
          .where('status', whereIn: ['pending', 'in_progress'])
          .get();

      List<String> delayedRequestIds = [];
      List<WriteBatch> batches = [];
      WriteBatch currentBatch = _firestore.batch();
      int batchCount = 0;
      
      for (QueryDocumentSnapshot doc in serviceRequestsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final serviceDetails = data['serviceDetails'] as Map<String, dynamic>?;
        print(serviceDetails);
        if (serviceDetails != null) {
          // Get the deadline from serviceDetails
          final deadlineTimestamp = serviceDetails['addressByDate'];
          print('afghgkjhsadgbsdkjfngskdjhgn:  ${deadlineTimestamp}');
          
          if (deadlineTimestamp != null) {
            DateTime deadline;
            
            // Handle different timestamp formats
            if (deadlineTimestamp is Timestamp) {
              deadline = deadlineTimestamp.toDate();
            } else if (deadlineTimestamp is String) {
              deadline = DateTime.parse(deadlineTimestamp);
            } else {
              continue; // Skip if deadline format is unknown
            }
            
            // Check if deadline has passed
            if (now.isAfter(deadline)) {
              delayedRequestIds.add(doc.id);
              
              // Update the service request status to 'delayed'
              currentBatch.update(doc.reference, {
                'status': 'delayed',
                'serviceDetails.delayedAt': FieldValue.serverTimestamp(),
                'serviceDetails.lastStatusUpdate': FieldValue.serverTimestamp(),
              });
              
              batchCount++;
              
              // Firestore batch limit is 500 operations
              if (batchCount >= 500) {
                batches.add(currentBatch);
                currentBatch = _firestore.batch();
                batchCount = 0;
              }
            }
          }
        }
      }

      // Add the last batch if it has operations
      if (batchCount > 0) {
        batches.add(currentBatch);
      }

      // Execute all batches
      for (WriteBatch batch in batches) {
        await batch.commit();
      }

      // Create notifications for delayed requests
      if (delayedRequestIds.isNotEmpty) {
        await _createDelayedNotifications(employeeId, delayedRequestIds);
      }

      print('Successfully updated ${delayedRequestIds.length} service requests to delayed status');
      
    } catch (e) {
      print('Error in checkAndUpdateDelayedServiceRequests: $e');
      rethrow;
    }
  }

  /// Creates notifications for delayed service requests
  static Future<void> _createDelayedNotifications(String employeeId, List<String> delayedRequestIds) async {
    try {
      // Get technician details
      DocumentSnapshot technicianDoc = await _firestore
          .collection('technicians')
          .doc(employeeId)
          .get();

      if (!technicianDoc.exists) return;

      final technicianData = technicianDoc.data() as Map<String, dynamic>;
      final technicianName = technicianData['name'] ?? 'Unknown Technician';

      // Create notification for admin
      await _firestore.collection('notifications').add({
        'type': 'delayed_service_requests',
        'title': 'Service Requests Delayed',
        'message': '$technicianName has ${delayedRequestIds.length} service request(s) that have passed their deadline',
        'recipientRole': 'admin',
        'senderId': employeeId,
        'senderName': technicianName,
        'data': {
          'employeeId': employeeId,
          'delayedRequestIds': delayedRequestIds,
          'delayedCount': delayedRequestIds.length,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Optional: Create notification for the technician as well
      await _firestore.collection('notifications').add({
        'type': 'delayed_reminder',
        'title': 'Service Requests Overdue',
        'message': 'You have ${delayedRequestIds.length} service request(s) that have passed their deadline',
        'recipientId': employeeId,
        'recipientRole': 'technician',
        'data': {
          'delayedRequestIds': delayedRequestIds,
          'delayedCount': delayedRequestIds.length,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print('Error creating delayed notifications: $e');
      // Don't rethrow here as notification failure shouldn't break the main process
    }
  }

  /// Alternative method that also returns the count of updated requests
  static Future<int> checkAndUpdateDelayedServiceRequestsWithCount(String employeeId) async {
    try {
      final DateTime now = DateTime.now();
      
      QuerySnapshot serviceRequestsSnapshot = await _firestore
          .collection('serviceRequests')
          .where('serviceDetails.assignedTo', isEqualTo: employeeId)
          .where('serviceDetails.status', whereIn: ['pending', 'in_progress'])
          .get();

      List<String> delayedRequestIds = [];
      WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot doc in serviceRequestsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final serviceDetails = data['serviceDetails'] as Map<String, dynamic>?;
        
        if (serviceDetails != null) {
          final deadlineTimestamp = serviceDetails['addressByDate'];
          print(deadlineTimestamp);
          
          if (deadlineTimestamp != null) {
            DateTime deadline;
            
            if (deadlineTimestamp is Timestamp) {
              deadline = deadlineTimestamp.toDate();
            } else if (deadlineTimestamp is String) {
              deadline = DateTime.parse(deadlineTimestamp);
            } else {
              continue;
            }
            
            if (now.isAfter(deadline)) {
              delayedRequestIds.add(doc.id);
              
              batch.update(doc.reference, {
                'serviceDetails.status': 'delayed',
                'serviceDetails.delayedAt': FieldValue.serverTimestamp(),
                'serviceDetails.lastStatusUpdate': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      }

      if (delayedRequestIds.isNotEmpty) {
        await batch.commit();
        await _createDelayedNotifications(employeeId, delayedRequestIds);
      }

      return delayedRequestIds.length;
      
    } catch (e) {
      print('Error in checkAndUpdateDelayedServiceRequestsWithCount: $e');
      rethrow;
    }
  }

  /// Helper method to get service requests by status (if not already implemented)
  static Future<List<Map<String, dynamic>>> getEmployeeServiceRequestsByStatus(
    String employeeId, 
    String status
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('service_requests')
          .where('assignedTechnician', isEqualTo: employeeId)
          .where('serviceDetails.status', isEqualTo: status)
          .orderBy('serviceDetails.assignedDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
    } catch (e) {
      print('Error getting service requests by status: $e');
      rethrow;
    }
  }

  /// Helper method to get all service requests for an employee (if not already implemented)
  static Future<List<Map<String, dynamic>>> getEmployeeServiceRequests(String employeeId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('service_requests')
          .where('assignedTechnician', isEqualTo: employeeId)
          .orderBy('serviceDetails.assignedDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
    } catch (e) {
      print('Error getting employee service requests: $e');
      rethrow;
    }
  }
}