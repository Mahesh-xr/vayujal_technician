// screens/service_acknowledgment_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vayujal_technician/models/service_acknowledgement_model.dart';
import 'package:vayujal_technician/services/pdf_service.dart';

class ServiceAcknowledgmentScreen extends StatefulWidget {
  final String srNumber;

  const ServiceAcknowledgmentScreen({Key? key, required this.srNumber}) : super(key: key);

  @override
  State<ServiceAcknowledgmentScreen> createState() => _ServiceAcknowledgmentScreenState();
}

class _ServiceAcknowledgmentScreenState extends State<ServiceAcknowledgmentScreen> {
  ServiceAcknowledgmentModel? _serviceData;
  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadServiceData();
    print("navigation to resolution sucessfull");
  }

  Future<void> _loadServiceData() async {
    try {
      // Load data from both collections
      final serviceRequestDoc = await FirebaseFirestore.instance
          .collection('serviceRequests')
          .where('srId', isEqualTo: widget.srNumber)
          .get();

      final serviceHistoryDoc = await FirebaseFirestore.instance
          .collection('serviceHistory')
          .where('srNumber', isEqualTo: widget.srNumber)
          .get();

      if (serviceRequestDoc.docs.isNotEmpty && serviceHistoryDoc.docs.isNotEmpty) {
        setState(() {
          _serviceData = ServiceAcknowledgmentModel.fromFirestore(
            serviceRequestDoc.docs.first.data(),
            serviceHistoryDoc.docs.first.data(),
          );
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

  Future<void> _generateAndDownloadPdf() async {
    if (_serviceData == null) return;

    setState(() {
      _isGeneratingPdf = true;
      _errorMessage = null;
    });

    try {
      // Generate PDF
      final pdfFile = await PdfService.generateServiceAcknowledgmentPdf(_serviceData!);
      
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
        const SnackBar(content: Text('Service acknowledgment PDF generated successfully!')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating PDF: $e';
        _isGeneratingPdf = false;
      });
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Acknowledgment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _serviceData == null
              ? Center(child: Text(_errorMessage ?? 'Service data not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Summary
                      _buildSection(
                        'Service Summary',
                        [
                          _buildInfoRow('SR Number', _serviceData!.srNumber),
                          _buildInfoRow('Service Date', _formatDate(_serviceData!.serviceDate)),
                          _buildInfoRow('Next Service Date', _formatDate(_serviceData!.nextServiceDate)),
                        ],
                      ),

                      // AWG Details
                      _buildSection(
                        'AWG Details',
                        [
                          _buildInfoRow('Model', _serviceData!.awgDetails.model),
                          _buildInfoRow('Serial Number', _serviceData!.awgDetails.serialNumber),
                        ],
                      ),

                      // Customer Details
                      _buildSection(
                        'Customer Details',
                        [
                          _buildInfoRow('Name', _serviceData!.customerDetails.name),
                          _buildInfoRow('Phone Number', _serviceData!.customerDetails.phone),
                          _buildInfoRow('Company', _serviceData!.customerDetails.company),
                          _buildInfoRow('Address', _serviceData!.customerDetails.fullAddress),
                        ],
                      ),

                      // Parts Replaced
                      _buildSection(
                        'Parts Replaced',
                        [
                          Text(_serviceData!.partsReplaced),
                          const SizedBox(height: 8),
                          const Text('Serial Number: if available'),
                        ],
                      ),

                      // Service Images
                      if (_serviceData!.images.issueImageUrl != null || 
                          _serviceData!.images.resolutionImageUrl != null)
                        _buildSection(
                          'Service Images',
                          [
                            _buildImageRow('Issue Photo', _serviceData!.images.issueImageUrl),
                            _buildImageRow('Resolution Photo', _serviceData!.images.resolutionImageUrl),
                          ],
                        ),

                      // Suggestions
                      _buildSection(
                        'Suggestions',
                        [
                          _buildSuggestionItem('Keep Air Filter Clean', _serviceData!.suggestions.keepAirFilterClean),
                          _buildSuggestionItem('Keep Away From Smells', _serviceData!.suggestions.keepAwayFromSmells),
                          _buildSuggestionItem('Protect From Sun And Rain', _serviceData!.suggestions.protectFromSunAndRain),
                          _buildSuggestionItem('Supply Stable Electricity', _serviceData!.suggestions.supplyStableElectricity),
                          if (_serviceData!.customSuggestions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Additional: ${_serviceData!.customSuggestions}'),
                            ),
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
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildImageRow(String label, String? imageUrl) {
    if (imageUrl == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String text, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: isSelected ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(text),
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
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Text(
                  'Download Service Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}