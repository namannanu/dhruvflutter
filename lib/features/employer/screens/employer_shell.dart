import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/employer/screens/employer_dashboard_screen.dart';
import 'package:talent/features/employer/screens/employer_jobs_screen.dart';
import 'package:talent/features/employer/screens/employer_profile_screen.dart';
import 'package:talent/features/shared/screens/messaging_screen.dart';
import 'package:talent/features/shared/screens/notifications_screen.dart';

import 'employee_attendence_managment.dart';
import 'employee_hire_application_screen.dart';

class EmployerShell extends StatefulWidget {
  const EmployerShell({super.key});

  @override
  State<EmployerShell> createState() => _EmployerShellState();
}

class _EmployerShellState extends State<EmployerShell> {
  int _index = 0;

  final pages = const [
    EmployerDashboardScreen(),
    EmployerJobsScreen(),
    EmployeeHireApplicationScreen(),
    EmployeeAttendanceManagementScreen(),
    EmployerProfileScreen(),
  ];

  void _openMessaging() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MessagingScreen(),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employer workspace'),
        actions: [
          IconButton(
            tooltip: 'Messages',
            icon: const Icon(Icons.message),
            onPressed: _openMessaging,
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications),
            onPressed: _openNotifications,
          ),

          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AppState>().refreshActiveRole(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AppState>().logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: IndexedStack(
          key: ValueKey(_index),
          index: _index,
          children: pages,
        ),
      ),
      bottomNavigationBar: Consumer<AppState>(
        builder: (context, appState, child) {
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) {
              setState(() {
                _index = value;
              });
            },
            destinations: const [
        
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                label: 'Dashboard',
              ),
         
              NavigationDestination(
                icon: Icon(Icons.work_outline),
                label: 'Jobs',
              ),
            
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                label: 'Application',
              ),
              
              NavigationDestination(
                icon: Icon(Icons.check_circle_outline),
                label: 'Attendance',
              ),
        
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}
