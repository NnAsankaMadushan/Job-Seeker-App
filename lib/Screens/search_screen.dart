// search_screen.dart
import 'package:flutter/material.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  static const _categories = [
    'Cleaning',
    'Gardening',
    'Painting',
    'Plumbing',
    'Electrical',
    'Moving',
    'Delivery',
    'Pet Care',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AppSectionHeader(
                title: 'Discover Jobs',
                subtitle: 'Find opportunities by skill or task type',
              ),
              const SizedBox(height: 14),
              AppGlassCard(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search for jobs, locations, providers...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AppGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Popular Categories',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories
                          .map((category) => _buildCategoryChip(context, category))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String label) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(
        Icons.trending_up_rounded,
        color: Theme.of(context).colorScheme.primary,
        size: 16,
      ),
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
      onPressed: () {},
    );
  }
}

