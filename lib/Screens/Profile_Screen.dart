import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:job_seeker_app/Screens/settings_screen.dart';
import 'package:job_seeker_app/services/cloudinary_service.dart';
import 'package:job_seeker_app/services/firebase_auth_service.dart';
import 'package:job_seeker_app/theme/app_theme.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  bool _isEditing = false;
  bool _isLoading = false;
  String? _selectedGender;
  DateTime? _selectedDate;
  File? _imageFile;
  String? _currentProfileImageUrl;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = FirebaseAuthService();
    final user = await authService.getCurrentUserData();

    if (!mounted || user == null) {
      return;
    }

    setState(() {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _addressController.text = user.address ?? '';
      _locationController.text = user.location ?? '';
      _currentProfileImageUrl = user.profileImage;
      _userType = user.userType;
    });
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

  Future<void> _pickImage() async {
    if (!_isEditing) {
      return;
    }

    try {
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
    if (!_isEditing) {
      return;
    }

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
      _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded),
            onPressed: () {
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ],
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                AppGlassCard(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
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
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                image: _profileImageProvider == null
                                    ? null
                                    : DecorationImage(
                                        image: _profileImageProvider!,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              child: _profileImageProvider == null
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 52,
                                      color: scheme.primary,
                                    )
                                  : null,
                            ),
                            if (_isEditing)
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 38,
                                  height: 38,
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
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ).animate().scale(
                            duration: 420.ms,
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 18),
                      Text(
                        _nameController.text.isEmpty
                            ? 'Your profile'
                            : _nameController.text,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _emailController.text.isEmpty
                            ? 'Account details'
                            : _emailController.text,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          AppPill(
                            label: _userType ?? 'Member',
                            icon: Icons.badge_outlined,
                            color: scheme.primary,
                          ),
                          AppPill(
                            label: _locationController.text.isEmpty
                                ? 'Location pending'
                                : _locationController.text,
                            icon: Icons.location_on_outlined,
                            color: scheme.secondary,
                          ),
                          AppPill(
                            label: _isEditing ? 'Editing mode' : 'View mode',
                            icon: _isEditing
                                ? Icons.edit_note_rounded
                                : Icons.visibility_outlined,
                            color:
                                _isEditing ? scheme.tertiary : scheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.08),
                const SizedBox(height: 24),
                AppGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(
                        eyebrow: 'Identity',
                        title: 'Personal details',
                        subtitle:
                            'Keep your name and contact details current so people can trust what they see.',
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full name',
                        icon: Icons.person_outline_rounded,
                        enabled: _isEditing,
                        isRequired: true,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.alternate_email_rounded,
                        enabled: false,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone number',
                        icon: Icons.phone_outlined,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      if (_isEditing)
                        DropdownButtonFormField<String>(
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
                        )
                      else
                        _InfoRow(
                          icon: Icons.people_outline_rounded,
                          label: 'Gender',
                          value: _selectedGender ?? 'Not provided yet',
                        ),
                      const SizedBox(height: 14),
                      if (_isEditing)
                        GestureDetector(
                          onTap: _selectDate,
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: _dateController,
                              decoration: const InputDecoration(
                                labelText: 'Date of birth',
                                prefixIcon: Icon(Icons.calendar_month_outlined),
                              ),
                            ),
                          ),
                        )
                      else
                        _InfoRow(
                          icon: Icons.calendar_month_outlined,
                          label: 'Date of birth',
                          value: _dateController.text.isEmpty
                              ? 'Not provided yet'
                              : _dateController.text,
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.08),
                const SizedBox(height: 18),
                AppGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(
                        eyebrow: 'Location',
                        title: 'Where you work',
                        subtitle:
                            'These fields help match you to nearby opportunities and give others the right context.',
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Address',
                        icon: Icons.home_outlined,
                        enabled: _isEditing,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _locationController,
                        label: 'Location',
                        icon: Icons.location_on_outlined,
                        enabled: _isEditing,
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleSave,
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
                              _isLoading ? 'Saving...' : 'Save profile',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.08),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider<Object>? get _profileImageProvider {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    }
    if (_currentProfileImageUrl != null &&
        _currentProfileImageUrl!.isNotEmpty) {
      return NetworkImage(_currentProfileImageUrl!);
    }
    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Future<void> _handleSave() async {
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
      final updateResult = await authService.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        address: _addressController.text.trim(),
        profileImage: imageUrl,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isEditing = false;
        if (imageUrl != null) {
          _currentProfileImageUrl = imageUrl;
          _imageFile = null;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updateResult
                ? 'Profile updated successfully'
                : 'Failed to update profile',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $error')),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Theme.of(context).colorScheme.surface.withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.dark ? 0.34 : 0.5,
            ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
