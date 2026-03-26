import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:job_seeker_app/Screens/job_location_picker_screen.dart';
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
  JobLocationSelection? _selectedLocation;
  final List<File> _jobImages = [];

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

  Future<void> _pickExactLocation() async {
    FocusScope.of(context).unfocus();

    final selection = await Navigator.of(context).push<JobLocationSelection>(
      MaterialPageRoute(
        builder: (_) => JobLocationPickerScreen(
          initialSelection: _selectedLocation,
        ),
      ),
    );

    if (selection == null || !mounted) {
      return;
    }

    setState(() {
      _selectedLocation = selection;
    });
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
                          AppGlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppDecoratedIcon(
                                      icon: Icons.map_outlined,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.14),
                                      size: 50,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Location',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _isPosting ? null : _pickExactLocation,
                                    icon: Icon(
                                      _selectedLocation == null
                                          ? Icons.add_location_alt_outlined
                                          : Icons.edit_location_alt_outlined,
                                    ),
                                    label: Text(
                                      _selectedLocation == null
                                          ? 'Choose on map'
                                          : 'Change location',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _selectedLocation == null
                                      ? 'Choose a point on the map to save the exact location.'
                                      : _selectedLocation!.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
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
                            icon: Icons.payments_outlined,
                            hint: 'Enter budget',
                            keyboardType: TextInputType.number,
                            prefixText: 'LKR ',
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

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick the exact job location on the map'),
        ),
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
        location: _selectedLocation!.address,
        locationLatitude: _selectedLocation!.latitude,
        locationLongitude: _selectedLocation!.longitude,
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
