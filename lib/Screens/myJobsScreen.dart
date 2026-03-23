import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/Screens/job_details_screen.dart';
import 'package:job_seeker_app/Screens/messaging_screen.dart';
import 'package:job_seeker_app/models/job.dart' as job_model;
import 'package:job_seeker_app/services/firebase_job_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  final FirebaseJobService _jobService = FirebaseJobService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applied Jobs'),
      ),
      body: AppGradientBackground(
        child: StreamBuilder<List<job_model.Job>>(
          stream: _jobService.getMyAppliedJobs(),
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
                    title: 'Unable to load your jobs',
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
                    title: 'No applied jobs yet',
                    subtitle: 'Apply for jobs to see them collected here.',
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
              children: [
                const AppSectionHeader(
                  eyebrow: 'Tracking',
                  title: 'Everything you have applied for',
                  subtitle:
                      'Monitor where you are waiting, working, or wrapping up.',
                ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.08),
                const SizedBox(height: 18),
                for (var index = 0; index < jobs.length; index++) ...[
                  _JobCard(job: jobs[index])
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 120 + (index * 80)))
                      .slideY(begin: 0.08),
                  if (index != jobs.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
  });

  final job_model.Job job;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = _resolveStatus(context, job.status);

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
                size: 54,
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
                label:
                    '${job.date.day}/${job.date.month}/${job.date.year} ${job.time}',
                icon: Icons.schedule_rounded,
                color: scheme.primary,
              ),
              AppPill(
                label: 'LKR ${job.budget.toStringAsFixed(0)}',
                icon: Icons.payments_outlined,
                color: scheme.tertiary,
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
                child: OutlinedButton.icon(
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
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('Message'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, IconData, Color) _resolveStatus(
      BuildContext context, String status) {
    switch (status) {
      case 'completed':
        return ('Completed', Icons.task_alt_rounded, const Color(0xFF2563EB));
      case 'in_progress':
        return ('In progress', Icons.bolt_rounded, const Color(0xFF059669));
      default:
        return (
          'Applied',
          Icons.schedule_outlined,
          Theme.of(context).colorScheme.primary
        );
    }
  }
}
