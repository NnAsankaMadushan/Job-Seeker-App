import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/Screens/job_details_screen.dart';
import 'package:job_seeker_app/models/job.dart';
import 'package:job_seeker_app/services/firebase_job_service.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _categories = [
    ('Cleaning', Icons.cleaning_services_outlined),
    ('Gardening', Icons.yard_outlined),
    ('Painting', Icons.format_paint_outlined),
    ('Plumbing', Icons.plumbing_outlined),
    ('Electrical', Icons.electrical_services_outlined),
    ('Moving', Icons.local_shipping_outlined),
    ('Delivery', Icons.delivery_dining_outlined),
    ('Pet Care', Icons.pets_outlined),
  ];

  final FirebaseJobService _jobService = FirebaseJobService();
  final TextEditingController _searchController = TextEditingController();
  late final Stream<List<Job>> _jobsStream;

  String _query = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _jobsStream = _jobService.getAvailableJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    setState(() => _query = value.trim());
  }

  void _toggleCategory(String category) {
    final nextCategory = _selectedCategory == category ? null : category;

    setState(() {
      _selectedCategory = nextCategory;
      if (nextCategory != null) {
        _searchController.text = nextCategory;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
        _query = nextCategory;
      } else {
        _searchController.clear();
        _query = '';
      }
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedCategory = null;
    });
  }

  List<Job> _filterJobs(List<Job> jobs) {
    final normalizedQuery = _query.toLowerCase();
    final normalizedCategory = _selectedCategory?.toLowerCase();

    return jobs.where((job) {
      final searchableText = [
        job.title,
        job.description,
        job.location,
        job.providerName,
        job.time,
      ].join(' ').toLowerCase();

      final matchesQuery =
          normalizedQuery.isEmpty || searchableText.contains(normalizedQuery);
      final matchesCategory = normalizedCategory == null ||
          searchableText.contains(normalizedCategory);

      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasActiveSearch = _query.isNotEmpty || _selectedCategory != null;

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: StreamBuilder<List<Job>>(
            stream: _jobsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AppEmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Search is unavailable',
                      subtitle: '${snapshot.error}',
                    ),
                  ),
                );
              }

              final allJobs = snapshot.data ?? [];
              final filteredJobs = _filterJobs(allJobs);

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                children: [
                  AppGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppPill(
                          label: 'Discover opportunities',
                          icon: Icons.manage_search_rounded,
                          color: scheme.secondary,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Search work by category, skill, or location.',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _searchController,
                          onChanged: _setQuery,
                          decoration: InputDecoration(
                            hintText:
                                'Search for jobs, locations, providers...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _query.isNotEmpty
                                ? IconButton(
                                    onPressed: _clearFilters,
                                    icon: const Icon(Icons.close_rounded),
                                  )
                                : const Icon(Icons.tune_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            AppPill(
                              label: '${filteredJobs.length} results',
                              icon: Icons.dataset_outlined,
                              color: scheme.primary,
                            ),
                            if (_selectedCategory != null)
                              AppPill(
                                label: _selectedCategory!,
                                icon: Icons.filter_alt_outlined,
                                color: scheme.tertiary,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.08),
                  const SizedBox(height: 24),
                  if (hasActiveSearch) ...[
                    AppSectionHeader(
                      eyebrow: 'Results',
                      title: filteredJobs.isEmpty
                          ? 'No matching jobs found'
                          : 'Matching job openings',
                      subtitle: filteredJobs.isEmpty
                          ? 'Try a broader term or clear the selected filter.'
                          : 'Results are shown directly below the search box.',
                      trailing: TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear'),
                      ),
                    ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.08),
                    const SizedBox(height: 16),
                    if (filteredJobs.isEmpty)
                      AppEmptyState(
                        icon: Icons.travel_explore_rounded,
                        title: 'Nothing matched your search',
                        subtitle:
                            'Try searching by title, location, or provider name.',
                        action: OutlinedButton(
                          onPressed: _clearFilters,
                          child: const Text('Reset filters'),
                        ),
                      ).animate().fadeIn(delay: 180.ms)
                    else
                      Column(
                        children: [
                          for (var index = 0;
                              index < filteredJobs.length;
                              index++) ...[
                            _SearchResultCard(job: filteredJobs[index])
                                .animate()
                                .fadeIn(
                                  delay: Duration(
                                      milliseconds: 180 + (index * 60)),
                                )
                                .slideX(begin: 0.05),
                            if (index != filteredJobs.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                  ] else ...[
                    const AppSectionHeader(
                      eyebrow: 'Popular',
                      title: 'Trending categories',
                      subtitle:
                          'Tap a category to use it as an instant filter.',
                    ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.08),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.08,
                      ),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final tone = [
                          scheme.primary,
                          scheme.secondary,
                          scheme.tertiary,
                          const Color(0xFF059669),
                        ][index % 4];

                        return AppActionCard(
                          title: category.$1,
                          subtitle: _selectedCategory == category.$1
                              ? 'Tap to clear this filter'
                              : 'Explore ${category.$1.toLowerCase()} requests',
                          icon: category.$2,
                          color: tone,
                          onTap: () => _toggleCategory(category.$1),
                        )
                            .animate()
                            .fadeIn(
                              delay: Duration(milliseconds: 180 + (index * 70)),
                            )
                            .slideY(begin: 0.08);
                      },
                    ),
                    const SizedBox(height: 24),
                    const AppSectionHeader(
                      eyebrow: 'Open Now',
                      title: 'Recent openings',
                      subtitle: 'Start typing to narrow the list instantly.',
                    ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.08),
                    const SizedBox(height: 16),
                    if (filteredJobs.isEmpty)
                      const AppEmptyState(
                        icon: Icons.travel_explore_rounded,
                        title: 'No jobs available right now',
                        subtitle: 'Check back later for new openings.',
                      ).animate().fadeIn(delay: 300.ms)
                    else
                      Column(
                        children: [
                          for (var index = 0;
                              index < filteredJobs.length;
                              index++) ...[
                            _SearchResultCard(job: filteredJobs[index])
                                .animate()
                                .fadeIn(
                                  delay: Duration(
                                      milliseconds: 300 + (index * 60)),
                                )
                                .slideX(begin: 0.05),
                            if (index != filteredJobs.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.job,
  });

  final Job job;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppListTileCard(
      leading: AppDecoratedIcon(
        icon: Icons.work_outline_rounded,
        color: scheme.primary,
        backgroundColor: scheme.primary.withValues(alpha: 0.14),
        size: 56,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Posted by ${job.providerName}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                label: 'LKR ${job.budget.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_outlined,
                color: scheme.primary,
              ),
              AppPill(
                label: '${job.date.day}/${job.date.month}/${job.date.year}',
                icon: Icons.schedule_rounded,
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
          const SizedBox(height: 10),
          Text(
            job.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      trailing: Icon(
        Icons.arrow_outward_rounded,
        color: scheme.onSurfaceVariant,
      ),
      onTap: () {
        openJobDetailsScreen(context, job);
      },
    );
  }
}
