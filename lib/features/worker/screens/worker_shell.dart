import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/shared/screens/messaging_screen.dart';
import 'package:talent/features/shared/screens/notifications_screen.dart';
import 'package:talent/features/worker/screens/worker_applications_screen.dart';
import 'package:talent/features/worker/screens/worker_attendance_screen.dart';
import 'package:talent/features/worker/screens/worker_dashboard_screen.dart';
import 'package:talent/features/worker/screens/worker_job_feed_screen.dart';
import 'package:talent/features/worker/screens/worker_settings_screen.dart';

class WorkerShell extends StatefulWidget {
  const WorkerShell({super.key});

  @override
  State<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends State<WorkerShell> {
  int _index = 0;

  void _openMessaging() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MessagingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Temporary implementation with fewer screens
    final pages = [
      const WorkerDashboardScreen(),
      const WorkerJobFeedScreen(),
      const WorkerApplicationsScreen(),
      const WorkerAttendanceScreen(),
      const WorkerSettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Worker Dashboard',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
        tooltip: 'Messages',
        icon: const Icon(Icons.message, size: 18),
        onPressed: _openMessaging,

          ),
          Badge(
        label: appState.unreadNotificationCount > 0
            ? Text(appState.unreadNotificationCount.toString())
            : null,
        child: IconButton(
          icon: const Icon(Icons.notifications_outlined,size: 18),
          onPressed: () {
            Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
            );
          },
        ),
          ),
          PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 18),
        onSelected: (value) async {
          if (value == 'logout') {
            await appState.logout();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'logout', child: Text('Logout')),
        ],
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Consumer<AppState>(
        builder: (context, appState, child) {
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.work_outline),
                label: 'Jobs',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                label: 'Applications',
              ),
              NavigationDestination(
                icon: Icon(Icons.check_circle_outline),
                label: 'Attendance',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                label: 'Settings',
              )
            ],
          );
        },
      ),
    );
  }
}
