// ignore_for_file: directives_ordering, require_trailing_commas

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/shared/widgets/section_header.dart';
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
    if (workerId.isNotEmpty) {
      await appState.loadWorkerJobs(workerId);
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
                ? const SliverToBoxAdapter(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.work_off_outlined, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'No matching jobs',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Try adjusting your filters or check back later',
                              textAlign: TextAlign.center,
                            ),
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
                children: [
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

              if (job.hasApplied != true)
                FilledButton.tonal(
                  onPressed: () => _handleApply(context),
                  child: Text('${job.applicantsCount} applicants · Apply now'),
                ),
            ],
          ),
        ),
      ),
    ); // Close AccessTagPositioned
  }

  Future<void> _handleApply(BuildContext context) async {
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
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to apply: ${error.toString()}')),
      );
    }
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
