import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vayujal_technician/DatabaseActions/service_history_modals/service_history_modal.dart';
import 'package:vayujal_technician/navigation/custom_app_bar.dart';

// Add the ServiceDetail model here or import it
class ServiceDetail {
  final String? acknowledgmentStatus;
  final DateTime? acknowledgmentTimestamp;
  final String? awgSerialNumber;
  final String? complaintRelatedTo;
  final String? customSuggestions;
  final String? customerComplaint;
  final String? frontViewImageUrl;
  final String? issueIdentification;
  final String? issueImageUrl;
  final String? issueType;
  final String? leftViewImageUrl;
  final DateTime? nextServiceDate;
  final String? partsReplaced;
  final String? resolutionImageUrl;
  final DateTime? resolutionTimestamp;
  final String? resolvedBy;
  final String? rightViewImageUrl;
  final String? serialNumber;
  final String? solutionProvided;
  final String? srNumber;
  final String? status;
  final Map<String, bool>? suggestions;
  final DateTime? timestamp;
  final String? typeOfRaisedIssue;

  ServiceDetail({
    this.acknowledgmentStatus,
    this.acknowledgmentTimestamp,
    this.awgSerialNumber,
    this.complaintRelatedTo,
    this.customSuggestions,
    this.customerComplaint,
    this.frontViewImageUrl,
    this.issueIdentification,
    this.issueImageUrl,
    this.issueType,
    this.leftViewImageUrl,
    this.nextServiceDate,
    this.partsReplaced,
    this.resolutionImageUrl,
    this.resolutionTimestamp,
    this.resolvedBy,
    this.rightViewImageUrl,
    this.serialNumber,
    this.solutionProvided,
    this.srNumber,
    this.status,
    this.suggestions,
    this.timestamp,
    this.typeOfRaisedIssue,
  });

  factory ServiceDetail.fromFirestore(Map<String, dynamic> data) {
    return ServiceDetail(
      acknowledgmentStatus: data['acknowledgmentStatus'] as String?,
      acknowledgmentTimestamp: data['acknowledgmentTimestamp']?.toDate(),
      awgSerialNumber: data['awgSerialNumber'] as String?,
      complaintRelatedTo: data['complaintRelatedTo'] as String?,
      customSuggestions: data['customSuggestions'] as String?,
      customerComplaint: data['customerComplaint'] as String?,
      frontViewImageUrl: data['frontViewImageUrl'] as String?,
      issueIdentification: data['issueIdentification'] as String?,
      issueImageUrl: data['issueImageUrl'] as String?,
      issueType: data['issueType'] as String?,
      leftViewImageUrl: data['leftViewImageUrl'] as String?,
      nextServiceDate: data['nextServiceDate']?.toDate(),
      partsReplaced: data['partsReplaced'] as String?,
      resolutionImageUrl: data['resolutionImageUrl'] as String?,
      resolutionTimestamp: data['resolutionTimestamp']?.toDate(),
      resolvedBy: data['resolvedBy'] as String?,
      rightViewImageUrl: data['rightViewImageUrl'] as String?,
      serialNumber: data['serialNumber'] as String?,
      solutionProvided: data['solutionProvided'] as String?,
      srNumber: data['srNumber'] as String?,
      status: data['status'] as String?,
      suggestions: data['suggestions'] != null 
          ? Map<String, bool>.from(data['suggestions']) 
          : null,
      timestamp: data['timestamp']?.toDate(),
      typeOfRaisedIssue: data['typeOfRaisedIssue'] as String?,
    );
  }
}

class ServiceDetailScreen extends StatefulWidget {
  final String srNumber;

  const ServiceDetailScreen({super.key, required this.srNumber});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ServiceDetail? serviceDetail;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchServiceDetail();
  }

  Future<void> _fetchServiceDetail() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Query serviceHistory collection where awgSerialNumber equals service.srNumber
      final querySnapshot = await FirebaseFirestore.instance
          .collection('serviceHistory')
          .where('srNumber', isEqualTo: widget.srNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        setState(() {
          serviceDetail = ServiceDetail.fromFirestore(doc.data());
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'No service details found for SR Number: ${widget.srNumber}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching service details: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(title: "Service Details"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red[600], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchServiceDetail,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(serviceDetail?.status ?? 'pending'),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (serviceDetail?.status ?? 'pending').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Service Request Details Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Service Request: ${serviceDetail?.srNumber ?? 'N/A'}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow('AWG Serial Number', serviceDetail?.awgSerialNumber ?? 'N/A'),
                              _buildInfoRow('Serial Number', serviceDetail?.serialNumber ?? 'N/A'),
                              _buildInfoRow('Complaint Related To', serviceDetail?.complaintRelatedTo ?? 'N/A'),
                              _buildInfoRow('Issue Type', serviceDetail?.issueType ?? 'N/A'),
                              _buildInfoRow('Issue Identification', serviceDetail?.issueIdentification ?? 'N/A'),
                              _buildInfoRow('Type of Raised Issue', serviceDetail?.typeOfRaisedIssue ?? 'N/A'),
                              _buildInfoRow('Acknowledgment Status', serviceDetail?.acknowledgmentStatus ?? 'N/A'),
                              if (serviceDetail?.resolvedBy != null)
                                _buildInfoRow('Resolved By', serviceDetail!.resolvedBy!),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Customer Complaint & Solution
                      SizedBox(
                        width: 440,
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Customer Complaint & Resolution',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 12),
                                _buildSectionHeader('Customer Complaint:'),
                                Text(serviceDetail?.customerComplaint ?? 'No complaint details available'),
                                const SizedBox(height: 12),
                                _buildSectionHeader('Solution Provided:'),
                                Text(serviceDetail?.solutionProvided ?? 'No solution details available'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Parts Replaced
                      if (serviceDetail?.partsReplaced != null && serviceDetail!.partsReplaced!.isNotEmpty)
                        SizedBox(
                          width: 440,
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Text(
                                    'Parts Replaced',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('• ${serviceDetail!.partsReplaced}'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Service Images
                      if (_hasAnyImage())
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Service Images',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 12),
                                
                                // Issue Image
                                if (serviceDetail?.issueImageUrl != null && serviceDetail!.issueImageUrl!.isNotEmpty)
                                  _buildImageSection('Issue Photo', serviceDetail!.issueImageUrl!),
                                
                                // Resolution Image
                                if (serviceDetail?.resolutionImageUrl != null && serviceDetail!.resolutionImageUrl!.isNotEmpty)
                                  _buildImageSection('Resolution Photo', serviceDetail!.resolutionImageUrl!),
                                
                                // Unit Views
                                if (serviceDetail?.frontViewImageUrl != null && serviceDetail!.frontViewImageUrl!.isNotEmpty)
                                  _buildImageSection('Front View', serviceDetail!.frontViewImageUrl!),
                                
                                if (serviceDetail?.leftViewImageUrl != null && serviceDetail!.leftViewImageUrl!.isNotEmpty)
                                  _buildImageSection('Left View', serviceDetail!.leftViewImageUrl!),
                                
                                if (serviceDetail?.rightViewImageUrl != null && serviceDetail!.rightViewImageUrl!.isNotEmpty)
                                  _buildImageSection('Right View', serviceDetail!.rightViewImageUrl!),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Technician Suggestions
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Technician Suggestions',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              
                              // Custom Suggestions
                              if (serviceDetail?.customSuggestions != null && serviceDetail!.customSuggestions!.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionHeader('Custom Suggestions:'),
                                    Text(serviceDetail!.customSuggestions!),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              
                              // Standard Suggestions Checklist
                              if (serviceDetail?.suggestions != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionHeader('Standard Maintenance Suggestions:'),
                                    _buildSuggestionItem('Keep air filter clean', serviceDetail!.suggestions?['keepAirFilterClean'] ?? false),
                                    _buildSuggestionItem('Keep away from smells', serviceDetail!.suggestions?['keepAwayFromSmells'] ?? false),
                                    _buildSuggestionItem('Protect from sun and rain', serviceDetail!.suggestions?['protectFromSunAndRain'] ?? false),
                                    _buildSuggestionItem('Supply stable electricity', serviceDetail!.suggestions?['supplyStableElectricity'] ?? false),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Timestamps
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Service Timeline',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              if (serviceDetail?.timestamp != null)
                                _buildTimestampRow('Service Requested', serviceDetail!.timestamp!),
                              if (serviceDetail?.resolutionTimestamp != null)
                                _buildTimestampRow('Service Resolved', serviceDetail!.resolutionTimestamp!),
                              if (serviceDetail?.acknowledgmentTimestamp != null)
                                _buildTimestampRow('Acknowledgment', serviceDetail!.acknowledgmentTimestamp!),
                              if (serviceDetail?.nextServiceDate != null)
                                _buildTimestampRow('Next Service Due', serviceDetail!.nextServiceDate!),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  bool _hasAnyImage() {
    return (serviceDetail?.issueImageUrl?.isNotEmpty ?? false) ||
           (serviceDetail?.resolutionImageUrl?.isNotEmpty ?? false) ||
           (serviceDetail?.frontViewImageUrl?.isNotEmpty ?? false) ||
           (serviceDetail?.leftViewImageUrl?.isNotEmpty ?? false) ||
           (serviceDetail?.rightViewImageUrl?.isNotEmpty ?? false);
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
      ),
    );
  }

  Widget _buildImageSection(String title, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSuggestionItem(String text, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isChecked ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildTimestampRow(String label, DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              '${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}