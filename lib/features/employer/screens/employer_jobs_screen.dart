// ignore_for_file: require_trailing_commas, directives_ordering, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/employer/screens/employee_hire_application_screen.dart';
import 'package:talent/features/employer/screens/employer_job_create_screen.dart';
import 'package:talent/features/shared/widgets/section_header.dart';
import 'package:talent/features/shared/mixins/auto_refresh_mixin.dart';
import 'package:talent/core/services/permission_service.dart';
import 'package:talent/core/widgets/permission_widgets.dart';
import 'package:talent/core/widgets/access_tag.dart';

class EmployerJobsScreen extends StatefulWidget {
  const EmployerJobsScreen({super.key});

  @override
  State<EmployerJobsScreen> createState() => _EmployerJobsScreenState();
}

class _EmployerJobsScreenState extends State<EmployerJobsScreen>
    with AutoRefreshMixin<EmployerJobsScreen> {
  JobStatus? _jobStatusFilter; // null = all, active, closed, filled

  @override
  Future<void> refreshData() async {
    if (mounted) {
      await context.read<AppState>().refreshActiveRole();
    }
  }

  List<JobPosting> _getFilteredJobs(List<JobPosting> jobs) {
    if (_jobStatusFilter == null) {
      return jobs;
    }
    return jobs.where((job) => job.status == _jobStatusFilter).toList();
  }

  String _getStatusLabel(JobStatus status) {
    switch (status) {
      case JobStatus.active:
        return 'Open';
      case JobStatus.closed:
        return 'Closed';
      case JobStatus.filled:
        return 'Filled';
    }
  }

  Future<void> _closeJobPost(BuildContext context, JobPosting job) async {
    print('_closeJobPost called for job: ${job.id}, status: ${job.status}');

    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Close Job Post?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${job.title}'),
            const SizedBox(height: 8),
            Text('Applicants: ${job.applicantsCount}'),
            const SizedBox(height: 16),
            const Text(
              'This will stop new applications and make the job post inactive. You can reopen it later if needed.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close Job'),
          ),
        ],
      ),
    );

    print('Dialog result: $shouldClose');
    if (shouldClose != true || !context.mounted) {
      return;
    }

    try {
      print('Attempting to close job via API...');
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Closing job posting...')),
      );

      // Update job status to closed
      await context
          .read<AppState>()
          .updateJobStatus(jobId: job.id, status: JobStatus.closed);

      print('Job closed successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job post closed successfully')),
      );
    } catch (e) {
      print('Error closing job: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to close job: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allJobs = appState.employerJobs;
    final filteredJobs = _getFilteredJobs(allJobs);
    final applications = appState.selectedJobApplications;
    final permissionService = PermissionService(context: context);

    if (!permissionService.hasPermission('view_jobs')) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48),
              SizedBox(height: 12),
              Text(
                'You do not have permission to view job postings.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => context.read<AppState>().refreshActiveRole(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(
            title: 'Job management',
            subtitle: 'Post openings, track applicants, and manage quotas',
          ),
          const SizedBox(height: 16),
          // Job Status Filter
          _JobStatusFilter(
            selectedStatus: _jobStatusFilter,
            onStatusChanged: (JobStatus? status) {
              setState(() {
                _jobStatusFilter = status;
              });
            },
            jobCounts: {
              null: allJobs.length,
              JobStatus.active:
                  allJobs.where((j) => j.status == JobStatus.active).length,
              JobStatus.closed:
                  allJobs.where((j) => j.status == JobStatus.closed).length,
              JobStatus.filled:
                  allJobs.where((j) => j.status == JobStatus.filled).length,
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              PermissionGuard(
                permission: 'create_jobs',
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final created = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                          builder: (_) => const EmployerJobCreateScreen()),
                    );
                    if (created == true) {
                      // job list updates inside AppState.createEmployerJob
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create new job'),
                ),
              ),
              PermissionGuard(
                permission: 'view_applications',
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EmployeeHireApplicationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people_alt_outlined),
                  label: Text(
                    'Review applications (${appState.employerApplications.length})',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filteredJobs.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.work_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _jobStatusFilter == null
                          ? 'No job postings yet. Tap "Create new job" to get started.'
                          : 'No ${_getStatusLabel(_jobStatusFilter!).toLowerCase()} jobs found.',
                    ),
                  ],
                ),
              ),
            )
          else
            ...filteredJobs.map((job) => _JobTile(
                  job: job,
                  onCloseJob: _closeJobPost,
                )),
          const SizedBox(height: 24),
          if (permissionService.hasPermission('view_applications') &&
              applications.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Applicants',
                  subtitle: 'Review candidates and take hiring actions',
                  trailing: Text('${applications.length} total'),
                ),
                const SizedBox(height: 12),
                ...applications.map(
                  (application) => _ApplicantCard(application: application),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _JobStatusFilter extends StatelessWidget {
  const _JobStatusFilter({
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.jobCounts,
  });

  final JobStatus? selectedStatus;
  final ValueChanged<JobStatus?> onStatusChanged;
  final Map<JobStatus?, int> jobCounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All (${jobCounts[null] ?? 0})',
            selected: selectedStatus == null,
            onSelected: () => onStatusChanged(null),
            theme: theme,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Open (${jobCounts[JobStatus.active] ?? 0})',
            selected: selectedStatus == JobStatus.active,
            onSelected: () => onStatusChanged(JobStatus.active),
            theme: theme,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Closed (${jobCounts[JobStatus.closed] ?? 0})',
            selected: selectedStatus == JobStatus.closed,
            onSelected: () => onStatusChanged(JobStatus.closed),
            theme: theme,
            color: Colors.red,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Filled (${jobCounts[JobStatus.filled] ?? 0})',
            selected: selectedStatus == JobStatus.filled,
            onSelected: () => onStatusChanged(JobStatus.filled),
            theme: theme,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.theme,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final ThemeData theme;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? theme.colorScheme.primary;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : chipColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.transparent,
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      side: BorderSide(color: chipColor),
      elevation: selected ? 2 : 0,
      pressElevation: 1,
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({
    required this.job,
    required this.onCloseJob,
  });

  final JobPosting job;
  final Function(BuildContext, JobPosting) onCloseJob;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context, job.status);
    final formatter = DateFormat('MMM d · HH:mm');
    final appState = context.watch<AppState>();
    final accessInfo = appState.ownershipAccessInfo(job.businessId);

    return AccessTagPositioned(
        accessInfo: accessInfo,
        child: Material(
          child: Card(
            child: InkWell(
              onTap: () => context.read<AppState>().selectJob(job.id),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.title,
                                style: theme.textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              if (job.businessName.isNotEmpty)
                                Text(
                                  job.businessName,
                                  style: theme.textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            job.status.name,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      job.description,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 16, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${formatter.format(job.scheduleStart)} - ${formatter.format(job.scheduleEnd)}',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Text(
                          '\$${job.hourlyRate.toStringAsFixed(0)}/hr',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: job.status == JobStatus.active
                              ? () {
                                  print(
                                      'Close button pressed for job: ${job.id}, status: ${job.status}');
                                  onCloseJob(context, job);
                                }
                              : null,
                          icon: Icon(
                            Icons.close,
                            color: job.status == JobStatus.active
                                ? Colors.red
                                : Colors.grey,
                          ),
                          label: Text(
                            job.status == JobStatus.active
                                ? 'Close Job'
                                : 'Closed',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: job.status == JobStatus.active
                                ? Colors.red
                                : Colors.grey,
                            side: BorderSide(
                              color: job.status == JobStatus.active
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Trigger POST /payments/job-posting when quota ends.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.credit_card_outlined),
                          label: const Text('Pay & publish'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}

// Helper function for determining job status colors
Color _statusColor(BuildContext context, JobStatus status) {
  final scheme = Theme.of(context).colorScheme;
  switch (status) {
    case JobStatus.active:
      return scheme.primary;
    case JobStatus.filled:
      return scheme.secondary;
    case JobStatus.closed:
      return scheme.error;
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.application});

  final Application application;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('MMM d · HH:mm');

    return Material(
        child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    application.workerName.isNotEmpty
                        ? application.workerName[0]
                        : '?',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.workerName,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      Text(
                        application.workerExperience,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Chip(label: Text(application.status.name)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Applied ${formatter.format(application.submittedAt)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              application.note?.isNotEmpty == true
                  ? application.note!
                  : 'No message from the candidate.',
              style: theme.textTheme.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    // Show date picker for start date
                    final startDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      helpText: 'Select Employment Start Date',
                      confirmText: 'HIRE',
                    );

                    if (startDate == null) return; // User cancelled

                    try {
                      await context.read<AppState>().hireEmployerApplication(
                          application.id,
                          startDate: startDate);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Applicant hired with start date: ${startDate.toString().split(' ')[0]}'),
                          ),
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to hire applicant: $error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Hire'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await context
                          .read<AppState>()
                          .updateEmployerApplicationStatus(
                            applicationId: application.id,
                            status: ApplicationStatus.rejected,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Application marked as rejected'),
                          ),
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Failed to reject application: $error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}
