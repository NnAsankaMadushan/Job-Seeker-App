import 'package:job_seeker_app/Screens/home_screen.dart';
import 'package:job_seeker_app/Screens/myJobsScreen.dart';
import 'package:job_seeker_app/Screens/notification.dart';
import 'package:job_seeker_app/Screens/work_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:job_seeker_app/services/firebase_auth_service.dart';
import 'package:job_seeker_app/services/firebase_chat_service.dart';
import 'package:job_seeker_app/services/firebase_job_service.dart';
import 'package:job_seeker_app/services/firebase_notification_service.dart';
import 'package:job_seeker_app/models/user.dart' as app_user;
import 'package:job_seeker_app/models/message.dart';
import 'package:job_seeker_app/models/job.dart' as JobModel;
import 'profile_screen.dart';
import 'available_duties_screen.dart';
import 'post_job_screen.dart';
import 'search_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of screens to show based on bottom navigation selection
  final List<Widget> _screens = [
    const _HomeContent(),  // Extracted home content
    const SearchScreen(), // Your search screen
    const MyJobsScreen(),   // Your jobs screen
    const ProfileScreen() // Your profile screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        // Show the selected screen based on bottom navigation index
        child: _selectedIndex == 0
            ? _screens[_selectedIndex]
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _screens[_selectedIndex],
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Extracted home content into a separate widget for better organization
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
  List<JobModel.Job> _recentJobs = [];
  List<Conversation> _recentConversations = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUnreadCounts();
    _loadRecentActivities();
  }

  Future<void> _loadUserData() async {
    final authService = FirebaseAuthService();
    final user = await authService.getCurrentUserData();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUnreadCounts() async {
    // Load unread message count
    final chatService = FirebaseChatService();
    chatService.getConversations().listen((conversations) {
      if (mounted) {
        int total = 0;
        for (var conv in conversations) {
          total += conv.unreadCount;
        }
        setState(() {
          _unreadMessageCount = total;
        });
      }
    });

    // Load unread notification count
    final notificationService = FirebaseNotificationService();
    notificationService.getUnreadCount().listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    });
  }

  Future<void> _loadRecentActivities() async {
    // Load recent jobs
    final jobService = FirebaseJobService();
    jobService.getAvailableJobs().listen((jobs) {
      if (mounted) {
        setState(() {
          _recentJobs = jobs.take(3).toList().cast<JobModel.Job>();
        });
      }
    });

    // Load recent conversations
    final chatService = FirebaseChatService();
    chatService.getConversations().listen((conversations) {
      if (mounted) {
        setState(() {
          _recentConversations = conversations.take(2).toList();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Custom App Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // User Profile Section
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF9E72C3),
                            width: 2,
                          ),
                        ),
                        child: _currentUser?.profileImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(
                                  _currentUser!.profileImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const CircleAvatar(
                                      backgroundColor: Color(0xFF9E72C3),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const CircleAvatar(
                                backgroundColor: Color(0xFF9E72C3),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _isLoading
                                ? 'Loading...'
                                : _currentUser?.name ?? 'User',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Message Icon with Badge
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => HomeScreen()),
                        );
                      },
                      icon: const Icon(Icons.message_outlined),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    if (_unreadMessageCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _unreadMessageCount > 99 ? '99+' : '$_unreadMessageCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                // Notifications Icon with Badge
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationScreen()),
                        );
                      },
                      icon: const Icon(Icons.notifications_outlined),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    if (_unreadNotificationCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions Grid
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildActionCard(
                        context,
                        title: 'Post a Job',
                        icon: Icons.add_task_outlined,
                        color: const Color(0xFF9E72C3),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PostJobScreen()),
                        ),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Available Jobs',
                        icon: Icons.work_outline,
                        color: Colors.blue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AvailableDutiesScreen()),
                        ),
                      ),
                      _buildActionCard(
                        context,
                        title: 'My Jobs',
                        icon: Icons.assignment_outlined,
                        color: Colors.orange,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyJobsScreen())
                        ),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Requests',
                        icon: Icons.request_page_outlined,
                        color: Colors.green,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WorkerRequestsScreen()),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(),

                  const SizedBox(height: 24),

                  // Recent Activities Section - Now using real Firebase data
                  Text(
                    'Recent Activities',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Show real data or empty state
                  if (_recentJobs.isEmpty && _recentConversations.isEmpty && !_isLoading)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No recent activities',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Post a job or start messaging to see activities here',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentJobs.length + _recentConversations.length,
                      itemBuilder: (context, index) {
                        // Show jobs first, then messages
                        if (index < _recentJobs.length) {
                          final job = _recentJobs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF9E72C3).withOpacity(0.2),
                                child: const Icon(
                                  Icons.work_outline,
                                  color: Color(0xFF9E72C3),
                                ),
                              ),
                              title: Text('New job: ${job.title}'),
                              subtitle: Text(job.location),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AvailableDutiesScreen(),
                                  ),
                                );
                              },
                            ),
                          ).animate().fadeIn(delay: (50 * index).ms).slideX();
                        } else {
                          final convIndex = index - _recentJobs.length;
                          final conversation = _recentConversations[convIndex];
                          final currentUserId = FirebaseAuthService().currentUser?.uid ?? '';
                          final isLastMessageFromCurrentUser = conversation.lastMessage?.senderId == currentUserId;

                          // Determine title and subtitle based on who sent the message
                          final messageTitle = isLastMessageFromCurrentUser
                              ? 'You messaged ${conversation.userName}'
                              : 'Message from ${conversation.userName}';
                          final messageSubtitle = conversation.lastMessage?.content ?? 'No message';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF9E72C3).withOpacity(0.2),
                                child: const Icon(
                                  Icons.message_outlined,
                                  color: Color(0xFF9E72C3),
                                ),
                              ),
                              title: Text(messageTitle),
                              subtitle: Text(
                                messageSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HomeScreen(),
                                  ),
                                );
                              },
                            ),
                          ).animate().fadeIn(delay: (50 * index).ms).slideX();
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
