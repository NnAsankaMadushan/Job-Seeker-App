import 'package:job_seeker_app/Screens/Login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import '../widgets/social_button.dart';
import 'home_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:job_seeker_app/services/cloudinary_service.dart';
import 'package:job_seeker_app/services/firebase_auth_service.dart';
import 'package:job_seeker_app/theme/app_theme.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

class RegisterScreen extends StatefulWidget {
  final String email;
  final String password;

  const RegisterScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _selectedGender;
  String? _selectedUserType;
  DateTime? _selectedDate;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _userTypeOptions = ['Job Seeker', 'Job Provider'];

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-fill email from previous screen
    _emailController.text = widget.email;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Request permissions first
      final status = await Permission.storage.request();
      final cameraStatus = await Permission.camera.request();
      
      if (status.isGranted && cameraStatus.isGranted) {
        final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 75,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        
        if (pickedFile != null) {
          final croppedFile = await _cropImage(pickedFile.path);
          if (croppedFile != null) {
            setState(() {
              _imageFile = File(croppedFile.path);
            });
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please grant the required permissions')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<CroppedFile?> _cropImage(String sourcePath) async {
    try {
      return await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: AppTheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cropping image: $e')),
      );
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Complete Profile',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppGlassCard(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.16),
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : null,
                                child: _imageFile == null
                                    ? Icon(
                                        Icons.person_add_alt_1_rounded,
                                        size: 50,
                                        color: Theme.of(context).colorScheme.primary,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().scale().fadeIn(),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ).animate().fadeIn().slideX(),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 200.ms).slideX(),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 280.ms).slideX(),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: Icon(Icons.people_outline),
                          ),
                          value: _selectedGender,
                          hint: const Text('Select Gender'),
                          items: _genderOptions.map((String gender) {
                            return DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your gender';
                            }
                            return null;
                          },
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedGender = newValue;
                            });
                          },
                        ).animate().fadeIn(delay: 360.ms).slideX(),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Date of Birth',
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              validator: (value) {
                                if (_selectedDate == null) {
                                  return 'Please select your date of birth';
                                }
                                return null;
                              },
                              controller: TextEditingController(
                                text: _selectedDate != null
                                    ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                                    : "",
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 460.ms).slideX(),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            prefixIcon: Icon(Icons.home_outlined),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your address';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 540.ms).slideX(),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your location';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 620.ms).slideX(),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'User Type',
                            prefixIcon: Icon(Icons.work_outline),
                          ),
                          value: _selectedUserType,
                          hint: const Text('Select User Type'),
                          items: _userTypeOptions.map((String type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select user type';
                            }
                            return null;
                          },
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedUserType = newValue;
                            });
                          },
                        ).animate().fadeIn(delay: 700.ms).slideX(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Create Account'),
                          ),
                        ).animate().fadeIn(delay: 860.ms).slideY(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        String? imageUrl;

        // Upload image to Cloudinary if selected
        if (_imageFile != null) {
          final cloudinaryService = CloudinaryService();
          final uploadResult = await cloudinaryService.uploadProfileImage(_imageFile!);

          if (uploadResult['success']) {
            imageUrl = uploadResult['data'];
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to upload image: ${uploadResult['message']}')),
              );
            }
            setState(() => _isLoading = false);
            return;
          }
        }

        // Register user with Firebase
        final authService = FirebaseAuthService();
        final result = await authService.register(
          email: _emailController.text.trim(),
          password: widget.password,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          userType: _selectedUserType!,
          location: _locationController.text.trim(),
          address: _addressController.text.trim(),
          profileImage: imageUrl,
        );

        setState(() => _isLoading = false);

        if (result['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful!')),
            );

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Registration failed: ${result['message']}')),
            );
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error during registration: $e')),
          );
        }
      }
    }
  }
}
