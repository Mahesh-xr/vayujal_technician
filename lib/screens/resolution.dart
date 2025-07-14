import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:vayujal_technician/screens/dbforresolution.dart';
import 'package:vayujal_technician/screens/service_acknowlwdgement_screen.dart.dart';

class ResolutionPage extends StatefulWidget {
  final String srNumber;
  
  const ResolutionPage({Key? key, required this.srNumber}) : super(key: key);

  @override
  State<ResolutionPage> createState() => _ResolutionPageState();
}

class _ResolutionPageState extends State<ResolutionPage> {
  final ResolutionService _resolutionService = ResolutionService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _issueTypeController = TextEditingController();
  final TextEditingController _solutionController = TextEditingController();
  final TextEditingController _customSuggestionsController = TextEditingController();
  
  // Form data
  String _selectedIssue = '';
  String _selectedParts = '';
  File? _resolutionImage;
  DateTime _nextServiceDate = DateTime.now().add(Duration(days: 30));
  
  // Suggestions checkboxes
  Map<String, bool> _suggestions = {
    'keepAirFilterClean': false,
    'supplyStableElectricity': false,
    'keepAwayFromSmells': false,
    'protectFromSunAndRain': false,
  };
  
  // Status
  String _selectedStatus = 'pending';
  bool _isLoading = false;

  // Issue options
  final List<String> _issueOptions = [
    'Adapter',
    'OLR',
    'Contactor',
    'LP/HP switch',
    'LED',
  ];

  // Parts options
  final List<String> _partsOptions = [
    'ROCKER SWITCH',
    'RED DPST',
    'BLUE DPST',
    'PUSH LOCK BUTTON',
  ];

  @override
  void initState() {
    super.initState();
    _loadServiceRequestData();
  }

  // Load existing service request data
  Future<void> _loadServiceRequestData() async {
    try {
      final data = await _resolutionService.getServiceRequestData(widget.srNumber);
      if (data != null) {
        // You can pre-fill any existing data here if needed
        setState(() {
          // Pre-fill any existing resolution data
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  // Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _resolutionService.pickImage(source);
      if (image != null) {
        setState(() {
          _resolutionImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Show image picker dialog
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Select next service date
  Future<void> _selectNextServiceDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextServiceDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _nextServiceDate) {
      setState(() {
        _nextServiceDate = picked;
      });
    }
  }

  // Submit resolution
  Future<void> _submitResolution() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedIssue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an issue')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _resolutionService.completeResolution(
        srNumber: widget.srNumber,
        serialNumber: _serialNumberController.text,
        issueIdentification: _selectedIssue,
        issueType: _issueTypeController.text,
        solutionProvided: _solutionController.text,
        partsReplaced: _selectedParts,
        resolutionImage: _resolutionImage,
        nextServiceDate: _nextServiceDate,
        suggestions: _suggestions,
        customSuggestions: _customSuggestionsController.text,
        status: _selectedStatus,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resolution submitted successfully!')),
      );

      // Navigate back or to next screen
      Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ServiceAcknowledgmentScreen(
      srNumber:widget.srNumber ,
    ),
  ),
);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting resolution: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resolution'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Request Information
                    _buildSection(
                      title: 'Service Request Information',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SR Number: ${widget.srNumber}', style: TextStyle(fontWeight: FontWeight.w500)),
                          SizedBox(height: 16),
                          
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Issue Identification
                    _buildSection(
                      title: 'Issue Identification',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Identified issues'),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedIssue.isEmpty ? null : _selectedIssue,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Select',
                            ),
                            items: _issueOptions.map((issue) => DropdownMenuItem(
                              value: issue,
                              child: Text(issue),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedIssue = value ?? '';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select an issue';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          Text('Type of identified issue'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _issueTypeController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Mention if others.',
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('Solution Provided'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _solutionController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Describe the solution provided',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please describe the solution';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Parts Replacement
                    _buildSection(
                      title: 'Parts Replacement',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enter parts replaced details'),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedParts.isEmpty ? null : _selectedParts,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Select',
                            ),
                            items: _partsOptions.map((part) => DropdownMenuItem(
                              value: part,
                              child: Text(part),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedParts = value ?? '';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Upload Resolution Photos
                    _buildSection(
                      title: 'Upload Post Resolution Photos',
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _resolutionImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _resolutionImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('No Photos uploaded', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _showImagePickerDialog,
                                  child: Text('Upload Photos'),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _pickImage(ImageSource.camera),
                                  child: Text('Take Photos'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Next Service Date
                    _buildSection(
                      title: 'Next Service date',
                      child: InkWell(
                        onTap: _selectNextServiceDate,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd-MM-yyyy').format(_nextServiceDate)),
                              Icon(Icons.calendar_today, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Suggestions
                    _buildSection(
                      title: 'Suggestions',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Provide customer suggestions'),
                          SizedBox(height: 16),
                          ..._suggestions.entries.map((entry) => CheckboxListTile(
                            title: Text(_getSuggestionText(entry.key)),
                            value: entry.value,
                            onChanged: (value) {
                              setState(() {
                                _suggestions[entry.key] = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          )),
                          SizedBox(height: 16),
                          Text('Custom Suggestions'),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _customSuggestionsController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter any additional suggestions',
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Status
                    _buildSection(
                      title: 'Status',
                      child: Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: Text('Completed'),
                              value: _selectedStatus == 'completed',
                              onChanged: (value) {
                                if (value == true) {
                                  setState(() {
                                    _selectedStatus = 'completed';
                                  });
                                }
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: Text('Pending'),
                              value: _selectedStatus == 'pending',
                              onChanged: (value) {
                                if (value == true) {
                                  setState(() {
                                    _selectedStatus = 'pending';
                                  });
                                }
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: Text('Ongoing'),
                              value: _selectedStatus == 'ongoing',
                              onChanged: (value) {
                                if (value == true) {
                                  setState(() {
                                    _selectedStatus = 'ongoing';
                                  });
                                }
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 30),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitResolution,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Continue to Customer Acknowledgement'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  String _getSuggestionText(String key) {
    switch (key) {
      case 'keepAirFilterClean':
        return 'Keep Air Filter Clean';
      case 'supplyStableElectricity':
        return 'Supply stable electricity';
      case 'keepAwayFromSmells':
        return 'Keep the machine away from smelly areas';
      case 'protectFromSunAndRain':
        return 'Protect from direct sunlight & rain water ingression.';
      default:
        return key;
    }
  }

  @override
  void dispose() {
    _serialNumberController.dispose();
    _issueTypeController.dispose();
    _solutionController.dispose();
    _customSuggestionsController.dispose();
    super.dispose();
  }
}