import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:job_seeker_app/services/cloudinary_service.dart';
import 'package:job_seeker_app/services/firebase_job_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';
import 'package:permission_handler/permission_handler.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  static const int _maxJobPhotos = 6;

  final _formKey = GlobalKey<FormState>();
  final FirebaseJobService _jobService = FirebaseJobService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedEndTime;
  bool _isPosting = false;
  bool _isFetchingLocation = false;
  final List<File> _jobImages = [];

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedEndDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedEndTime) {
      setState(() {
        _selectedEndTime = picked;
      });
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSnackBarAction({
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: actionLabel,
          onPressed: onAction,
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    if (_isFetchingLocation) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isFetchingLocation = true;
    });

    try {
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        _showSnackBarAction(
          message: 'Location services are disabled.',
          actionLabel: 'Enable',
          onAction: () {
            Geolocator.openLocationSettings();
          },
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permission denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBarAction(
          message: 'Location permission permanently denied.',
          actionLabel: 'Settings',
          onAction: () {
            Geolocator.openAppSettings();
          },
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String resolvedLocation;
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addressParts = <String>[
          if (place.subLocality?.trim().isNotEmpty ?? false)
            place.subLocality!.trim(),
          if (place.locality?.trim().isNotEmpty ?? false)
            place.locality!.trim(),
          if (place.administrativeArea?.trim().isNotEmpty ?? false)
            place.administrativeArea!.trim(),
          if (place.country?.trim().isNotEmpty ?? false) place.country!.trim(),
        ];

        resolvedLocation = addressParts.join(', ');
      } else {
        resolvedLocation =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      }

      _locationController.text = resolvedLocation;
    } catch (_) {
      _showSnackBar('Unable to fetch current location. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  Future<void> _pickJobImages() async {
    try {
      final photoPermission = await Permission.photos.request();
      final storagePermission = await Permission.storage.request();
      final hasPermission =
          photoPermission.isGranted || storagePermission.isGranted;

      if (!hasPermission) {
        _showSnackBar('Please grant photo access to add workplace photos.');
        return;
      }

      final remainingSlots = _maxJobPhotos - _jobImages.length;
      if (remainingSlots <= 0) {
        _showSnackBar('You can upload up to $_maxJobPhotos photos per post.');
        return;
      }

      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: 75,
        maxWidth: 1440,
        maxHeight: 1440,
      );

      if (pickedFiles.isEmpty) {
        return;
      }

      final existingPaths = _jobImages.map((file) => file.path).toSet();
      final filesToAdd = <File>[];

      for (final pickedFile in pickedFiles) {
        if (existingPaths.contains(pickedFile.path)) {
          continue;
        }
        if (filesToAdd.length >= remainingSlots) {
          break;
        }

        existingPaths.add(pickedFile.path);
        filesToAdd.add(File(pickedFile.path));
      }

      if (filesToAdd.isEmpty) {
        _showSnackBar('No new photos were added.');
        return;
      }

      setState(() => _jobImages.addAll(filesToAdd));

      final skippedCount = pickedFiles.length - filesToAdd.length;
      if (skippedCount > 0) {
        _showSnackBar(
          'Added ${filesToAdd.length} photos. $skippedCount were skipped because of duplicates or the $_maxJobPhotos-photo limit.',
        );
      }
    } catch (error) {
      _showSnackBar('Error picking job photos: $error');
    }
  }

  void _removeJobImage(int index) {
    if (index < 0 || index >= _jobImages.length) {
      return;
    }

    setState(() => _jobImages.removeAt(index));
  }

  Future<List<String>> _uploadJobImages() async {
    if (_jobImages.isEmpty) {
      return const [];
    }

    final imageUrls = <String>[];

    for (final imageFile in _jobImages) {
      final uploadResult = await _cloudinaryService.uploadJobImage(imageFile);
      if (uploadResult['success'] != true || uploadResult['data'] == null) {
        throw uploadResult['message'] ??
            'Failed to upload one of the job photos';
      }

      imageUrls.add(uploadResult['data'].toString());
    }

    return imageUrls;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        prefixText: prefixText,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Job Details',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _titleController,
                            label: 'Job Title',
                            icon: Icons.work_outline,
                            hint: 'e.g. Home Cleaning Service',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            icon: Icons.description_outlined,
                            hint: 'Describe the job requirements...',
                            maxLines: 4,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Workplace Photos',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Add up to $_maxJobPhotos photos of the place or the work so people can inspect the post before they apply.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[700],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _isPosting ? null : _pickJobImages,
                                icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                ),
                                label: Text(
                                  _jobImages.isEmpty ? 'Add' : 'More',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_jobImages.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                              ),
                              child: Text(
                                'No photos selected yet. They will appear when users open the post.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: List.generate(
                                _jobImages.length,
                                (index) => _buildJobPhotoPreview(index),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            '${_jobImages.length}/$_maxJobPhotos photos selected',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _locationController,
                            label: 'Location',
                            icon: Icons.location_on_outlined,
                            hint: 'Enter job location',
                            suffixIcon: _isFetchingLocation
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    tooltip: 'Use current location',
                                    onPressed: _useCurrentLocation,
                                    icon:
                                        const Icon(Icons.my_location_outlined),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _selectDate,
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Date',
                                      prefixIcon: const Icon(
                                        Icons.calendar_today_outlined,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      _selectedDate != null
                                          ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                                          : 'Select Date',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: _selectTime,
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Time',
                                      prefixIcon: const Icon(
                                        Icons.access_time_outlined,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      _selectedTime != null
                                          ? _selectedTime!.format(context)
                                          : 'Select Time',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _selectEndDate,
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'End Date (Optional)',
                                      prefixIcon: const Icon(
                                        Icons.event_busy_outlined,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      _selectedEndDate != null
                                          ? "${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}"
                                          : 'Default: +24 hours',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: _selectEndTime,
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'End Time (Optional)',
                                      prefixIcon: const Icon(
                                        Icons.timelapse_outlined,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      _selectedEndTime != null
                                          ? _selectedEndTime!.format(context)
                                          : 'Default: +24 hours',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'If not set, this opportunity will expire in 24 hours.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _budgetController,
                            label: 'Budget',
                            icon: Icons.attach_money_outlined,
                            hint: 'Enter budget',
                            keyboardType: TextInputType.number,
                            prefixText: '\$ ',
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().slideY(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPosting ? null : _handlePostJob,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isPosting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Post Job',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  )
                      .animate()
                      .fadeIn()
                      .slideY(delay: const Duration(milliseconds: 200)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobPhotoPreview(int index) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _jobImages[index],
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: _isPosting ? null : () => _removeJobImage(index),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePostJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }

    DateTime? expiresAt;
    final isPartialEndInput =
        (_selectedEndDate == null) != (_selectedEndTime == null);
    if (isPartialEndInput) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both end date and end time')),
      );
      return;
    }
    if (_selectedEndDate != null && _selectedEndTime != null) {
      expiresAt = _combineDateAndTime(_selectedEndDate!, _selectedEndTime!);
      if (!expiresAt.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('End date and time must be in the future')),
        );
        return;
      }
    }

    setState(() => _isPosting = true);

    try {
      final time =
          '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      final budget = double.tryParse(_budgetController.text) ?? 0.0;
      final imageUrls = await _uploadJobImages();

      final result = await _jobService.postJob(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        date: _selectedDate!,
        time: time,
        budget: budget,
        expiresAt: expiresAt,
        imageUrls: imageUrls,
      );

      setState(() => _isPosting = false);

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job posted successfully!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to post job')),
          );
        }
      }
    } catch (e) {
      setState(() => _isPosting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    }
  }
}
