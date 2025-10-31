// ignore_for_file: directives_ordering, require_trailing_commas, avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';
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
  String _filter =
      'available'; // 'available' = open jobs, 'applied' = jobs I applied to
  String _categoryFilter = 'All Jobs'; // Category filter
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _loading = true);
    final appState = context.read<AppState>();
    final workerId = appState.currentUser?.id ?? '';

    if (workerId.isEmpty) {
      print('❌ Cannot load jobs: No worker ID available');
      setState(() => _loading = false);
      return;
    }

    try {
      print('🔍 Loading jobs for worker: $workerId');
      await appState.loadWorkerJobs(workerId);
      print('✅ Jobs loaded successfully');
    } catch (error) {
      print('❌ Failed to load jobs: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load jobs: ${error.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadJobs,
            ),
          ),
        );
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final jobs = appState.workerJobs;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredJobs = jobs.where((job) {
      // Only show active jobs (not closed or filled)
      if (job.status != JobStatus.active) {
        return false;
      }

      // Filter by category
      if (_categoryFilter != 'All Jobs') {
        bool matchesCategory = false;
        for (String tag in job.tags) {
          if (tag.toLowerCase().contains(_categoryFilter.toLowerCase())) {
            matchesCategory = true;
            break;
          }
        }
        // Special handling for "Daily Jobs"
        if (_categoryFilter == 'Daily Jobs') {
          matchesCategory = job.tags.any((tag) =>
              tag.toLowerCase().contains('daily') ||
              tag.toLowerCase().contains('event') ||
              tag.toLowerCase().contains('flexible'));
        }
        if (!matchesCategory) {
          return false;
        }
      }

      // Filter by application status
      if (_filter == 'applied') {
        // Show jobs I have applied to (assuming hasApplied property)
        return job.hasApplied == true;
      } else if (_filter == 'available') {
        // Show jobs I haven't applied to yet
        return job.hasApplied != true;
      }
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async => context.read<AppState>().refreshActiveRole(),
      child: CustomScrollView(
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
                  ),
                  const SizedBox(height: 16),
                  // Category Filter Chips
                  _CategoryFilterChips(
                    selectedCategory: _categoryFilter,
                    onCategoryChanged: (String category) {
                      setState(() {
                        _categoryFilter = category;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Simple Available/Applied Filter
                  _WorkerJobApplicationFilter(
                    selectedFilter: _filter,
                    onFilterChanged: (String filter) {
                      setState(() {
                        _filter = filter;
                      });
                    },
                    jobCounts: {
                      'available': jobs
                          .where((j) =>
                              j.status == JobStatus.active &&
                              j.hasApplied != true)
                          .length,
                      'applied': jobs.where((j) => j.hasApplied == true).length,
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
                              jobs.isEmpty
                                  ? Icons.error_outline
                                  : Icons.work_off_outlined,
                              size: 48,
                              color: jobs.isEmpty ? Colors.red : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              jobs.isEmpty
                                  ? 'Unable to load jobs'
                                  : 'No matching jobs',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              jobs.isEmpty
                                  ? 'Check your internet connection and login status. Pull down to retry.'
                                  : 'Try adjusting your filters or check back later',
                              textAlign: TextAlign.center,
                            ),
                            if (jobs.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadJobs,
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
                          padding: const EdgeInsets.only(bottom: 12),
                          child: JobCard(job: job),
                        );
                      },
                      childCount: filteredJobs.length,
                    ),
                  ),
          ),
        ],
      ),
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
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
      ),
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
                    'Submit as many applications as you need each month.',
                  ),
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
            Text(
              'Ready to submit',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (job.businessName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Company: ${job.businessName}'),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Rate: \$${job.hourlyRate.toStringAsFixed(2)}/hr',
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Premium upgrade flow coming soon — contact support to enable.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.lock_open),
            label: const Text('Contact support to upgrade'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Maybe later'),
          ),
        ],
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
  });

  final JobPosting job;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final teamProvider = context.watch<TeamProvider>();
    final currentUser = appState.currentUser;

    // Get access context for this job
    BusinessAccessInfo? accessInfo;
    if (currentUser != null) {
      accessInfo = BusinessAccessContext().getAccessContext(
        employerEmail: job.employerId, // Using employerId as fallback
        employerName: null,
        businessName: job.businessName.isNotEmpty ? job.businessName : null,
        currentUserEmail: currentUser.email,
        teamAccesses: teamProvider.managedAccess,
      );
    }

    return AccessTagPositioned(
      accessInfo: accessInfo,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BusinessLogoAvatar(
                    logoUrl: job.businessLogoSquareUrl ??
                        job.businessLogoUrl ??
                        job.businessLogoOriginalUrl,
                    name: job.businessName.isNotEmpty
                        ? job.businessName
                        : job.title,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (job.businessName.isNotEmpty)
                          Text(
                            job.businessName,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (job.isVerificationRequired == true)
                    const Tooltip(
                      message: 'Verification required',
                      child: Icon(Icons.verified_user,
                          color: Colors.blue, size: 16),
                    ),
                  if (job.premiumRequired == true)
                    const Tooltip(
                      message: 'Premium job',
                      child: Icon(Icons.star, color: Colors.amber, size: 16),
                    ),
                  if (job.hasApplied == true) ...[
                    const SizedBox(width: 8),
                    const Chip(label: Text('Applied')),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Tags
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(
                      NumberFormat.simpleCurrency().format(job.hourlyRate),
                    ),
                  ),
                  if (job.distanceMiles != null && job.distanceMiles! > 0)
                    Chip(
                      label: Text(
                          '${job.distanceMiles!.toStringAsFixed(1)} miles'),
                    ),
                  if (job.locationSummary != null)
                    Chip(label: Text(job.locationSummary!)),
                  ...job.tags.map((tag) => Chip(label: Text(tag))),
                ],
              ),

              const SizedBox(height: 12),

              Text(job.description),

              const SizedBox(height: 12),

              if (job.hasApplied != true) ...[
                Builder(
                  builder: (context) {
                    final appState = context.watch<AppState>();
                    final canApply = appState.canApplyToJob();

                    return FilledButton.tonal(
                      onPressed: () => _handleApply(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: canApply
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.1),
                      ),
                      child: Text(
                        canApply
                            ? '${job.applicantsCount} applicants · Apply now'
                            : 'Upgrade to Premium to Apply',
                      ),
                    );
                  },
                ),
                // Show remaining applications info for free users
                Builder(
                  builder: (context) {
                    final appState = context.watch<AppState>();
                    final remainingApplications =
                        appState.getRemainingApplications();
                    final profile = appState.workerProfile;

                    if (profile?.isPremium == true) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        remainingApplications > 0
                            ? 'You have $remainingApplications application${remainingApplications == 1 ? '' : 's'} remaining'
                            : 'Application limit reached - Upgrade to Premium',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: remainingApplications > 0
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    ); // Close AccessTagPositioned
  }

  Future<void> _handleApply(BuildContext context) async {
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
        const SnackBar(content: Text('Application submitted.')),
      );
    } catch (error) {
      if (!context.mounted) return;

      // Check if it's a 402 payment required error
      if (error.toString().contains('402') &&
          error.toString().toLowerCase().contains('free application limit')) {
        // Show premium upgrade dialog
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
      builder: (BuildContext context) {
        return AlertDialog(
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
                'Upgrade to Premium to continue applying for jobs and unlock:',
              ),
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
                    Text(
                      'Job: ${job.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToSubscriptionPage(context, job);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade Now'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToSubscriptionPage(BuildContext context, JobPosting job) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkerPremiumUpgradeScreen(pendingJob: job),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter jobs:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'available',
              label: Text('Available (${jobCounts['available'] ?? 0})'),
            ),
            ButtonSegment(
              value: 'applied',
              label: Text('Applied (${jobCounts['applied'] ?? 0})'),
            ),
          ],
          selected: {selectedFilter},
          onSelectionChanged: (selection) {
            onFilterChanged(selection.first);
          },
        ),
      ],
    );
  }
}

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
      'Restaurant',
      'Retail',
      'Warehouse',
      'Daily Jobs',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((category) {
              final isSelected = selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      onCategoryChanged(category);
                    },
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    showCheckmark: false,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
