import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'messaging_screen.dart';

// Sample job data
class JobListing {
  final String id;
  final String title;
  final String description;
  final String location;
  final String date;
  final double budget;
  final String providerName;

  JobListing({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.budget,
    required this.providerName,
  });
}

final List<JobListing> sampleJobs = [
  JobListing(
    id: '1',
    title: 'Home Cleaning Service',
    description: 'Looking for an experienced cleaner for a 3-bedroom house. Deep cleaning required including kitchen and bathrooms.',
    location: 'New York, NY',
    date: 'Jan 15, 2025',
    budget: 50,
    providerName: 'Sarah Johnson',
  ),
  JobListing(
    id: '2',
    title: 'Garden Maintenance',
    description: 'Need help with lawn mowing, trimming, and general garden upkeep. Tools provided.',
    location: 'Brooklyn, NY',
    date: 'Jan 16, 2025',
    budget: 55,
    providerName: 'Michael Chen',
  ),
  JobListing(
    id: '3',
    title: 'Painting Interior Walls',
    description: 'Two rooms need repainting. Paint and supplies will be provided.',
    location: 'Manhattan, NY',
    date: 'Jan 17, 2025',
    budget: 60,
    providerName: 'Emma Davis',
  ),
  JobListing(
    id: '4',
    title: 'Moving Assistance',
    description: 'Help needed to move furniture and boxes to a new apartment. Heavy lifting required.',
    location: 'Queens, NY',
    date: 'Jan 18, 2025',
    budget: 65,
    providerName: 'David Miller',
  ),
  JobListing(
    id: '5',
    title: 'Pet Sitting',
    description: 'Need someone to watch my dog for the weekend. Experience with dogs required.',
    location: 'Bronx, NY',
    date: 'Jan 19, 2025',
    budget: 45,
    providerName: 'Lisa Anderson',
  ),
];

class AvailableDutiesScreen extends StatefulWidget {
  const AvailableDutiesScreen({super.key});

  @override
  State<AvailableDutiesScreen> createState() => _AvailableDutiesScreenState();
}

class _AvailableDutiesScreenState extends State<AvailableDutiesScreen> {
  final Set<String> _appliedJobs = {};

  void _showApplyDialog(JobListing job) {
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
            onPressed: () {
              setState(() {
                _appliedJobs.add(job.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application submitted successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sampleJobs.length,
          itemBuilder: (context, index) {
            final job = sampleJobs[index];
            final hasApplied = _appliedJobs.contains(job.id);

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
                              color: hasApplied
                                  ? Colors.green
                                  : const Color(0xFF9E72C3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              hasApplied ? 'Applied' : 'Available',
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
                                job.date,
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
                                '\$${job.budget}/hr',
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
                                  onPressed: hasApplied ? null : () => _showApplyDialog(job),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: hasApplied
                                        ? Colors.grey
                                        : const Color(0xFF9E72C3),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: Icon(hasApplied
                                      ? Icons.check_circle
                                      : Icons.send_outlined),
                                  label: Text(hasApplied ? 'Applied' : 'Apply Now'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MessagingScreen(
                                        userId: int.parse(job.id),
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
