import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/team_provider.dart';
import 'features/employer/screens/employer_dashboard_screen.dart';
import 'features/team/screens/team_management_screen.dart';

class WorkConnectApp extends StatelessWidget {
  const WorkConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Add other providers here
        ChangeNotifierProvider(create: (_) => TeamProvider()),
      ],
      child: MaterialApp(
        title: 'WorkConnect',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: '/employer-dashboard',
        routes: {
          '/employer-dashboard': (context) => const EmployerDashboardScreen(),
          '/team-management': (context) => const TeamManagementScreen(),
        },
        onGenerateRoute: (settings) {
          // Handle user data route with arguments
          if (settings.name == '/user-data') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => UserDataScreen(
                userId: args['userId'] as String,
                userName: args['userName'] as String,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}

// Example User Data Screen that would be implemented
class UserDataScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserDataScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserDataScreen> createState() => _UserDataScreenState();
}

class _UserDataScreenState extends State<UserDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);
      final userData = await teamProvider.getUserData(widget.userId);

      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName} Data'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Jobs', icon: Icon(Icons.work)),
            Tab(text: 'Applications', icon: Icon(Icons.assignment)),
            Tab(text: 'Attendance', icon: Icon(Icons.access_time)),
            Tab(text: 'Employment', icon: Icon(Icons.business)),
            Tab(text: 'Payments', icon: Icon(Icons.payment)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      const Text('Error loading user data'),
                      const SizedBox(height: 8),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildJobsTab(),
                    _buildApplicationsTab(),
                    _buildAttendanceTab(),
                    _buildEmploymentTab(),
                    _buildPaymentsTab(),
                  ],
                ),
    );
  }

  Widget _buildJobsTab() {
    final jobs = _userData?['jobs'] as List<dynamic>? ?? [];

    if (jobs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No jobs found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return Card(
          child: ListTile(
            title: Text((job['title'] ?? 'Unknown Job') as String),
            subtitle: Text((job['description'] ?? '') as String),
            trailing: Chip(
              label: Text((job['status'] ?? 'unknown') as String),
            ),
          ),
        );
      },
    );
  }

  Widget _buildApplicationsTab() {
    final applications = _userData?['applications'] as List<dynamic>? ?? [];

    if (applications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No applications found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];
        return Card(
          child: ListTile(
            title: Text((application['jobTitle'] ?? 'Unknown Job') as String),
            subtitle: Text(
                'Status: ${(application['status'] ?? 'unknown') as String}'),
            trailing: Text((application['appliedAt'] ?? '') as String),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab() {
    final attendance = _userData?['attendance'] as List<dynamic>? ?? [];

    if (attendance.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No attendance records found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attendance.length,
      itemBuilder: (context, index) {
        final record = attendance[index];
        return Card(
          child: ListTile(
            title: Text(
                '${(record['type'] ?? 'Unknown') as String} - ${(record['jobTitle'] ?? 'Job') as String}'),
            subtitle: Text((record['timestamp'] ?? '') as String),
            trailing: record['location'] != null &&
                    record['location']['isWithinGeofence'] == true
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.warning, color: Colors.orange),
          ),
        );
      },
    );
  }

  Widget _buildEmploymentTab() {
    final employments = _userData?['employments'] as List<dynamic>? ?? [];

    if (employments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No employment records found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: employments.length,
      itemBuilder: (context, index) {
        final employment = employments[index];
        return Card(
          child: ListTile(
            title: Text((employment['jobTitle'] ?? 'Unknown Job') as String),
            subtitle: Text(
                'Status: ${(employment['status'] ?? 'unknown') as String}'),
            trailing: Text('\$${employment['hourlyRate'] ?? 0}/hr'),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    final payments = _userData?['payments'] as List<dynamic>? ?? [];

    if (payments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No payment records found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return Card(
          child: ListTile(
            title: Text('\$${payment['amount'] ?? 0}'),
            subtitle: Text(
                '${(payment['jobTitle'] ?? 'Job') as String} - ${(payment['payPeriod'] ?? '') as String}'),
            trailing: Chip(
              label: Text((payment['status'] ?? 'unknown') as String),
            ),
          ),
        );
      },
    );
  }
}

// Example of how to use in main.dart
void main() {
  runApp(const WorkConnectApp());
}
