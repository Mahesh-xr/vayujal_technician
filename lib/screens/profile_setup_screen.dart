import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vayujal_technician/functions/firebase_profile_action.dart';
import 'package:vayujal_technician/navigation/custom_app_bar.dart';
import 'package:vayujal_technician/widgets/profile/profile_image_picker.dart';
import '../utils/constants.dart';

class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback? onProfileComplete;

  const ProfileSetupScreen({
    Key? key,
    this.onProfileComplete,
  }) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedDesignation = 'Technician';
  XFile? _selectedImage;
  bool _isLoading = false;

  final List<String> _designations = [
    'Technician',
    'Senior Technician',
    'Lead Technician',
    'Supervisor',
    'Manager',
    'Engineer',
    'Senior Engineer',
  ];

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      _emailController.text = user.email!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onImageSelected(XFile? image) {
    setState(() {
      _selectedImage = image;
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmployeeId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Employee ID is required';
    }
    if (value.trim().length < 3) {
      return 'Employee ID must be at least 3 characters';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final phoneRegex = RegExp(r'^[+]?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid mobile number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FirebaseProfileActions.completeProfileSetup(
        name: _nameController.text,
        employeeId: _employeeIdController.text,
        mobileNumber: _mobileController.text,
        email: _emailController.text,
        designation: _selectedDesignation,
        
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppConstants.successColor,
          ),
        );
        
        // Call the callback to notify parent
        if (widget.onProfileComplete != null) {
          widget.onProfileComplete!();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: AppConstants.errorColor,
        ),
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
      backgroundColor: AppConstants.backgroundColor,
      appBar: CustomAppBar(
        title: "Profile Set Up",
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppConstants.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Profile Image Picker
              ProfileImagePicker(
                onImageSelected: _onImageSelected,
                initialImage: _selectedImage,
              ),
              
              const SizedBox(height: 32),
              
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: AppConstants.getInputDecoration(
                  'Name',
                  hint: 'Enter your full name',
                ),
                validator: _validateName,
                textCapitalization: TextCapitalization.words,
              ),
              
              const SizedBox(height: 16),
              
              // Employee ID Field
              TextFormField(
                controller: _employeeIdController,
                decoration: AppConstants.getInputDecoration(
                  'Employee ID',
                  hint: 'Enter your employee ID',
                ),
                validator: _validateEmployeeId,
                textCapitalization: TextCapitalization.characters,
              ),
              
              const SizedBox(height: 16),
              
              // Mobile Number Field
              TextFormField(
                controller: _mobileController,
                decoration: AppConstants.getInputDecoration(
                  'Mobile Number',
                  hint: 'Enter your mobile number',
                ),
                keyboardType: TextInputType.phone,
                validator: _validateMobile,
              ),
              
              const SizedBox(height: 16),
              
              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: AppConstants.getInputDecoration(
                  'Email',
                  hint: 'Enter your email address',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              
              const SizedBox(height: 16),
              
              // Designation Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDesignation,
                decoration: AppConstants.getInputDecoration('Designation'),
                items: _designations.map((String designation) {
                  return DropdownMenuItem<String>(
                    value: designation,
                    child: Text(designation),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedDesignation = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a designation';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppConstants.buttonBorderRadius,
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Required fields note
              const Text(
                '* Required fields',
                style: AppConstants.captionStyle,
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}