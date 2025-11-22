import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/services/firebase_job_service.dart';
import 'package:job_seeker_app/services/firebase_auth_service.dart';
import 'package:job_seeker_app/models/job.dart';
import 'messaging_screen.dart';

class AvailableDutiesScreen extends StatefulWidget {
  const AvailableDutiesScreen({super.key});

  @override
  State<AvailableDutiesScreen> createState() => _AvailableDutiesScreenState();
}

class _AvailableDutiesScreenState extends State<AvailableDutiesScreen> {
  final FirebaseJobService _jobService = FirebaseJobService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final Set<String> _appliedJobs = {};
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadAppliedJobs();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUserData();
    if (mounted) {
      setState(() {
        _currentUserId = user?.id;
      });
    }
  }

  Future<void> _loadAppliedJobs() async {
    try {
      final appliedJobIds = await _jobService.getAppliedJobIds();
      if (mounted) {
        setState(() {
          _appliedJobs.addAll(appliedJobIds);
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  void _showApplyDialog(Job job) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apply for ${job.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send a message to ${job.providerName}'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tell them why you\'re a great fit for this job...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final message = messageController.text.trim();
              if (message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a message')),
                );
                return;
              }

              Navigator.pop(context);

              final result = await _jobService.applyForJob(
                jobId: job.id,
                message: message,
              );

              if (mounted) {
                if (result['success']) {
                  setState(() {
                    _appliedJobs.add(job.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application submitted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'] ?? 'Failed to apply')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9E72C3),
            ),
            child: const Text('Submit Application'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Jobs'),
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
        child: StreamBuilder<List<Job>>(
          stream: _jobService.getAvailableJobs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final jobs = snapshot.data ?? [];

            if (jobs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.work_off_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No available jobs',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new opportunities',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                final hasApplied = _appliedJobs.contains(job.id);
                final isOwnJob = _currentUserId == job.providerId;

                return Card(
              elevation: 5,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job Header with Status Badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9E72C3).withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isOwnJob
                                  ? Colors.orange
                                  : (hasApplied
                                      ? Colors.green
                                      : const Color(0xFF9E72C3)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOwnJob
                                  ? 'Your Post'
                                  : (hasApplied ? 'Applied' : 'Available'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Job Details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Provider name
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                color: Color(0xFF9E72C3),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Posted by ${job.providerName}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Location
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFF9E72C3),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                job.location,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Date
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF9E72C3),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${job.date.day}/${job.date.month}/${job.date.year}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Price
                          Row(
                            children: [
                              const Icon(
                                Icons.attach_money_outlined,
                                color: Color(0xFF9E72C3),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '\$${job.budget.toStringAsFixed(2)}/hr',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Description
                          Text(
                            job.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: (hasApplied || isOwnJob)
                                      ? null
                                      : () => _showApplyDialog(job),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isOwnJob
                                        ? Colors.orange
                                        : (hasApplied
                                            ? Colors.grey
                                            : const Color(0xFF9E72C3)),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: Icon(isOwnJob
                                      ? Icons.work
                                      : (hasApplied
                                          ? Icons.check_circle
                                          : Icons.send_outlined)),
                                  label: Text(isOwnJob
                                      ? 'Your Post'
                                      : (hasApplied ? 'Applied' : 'Apply Now')),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MessagingScreen(
                                        userId: job.providerId,
                                        userName: job.providerName,
                                      ),
                                    ),
                                  );
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey.shade200,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.chat_outlined,
                                  color: Color(0xFF9E72C3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
                ).animate().fadeIn(delay: (50 * index).ms).slideX();
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF9E72C3),
        child: const Icon(Icons.filter_list),
      ).animate().scale(),
    );
  }
}
