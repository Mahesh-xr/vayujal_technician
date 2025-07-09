import 'package:flutter/material.dart';
import 'package:vayujal_technician/DatabaseActions/adminAction.dart';
import 'package:vayujal_technician/screens/service_hostory_screen.dart';
import 'package:vayujal_technician/utils/submit_botton.dart';


class ServiceDetailsPage extends StatefulWidget {
  final String serviceRequestId;
  
  const ServiceDetailsPage({
    super.key,
    required this.serviceRequestId,
  });

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  Map<String, dynamic>? _serviceRequest;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServiceRequestDetails();
  }

  Future<void> _loadServiceRequestDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic>? serviceRequest = await AdminAction.getServiceRequestById(widget.serviceRequestId);
      setState(() {
        _serviceRequest = serviceRequest;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading service request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      DateTime date;
      if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        date = timestamp.toDate();
      }
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildDetailCard(String title, Widget content) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentDetails() {
    Map<String, dynamic> equipmentDetails = _serviceRequest?['equipmentDetails'] ?? {};
    
    return _buildDetailCard(
      'VJ AWG Details',
      Column(
        children: [
          _buildDetailRow('Model', equipmentDetails['model'] ?? ''),
          _buildDetailRow('Serial Number', equipmentDetails['awgSerialNumber'] ?? ''),
          _buildDetailRow('City', equipmentDetails['city'] ?? ''),
          _buildDetailRow('State', equipmentDetails['state'] ?? ''),
          _buildDetailRow('Owner', equipmentDetails['owner'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildOwnerDetails() {
    Map<String, dynamic> customerDetails = _serviceRequest?['customerDetails'] ?? {};
    
    return _buildDetailCard(
      'Owner Details',
      Column(
        children: [
          _buildDetailRow('Name', customerDetails['name'] ?? ''),
          _buildDetailRow('Company', customerDetails['company'] ?? ''),
          _buildDetailRow('Mobile', customerDetails['phone'] ?? ''),
          _buildDetailRow('Email', customerDetails['email'] ?? ''),
          _buildDetailRow('Address', customerDetails['address']['fullAddress'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildServiceHistory() {
    // Check if service history exists
    Map<String, dynamic> serviceDetails = _serviceRequest?['equipmentDetails']['amcDetails']?? {};
    
    // For now, we'll show basic service information
    // You can extend this to fetch actual service history from a separate collection
    return _buildDetailCard(
      'Service History',
      Column(
        children: [
          _buildDetailRow('AMC Start', (serviceDetails['amcStartDate'] ?? '')),
          _buildDetailRow('AMC End', (serviceDetails['amcEndDate'] ?? '')),
          _buildDetailRow('AMC Type', (serviceDetails['amcType'] ?? '')),
          _buildDetailRow("Annual Contact", (serviceDetails['annualContract'] ? 'yes':'no')),
          SubmitButton(
            text: "View Full History",
            onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceHistoryScreen(serialNumber: _serviceRequest?['deviceId'] ,),
      ),
    );
  })
           
         
        
          
        ],
      ),
    );
  }

  Widget _buildComplaintDetails() {
    Map<String, dynamic> serviceDetails = _serviceRequest?['serviceDetails'] ?? {};
    String requestType = serviceDetails['requestType'] ?? '';
    String description = serviceDetails['description'] ?? '';
    String comments = serviceDetails['comments'] ?? '';
    
    // Only show complaint details if it's a customer complaint
    if (requestType.toLowerCase().contains('complaint') || 
        description.isNotEmpty || 
        comments.isNotEmpty) {
      
      return _buildDetailCard(
        
        'Complaint Details',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) ...[
              const Text(
                'Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (comments.isNotEmpty && comments != description) ...[
              const Text(
                'Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                comments,
                style: const TextStyle(
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Service Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _serviceRequest == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Service request not found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadServiceRequestDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service Request Header
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade600, Colors.blue.shade400],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _serviceRequest?['serviceDetails']?['srId'] ?? 
                                  _serviceRequest?['srId'] ?? 
                                  'Service Request',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Status: ${(_serviceRequest?['serviceDetails']?['status'] ?? _serviceRequest?['status'] ?? 'pending').toString().replaceAll('_', ' ').toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Equipment Details
                        _buildEquipmentDetails(),

                        // Owner Details
                        _buildOwnerDetails(),

                        // Service History
                        _buildServiceHistory(),

                        // Complaint Details (conditional)
                        _buildComplaintDetails(),
                      ],
                    ),
                  ),
                ),
    );
  }
}