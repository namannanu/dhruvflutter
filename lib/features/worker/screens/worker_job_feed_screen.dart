// ignore_for_file: directives_ordering, require_trailing_commas, avoid_print, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/core/utils/job_display_utils.dart';
import 'package:talent/core/utils/image_url_optimizer.dart';
import 'package:talent/features/shared/widgets/section_header.dart';
import 'package:talent/features/shared/widgets/business_logo_avatar.dart';
import 'package:talent/core/widgets/access_tag.dart';
import 'package:talent/core/services/business_access_context.dart';
import 'package:talent/core/providers/team_provider.dart';

class WorkerJobFeedScreen extends StatefulWidget {
  const WorkerJobFeedScreen({super.key});

  @override
  State<WorkerJobFeedScreen> createState() => _WorkerJobFeedScreenState();
}

class _WorkerJobFeedScreenState extends State<WorkerJobFeedScreen> {
  // 'available' = open jobs, 'applied' = jobs I applied to
  String _filter = 'available';
  String _categoryFilter = 'All Jobs';
  bool _hasShownInitialMessage = false;

  // Cache for filtered jobs to avoid recalculating
  List<JobPosting>? _cachedFilteredJobs;
  String? _lastFilterKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _debugJobState());
  }

  void _debugJobState() {
    final appState = context.read<AppState>();
    print('🔍 === OPTIMIZED JOB FEED DEBUG ===');
    print('🔍 Total worker jobs: ${appState.workerJobs.length}');
    print('🔍 Current filter: $_filter');
    print('🔍 Current category: $_categoryFilter');
    print('🔍 Current user ID: ${appState.currentUser?.id}');
    print('🔍 User type: ${appState.currentUser?.type}');

    for (int i = 0; i < appState.workerJobs.length; i++) {
      final job = appState.workerJobs[i];
      print('🔍 Job $i: ${job.id} - ${job.title}');
      print('   Status: ${job.status} (${job.status.name})');
      print('   HasApplied: ${job.hasApplied}');
      print('   BusinessName: ${job.businessName}');
      print('   BusinessAddress: "${job.businessAddress}"');
      print('   BusinessAddress.isEmpty: ${job.businessAddress.isEmpty}');
      print('   Tags: ${job.tags}');
    }
    print('🔍 ===============================');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final jobs = appState.workerJobs;

        print(
            '🔍 DEBUG: Building WorkerJobFeedScreen with ${jobs.length} total jobs');
        print('🔍 DEBUG: Current filter: $_filter, category: $_categoryFilter');

        final canApply = appState.canApplyToJob();
        final remainingApplications = appState.getRemainingApplications();
        final isPremium = appState.workerProfile?.isPremium == true;

        final filteredJobs = _getFilteredJobs(jobs);
        print('🔍 DEBUG: Filtered jobs count: ${filteredJobs.length}');

        // One-time heads-up if jobs exist but filtered out of "available"
        if (!_hasShownInitialMessage &&
            jobs.isNotEmpty &&
            filteredJobs.isEmpty &&
            _filter == 'available') {
          _hasShownInitialMessage = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'You have jobs, but they\'re in the "applied" section. Tap "Applied" to see them.',
                ),
                action: SnackBarAction(
                  label: 'Show Applied',
                  onPressed: () {
                    setState(() {
                      _filter = 'applied';
                      _cachedFilteredJobs = null;
                    });
                  },
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          });
        }

        return RefreshIndicator(
          onRefresh: () async => appState.refreshActiveRole(),
          child: _buildJobsList(
            context,
            filteredJobs,
            jobs,
            canApply,
            remainingApplications,
            isPremium,
          ),
        );
      },
    );
  }

  List<JobPosting> _getFilteredJobs(List<JobPosting> jobs) {
    // Cache key includes filter/category and a snapshot of first few job states
    final filterKey =
        '$_filter-$_categoryFilter-${jobs.length}-${jobs.map((j) => '${j.id}:${j.hasApplied}').take(5).join(',')}';

    if (_lastFilterKey == filterKey && _cachedFilteredJobs != null) {
      return _cachedFilteredJobs!;
    }

    print(
      '🔍 DEBUG: Filtering ${jobs.length} jobs with filter: $_filter, category: $_categoryFilter',
    );

    final filtered = jobs.where((job) {
      // Only show active jobs
      if (job.status != JobStatus.active) return false;

      // Category filter
      if (_categoryFilter != 'All Jobs') {
        bool matchesCategory = false;

        if (_categoryFilter == 'Daily Jobs') {
          matchesCategory = job.tags.any((tag) {
            final t = tag.toLowerCase();
            return t.contains('daily') ||
                t.contains('event') ||
                t.contains('flexible');
          });
        } else {
          final categoryLower = _categoryFilter.toLowerCase();
          matchesCategory =
              job.tags.any((tag) => tag.toLowerCase().contains(categoryLower));
        }

        if (!matchesCategory) return false;
      }

      // Applied/Available filter
      if (_filter == 'applied') return job.hasApplied == true;
      if (_filter == 'available') return job.hasApplied != true;

      return true;
    }).toList();

    print(
        '🔍 DEBUG: Filtered result: ${filtered.length} jobs out of ${jobs.length}');

    _cachedFilteredJobs = filtered;
    _lastFilterKey = filterKey;
    return filtered;
  }

  Widget _buildJobsList(
    BuildContext context,
    List<JobPosting> filteredJobs,
    List<JobPosting> allJobs,
    bool canApply,
    int remainingApplications,
    bool isPremium,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Open positions',
                  subtitle: 'Explore and apply for jobs',
                  style: TextStyle(fontSize: 10),
                ),
                const SizedBox(height: 16),
                _CategoryFilterChips(
                  selectedCategory: _categoryFilter,
                  onCategoryChanged: (category) {
                    setState(() {
                      _categoryFilter = category;
                      _cachedFilteredJobs = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _WorkerJobApplicationFilter(
                  selectedFilter: _filter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _filter = filter;
                      _cachedFilteredJobs = null;
                    });
                  },
                  jobCounts: {
                    'available': allJobs
                        .where((j) =>
                            j.status == JobStatus.active &&
                            j.hasApplied != true)
                        .length,
                    'applied':
                        allJobs.where((j) => j.hasApplied == true).length,
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: filteredJobs.isEmpty
              ? SliverToBoxAdapter(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            allJobs.isEmpty
                                ? Icons.error_outline
                                : Icons.work_off_outlined,
                            size: 48,
                            color: allJobs.isEmpty ? Colors.red : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            allJobs.isEmpty
                                ? 'Unable to load jobs'
                                : _filter == 'available'
                                    ? 'No available jobs to apply to'
                                    : 'No applied jobs yet',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            allJobs.isEmpty
                                ? 'Check your internet connection and login status. Pull down to retry.'
                                : _filter == 'available'
                                    ? 'Total jobs: ${allJobs.length}. You may have already applied to available jobs. Check the "Applied" tab to see your applications.'
                                    : 'You haven\'t applied to any jobs yet. Switch to "Available" to see jobs you can apply to.',
                            textAlign: TextAlign.center,
                          ),
                          if (allJobs.isNotEmpty && filteredJobs.isEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_filter == 'available')
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _filter = 'applied';
                                        _cachedFilteredJobs = null;
                                      });
                                    },
                                    child: const Text('View Applied Jobs'),
                                  ),
                                if (_filter == 'applied')
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _filter = 'available';
                                        _cachedFilteredJobs = null;
                                      });
                                    },
                                    child: const Text('View Available Jobs'),
                                  ),
                              ],
                            ),
                          ],
                          if (allJobs.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  context.read<AppState>().refreshActiveRole(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final job = filteredJobs[index];
                      return Padding(
                        key: ValueKey(job.id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: JobCard(
                          job: job,
                          canApply: canApply,
                          remainingApplications: remainingApplications,
                          isPremium: isPremium,
                          onApply: () => _handleApply(context, job),
                        ),
                      );
                    },
                    childCount: filteredJobs.length,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _handleApply(BuildContext context, JobPosting job) async {
    final appState = context.read<AppState>();

    // Check if user can apply to more jobs
    if (!appState.canApplyToJob()) {
      _showPremiumUpgradeDialog(context, job);
      return;
    }

    final noteController = TextEditingController();

    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apply for job'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Add a note (optional)',
            hintText: 'Why you\'re a great fit...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          FilledButton(
            child: const Text('Apply'),
            onPressed: () =>
                Navigator.of(dialogContext).pop(noteController.text.trim()),
          ),
        ],
      ),
    );

    if (message == null) return;
    if (!context.mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AppState>().submitWorkerApplication(
            jobId: job.id,
            message: message.isEmpty ? null : message,
          );
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Application submitted.')));
    } catch (error) {
      if (!context.mounted) return;

      // Check if it's a 402 payment required error
      final err = error.toString().toLowerCase();
      if (err.contains('402') && err.contains('free application limit')) {
        _showPremiumUpgradeDialog(context, job);
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to apply: ${error.toString()}')),
        );
      }
    }
  }

  void _showPremiumUpgradeDialog(BuildContext context, JobPosting job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You\'ve reached your free application limit!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
                'Upgrade to Premium to continue applying for jobs and unlock:'),
            const SizedBox(height: 8),
            const Text('• Unlimited job applications'),
            const Text('• Priority support'),
            const Text('• Advanced job filters'),
            const Text('• Direct employer messaging'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Job: ${job.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (job.businessName.isNotEmpty)
                    Text('Company: ${job.businessName}'),
                  Text('Rate: \$${job.hourlyRate.toStringAsFixed(2)}/hr'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your application will be saved and automatically submitted once you upgrade.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Later')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _navigateToSubscriptionPage(context, job);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _navigateToSubscriptionPage(BuildContext context, JobPosting job) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => WorkerPremiumUpgradeScreen(pendingJob: job)),
    );
  }
}

class WorkerPremiumUpgradeScreen extends StatelessWidget {
  const WorkerPremiumUpgradeScreen({super.key, this.pendingJob});
  final JobPosting? pendingJob;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final job = pendingJob;

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Premium')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Unlock unlimited applications',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            job != null
                ? 'Upgrade now to finish applying for ${job.title} and other premium roles.'
                : 'Upgrade now to access premium jobs and apply without limits.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side:
                  BorderSide(color: theme.colorScheme.primary.withOpacity(.1)),
            ),
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.work_outline),
                  title: Text('Unlimited applications'),
                  subtitle: Text(
                      'Submit as many applications as you need each month.'),
                ),
                Divider(height: 0),
                ListTile(
                  leading: Icon(Icons.workspace_premium_outlined),
                  title: Text('Premium job access'),
                  subtitle: Text('See roles from top employers before others.'),
                ),
                Divider(height: 0),
                ListTile(
                  leading: Icon(Icons.support_agent_outlined),
                  title: Text('Priority support'),
                  subtitle:
                      Text('Get fast help from our support and career team.'),
                ),
              ],
            ),
          ),
          if (job != null) ...[
            const SizedBox(height: 24),
            Text('Ready to submit',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      if (job.businessName.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Company: ${job.businessName}'),
                      ],
                      const SizedBox(height: 8),
                      Text('Rate: \$${job.hourlyRate.toStringAsFixed(2)}/hr'),
                    ]),
              ),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Premium upgrade flow coming soon — contact support to enable.')),
              );
            },
            icon: const Icon(Icons.lock_open),
            label: const Text('Contact support to upgrade'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 12),
          TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Maybe later')),
        ],
      ),
    );
  }
}

/* ================== Job Card & Pieces ================== */

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.isPremium,
    required this.remainingApplications,
    required this.canApply,
    required this.onApply,
  });

  final JobPosting job;
  final bool isPremium;
  final int remainingApplications;
  final bool canApply;
  final VoidCallback onApply;

  /// Format business address with enhanced logic and city-specific formatting
  String _formatBusinessAddress() {
    // Debug: Print what we have
    print('🏠 Worker Feed DEBUG: Job ${job.id}');
    print('   job.businessAddress: "${job.businessAddress}"');
    print('   job.locationSummary: "${job.locationSummary}"');
    print('   job.businessName: "${job.businessName}"');
    if (job.location != null) {
      print(
          '   job.location: line1="${job.location!.line1}", city="${job.location!.city}", state="${job.location!.state}", lat=${job.location!.latitude}, lng=${job.location!.longitude}');
    }

    // Primary: Use businessAddress field (populated by backend migration/new jobs)
    if (job.businessAddress.isNotEmpty) {
      print('   ✅ Using businessAddress: "${job.businessAddress}"');
      return _cleanAddressFormat(job.businessAddress);
    }

    // Secondary: Use resolved location if available
    final location = job.location;
    final locationAddress =
        location?.fullAddress ?? location?.shortAddress ?? location?.line1;
    if (locationAddress != null && locationAddress.trim().isNotEmpty) {
      print('   ✅ Using resolved location address: "$locationAddress"');
      return _cleanAddressFormat(locationAddress.trim());
    }

    // Fallback: Use locationSummary if available
    if (job.locationSummary?.trim().isNotEmpty == true) {
      print('   ✅ Using locationSummary: "${job.locationSummary}"');
      return _cleanAddressFormat(job.locationSummary!.trim());
    }

    // No address available - return empty string instead of business name
    print('   ❌ No address found, returning empty');
    return ''; // No location info available
  }

  /// Clean and format address string for better display
  String _cleanAddressFormat(String address) {
    final normalized = address.trim();
    if (normalized.isEmpty) return '';

    final lowered = normalized.toLowerCase();
    if (lowered == 'null' || lowered == 'undefined' || lowered == 'n/a') {
      return '';
    }

    // Remove any excessive whitespace
    final cleaned = normalized.replaceAll(RegExp(r'\s+'), ' ');

    // Smart address formatting - prioritize street + city for readability
    if (cleaned.contains(',')) {
      final parts = cleaned.split(',').map((e) => e.trim()).toList();

      // If we have multiple parts, show street + city/state for better UX
      if (parts.length >= 3) {
        // Format: "Street, City, State" instead of full long address
        final street = parts[0]; // "Mahaveer Nagar III Cir"
        final city =
            parts.length >= 4 ? parts[parts.length - 3] : parts[1]; // "Kota"
        final state =
            parts.length >= 3 ? parts[parts.length - 2] : ''; // "Rajasthan"

        if (street.isNotEmpty && city.isNotEmpty) {
          return state.isNotEmpty ? '$street, $city, $state' : '$street, $city';
        }
      }
    }

    // Fallback: Truncate very long addresses for better UI
    if (cleaned.length > 60) {
      // Try to find a good break point (comma, after street address)
      final commaIndex = cleaned.indexOf(',');
      if (commaIndex > 20 && commaIndex < 50) {
        final parts = cleaned.split(',');
        if (parts.length >= 2) {
          // Show first part + last part (usually city/state)
          final firstPart = parts[0].trim();
          final lastPart = parts.last.trim();
          return '$firstPart, $lastPart';
        }
      }
      // If no good break point, just truncate with ellipsis
      return '${cleaned.substring(0, 57)}...';
    }

    return cleaned;
  }

  /// Get formatted location for detail view (allows longer text)
  String _getFormattedLocation() {
    // Primary: Use businessAddress field (populated by backend migration/new jobs)
    if (job.businessAddress.isNotEmpty) {
      final cleaned = _cleanAddressFormat(job.businessAddress);
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }

    final location = job.location;
    final locationAddress =
        location?.fullAddress ?? location?.shortAddress ?? location?.line1;
    if (locationAddress != null && locationAddress.trim().isNotEmpty) {
      final cleaned = _cleanAddressFormat(locationAddress);
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }

    // Fallback: Use locationSummary if available
    if (job.locationSummary?.trim().isNotEmpty == true) {
      final cleaned = _cleanAddressFormat(job.locationSummary!);
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }

    // No location address available
    return ''; // No location info available
  }

  /// Format recurrence/frequency for display
  String _formatRecurrence() {
    return JobDisplayUtils.formatRecurrence(job.recurrence);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.select<AppState, User?>((s) => s.currentUser);

    // Enhanced address formatting with better fallback logic
    final headerLocation = _formatBusinessAddress();

    BusinessAccessInfo? accessInfo;
    if (currentUser != null) {
      final teamProvider = context.read<TeamProvider>();
      accessInfo = BusinessAccessContext().getAccessContext(
        employerEmail: job.employerId,
        employerName: null,
        businessName: job.businessName.isNotEmpty ? job.businessName : null,
        currentUserEmail: currentUser.email,
        teamAccesses: teamProvider.managedAccess,
      );
    }

    return AccessTagPositioned(
      accessInfo: accessInfo,
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Logo and Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BusinessLogoAvatar(
                    logoUrl: job.businessLogoSmall ??
                        job.businessLogoSmall ??
                        job.businessLogoSmall,
                    name: job.businessName.isNotEmpty
                        ? job.businessName
                        : job.title,
                    size: 40,
                    imageContext: ImageContext.jobList,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (job.businessName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Company: ${job.businessName}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        if (headerLocation.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            headerLocation,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Job Details List
              _buildJobDetailsList(context),

              const SizedBox(height: 12),

              // Apply Section
              if (job.hasApplied != true)
                _ApplySection(
                  canApply: canApply,
                  isPremium: isPremium,
                  remainingApplications: remainingApplications,
                  applicantsCount: job.applicantsCount,
                  onApply: onApply,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobDetailsList(BuildContext context) {
    final details = <Widget>[];

    // Job Timing - Simple format like "2:00 to 3:00"
    details.add(
      _buildDetailItem(
        'Job Timing',
        _formatSimpleTimeRange(job.scheduleStart, job.scheduleEnd),
        Icons.access_time,
      ),
    );

    // Location - Enhanced formatting with better fallback
    final locationLine = _getFormattedLocation();

    details.add(_buildDetailItem(
      'Location',
      locationLine,
      Icons.location_on,
    ));

    // Pay Information
    final hasOvertime = job.overtime.allowed;
    final baseRate = job.hourlyRate;
    final overtimeRate =
        hasOvertime ? baseRate * job.overtime.rateMultiplier : 0;

    final payRateText = hasOvertime
        ? '\$${baseRate.toStringAsFixed(2)}/hr (\$${overtimeRate.toStringAsFixed(2)}/hr overtime)'
        : '\$${baseRate.toStringAsFixed(2)}/hour';

    details.add(_buildDetailItem(
      'Pay Rate',
      payRateText,
      Icons.attach_money,
    ));

    // Job Description
    details.add(_buildDetailItem(
      'Description',
      job.description,
      Icons.description,
    ));

    // Frequency/Recurrence
    details.add(_buildDetailItem(
      'Frequency',
      _formatRecurrence(),
      Icons.repeat,
    ));

    // Urgency
    details.add(_buildDetailItem(
      'Urgency',
      job.urgency,
      Icons.priority_high,
    ));

    // Distance (if available)
    if (job.distanceMiles != null && job.distanceMiles! > 0) {
      details.add(_buildDetailItem(
        'Distance',
        '${job.distanceMiles!.toStringAsFixed(1)} miles',
        Icons.directions,
      ));
    }

    // Applicants Count
    details.add(_buildDetailItem(
      'Applicants',
      '${job.applicantsCount} applied',
      Icons.people,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details,
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSimpleTimeRange(DateTime start, DateTime end) {
    final hour1 = start.hour;
    final minute1 = start.minute;
    final hour2 = end.hour;
    final minute2 = end.minute;

    final startTime = '$hour1:${minute1.toString().padLeft(2, '0')}';
    final endTime = '$hour2:${minute2.toString().padLeft(2, '0')}';

    return '$startTime to $endTime';
  }
}

class _ApplySection extends StatelessWidget {
  const _ApplySection({
    required this.canApply,
    required this.isPremium,
    required this.remainingApplications,
    required this.applicantsCount,
    required this.onApply,
  });

  final bool canApply;
  final bool isPremium;
  final int remainingApplications;
  final int applicantsCount;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final disabledBg = Theme.of(context).colorScheme.secondary.withOpacity(0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonal(
          onPressed: canApply ? onApply : null,
          style: FilledButton.styleFrom(
            backgroundColor: canApply ? null : disabledBg,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            canApply
                ? '$applicantsCount applicants · Apply now'
                : 'Upgrade to Premium to Apply',
            textAlign: TextAlign.center,
          ),
        ),
        if (!isPremium)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              remainingApplications > 0
                  ? 'You have $remainingApplications application${remainingApplications == 1 ? '' : 's'} remaining'
                  : 'Application limit reached · Upgrade to Premium',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: remainingApplications > 0
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

/* ---------- Helpers ---------- */

NumberFormat _safeCurrency(String? currencyCode) {
  try {
    if (currencyCode != null && currencyCode.trim().isNotEmpty) {
      return NumberFormat.simpleCurrency(name: currencyCode);
    }
    return NumberFormat.simpleCurrency(); // locale default
  } catch (_) {
    // Fallback with plain symbol if intl can't resolve the code.
    return NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  }
}

String _formatRate(NumberFormat fmt, num? hourlyRate) {
  final rate = (hourlyRate ?? 0).toDouble();
  final value =
      rate % 1 == 0 ? rate.toStringAsFixed(0) : rate.toStringAsFixed(2);
  final withSymbol = '${fmt.currencySymbol}$value';
  return '$withSymbol/hr';
}

/* ---------- Filter Widgets ---------- */

class _CategoryFilterChips extends StatelessWidget {
  const _CategoryFilterChips({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All Jobs',
      'Daily Jobs',
      'Retail',
      'Food Service',
      'Warehouse',
      'Delivery',
      'Admin',
      'Other',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = category == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => onCategoryChanged(category),
              backgroundColor: Colors.grey.shade100,
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WorkerJobApplicationFilter extends StatelessWidget {
  const _WorkerJobApplicationFilter({
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.jobCounts,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final Map<String, int> jobCounts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FilterButton(
            title: 'Available',
            count: jobCounts['available'] ?? 0,
            isSelected: selectedFilter == 'available',
            onTap: () => onFilterChanged('available'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FilterButton(
            title: 'Applied',
            count: jobCounts['applied'] ?? 0,
            isSelected: selectedFilter == 'applied',
            onTap: () => onFilterChanged('applied'),
          ),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.title,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.primaryColor.withOpacity(0.1)
          : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? theme.primaryColor : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? theme.primaryColor : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
