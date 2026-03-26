import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/Screens/home_screen.dart';
import 'package:job_seeker_app/Screens/job_details_screen.dart';
import 'package:job_seeker_app/Screens/myJobsScreen.dart';
import 'package:job_seeker_app/Screens/notification.dart';
import 'package:job_seeker_app/Screens/work_request_screen.dart';
import 'package:job_seeker_app/models/job.dart' as job_model;
import 'package:job_seeker_app/models/user.dart' as app_user;
import 'package:job_seeker_app/services/firebase_auth_service.dart';
import 'package:job_seeker_app/services/firebase_chat_service.dart';
import 'package:job_seeker_app/services/firebase_job_service.dart';
import 'package:job_seeker_app/services/firebase_notification_service.dart';
import 'package:job_seeker_app/widgets/app_navigation_bar.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

import 'available_duties_screen.dart';
import 'post_job_screen.dart';
import 'Profile_Screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController = PageController();
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    AppGradientBackground(
      child: _HomeContent(),
    ),
    SearchScreen(),
    MyJobsScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  final List<AppNavigationItem> _navigationItems = const [
    AppNavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    AppNavigationItem(
      label: 'Search',
      icon: Icons.search_rounded,
      selectedIcon: Icons.manage_search_rounded,
    ),
    AppNavigationItem(
      label: 'Jobs',
      icon: Icons.work_outline_rounded,
      selectedIcon: Icons.work_rounded,
    ),
    AppNavigationItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
    AppNavigationItem(
      label: 'Settings',
      icon: Icons.tune_rounded,
      selectedIcon: Icons.tune,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleItemSelected(int index) async {
    if (index == _selectedIndex) {
      return;
    }

    setState(() => _selectedIndex = index);
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          if (_selectedIndex != index) {
            setState(() => _selectedIndex = index);
          }
        },
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SafeArea(
          top: false,
          child: AppFloatingNavigationBar(
            items: _navigationItems,
            selectedIndex: _selectedIndex,
            onItemSelected: _handleItemSelected,
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  app_user.User? _currentUser;
  int _unreadMessageCount = 0;
  int _unreadNotificationCount = 0;
  bool _isLoading = true;
  List<job_model.Job> _recentJobs = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUnreadCounts();
    _loadRecentJobs();
  }

  Future<void> _loadUserData() async {
    final authService = FirebaseAuthService();
    try {
      final user = await authService.getCurrentUserData();
      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = user;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadUnreadCounts() {
    final chatService = FirebaseChatService();
    chatService.getConversations().listen((conversations) {
      if (!mounted) {
        return;
      }

      var total = 0;
      for (final conversation in conversations) {
        total += conversation.unreadCount;
      }

      setState(() => _unreadMessageCount = total);
    });

    final notificationService = FirebaseNotificationService();
    notificationService.getUnreadCount().listen((count) {
      if (mounted) {
        setState(() => _unreadNotificationCount = count);
      }
    });
  }

  void _loadRecentJobs() {
    final jobService = FirebaseJobService();
    jobService.getAvailableJobs().listen((jobs) {
      if (mounted) {
        setState(() {
          _recentJobs = jobs.take(3).toList().cast<job_model.Job>();
        });
      }
    });
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  String get _displayName {
    final fullName = _currentUser?.name.trim();
    if (fullName == null || fullName.isEmpty) {
      return _isLoading ? 'there' : 'friend';
    }

    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quickActions = [
      (
        title: 'Post a job',
        subtitle: 'Create a new task and start hiring quickly.',
        icon: Icons.add_task_rounded,
        color: scheme.primary,
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PostJobScreen()),
            ),
      ),
      (
        title: 'Browse jobs',
        subtitle: 'See fresh openings near your preferred location.',
        icon: Icons.travel_explore_rounded,
        color: scheme.secondary,
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AvailableDutiesScreen()),
            ),
      ),
      (
        title: 'Track work',
        subtitle: 'Review active applications and current progress.',
        icon: Icons.assignment_turned_in_rounded,
        color: scheme.tertiary,
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyJobsScreen()),
            ),
      ),
      (
        title: 'Open requests',
        subtitle: 'Respond to worker requests and incoming updates.',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF059669),
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkerRequestsScreen()),
            ),
      ),
    ];

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                          child: Row(
                            children: [
                              _ProfileAvatar(
                                imageUrl: _currentUser?.profileImage,
                                accentColor: scheme.primary,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _greeting,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isLoading
                                          ? 'Loading your dashboard'
                                          : _currentUser?.name ??
                                              'Welcome back',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AppIconActionButton(
                        icon: Icons.forum_outlined,
                        badgeCount: _unreadMessageCount,
                        tooltip: 'Messages',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      AppIconActionButton(
                        icon: Icons.notifications_none_rounded,
                        badgeCount: _unreadNotificationCount,
                        tooltip: 'Notifications',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ).animate().fadeIn(duration: 320.ms).slideY(begin: -0.08),
                  const SizedBox(height: 24),
                  AppGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            AppPill(
                              label: 'Account',
                              icon: Icons.auto_awesome_rounded,
                              color: scheme.primary,
                            ),
                            if ((_currentUser?.location ?? '').isNotEmpty)
                              AppPill(
                                label: _currentUser!.location!,
                                icon: Icons.location_on_outlined,
                                color: scheme.secondary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '$_greeting, $_displayName',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Move between conversations, job requests, and active applications from one polished control center.',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.08),
                  const SizedBox(height: 30),
                  AppSectionHeader(
                    eyebrow: 'Dashboard',
                    title: 'Quick actions',
                    subtitle:
                        'Jump into the tasks that keep your work moving today.',
                    trailing: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AvailableDutiesScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('See jobs'),
                    ),
                  ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.08),
                  const SizedBox(height: 18),
                  GridView.builder(
                    itemCount: quickActions.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.98,
                    ),
                    itemBuilder: (context, index) {
                      final action = quickActions[index];
                      return AppActionCard(
                        title: action.title,
                        subtitle: action.subtitle,
                        icon: action.icon,
                        color: action.color,
                        onTap: action.onTap,
                      )
                          .animate()
                          .fadeIn(
                              delay: Duration(milliseconds: 260 + (index * 90)))
                          .slideY(begin: 0.1);
                    },
                  ),
                  const SizedBox(height: 30),
                  AppSectionHeader(
                    eyebrow: 'Opportunities',
                    title: 'Latest job openings',
                    subtitle: 'A quick scan of fresh work requests around you.',
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AvailableDutiesScreen(),
                          ),
                        );
                      },
                      child: const Text('View all'),
                    ),
                  ).animate().fadeIn(delay: 480.ms).slideY(begin: 0.08),
                  const SizedBox(height: 18),
                  if (_isLoading && _recentJobs.isEmpty)
                    AppGlassCard(
                      child: Row(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              'Loading the latest work opportunities for your feed.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 540.ms)
                  else if (_recentJobs.isEmpty)
                    const AppEmptyState(
                      icon: Icons.work_outline_rounded,
                      title: 'No openings yet',
                      subtitle:
                          'New jobs will appear here as soon as providers publish them.',
                    ).animate().fadeIn(delay: 540.ms)
                  else
                    Column(
                      children: [
                        for (var i = 0; i < _recentJobs.length; i++) ...[
                          _JobPreviewCard(job: _recentJobs[i])
                              .animate()
                              .fadeIn(
                                delay: Duration(milliseconds: 560 + (i * 90)),
                              )
                              .slideX(begin: 0.08),
                          if (i != _recentJobs.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.accentColor,
  });

  final String? imageUrl;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final avatar = imageUrl != null && imageUrl!.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _fallbackAvatar();
              },
            ),
          )
        : _fallbackAvatar();

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.2),
            accentColor.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: avatar,
    );
  }

  Widget _fallbackAvatar() {
    return Icon(
      Icons.person_rounded,
      color: accentColor,
      size: 28,
    );
  }
}

class _JobPreviewCard extends StatelessWidget {
  const _JobPreviewCard({
    required this.job,
  });

  final job_model.Job job;

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
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Wrap(
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
