import 'package:flutter/material.dart';
import 'package:job_seeker_app/models/job.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

void openJobDetailsScreen(BuildContext context, Job job) {
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => JobDetailsScreen(job: job),
    ),
  );
}

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({
    super.key,
    required this.job,
  });

  final Job job;

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  late final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _jumpToImage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              _buildHeaderCard(context, job),
              const SizedBox(height: 20),
              if (job.hasPhotos) ...[
                const AppSectionHeader(
                  eyebrow: 'Photos',
                  title: 'Workplace gallery',
                  subtitle:
                      'These photos were added by the person who posted the job.',
                ),
                const SizedBox(height: 16),
                _buildGalleryCard(context, job),
              ] else
                AppGlassCard(
                  child: Row(
                    children: [
                      AppDecoratedIcon(
                        icon: Icons.photo_library_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.14),
                        size: 54,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'No workplace photos were added to this post.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              const AppSectionHeader(
                eyebrow: 'Overview',
                title: 'Job information',
                subtitle:
                    'Review the timing, location, budget, and description before responding.',
              ),
              const SizedBox(height: 16),
              AppGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppPill(
                          label: job.location,
                          icon: Icons.location_on_outlined,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        AppPill(
                          label:
                              '${job.date.day}/${job.date.month}/${job.date.year}',
                          icon: Icons.calendar_month_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        AppPill(
                          label: job.time,
                          icon: Icons.schedule_rounded,
                          color: Theme.of(context).colorScheme.tertiary,
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
                            color: const Color(0xFFF59E0B),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      job.description,
                      style: Theme.of(context).textTheme.bodyLarge,
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

  Widget _buildHeaderCard(BuildContext context, Job job) {
    final status = _resolveStatus(context, job.status);
    final scheme = Theme.of(context).colorScheme;

    return AppGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppPill(
                label: status.$1,
                icon: status.$2,
                color: status.$3,
              ),
              if (job.hasPhotos)
                AppPill(
                  label: '${job.imageUrls.length} photos',
                  icon: Icons.photo_library_outlined,
                  color: const Color(0xFFF59E0B),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            job.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Posted by ${job.providerName}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryCard(BuildContext context, Job job) {
    return AppGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: job.imageUrls.length,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return _JobDetailImage(
                        imageUrl: job.imageUrls[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${job.imageUrls.length}',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (job.imageUrls.length > 1) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: job.imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final isSelected = index == _currentImageIndex;

                  return GestureDetector(
                    onTap: () => _jumpToImage(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 92,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _JobDetailImage(
                          imageUrl: job.imageUrls[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
      case 'cancelled':
        return ('Cancelled', Icons.cancel_outlined, const Color(0xFFDC2626));
      default:
        return (
          'Open',
          Icons.work_outline_rounded,
          Theme.of(context).colorScheme.primary,
        );
    }
  }
}

class _JobDetailImage extends StatelessWidget {
  const _JobDetailImage({
    required this.imageUrl,
    this.fit,
  });

  final String imageUrl;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: fit ?? BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          color: Colors.black.withValues(alpha: 0.04),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: AppDecoratedIcon(
            icon: Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
            size: 58,
          ),
        );
      },
    );
  }
}
