// ignore_for_file: require_trailing_commas, directives_ordering, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/core/utils/job_display_utils.dart';
import 'package:talent/features/employer/screens/employer_job_create_screen.dart';
import 'package:talent/features/employer/screens/job_payment_screen.dart';
import 'package:talent/core/utils/image_url_optimizer.dart';
import 'package:talent/features/shared/widgets/business_logo_avatar.dart';
import 'package:talent/features/shared/widgets/section_header.dart';
import 'package:talent/features/shared/mixins/auto_refresh_mixin.dart';
import 'package:talent/core/widgets/access_tag.dart';

class EmployerJobsScreen extends StatefulWidget {
  const EmployerJobsScreen({super.key});

  @override
  State<EmployerJobsScreen> createState() => _EmployerJobsScreenState();
}

class _EmployerJobsScreenState extends State<EmployerJobsScreen>
    with AutoRefreshMixin<EmployerJobsScreen> {
  JobStatus? _jobStatusFilter;

  Null get trailing => null; // null = all, active, closed, filled

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
    return jobs.where((job) {
      // First check the job status
      if (job.status != _jobStatusFilter) {
        return false;
      }

      // For active jobs, only show published ones
      if (job.status == JobStatus.active && !job.isPublished) {
        return false;
      }

      return true;
    }).toList();
  }

  String _getStatusLabel(JobStatus status) {
    switch (status) {
      case JobStatus.active:
        return 'Open';
      case JobStatus.filled:
        return 'Filled';
      case JobStatus.closed:
        return 'Closed';
      case JobStatus.paused:
        return 'Paused';
      case JobStatus.expired:
        return 'Expired';
      case JobStatus.deleted:
        return 'Removed';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.draft:
        return 'Draft';
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

    // Permission checks removed per user request

    return RefreshIndicator(
      onRefresh: () async => context.read<AppState>().refreshActiveRole(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(
            title: 'Job management',
            style: TextStyle(fontSize: 16),
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
              ElevatedButton.icon(
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
                    const SizedBox(height: 10),
                    Text(
                      _jobStatusFilter == null
                          ? 'No job postings yet. Tap "Create new job" to get started.'
                          : 'No ${_getStatusLabel(_jobStatusFilter!).toLowerCase()} jobs found.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filteredJobs.map((job) {
              // Find the business for this job
              BusinessLocation? business;
              for (final candidate in appState.businesses) {
                if (candidate.id == job.businessId) {
                  business = candidate;
                  break;
                }
              }

              return _JobTile(
                job: job,
                business: business,
                onCloseJob: _closeJobPost,
              );
            }),
          const SizedBox(height: 24),
          if (applications.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Applicants',
                  subtitle: 'Review candidates and take hiring actions',
                  style: TextStyle(fontSize: 10),
                ),
                Text('${applications.length} total'),
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
    this.business,
    required this.onCloseJob,
  });

  final JobPosting job;
  final BusinessLocation? business;
  final Function(BuildContext, JobPosting) onCloseJob;

  String _getDisplayAddress() {
    // Priority 1: Use job's specific business address (includes custom address)
    if (job.businessAddress.isNotEmpty) {
      return job.businessAddress;
    }

    // Priority 2: Use business address from business object
    if (business?.address.isNotEmpty == true) {
      return business!.address;
    }

    // Priority 3: Try to build from business name
    if (job.businessName.isNotEmpty) {
      return job.businessName;
    }

    return 'Location not specified';
  }

  String _formatSchedule() {
    final sameDay = job.scheduleStart.year == job.scheduleEnd.year &&
        job.scheduleStart.month == job.scheduleEnd.month &&
        job.scheduleStart.day == job.scheduleEnd.day;
    final dayFormatter = DateFormat('EEE, MMM d');
    final timeFormatter = DateFormat('h:mm a');

    final startDay = dayFormatter.format(job.scheduleStart);
    final endDay = dayFormatter.format(job.scheduleEnd);
    final startTime = timeFormatter.format(job.scheduleStart);
    final endTime = timeFormatter.format(job.scheduleEnd);

    if (sameDay) {
      return '$startDay • $startTime - $endTime';
    }

    final startFull = '$startDay • $startTime';
    final endFull = '$endDay • $endTime';
    return '$startFull → $endFull';
  }

  String _formatRecurrence() {
    return JobDisplayUtils.formatRecurrence(job.recurrence);
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  String _formatPayRate() {
    final base = '\$${job.hourlyRate.toStringAsFixed(0)}/hr';
    if (!job.overtime.allowed) return base;

    final overtimeRate =
        job.hourlyRate * (job.overtime.rateMultiplier <= 0 ? 1.5 : job.overtime.rateMultiplier);
    final overtimeLabel =
        '\$${overtimeRate.toStringAsFixed(0)}/hr overtime';
    return '$base ($overtimeLabel)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final needsPayment = job.premiumRequired;
    final needsPublishing = !job.isPublished && job.status == JobStatus.active;
    final statusColor =
        needsPayment ? Colors.orange : _statusColor(context, job.status);
    final statusLabel = needsPayment ? 'Payment pending' : job.status.name;
    final appState = context.watch<AppState>();
    final accessInfo = appState.jobAccessInfo(job);

    final businessLogoUrl = job.businessLogoSmall ??
        job.businessLogoSmall ??
        job.businessLogoSmall ??
      
        business?.logoUrl ??
        business?.logoSmall;
    final businessDisplayName = job.businessName.isNotEmpty
        ? job.businessName
        : business?.name ?? job.title;

    return AccessTagPositioned(
      accessInfo: null,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BusinessLogoAvatar(
                        logoUrl: businessLogoUrl,
                        name: businessDisplayName,
                        size: 44,
                        imageContext: ImageContext.jobList,
                      ),
                      const SizedBox(width: 12),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
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
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (accessInfo != null) ...[
                            const SizedBox(height: 8),
                            AccessTag(
                              accessInfo: accessInfo,
                              size: AccessTagSize.small,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _JobDetailItem(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: _getDisplayAddress(),
                  ),
                  _JobDetailItem(
                    icon: Icons.sticky_note_2_outlined,
                    label: 'Description',
                    value: job.description.isNotEmpty
                        ? job.description
                        : 'No description provided.',
                  ),
                  _JobDetailItem(
                    icon: Icons.repeat_outlined,
                    label: 'Frequency',
                    value: _formatRecurrence(),
                  ),
                  _JobDetailItem(
                    icon: Icons.schedule_outlined,
                    label: 'Schedule',
                    value: _formatSchedule(),
                  ),
                  _JobDetailItem(
                    icon: Icons.payments_outlined,
                    label: 'Pay rate',
                    value: _formatPayRate(),
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
                      if (needsPayment)
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (context) => JobPaymentScreen(
                                  jobId: job.id,
                                  amount: 50.0,
                                  currency: 'INR',
                                ),
                              ),
                            );
                            if (context.mounted) {
                              await context
                                  .read<AppState>()
                                  .refreshActiveRole();
                            }
                          },
                          icon: const Icon(Icons.credit_card_outlined),
                          label: const Text('Pay & Publish'),
                        )
                      else if (needsPublishing)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final state = context.read<AppState>();
                            await state.publishJob(job.id);
                            if (context.mounted) {
                              await context
                                  .read<AppState>()
                                  .refreshActiveRole();
                            }
                          },
                          icon: const Icon(Icons.publish),
                          label: const Text('Publish'),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: null,
                          icon: Icon(
                            Icons.check_circle_outline,
                            color: theme.colorScheme.primary,
                          ),
                          label: Text(
                            job.isPublished ? 'Published' : job.publishStatus,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JobDetailItem extends StatelessWidget {
  const _JobDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                  softWrap: false,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function for determining job status colors
Color _statusColor(BuildContext context, JobStatus status) {
  final scheme = Theme.of(context).colorScheme;
  switch (status) {
    case JobStatus.active:
      return scheme.primary;
    case JobStatus.closed:
      return scheme.error;
    case JobStatus.filled:
      return scheme.secondary;
    case JobStatus.paused:
      return scheme.tertiary;
    case JobStatus.expired:
      return scheme.error.withValues(alpha: 0.8);
    case JobStatus.deleted:
      return scheme.error;
    case JobStatus.completed:
      return scheme.primary;
    case JobStatus.draft:
      return scheme.outline;
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
