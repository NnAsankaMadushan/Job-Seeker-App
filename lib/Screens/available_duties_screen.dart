import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/Screens/job_details_screen.dart';
import 'package:job_seeker_app/Screens/messaging_screen.dart';
import 'package:job_seeker_app/models/job.dart';
import 'package:job_seeker_app/services/firebase_auth_service.dart';
import 'package:job_seeker_app/services/firebase_job_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

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
      setState(() => _currentUserId = user?.id);
    }
  }

  Future<void> _loadAppliedJobs() async {
    try {
      final appliedJobIds = await _jobService.getAppliedJobIds();
      if (mounted) {
        setState(() => _appliedJobs.addAll(appliedJobIds));
      }
    } catch (_) {
      // Keep the screen usable even if applied-state hydration fails.
    }
  }

  void _showApplyDialog(Job job) {
    final messageController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Apply for ${job.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Introduce yourself to ${job.providerName}.'),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Tell them why you are a strong fit for this job...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final message = messageController.text.trim();
                if (message.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a message before applying'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                final result = await _jobService.applyForJob(
                  jobId: job.id,
                  message: message,
                );

                if (!mounted) {
                  return;
                }

                if (result['success']) {
                  setState(() => _appliedJobs.add(job.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application submitted successfully'),
                    ),
                  );
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Failed to apply'),
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Jobs'),
      ),
      body: AppGradientBackground(
        child: StreamBuilder<List<Job>>(
          stream: _jobService.getAvailableJobs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load jobs',
                    subtitle: '${snapshot.error}',
                  ),
                ),
              );
            }

            final jobs = snapshot.data ?? [];

            if (jobs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: AppEmptyState(
                    icon: Icons.work_off_outlined,
                    title: 'No available jobs',
                    subtitle: 'Check back later for new opportunities.',
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
              children: [
                const AppSectionHeader(
                  eyebrow: 'Marketplace',
                  title: 'Fresh work requests',
                  subtitle:
                      'Browse open jobs, message providers, and submit your pitch quickly.',
                ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.08),
                const SizedBox(height: 18),
                for (var index = 0; index < jobs.length; index++) ...[
                  _AvailableJobCard(
                    job: jobs[index],
                    hasApplied: _appliedJobs.contains(jobs[index].id),
                    isOwnJob: _currentUserId == jobs[index].providerId,
                    onApply: () => _showApplyDialog(jobs[index]),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 120 + (index * 70)))
                      .slideY(begin: 0.08),
                  if (index != jobs.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.filter_list_rounded),
      ).animate().scale(duration: 320.ms),
    );
  }
}

class _AvailableJobCard extends StatelessWidget {
  const _AvailableJobCard({
    required this.job,
    required this.hasApplied,
    required this.isOwnJob,
    required this.onApply,
  });

  final Job job;
  final bool hasApplied;
  final bool isOwnJob;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = _resolveStatus(scheme);

    return AppGlassCard(
      onTap: () => openJobDetailsScreen(context, job),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDecoratedIcon(
                icon: Icons.work_outline_rounded,
                color: scheme.primary,
                backgroundColor: scheme.primary.withValues(alpha: 0.14),
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Posted by ${job.providerName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppPill(
                label: status.$1,
                icon: status.$2,
                color: status.$3,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppPill(
                label: job.location,
                icon: Icons.location_on_outlined,
                color: scheme.secondary,
              ),
              AppPill(
                label: '${job.date.day}/${job.date.month}/${job.date.year}',
                icon: Icons.calendar_month_outlined,
                color: scheme.primary,
              ),
              AppPill(
                label: job.time,
                icon: Icons.schedule_rounded,
                color: scheme.tertiary,
              ),
              AppPill(
                label: 'LKR ${job.budget.toStringAsFixed(0)}',
                icon: Icons.payments_outlined,
                color: const Color(0xFF059669),
              ),
              if (job.hasPhotos)
                AppPill(
                  label: '${job.imageUrls.length} photos',
                  icon: Icons.photo_library_outlined,
                  color: Color(0xFFF59E0B),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            job.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasApplied || isOwnJob ? null : onApply,
                  icon: Icon(
                    isOwnJob
                        ? Icons.work_history_outlined
                        : hasApplied
                            ? Icons.check_circle_outline_rounded
                            : Icons.send_outlined,
                  ),
                  label: Text(
                    isOwnJob
                        ? 'Your post'
                        : hasApplied
                            ? 'Applied'
                            : 'Apply now',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
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
                child: const Icon(Icons.forum_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, IconData, Color) _resolveStatus(ColorScheme scheme) {
    if (isOwnJob) {
      return ('Your post', Icons.edit_note_rounded, scheme.tertiary);
    }
    if (hasApplied) {
      return (
        'Applied',
        Icons.check_circle_outline_rounded,
        const Color(0xFF059669)
      );
    }
    return ('Open', Icons.bolt_rounded, scheme.primary);
  }
}
