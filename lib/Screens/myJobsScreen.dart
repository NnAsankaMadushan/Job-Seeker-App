import 'package:job_seeker_app/Screens/messaging_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/services/firebase_job_service.dart';
import 'package:job_seeker_app/models/job.dart' as JobModel;
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
        child: StreamBuilder<List<JobModel.Job>>(
          stream: _jobService.getMyAppliedJobs(),
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
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: AppEmptyState(
                    icon: Icons.work_off_outlined,
                    title: 'No applied jobs yet',
                    subtitle: 'Apply for jobs to see them here',
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return JobCard(job: job)
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 100 * index),
                    )
                    .slideX();
              },
            );
          },
        ),
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final JobModel.Job job;

  const JobCard({
    super.key,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.14),
                  child: Icon(
                    Icons.work_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        'Posted by ${job.providerName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${job.budget}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.location_on_outlined,
              job.location,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.access_time,
              '${job.date.day}/${job.date.month}/${job.date.year} at ${job.time}',
            ),
            const SizedBox(height: 16),
            Text(
              job.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessagingScreen(
                          userId: job.providerId,
                          userName: job.providerName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('Message'),
                ),
                _buildStatusButton(context, job.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(BuildContext context, String status) {
    final isInProgress = status == 'in_progress';
    final isCompleted = status == 'completed';
    final isAvailable = status == 'available';

    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending_outlined;
    String statusLabel = 'Available';

    if (isCompleted) {
      statusColor = Colors.blue;
      statusIcon = Icons.check_circle_outline;
      statusLabel = 'Completed';
    } else if (isInProgress) {
      statusColor = Colors.green;
      statusIcon = Icons.work_outline;
      statusLabel = 'In Progress';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Text(
            statusLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}
