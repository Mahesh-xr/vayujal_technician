import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:vayujal_technician/screens/resolution.dart';

class StartServiceScreen extends StatefulWidget {
  final String srNumber;
  final String customerComplaint;
  final String awgSerialNumber; // Added AWG serial number

  const StartServiceScreen({
    Key? key,
    required this.srNumber,
    required this.customerComplaint,
    required this.awgSerialNumber, // Added AWG serial number
  }) : super(key: key);

  @override
  State<StartServiceScreen> createState() => _StartServiceScreenState();
}

class _StartServiceScreenState extends State<StartServiceScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _complaintOthersController = TextEditingController();
  final TextEditingController _issueOthersController = TextEditingController();
  
  // Image files
  File? _leftViewImage;
  File? _rightViewImage;
  File? _frontViewImage;

  File? _issueImage;
  
  // Dropdown values
  String? _selectedComplaintType;
  String? _selectedIssueType;
  
  // Loading states
  bool _isUploading = false;
  bool _leftViewUploading = false;
  bool _rightViewUploading = false;
  bool _issuePhotoUploading = false;
  bool _frontViewUploading = false;

  // Dropdown options
  static List<String> _complaintTypes = [
    'Refrigeration', 'Filtration', 'Mechanical', 'General Service', 'Others'
  ];

  static List<String> _issueTypes = [
    'Machine start', 'Machine trip', 'LP trip', 'HP trip', 'PP error', 'Tank full error'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Start Service',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 16.0),
        //     child: Image.asset(
        //       'assets/vayujal_logo.png', // Replace with your logo path
        //       height: 30,
        //     ),
        //   ),
        // ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // SR Number (Read-only)
            _buildReadOnlyField('SR Number', widget.srNumber),
            const SizedBox(height: 16),
            
            // Customer Complaint (Read-only)
            _buildReadOnlyField('Customer Complaint', widget.customerComplaint),
            const SizedBox(height: 24),

             _buildPhotoSection(
              'Front View',
              _frontViewImage,
              _frontViewUploading,
              () => _pickImage('front'),
            ),
            const SizedBox(height: 24),
            
            // Left View Photo Section
            _buildPhotoSection(
              'Left View',
              _leftViewImage,
              _leftViewUploading,
              () => _pickImage('left'),
            ),
            const SizedBox(height: 16),
            
            // Right View Photo Section
            _buildPhotoSection(
              'Right View',
              _rightViewImage,
              _rightViewUploading,
              () => _pickImage('right'),
            ),
            const SizedBox(height: 24),

            
            
            // Complaint Details Section
            _buildSectionTitle('Complaint Details'),
            const Text(
              'Select related components',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // Complaint Related to Dropdown
            _buildDropdownField(
              'Complaint Related to',
              _selectedComplaintType,
              _complaintTypes,
              (value) => setState(() => _selectedComplaintType = value),
            ),
            
            // Show "Mention if Others" field for complaint type
            if (_selectedComplaintType == 'Others')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildTextField(
                  'Mention if Others',
                  _complaintOthersController,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Type of Raised Issue Dropdown
            _buildDropdownField(
              'Type of Raised Issue',
              _selectedIssueType,
              _issueTypes,
              (value) => setState(() => _selectedIssueType = value),
            ),
            
            // Show "Mention if Others" field for issue type
            if (_selectedIssueType == 'Others')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildTextField(
                  'Mention if Others',
                  _issueOthersController,
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Issue Photos Section
            _buildSectionTitle('Upload Issue Photos'),
            _buildPhotoSection(
              '',
              _issueImage,
              _issuePhotoUploading,
              () => _pickImage('issue'),
            ),
            const SizedBox(height: 32),
            
            // Continue to Resolution Button
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveServiceData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Continue to Resolution',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(String title, File? image, bool isUploading, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (title.isNotEmpty) const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 210, // Reduced from 120
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    image,
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 6), // Reduced from 8
                    Text(
                      'No Photos uploaded',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12, // Reduced from 14
                      ),
                    ),
                    const SizedBox(height: 8), // Reduced from 12
                    ElevatedButton(
                      onPressed: isUploading ? null : onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), // Reduced padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: isUploading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Upload Photos',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: const Text('Select'),
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          switch (type) {
            case 'left':
              _leftViewImage = File(image.path);
              break;
            case 'right':
              _rightViewImage = File(image.path);
              break;
            case 'issue':
              _issueImage = File(image.path);
              break;
            case 'front':
              _frontViewImage = File(image.path);
          }
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile, String imageName) async {
    try {
      String fileName = '${widget.srNumber}_$imageName.jpg';
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('service_requests')
          .child(widget.srNumber)
          .child(fileName);

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveServiceData() async {
    // Validate required fields
    if (_selectedComplaintType == null || _selectedIssueType == null) {
      _showErrorDialog('Please fill in all required fields');
      return;
    }

    if (_selectedComplaintType == 'Others' && _complaintOthersController.text.trim().isEmpty) {
      _showErrorDialog('Please specify the complaint type');
      return;
    }

    if (_selectedIssueType == 'Others' && _issueOthersController.text.trim().isEmpty) {
      _showErrorDialog('Please specify the issue type');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Upload images
      String? leftViewUrl;
      String? rightViewUrl;
      String? issueImageUrl;
      String? frontViewUrl;

      if (_leftViewImage != null) {
        leftViewUrl = await _uploadImageToFirebase(_leftViewImage!, 'left_view');
      }

      if (_rightViewImage != null) {
        rightViewUrl = await _uploadImageToFirebase(_rightViewImage!, 'right_view');
      }

      if (_issueImage != null) {
        issueImageUrl = await _uploadImageToFirebase(_issueImage!, 'issue_photo');
      }
      if (_frontViewImage != null) {
        frontViewUrl = await _uploadImageToFirebase(_frontViewImage!, 'front_view');
      }

      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      final FirebaseAuth _auth = FirebaseAuth.instance;
      final user = _auth.currentUser;
    
          final doc = await _firestore.collection('technicians').doc(user?.uid).get();
          final data = doc.data() as Map<String, dynamic>;
          String technician = data['name'] ?? 'Unknown Technician';
          String empId = data['employeeId'] ?? 'Unknown Employee ID';
        
      
      // Prepare data for Firestore
      Map<String, dynamic> serviceData = {
        'technician':technician ,
        'empId':empId,
        'srNumber': widget.srNumber,
        'customerComplaint': widget.customerComplaint,
        'complaintRelatedTo': _selectedComplaintType,
        'typeOfRaisedIssue': _selectedIssueType,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'in_progress',
        'awgSerialNumber':widget.awgSerialNumber, // Added AWG serial number
      };

      // Add image URLs if available
      if (leftViewUrl != null) serviceData['leftViewImageUrl'] = leftViewUrl;
      if (rightViewUrl != null) serviceData['rightViewImageUrl'] = rightViewUrl;
      if (issueImageUrl != null) serviceData['issueImageUrl'] = issueImageUrl;
      if (frontViewUrl != null) serviceData['frontViewImageUrl'] = frontViewUrl;

      // Add others text if applicable
      if (_selectedComplaintType == 'Others') {
        serviceData['complaintOthersText'] = _complaintOthersController.text.trim();
      }
      if (_selectedIssueType == 'Others') {
        serviceData['issueOthersText'] = _issueOthersController.text.trim();
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('serviceHistory')
          .doc(widget.srNumber)
          .set(serviceData, SetOptions(merge: true));

      // Navigate to resolution screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResolutionPage(
            srNumber: widget.srNumber,
          ),
        ),
      );

    } catch (e) {
      _showErrorDialog('Error saving data: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _complaintOthersController.dispose();
    _issueOthersController.dispose();
    super.dispose();
  }
}

// Placeholder for Resolution Screen
