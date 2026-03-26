import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:job_seeker_app/Screens/Login_screen.dart';
import 'package:job_seeker_app/Screens/home_page.dart';
import 'package:job_seeker_app/services/cloudinary_service.dart';
import 'package:job_seeker_app/services/app_settings_service.dart';
import 'package:job_seeker_app/services/firebase_auth_service.dart';
import 'package:job_seeker_app/theme/app_theme.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:job_seeker_app/models/user.dart' as app_user;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.email,
    this.password,
    this.initialUser,
    this.isProfileSetupOnly = false,
  });

  final String email;
  final String? password;
  final app_user.User? initialUser;
  final bool isProfileSetupOnly;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();

  final List<String> _genderOptions = const [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  bool _isLoading = false;
  String? _selectedGender;
  DateTime? _selectedDate;
  File? _imageFile;
  String? _currentProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
    if (widget.initialUser != null) {
      _applyInitialUser(widget.initialUser!);
    }

    if (widget.isProfileSetupOnly && widget.initialUser == null) {
      _loadCurrentUserData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _applyInitialUser(app_user.User user) {
    _nameController.text = user.name;
    _emailController.text = user.email.isNotEmpty ? user.email : widget.email;
    _phoneController.text = user.phone;
    _addressController.text = user.address ?? '';
    _locationController.text = user.location ?? '';
    _selectedGender = user.gender;
    _selectedDate = _parseDateOfBirth(user.dateOfBirth);
    _dateController.text =
        _selectedDate == null ? '' : _formatDateForDisplay(_selectedDate!);
    _currentProfileImageUrl = user.profileImage;
  }

  Future<void> _loadCurrentUserData() async {
    final authService = FirebaseAuthService();
    final user = await authService.getCurrentUserData();

    if (!mounted || user == null) {
      return;
    }

    setState(() {
      _applyInitialUser(user);
    });
  }

  DateTime? _parseDateOfBirth(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  String _formatDateForDisplay(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _pickImage() async {
    try {
      final photoPermission = await Permission.photos.request();
      final storagePermission = await Permission.storage.request();

      final hasPermission =
          photoPermission.isGranted || storagePermission.isGranted;
      if (!hasPermission) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Please grant photo access to add a profile picture.'),
          ),
        );
        return;
      }

      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile == null) {
        return;
      }

      final croppedFile = await _cropImage(pickedFile.path);
      if (croppedFile == null) {
        return;
      }

      setState(() => _imageFile = File(croppedFile.path));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $error')),
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
    } catch (error) {
      if (!mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cropping image: $error')),
      );
      return null;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked;
      _dateController.text = _formatDateForDisplay(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isProfileSetupOnly)
                    IconButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ).animate().fadeIn(duration: 240.ms)
                  else
                    const SizedBox(height: 48),
                  const SizedBox(height: 8),
                  AppPill(
                    label: widget.isProfileSetupOnly
                        ? 'Complete setup'
                        : 'Step 2 of 2',
                    icon: Icons.workspace_premium_outlined,
                    color: scheme.primary,
                  ).animate().fadeIn(delay: 60.ms).slideY(begin: -0.08),
                  const SizedBox(height: 18),
                  Text(
                    widget.isProfileSetupOnly
                        ? 'Complete your profile'
                        : 'Complete the profile that clients and workers will see first.',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.08),
                  const SizedBox(height: 12),
                  Text(
                    widget.isProfileSetupOnly
                        ? 'Add the details needed to finish your first sign-in.'
                        : 'Add the identity and location details that make your account feel credible from day one.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ).animate().fadeIn(delay: 180.ms),
                  const SizedBox(height: 24),
                  AppGlassCard(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 112,
                                height: 112,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      scheme.primary.withValues(alpha: 0.22),
                                      scheme.secondary.withValues(alpha: 0.12),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.52),
                                  ),
                                  image: _imageFile != null
                                      ? DecorationImage(
                                          image: FileImage(_imageFile!),
                                          fit: BoxFit.cover,
                                        )
                                      : _currentProfileImageUrl != null &&
                                              _currentProfileImageUrl!
                                                  .isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                _currentProfileImageUrl!,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                ),
                                child: _imageFile == null &&
                                        (_currentProfileImageUrl == null ||
                                            _currentProfileImageUrl!.isEmpty)
                                    ? Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 36,
                                        color: scheme.primary,
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().scale(
                              duration: 520.ms,
                              curve: Curves.easeOutBack,
                            ),
                        const SizedBox(height: 18),
                        Text(
                          'Add a profile photo',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A clear picture increases trust when people review your messages, applications, and job posts.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.08),
                  const SizedBox(height: 18),
                  AppGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSectionHeader(
                          eyebrow: 'Identity',
                          title: 'Tell people who you are',
                          subtitle:
                              'These details appear throughout the app when you post work or apply for jobs.',
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailController,
                          enabled: !widget.isProfileSetupOnly,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_selectedGender),
                          initialValue: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: Icon(Icons.people_outline_rounded),
                          ),
                          items: _genderOptions
                              .map(
                                (gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedGender = value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your gender';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _selectDate,
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: _dateController,
                              decoration: const InputDecoration(
                                labelText: 'Date of birth',
                                prefixIcon: Icon(Icons.calendar_month_outlined),
                              ),
                              validator: (value) {
                                if (_selectedDate == null) {
                                  return 'Please select your date of birth';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08),
                  const SizedBox(height: 18),
                  AppGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSectionHeader(
                          eyebrow: 'Profile',
                          title: 'Add your details',
                          subtitle:
                              'This helps complete your account and keeps your profile ready for use.',
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            prefixIcon: Icon(Icons.home_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your location';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleRegister,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(
                                    Icons.check_circle_outline_rounded),
                            label: Text(
                              _isLoading
                                  ? (widget.isProfileSetupOnly
                                      ? 'Saving...'
                                      : 'Creating account...')
                                  : (widget.isProfileSetupOnly
                                      ? 'Save and continue'
                                      : 'Create account'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.08),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      if (_imageFile != null) {
        final cloudinaryService = CloudinaryService();
        final uploadResult =
            await cloudinaryService.uploadProfileImage(_imageFile!);

        if (!uploadResult['success']) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to upload image: ${uploadResult['message']}',
              ),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        imageUrl = uploadResult['data'];
      }

      final authService = FirebaseAuthService();
      final dateOfBirth = _selectedDate?.toIso8601String();

      final bool success;
      String? failureMessage;
      if (widget.isProfileSetupOnly) {
        success = await authService.completeProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          location: _locationController.text.trim(),
          address: _addressController.text.trim(),
          profileImage: imageUrl ?? _currentProfileImageUrl,
          gender: _selectedGender,
          dateOfBirth: dateOfBirth,
        );
        if (!success) {
          failureMessage = 'Failed to complete profile';
        }
      } else {
        final result = await authService.register(
          email: _emailController.text.trim(),
          password: widget.password!,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          location: _locationController.text.trim(),
          address: _addressController.text.trim(),
          profileImage: imageUrl,
          gender: _selectedGender,
          dateOfBirth: dateOfBirth,
        );
        success = result['success'] == true;
        if (!success) {
          failureMessage = result['message']?.toString();
        }
      }

      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);

      if (success) {
        await AppSettingsService.instance.setSkipAppLockOnce(true);

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isProfileSetupOnly
                  ? 'Profile completed successfully'
                  : 'Registration successful',
            ),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failureMessage ??
                (widget.isProfileSetupOnly
                    ? 'Failed to complete profile'
                    : 'Registration failed'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during registration: $error')),
      );
    }
  }
}
