// ignore_for_file: use_build_context_synchronously, avoid_print, prefer_final_locals

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/services/business_access_context.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/core/widgets/access_tag.dart';
import 'package:talent/features/shared/widgets/section_header.dart';

class EmployeeHireApplicationScreen extends StatefulWidget {
  const EmployeeHireApplicationScreen({super.key});

  @override
  State<EmployeeHireApplicationScreen> createState() =>
      _EmployeeHireApplicationScreenState();
}

class _EmployeeHireApplicationScreenState
    extends State<EmployeeHireApplicationScreen> {
  ApplicationStatus? _statusFilter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApplications(silent: true);
    });
  }

  Future<void> _loadApplications({bool silent = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = context.read<AppState>();
      final businessId = appState.service.currentUserBusinessId ??
          (appState.businesses.isNotEmpty
              ? appState.businesses.first.id
              : null);
      await appState.refreshEmployerApplications(
        status: _statusFilter,
        businessId: businessId,
      );
    } catch (error) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh applications: $error'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateFilter(ApplicationStatus? status) {
    if (_statusFilter == status) {
      return;
    }
    setState(() {
      _statusFilter = status;
    });
    _loadApplications();
  }

  @override
  Widget build(BuildContext context) {
    final applications = context.watch<AppState>().employerApplications;
    final filtered = _statusFilter == null
        ? applications
        : applications
            .where((app) => app.status == _statusFilter)
            .toList(growable: false);

    return RefreshIndicator(
      onRefresh: () => _loadApplications(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(
            title: 'Candidate applications',
            subtitle: 'Review applicants and move quickly on hiring decisions',
          ),
          const SizedBox(height: 16),
          _StatusFilterChips(
            selected: _statusFilter,
            onSelected: _updateFilter,
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: LinearProgressIndicator(),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: _EmptyApplicationsMessage(
                isLoading: _isLoading,
                filterActive: _statusFilter != null,
              ),
            )
          else
            ...filtered.map(
              (application) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _EmployerApplicationCard(application: application),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({
    required this.selected,
    required this.onSelected,
  });

  final ApplicationStatus? selected;
  final ValueChanged<ApplicationStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (isSelected) {
              if (isSelected) {
                onSelected(null);
              }
            },
          ),
          ...ApplicationStatus.values.map(
            (status) => ChoiceChip(
              label: Text(_statusLabel(status)),
              selected: selected == status,
              onSelected: (isSelected) {
                onSelected(isSelected ? status : null);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyApplicationsMessage extends StatelessWidget {
  const _EmptyApplicationsMessage({
    required this.isLoading,
    required this.filterActive,
  });

  final bool isLoading;
  final bool filterActive;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final message = filterActive
        ? 'No applications match this filter yet.'
        : 'You have not received any applications yet.';
    final subtext = filterActive
        ? 'Adjust the filters or check back after more candidates apply.'
        : 'Once workers apply to your jobs, their details will appear here.';

    return Material(
      child: Card(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtext,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )),
    );
  }
}

class _EmployerApplicationCard extends StatefulWidget {
  const _EmployerApplicationCard({required this.application});

  final Application application;

  @override
  State<_EmployerApplicationCard> createState() =>
      _EmployerApplicationCardState();
}

class _EmployerApplicationCardState extends State<_EmployerApplicationCard> {
  ApplicationStatus? _pendingAction;

  Future<void> _hire() async {
    if (_pendingAction != null ||
        widget.application.status == ApplicationStatus.hired) {
      return;
    }

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

    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _pendingAction = ApplicationStatus.hired;
    });

    try {
      await appState.updateEmployerApplicationStatus(
        applicationId: widget.application.id,
        status: ApplicationStatus.hired,
        note: 'Hired with start date: ${startDate.toString().split(' ')[0]}',
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'Applicant hired with start date: ${startDate.toString().split(' ')[0]}'),
        ),
      );
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to hire applicant: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingAction = null;
        });
      }
    }
  }

  Future<void> _reject() async {
    if (_pendingAction != null ||
        widget.application.status == ApplicationStatus.rejected) {
      return;
    }

    final controller = TextEditingController();
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject application?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'The candidate will be notified. You can optionally share a reason.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    final message = controller.text.trim();
    controller.dispose();

    if (shouldReject != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _pendingAction = ApplicationStatus.rejected;
    });

    try {
      await appState.updateEmployerApplicationStatus(
        applicationId: widget.application.id,
        status: ApplicationStatus.rejected,
        note: message.isEmpty ? null : message,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Application marked as rejected')),
      );
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to reject application: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingAction = null;
        });
      }
    }
  }

  Future<void> _restoreToPending() async {
    if (_pendingAction != null ||
        widget.application.status == ApplicationStatus.pending) {
      return;
    }

    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _pendingAction = ApplicationStatus.pending;
    });

    try {
      await appState.updateEmployerApplicationStatus(
        applicationId: widget.application.id,
        status: ApplicationStatus.pending,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Application moved back to pending')),
      );
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to update application: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingAction = null;
        });
      }
    }
  }

  Future<void> _scheduleAttendance() async {
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);

    // First, fetch the job details to get the hourly rate
    try {
      final jobDetails =
          await appState.fetchJobDetails(widget.application.jobId);

      if (jobDetails == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to load job details. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _ScheduleAttendanceDialog(
          workerName: widget.application.workerName,
          jobId: widget.application.jobId,
          jobDetails: jobDetails,
        ),
      );

      if (result == null) return;

      await appState.scheduleAttendanceForWorker(
        workerId: widget.application.workerId,
        jobId: widget.application.jobId,
        startDate: result['scheduledStart'] as DateTime,
        location: 'TBD', // Default location
        hoursScheduled: 8.0, // Default hours
        notes: result['notes'] as String?,
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content:
                Text('Shift scheduled for ${widget.application.workerName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to schedule shift: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final application = widget.application;
    final appState = context.watch<AppState>();

    // Determine access tag based on application data
    BusinessAccessInfo? displayAccessInfo;

    // Use the createdByTag from the application if available (from backend for employer requests)
    if (application.createdByTag != null &&
        application.createdByTag!.isNotEmpty) {
      final tag = application.createdByTag!;
      if (tag.toLowerCase() == 'owner') {
        displayAccessInfo = BusinessAccessInfo(
          ownerName: 'Owner',
          ownerEmail: appState.currentUser?.email ?? '',
          businessName: null,
        );
      } else if (tag != 'team_member') {
        // It's an email - someone else's business
        displayAccessInfo = BusinessAccessInfo(
          ownerName: tag,
          ownerEmail: tag,
          businessName: null,
        );
      }
    } else if (application.job != null) {
      // Fallback: Use job's business information to determine ownership
      final job = application.job!;
      final currentUserId = appState.currentUser?.id;

      if (currentUserId != null) {
        // Check if current user is the job's employer (direct owner)
        if (job.employerId == currentUserId) {
          displayAccessInfo = BusinessAccessInfo(
            ownerName: 'Owner',
            ownerEmail: appState.currentUser?.email ?? '',
            businessName: job.businessName.isNotEmpty ? job.businessName : null,
          );
        }
        // If user is not the direct employer but has access to this job,
        // it means they have team access (since they can see the application)
        else {
          displayAccessInfo = BusinessAccessInfo(
            ownerName: 'Team Access',
            ownerEmail: appState.currentUser?.email ?? '',
            businessName: job.businessName.isNotEmpty ? job.businessName : null,
          );
        }
      }
    }

    print('DEBUG: Application createdByTag: ${application.createdByTag}');
    print('DEBUG: Job employerId: ${application.job?.employerId}');
    print('DEBUG: Current user ID: ${appState.currentUser?.id}');
    print('DEBUG: Using displayAccessInfo: $displayAccessInfo');

    final submittedLabel =
        DateFormat.yMMMd().add_jm().format(application.submittedAt);
    final statusColor = _statusColor(context, application.status);
    final initials = _initials(application.workerName);

    final canHire = application.status != ApplicationStatus.hired;
    final canReject = application.status != ApplicationStatus.rejected;
    final canRestore = application.status != ApplicationStatus.pending;

    return AccessTagPositioned(
      accessInfo: displayAccessInfo,
      top: 8.0,
      right: 8.0,
      size: AccessTagSize.medium,
      child: Material(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      child: Text(initials),
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
                          if (application.workerExperience.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                application.workerExperience,
                                style: theme.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Applied $submittedLabel',
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: _StatusPill(
                        color: statusColor,
                        label: _statusLabel(application.status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Application ${_shortId(application.id)}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.work_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Job ID: ${application.jobId}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                if (application.workerSkills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: application.workerSkills
                        .take(6)
                        .map((skill) => Chip(label: Text(skill)))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
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
                      onPressed:
                          canHire && _pendingAction == null ? _hire : null,
                      icon: _ActionIcon(
                        isActive: _pendingAction == ApplicationStatus.hired,
                        icon: Icons.check_circle_outline,
                      ),
                      label: const Text('Hire'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          canReject && _pendingAction == null ? _reject : null,
                      icon: _ActionIcon(
                        isActive: _pendingAction == ApplicationStatus.rejected,
                        icon: Icons.close,
                      ),
                      label: const Text('Reject'),
                    ),
                    if (canRestore)
                      TextButton.icon(
                        onPressed:
                            _pendingAction == null ? _restoreToPending : null,
                        icon: _ActionIcon(
                          isActive: _pendingAction == ApplicationStatus.pending,
                          icon: Icons.refresh,
                        ),
                        label: const Text('Mark pending'),
                      ),
                    if (application.status == ApplicationStatus.hired)
                      FilledButton.tonalIcon(
                        onPressed:
                            _pendingAction == null ? _scheduleAttendance : null,
                        icon: const Icon(Icons.schedule),
                        label: const Text('Schedule Shift'),
                      ),
                  ],
                ),
              ],
            ), // closes Column
          ), // closes Padding
        ), // closes Card
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.isActive,
    required this.icon,
  });

  final bool isActive;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(icon);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

String _statusLabel(ApplicationStatus status) {
  switch (status) {
    case ApplicationStatus.pending:
      return 'Pending review';
    case ApplicationStatus.hired:
      return 'Hired';
    case ApplicationStatus.rejected:
      return 'Rejected';
  }
}

Color _statusColor(BuildContext context, ApplicationStatus status) {
  final scheme = Theme.of(context).colorScheme;
  switch (status) {
    case ApplicationStatus.pending:
      return scheme.primary;
    case ApplicationStatus.hired:
      return scheme.secondary;
    case ApplicationStatus.rejected:
      return scheme.error;
  }
}

String _shortId(String value) {
  if (value.isEmpty) {
    return '—';
  }
  final parts = value.split('-');
  final suffix = parts.isNotEmpty ? parts.last : value;
  return suffix.toUpperCase();
}

String _initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first[0].toUpperCase();
  }
  final buffer = StringBuffer();
  for (final part in parts.take(2)) {
    if (part.isNotEmpty) {
      buffer.write(part[0].toUpperCase());
    }
  }
  final initials = buffer.toString();
  return initials.isEmpty ? trimmed[0].toUpperCase() : initials;
}

class _ScheduleAttendanceDialog extends StatefulWidget {
  final String workerName;
  final String jobId;
  final JobPosting jobDetails;

  const _ScheduleAttendanceDialog({
    required this.workerName,
    required this.jobId,
    required this.jobDetails,
  });

  @override
  State<_ScheduleAttendanceDialog> createState() =>
      _ScheduleAttendanceDialogState();
}

class _ScheduleAttendanceDialogState extends State<_ScheduleAttendanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hourlyRateController;
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late final double _minimumHourlyRate;

  @override
  void initState() {
    super.initState();
    _minimumHourlyRate = widget.jobDetails.hourlyRate;
    _hourlyRateController = TextEditingController(
      text: _minimumHourlyRate.toStringAsFixed(2),
    );

    // Initialize times from job posting schedule
    _startTime = TimeOfDay.fromDateTime(widget.jobDetails.scheduleStart);
    _endTime = TimeOfDay.fromDateTime(widget.jobDetails.scheduleEnd);
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Shift Date',
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'Select Start Time',
    );
    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: 'Select End Time',
    );
    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final result = {
      'scheduledStart': startDateTime,
      'scheduledEnd': endDateTime,
      'hourlyRate': double.tryParse(_hourlyRateController.text) ?? 0.0,
      'notes': _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    };

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Schedule Shift for ${widget.workerName}'),
          const SizedBox(height: 4),
          Text(
            '${widget.jobDetails.title} • \$${widget.jobDetails.hourlyRate.toStringAsFixed(2)}/hr',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Selection
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title:
                    Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectDate,
              ),
              const Divider(),

              // Time Selection
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: Text('Start: ${_startTime.format(context)}'),
                      onTap: _selectStartTime,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('End: ${_endTime.format(context)}'),
                      onTap: _selectEndTime,
                    ),
                  ),
                ],
              ),
              const Divider(),

              // Hourly Rate
              TextFormField(
                controller: _hourlyRateController,
                decoration: InputDecoration(
                  labelText: 'Hourly Rate (\$)',
                  prefixText: '\$',
                  helperText:
                      'Minimum: \$${_minimumHourlyRate.toStringAsFixed(2)} (job posting rate)',
                  helperMaxLines: 2,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter hourly rate';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null ||
                      rate <= 0 ||
                      rate.isNaN ||
                      rate.isInfinite) {
                    return 'Please enter a valid rate';
                  }
                  if (rate < _minimumHourlyRate) {
                    return 'Rate cannot be less than \$${_minimumHourlyRate.toStringAsFixed(2)}\\n(the rate this worker applied for)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Additional shift details...',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Schedule Shift'),
        ),
      ],
    );
  }
}

class EmployerCandidatesScreen extends StatelessWidget {
  const EmployerCandidatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmployeeHireApplicationScreen();
  }
}
