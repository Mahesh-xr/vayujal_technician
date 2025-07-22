import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vayujal_technician/models/service_acknowledgement_model.dart';
import 'package:vayujal_technician/navigation/NormalAppBar.dart';
import 'package:vayujal_technician/services/pdf_service.dart';

class ServiceAcknowledgmentScreen extends StatefulWidget {
  final String srNumber;

  const ServiceAcknowledgmentScreen({Key? key, required this.srNumber}) : super(key: key);

  @override
  State<ServiceAcknowledgmentScreen> createState() => _ServiceAcknowledgmentScreenState();
}

class _ServiceAcknowledgmentScreenState extends State<ServiceAcknowledgmentScreen> {
  Map<String, dynamic>? _serviceRequestData;
  Map<String, dynamic>? _serviceHistoryData;
  Map<String, dynamic>? _technicianData;
  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadServiceData();
    print("Navigation to service acknowledgment successful");
  }

  Future<void> _loadServiceData() async {
    try {
      // Load service request data
      final serviceRequestQuery = await FirebaseFirestore.instance
          .collection('serviceRequests')
          .where('srId', isEqualTo: widget.srNumber)
          .get();

      // Load service history data
      final serviceHistoryQuery = await FirebaseFirestore.instance
          .collection('serviceHistory')
          .where('srNumber', isEqualTo: widget.srNumber)
          .get();

      if (serviceRequestQuery.docs.isNotEmpty && serviceHistoryQuery.docs.isNotEmpty) {
        _serviceRequestData = serviceRequestQuery.docs.first.data();
        _serviceHistoryData = serviceHistoryQuery.docs.first.data();

        // Load technician data
        final technicianId = _serviceHistoryData!['resolvedBy'] ?? _serviceHistoryData!['technician'];
        if (technicianId != null) {
          final technicianQuery = await FirebaseFirestore.instance
              .collection('technicians')
              .where('uid', isEqualTo: technicianId)
              .get();
          
          if (technicianQuery.docs.isNotEmpty) {
            _technicianData = technicianQuery.docs.first.data();
          }
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Service data not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading service data: $e';
        _isLoading = false;
      });
    }
  }

 // Update the _generateAndDownloadPdf method in your ServiceAcknowledgmentScreen

Future<void> _generateAndDownloadPdf() async {
  if (_serviceRequestData == null || _serviceHistoryData == null) return;

  setState(() {
    _isGeneratingPdf = true;
    _errorMessage = null;
  });

  try {
    // Generate PDF using the updated method
    final pdfFile = await PdfService.generateServiceAcknowledgmentPdf(
      _serviceRequestData!,
      _serviceHistoryData!,
      _technicianData,
    );
    
    // Share/Download PDF
    await PdfService.shareAcknowledgmentPdf(pdfFile);
    
    // Update acknowledgment status in Firestore
    await FirebaseFirestore.instance
        .collection('serviceHistory')
        .where('srNumber', isEqualTo: widget.srNumber)
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        doc.reference.update({
          'acknowledgmentStatus': 'downloaded',
          'acknowledgmentTimestamp': FieldValue.serverTimestamp(),
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Service acknowledgment PDF generated successfully!'),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  } catch (e) {
    setState(() {
      _errorMessage = 'Error generating PDF: $e';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error generating PDF: $e'),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 5),
      ),
    );
  } finally {
    setState(() {
      _isGeneratingPdf = false;
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Normalappbar(
        title: 'Service Acknowledgment'
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _serviceRequestData == null || _serviceHistoryData == null
              ? Center(child: Text(_errorMessage ?? 'Service data not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Summary Section
                      _buildSection(
                        'Service Summary',
                        [
                          _buildInfoRow('SR Number', widget.srNumber),
                          _buildInfoRow('Service Date', _formatTimestamp(_serviceHistoryData!['timestamp'])),
                          _buildInfoRow('Next Service Date', _formatTimestamp(_serviceHistoryData!['nextServiceDate'])),
                          _buildInfoRow('Status', _serviceHistoryData!['status'] ?? 'Completed'),
                          _buildInfoRow('Technician', _getTechnicianName()),
                        ],
                      ),

                      // AWG/Device Details Section
                      _buildSection(
                        'AWG Details',
                        [
                          _buildInfoRow('Serial Number', _serviceHistoryData!['awgSerialNumber'] ?? 'N/A'),
                          _buildInfoRow('Model', _serviceHistoryData!['model'] ?? 'N/A'),
                        ],
                      ),

                      // Customer Details Section
                      _buildSection(
                        'Customer Details',
                        [
                          _buildInfoRow('Name', _serviceRequestData!['serviceDetails']?['customerName'] ?? 'N/A'),
                          _buildInfoRow('Phone Number', _serviceRequestData!['serviceDetails']?['customerPhoneNumber'] ?? 'N/A'),
                          _buildInfoRow('Company', _serviceRequestData!['serviceDetails']?['companyName'] ?? 'N/A'),
                          _buildInfoRow('Address', _getFullAddress()),
                        ],
                      ),

                      // Service Details Section
                      _buildSection(
                        'Service Details',
                        [
                          _buildInfoRow('Issue Identification', _serviceHistoryData!['issueIdentification'] ?? 'N/A'),
                          _buildInfoRow('Parts Replaced', _serviceHistoryData!['partsReplaced'] ?? 'N/A'),
                          _buildInfoRow('Complaint Related To', _serviceHistoryData!['complaintRelatedTo'] ?? 'N/A'),
                          _buildInfoRow('Customer Complaint', _serviceHistoryData!['customerComplaint'] ?? 'N/A'),
                          _buildInfoRow('Solution Provided', _serviceHistoryData!['solutionProvided'] ?? 'N/A'),
                          _buildInfoRow('Request Type', _serviceRequestData!['requestType'] ?? 'N/A'),
                        ],
                      ),

                      // Service Images Section (Issue and Resolution only)
                      if (_hasServiceImages())
                        _buildSection(
                          'Service Images',
                          [
                            _buildImageRow('Issue Photo', _getIssueImageUrl()),
                            _buildImageRow('Resolution Photo', _serviceHistoryData!['resolutionImageUrl']),
                          ],
                        ),

                      // Maintenance Suggestions Section
                      _buildSection(
                        'Maintenance Suggestions',
                        [
                          _buildSuggestionItem('Keep Air Filter Clean', _serviceHistoryData!['suggestions']?['keepAirFilterClean'] ?? false),
                          _buildSuggestionItem('Keep Away From Smells', _serviceHistoryData!['suggestions']?['keepAwayFromSmells'] ?? false),
                          _buildSuggestionItem('Protect From Sun And Rain', _serviceHistoryData!['suggestions']?['protectFromSunAndRain'] ?? false),
                          _buildSuggestionItem('Supply Stable Electricity', _serviceHistoryData!['suggestions']?['supplyStableElectricity'] ?? false),
                          if (_serviceHistoryData!['customSuggestions'] != null && _serviceHistoryData!['customSuggestions'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Additional Suggestions: ${_serviceHistoryData!['customSuggestions']}'),
                            ),
                        ],
                      ),

                      // Service Timeline Section
                      _buildSection(
                        'Service Timeline',
                        [
                          _buildInfoRow('Request Created', _formatTimestamp(_serviceRequestData!['createddate'])),
                          _buildInfoRow('Service Delayed At', _formatTimestamp(_serviceRequestData!['delayedAt'])),
                          _buildInfoRow('Resolution Time', _formatTimestamp(_serviceHistoryData!['resolutionTimestamp'])),
                          if (_serviceHistoryData!['acknowledgmentTimestamp'] != null)
                            _buildInfoRow('Acknowledgment Time', _formatTimestamp(_serviceHistoryData!['acknowledgmentTimestamp'])),
                        ],
                      ),

                      // Download PDF Section
                      _buildDownloadSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getSectionIcon(title),
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Service Summary':
        return Icons.summarize;
      case 'AWG Details':
        return Icons.devices;
      case 'Customer Details':
        return Icons.person;
      case 'Service Details':
        return Icons.build;
      case 'Service Images':
        return Icons.photo_library;
      case 'Maintenance Suggestions':
        return Icons.lightbulb;
      case 'Service Timeline':
        return Icons.timeline;
      case 'Download Service Report':
        return Icons.download;
      default:
        return Icons.info;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageRow(String label, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      Text('Failed to load image'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String text, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: isSelected ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.green[700] : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.download,
                  color: Colors.green[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Download Service Report',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const Text(
                  'Generate and download the service acknowledgment PDF report',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingPdf ? null : _generateAndDownloadPdf,
                    icon: _isGeneratingPdf
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isGeneratingPdf ? 'Generating PDF...' : 'Download PDF Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        date = DateTime.parse(timestamp);
      } catch (e) {
        return timestamp;
      }
    } else {
      return 'N/A';
    }
    
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getTechnicianName() {
    if (_technicianData != null) {
      return _technicianData!['fullName'] ?? _technicianData!['name'] ?? 'N/A';
    }
    return _serviceHistoryData!['technician'] ?? 'N/A';
  }

  String _getFullAddress() {
    final serviceDetails = _serviceRequestData!['serviceDetails'];
    if (serviceDetails == null) return 'N/A';
    
    final List<String> addressParts = [];
    
    if (serviceDetails['address'] != null) addressParts.add(serviceDetails['address']);
    if (serviceDetails['city'] != null) addressParts.add(serviceDetails['city']);
    if (serviceDetails['state'] != null) addressParts.add(serviceDetails['state']);
    if (serviceDetails['pincode'] != null) addressParts.add(serviceDetails['pincode']);
    
    return addressParts.isNotEmpty ? addressParts.join(', ') : 'N/A';
  }

  bool _hasServiceImages() {
    return _getIssueImageUrl() != null || _serviceHistoryData!['resolutionImageUrl'] != null;
  }

  String? _getIssueImageUrl() {
    final issueImageUrls = _serviceHistoryData!['issueImageUrls'];
    if (issueImageUrls != null && issueImageUrls is List && issueImageUrls.isNotEmpty) {
      return issueImageUrls[0];
    }
    return null;
  }
}