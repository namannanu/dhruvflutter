// ignore_for_file: require_trailing_commas, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/shared/widgets/section_header.dart';
import 'package:talent/features/worker/screens/premium_plan_screen.dart';
import 'package:talent/features/worker/screens/worker_profile_screen_new.dart';
import 'package:talent/features/worker/screens/worker_settings_screen.dart';

class WorkerDashboardScreen extends StatelessWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final metrics = appState.workerMetrics;
    final profile = appState.workerProfile;

    if (profile == null) {
      // Display a more informative loading screen
      return Scaffold(
        appBar: AppBar(
          title: const Text('Worker Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<AppState>().refreshActiveRole(),
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkerSettingsScreen(),
                  ),
                );
              },
              tooltip: 'Settings',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text('Loading profile data...',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing data...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  // Call refreshActiveRole which now properly initializes data
                  await context.read<AppState>().refreshActiveRole();
                },
                child: const Text('Tap to refresh'),
              ),
            ],
          ),
        ),
      );
    }

    final currency = NumberFormat.simpleCurrency();

    return RefreshIndicator(
      onRefresh: () async => context.read<AppState>().refreshActiveRole(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header with profile info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${profile.firstName.split(' ').first}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(profile.bio,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  profile.firstName.isNotEmpty ? profile.firstName[0] : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Metrics - 2 columns grid
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Available jobs',
                      value: metrics!.availableJobs.toString(),
                      icon: Icons.work_outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      label: 'Active applications',
                      value: metrics.activeApplications.toString(),
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Upcoming shifts',
                      value: metrics.upcomingShifts.toString(),
                      icon: Icons.schedule,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      label: 'Hours completed',
                      value: metrics.completedHours.toStringAsFixed(0),
                      icon: Icons.timer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Earnings this week',
                      value: currency.format(metrics.earningsThisWeek),
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      label: 'Free applications left',
                      value: metrics.freeApplicationsRemaining.toString(),
                      icon: Icons.workspace_premium_outlined,
                      highlight: metrics.freeApplicationsRemaining == 0,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Action center
          const SectionHeader(
            title: 'Action center',
            subtitle: 'Pick up where you left off',
          ),
          const SizedBox(height: 16),

          _ActionCard(
            title: 'Complete your profile',
            description:
                'Add new skills, languages, and work preferences so employers can discover you faster.',
            icon: Icons.person_outline,
            buttonLabel: 'Update profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkerProfileScreen(),
                ),
              );
            },
          ),

          _ActionCard(
            title: 'Unlock premium applications',
            description: () {
              final remainingApplications = appState.getRemainingApplications();
              final isPremium = profile.isPremium;

              if (isPremium) {
                return 'Premium active - Apply to unlimited jobs and access premium features.';
              } else if (remainingApplications > 0) {
                return 'You have $remainingApplications application${remainingApplications == 1 ? '' : 's'} remaining. Go unlimited and access premium job postings.';
              } else {
                return 'Application limit reached! Upgrade to continue applying to jobs and access premium postings.';
              }
            }(),
            icon: Icons.workspace_premium,
            buttonLabel: profile.isPremium ? 'Manage plan' : 'View plans',
            highlight: !profile.isPremium,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumPlanScreen(),
                ),
              );

              // Refresh data if premium was activated
              if (result == true) {
                await appState.refreshActiveRole();
              }
            },
          ),

          const SizedBox(height: 32),

          // Attendance
          const SectionHeader(
            title: 'Attendance insights',
            subtitle: 'Track hours and lateness',
          ),
          const SizedBox(height: 16),
          ...appState.workerAttendance
              .take(3)
              .map((record) => _AttendanceTile(record: record)),
        ],
      ),
    );
  }
}

// ---------------- Metric Card ----------------
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background =
        highlight ? theme.colorScheme.errorContainer : Colors.white;
    final foreground =
        highlight ? theme.colorScheme.error : theme.colorScheme.primary;

    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(color: foreground),
            ),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// ---------------- Action Card ----------------
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.buttonLabel,
    required this.onTap,
    this.highlight = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        highlight ? theme.colorScheme.primary : theme.colorScheme.secondary;

    final iconAvatar = CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.12),
      foregroundColor: color,
      child: Icon(icon),
    );

    Widget buildContent(bool stacked) {
      final textColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(onPressed: onTap, child: Text(buttonLabel)),
          ),
        ],
      );

      return stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [iconAvatar, const SizedBox(height: 16), textColumn],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconAvatar,
                const SizedBox(width: 16),
                Expanded(child: textColumn)
              ],
            );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 360;
            return buildContent(stacked);
          },
        ),
      ),
    );
  }
}

// ---------------- Attendance Tile ----------------
class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('MMM d · HH:mm');

    Color statusColor;
    String statusLabel;
    switch (record.status) {
      case AttendanceStatus.scheduled:
        statusColor = theme.colorScheme.primary;
        statusLabel = 'Scheduled';
        break;
      case AttendanceStatus.clockedIn:
        statusColor = theme.colorScheme.secondary;
        statusLabel = 'Clocked in';
        break;
      case AttendanceStatus.completed:
        statusColor = theme.colorScheme.tertiary;
        statusLabel = 'Completed';
        break;
      case AttendanceStatus.missed:
        statusColor = theme.colorScheme.error;
        statusLabel = 'Missed';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(record.jobTitle ?? 'Shift',
                    style: theme.textTheme.titleMedium),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${formatter.format(record.scheduledStart)} — ${formatter.format(record.scheduledEnd)}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Earned ${NumberFormat.simpleCurrency().format(record.earnings)}',
                ),
                if (record.isLate) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.warning_amber_outlined,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 4),
                  const Text('Marked late'),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
