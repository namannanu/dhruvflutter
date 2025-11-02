// ignore_for_file: require_trailing_commas, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/shared/widgets/section_header.dart';
import 'package:talent/features/worker/screens/premium_plan_screen.dart';
import 'package:talent/features/worker/screens/worker_profile_screen_new.dart';
import 'package:talent/features/worker/screens/worker_settings_screen.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Immediate cache-first load for instant UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _quickCacheLoad();
    });
  }

  Future<void> _quickCacheLoad() async {
    if (!mounted) return;

    try {
      final appState = context.read<AppState>();

      // Try the new ultra-fast dashboard load
      await appState.quickDashboardLoad();

      // If we still don't have profile data, fall back to light refresh
      if (appState.workerProfile == null) {
        await appState.lightRefreshActiveRole().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print('⚠️ Fallback load timed out');
          },
        );
      }
    } catch (error) {
      print('❌ Quick cache load error: $error');
      // Final fallback to light refresh
      await _lightRefresh();
    }
  }

  void _backgroundRefresh() {
    // Non-blocking background refresh
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (!mounted) return;
      try {
        final appState = context.read<AppState>();
        await appState.lightRefreshActiveRole();
      } catch (error) {
        print('🔄 Background refresh completed with minor issues: $error');
      }
    });
  }

  Future<void> _lightRefresh() async {
    if (_isRefreshing || !mounted) return;

    setState(() => _isRefreshing = true);
    try {
      final appState = context.read<AppState>();
      // Use the new lightweight refresh method with timeout
      await appState.lightRefreshActiveRole().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Light refresh timed out');
        },
      );
    } catch (error) {
      print('❌ Light refresh error: $error');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _fullRefresh() async {
    if (_isRefreshing || !mounted) return;

    setState(() => _isRefreshing = true);
    try {
      final appState = context.read<AppState>();
      await appState.refreshActiveRole().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Full refresh timed out');
        },
      );
    } catch (error) {
      print('❌ Full refresh error: $error');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final metrics = appState.workerMetrics;
    final profile = appState.workerProfile;

    // Show loading only if we truly have no data at all
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fullRefresh,
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
              const SizedBox(height: 16),
              Text(
                'Loading your dashboard...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Getting your latest data',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fullRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // At this point we know profile is not null
    // Show fallback metrics while loading
    final safeMetrics = metrics ??
        const WorkerDashboardMetrics(
          availableJobs: 0,
          activeApplications: 0,
          upcomingShifts: 0,
          completedHours: 0,
          earningsThisWeek: 0.0,
          freeApplicationsRemaining: 2,
          isPremium: false,
        );
    final currency = NumberFormat.simpleCurrency();

    return RefreshIndicator(
      onRefresh: _fullRefresh,
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
                      value: safeMetrics.availableJobs.toString(),
                      icon: Icons.work_outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      label: 'Active applications',
                      value: safeMetrics.activeApplications.toString(),
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
                      value: safeMetrics.upcomingShifts.toString(),
                      icon: Icons.schedule,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      label: 'Hours completed',
                      value: safeMetrics.completedHours.toStringAsFixed(0),
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
                      label: 'This week earnings',
                      value: currency.format(safeMetrics.earningsThisWeek),
                      icon: Icons.attach_money,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      label: 'Free applications left',
                      value: safeMetrics.freeApplicationsRemaining.toString(),
                      icon: Icons.free_breakfast,
                      highlight: safeMetrics.freeApplicationsRemaining == 0,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

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
                      builder: (context) => const WorkerProfileScreen()));
            },
          ),

          _ActionCard(
            title: ' Unlock premium applications',
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
                await _fullRefresh();
              }
            },
          ),

          const SizedBox(height: 32),

          // Attendance
          const SectionHeader(
            title: 'Attendance insights',
            subtitle: 'Track hours and lateness',
            style: TextStyle(fontSize: 10),
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
