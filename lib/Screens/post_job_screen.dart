import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:job_seeker_app/services/firebase_job_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseJobService _jobService = FirebaseJobService();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedEndTime;
  bool _isPosting = false;
  bool _isFetchingLocation = false;

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
      initialDate: _selectedEndDate ?? DateTime.now().add(const Duration(days: 1)),
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
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String resolvedLocation;
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addressParts = <String>[
          if (place.subLocality?.trim().isNotEmpty ?? false) place.subLocality!.trim(),
          if (place.locality?.trim().isNotEmpty ?? false) place.locality!.trim(),
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Post a Job'),
        backgroundColor: const Color(0xFF9E72C3).withOpacity(0.2),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
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
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: const Color(0xFF9E72C3),
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
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        )
                                      : IconButton(
                                          tooltip: 'Use current location',
                                          onPressed: _useCurrentLocation,
                                          icon: const Icon(Icons.my_location_outlined),
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
                                            prefixIcon: const Icon(Icons.calendar_today_outlined),
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
                                            prefixIcon: const Icon(Icons.access_time_outlined),
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
                                            prefixIcon: const Icon(Icons.event_busy_outlined),
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
                                            prefixIcon: const Icon(Icons.timelapse_outlined),
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
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isPosting ? null : _handlePostJob,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9E72C3),
                                foregroundColor: Colors.white,
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
                          ),
                        ).animate().fadeIn().slideY(delay: const Duration(milliseconds: 200)),
                      ],
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
    final isPartialEndInput = (_selectedEndDate == null) != (_selectedEndTime == null);
    if (isPartialEndInput) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both end date and end time')),
      );
      return;
    }
    if (_selectedEndDate != null && _selectedEndTime != null) {
      expiresAt = _combineDateAndTime(_selectedEndDate!, _selectedEndTime!);
      if (!expiresAt.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date and time must be in the future')),
        );
        return;
      }
    }

    setState(() => _isPosting = true);

    try {
      final time = '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      final budget = double.tryParse(_budgetController.text) ?? 0.0;

      final result = await _jobService.postJob(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        date: _selectedDate!,
        time: time,
        budget: budget,
        expiresAt: expiresAt,
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
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
