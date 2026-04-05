import 'package:job_seeker_app/Screens/messaging_screen.dart';
import 'package:flutter/material.dart';
import 'package:job_seeker_app/services/firebase_job_service.dart';
import 'package:job_seeker_app/models/applicant_rating_summary.dart';
import 'package:job_seeker_app/models/job_application.dart';
import 'package:job_seeker_app/services/firebase_rating_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

class WorkerRequestsScreen extends StatefulWidget {
  final String? jobId;

  const WorkerRequestsScreen({super.key, this.jobId});

  @override
  State<WorkerRequestsScreen> createState() => _WorkerRequestsScreenState();
}

class _WorkerRequestsScreenState extends State<WorkerRequestsScreen> {
  final FirebaseJobService _jobService = FirebaseJobService();
  final FirebaseRatingService _ratingService = FirebaseRatingService();
  final Map<String, Future<ApplicantRatingSummary>> _ratingSummaryCache = {};

  Future<ApplicantRatingSummary> _ratingSummaryFor(String applicantId) {
    return _ratingSummaryCache.putIfAbsent(
      applicantId,
      () => _ratingService.getApplicantRatingSummary(applicantId),
    );
  }

  Future<void> _showFeedbackDialog(JobApplication application) async {
    final feedbackController = TextEditingController();
    var selectedRating = 0;

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('Rate ${application.applicantName}'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a star rating for this applicant.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starValue = index + 1;
                          final isSelected = starValue <= selectedRating;

                          return IconButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedRating = starValue;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            icon: Icon(
                              isSelected
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: const Color(0xFFF59E0B),
                              size: 30,
                            ),
                            tooltip:
                                '$starValue star${starValue == 1 ? '' : 's'}',
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: feedbackController,
                        maxLines: 3,
                        maxLength: 300,
                        decoration: const InputDecoration(
                          labelText: 'Feedback',
                          hintText: 'Optional note about this applicant',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: selectedRating == 0
                        ? null
                        : () {
                            Navigator.pop(dialogContext, {
                              'rating': selectedRating,
                              'feedback': feedbackController.text.trim(),
                            });
                          },
                    child: const Text('Submit'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == null || !mounted) {
        return;
      }

      final rating = result['rating'] as int;
      final feedback = (result['feedback'] ?? '').toString();

      final messenger = ScaffoldMessenger.of(context);
      final submitResult = await _ratingService.submitApplicantRating(
        applicationId: application.id,
        rating: rating,
        feedback: feedback,
      );

      if (!mounted) {
        return;
      }

      if (submitResult['success'] == true) {
        setState(() {
          _ratingSummaryCache.remove(application.applicantId);
        });
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            submitResult['message'] ?? 'Unable to submit feedback',
          ),
        ),
      );
    } finally {
      feedbackController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Requests'),
      ),
      body: AppGradientBackground(
        child: StreamBuilder<List<JobApplication>>(
          stream: widget.jobId != null
              ? _jobService.getJobApplications(widget.jobId!)
              : _jobService.getAllMyJobApplications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final applications = snapshot.data ?? [];

            if (applications.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: AppEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No applications yet',
                    subtitle: 'Applications will appear here',
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final application = applications[index];
                final applicantRatingFuture =
                    _ratingSummaryFor(application.applicantId);
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Worker Info Row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.14),
                              backgroundImage: application.applicantImage !=
                                      null
                                  ? NetworkImage(application.applicantImage!)
                                  : null,
                              child: application.applicantImage == null
                                  ? Text(
                                      application.applicantName.isNotEmpty
                                          ? application.applicantName[0]
                                              .toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.teal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    application.applicantName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  _ApplicantRatingSummary(
                                    summaryFuture: applicantRatingFuture,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Applied: ${_formatDate(application.appliedAt)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusChip(application.status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Job Details
                        Text(
                          'Job: ${application.jobTitle}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Message: ${application.message}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MessagingScreen(
                                    userId: application.applicantId,
                                    userName: application.applicantName,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Chat with applicant'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        if (application.status == 'pending') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final result = await _jobService
                                        .updateApplicationStatus(
                                      applicationId: application.id,
                                      status: 'accepted',
                                    );
                                    if (mounted && result['success']) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Application accepted'),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Accept'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final result = await _jobService
                                        .updateApplicationStatus(
                                      applicationId: application.id,
                                      status: 'rejected',
                                    );
                                    if (mounted && result['success']) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Application rejected'),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('Reject'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showFeedbackDialog(application),
                            icon: const Icon(Icons.star_rounded),
                            label: const Text('Give feedback'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'accepted':
        color = Colors.green;
        label = 'Accepted';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = Colors.orange;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _ApplicantRatingSummary extends StatelessWidget {
  const _ApplicantRatingSummary({
    required this.summaryFuture,
  });

  final Future<ApplicantRatingSummary> summaryFuture;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<ApplicantRatingSummary>(
      future: summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Loading applicant rating...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Ratings unavailable',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          );
        }

        final summary = snapshot.data ?? const ApplicantRatingSummary.empty();

        if (!summary.hasRatings) {
          return Row(
            children: [
              const Icon(
                Icons.star_border_rounded,
                size: 16,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 6),
              Text(
                'No ratings yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          );
        }

        final starCount = summary.averageRating.round().clamp(0, 5);

        return Row(
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < starCount
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 16,
                  color: const Color(0xFFF59E0B),
                );
              }),
            ),
            const SizedBox(width: 8),
            Text(
              '${summary.averageLabel}/5 - ${summary.ratingCount} review${summary.ratingCount == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        );
      },
    );
  }
}
