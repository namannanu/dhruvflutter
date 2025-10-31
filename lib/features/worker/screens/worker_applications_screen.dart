// ignore_for_file: directives_ordering, deprecated_member_use, avoid_print, depend_on_referenced_packages, use_build_context_synchronously, unawaited_futures

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/features/shared/widgets/section_header.dart';
import 'package:talent/features/shared/screens/messaging_screen.dart';
import 'package:talent/features/shared/services/conversation_api_service.dart';
import 'package:talent/features/shared/widgets/business_logo_avatar.dart';

class WorkerApplicationsScreen extends StatelessWidget {
  const WorkerApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final applications = context.watch<AppState>().workerApplications;

    return RefreshIndicator(
      onRefresh: () async {
        final appState = context.read<AppState>();
        // Load both applications and jobs so messaging can work
        await Future.wait([
          appState.refreshActiveRole(),
          if (appState.currentUser != null) ...[
            appState.loadWorkerJobs(appState.currentUser!.id),
            appState.loadWorkerApplications(appState.currentUser!.id),
          ],
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(
            title: 'Applications',
            subtitle: 'Track status and employer responses',
          ),
          const SizedBox(height: 16),
          if (applications.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined, size: 48),
                    SizedBox(height: 12),
                    Text('You have not applied to any jobs yet.'),
                  ],
                ),
              ),
            )
          else
            ...applications.map((app) => _ApplicationCard(application: app)),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});

  final Application application;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submittedLabel = DateFormat.yMMMd().format(application.submittedAt);
    final statusColor = _statusColor(context, application.status);

    final statusChip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: statusColor.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusLabel(application.status),
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            LayoutBuilder(
              builder: (context, constraints) {
                final title = Text(
                  'Application ${application.id.split('-').last}',
                  style: theme.textTheme.titleMedium,
                  maxLines: constraints.maxWidth >= 360 ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                );

                if (constraints.maxWidth >= 360) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 12),
                      statusChip,
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 8),
                    statusChip,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Job info row with business logo and job title
            if (application.job != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BusinessLogoAvatar(
                    logoUrl: application.job!.businessLogoSquareUrl ??
                        application.job!.businessLogoUrl ??
                        application.job!.businessLogoOriginalUrl,
                    name: application.job!.businessName.isNotEmpty
                        ? application.job!.businessName
                        : application.job!.title,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.job!.title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (application.job!.businessName.isNotEmpty)
                          Text(
                            application.job!.businessName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Submitted date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Submitted $submittedLabel',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Job details
            Row(
              children: [
                const Icon(Icons.work_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    application.job != null
                        ? 'Job: ${application.job!.title}'
                        : 'Job ID: ${application.jobId}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Additional job info (hourly rate)
            if (application.job != null) ...[
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '\$${application.job!.hourlyRate.toStringAsFixed(2)}/hour',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Note
            Text(
              application.note ?? 'No cover note provided.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Actions
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton(
                  onPressed: application.status == ApplicationStatus.pending
                      ? () => _handleWithdraw(context)
                      : null,
                  child: const Text('Withdraw'),
                ),
                OutlinedButton(
                  onPressed: () => _handleMessageEmployer(context),
                  child: const Text('Message employer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleWithdraw(BuildContext context) async {
    if (application.status != ApplicationStatus.pending) {
      return;
    }

    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    final shouldWithdraw = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Withdraw application?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Withdrawing will notify the employer. You can include an optional message.',
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
              child: const Text('Withdraw'),
            ),
          ],
        );
      },
    );

    final message = controller.text.trim();
    controller.dispose();

    if (shouldWithdraw != true) {
      return;
    }

    try {
      await appState.withdrawWorkerApplication(
        applicationId: application.id,
        message: message.isEmpty ? null : message,
      );
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Application withdrawn'),
        ),
      );
    } catch (error) {
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to withdraw: $error'),
        ),
      );
    }
  }

  Future<void> _handleMessageEmployer(BuildContext context) async {
    try {
      final appState = context.read<AppState>();
      final currentUser = appState.currentUser;

      print('DEBUG: Current user: ${currentUser?.id}');
      print('DEBUG: Application job ID: ${application.jobId}');
      print(
          'DEBUG: Available worker jobs count: ${appState.workerJobs.length}');

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to send messages'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if application has a valid job ID
      if (application.jobId.isEmpty) {
        print('DEBUG: Application has empty job ID');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'This application is missing job information. Unable to contact employer.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      // If worker jobs are empty, try to load them
      if (appState.workerJobs.isEmpty) {
        print('DEBUG: Worker jobs empty, loading...');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading job data...'),
            backgroundColor: Colors.blue,
          ),
        );

        try {
          await appState.loadWorkerJobs(currentUser.id);
          print('DEBUG: Jobs loaded, count: ${appState.workerJobs.length}');
        } catch (error) {
          print('DEBUG: Failed to load jobs: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load job data: $error'),
              backgroundColor: Colors.red,
            ),
          );
          // Don't return here - try the alternative approach
        }
      }

      // Try to find the job in the loaded jobs first
      JobPosting? job = appState.workerJobs.firstWhereOrNull(
        (j) => j.id == application.jobId,
      );

      // If not found in worker jobs, try fetching the specific job by ID
      if (job == null) {
        print(
            'DEBUG: Job not found in worker jobs, fetching by ID: ${application.jobId}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fetching job details...'),
            backgroundColor: Colors.blue,
          ),
        );

        try {
          job = await appState.service.worker.fetchJobById(application.jobId);
        } catch (error) {
          print('DEBUG: Failed to fetch job by ID: $error');
        }
      }

      // If still no job found, create placeholder
      if (job == null) {
        print('DEBUG: Job not found, creating placeholder');
        job = JobPosting(
          id: '',
          title: 'Unknown Job',
          description: '',
          employerId: '',
          businessId: '',
          hourlyRate: 0,
          scheduleStart: DateTime.now(),
          scheduleEnd: DateTime.now(),
          recurrence: 'one-time',
          overtimeRate: 0,
          urgency: 'medium',
          tags: const [],
          workDays: const [],
          isVerificationRequired: false,
          status: JobStatus.active,
          postedAt: DateTime.now(),
          premiumRequired: false,
          applicantsCount: 0,
          businessName: '',
        );
      }

      print('DEBUG: Found job with employer ID: ${job.employerId}');
      print('DEBUG: Job title: ${job.title}');
      print(
          'DEBUG: All available job IDs: ${appState.workerJobs.map((j) => j.id).toList()}');
      print('DEBUG: Looking for job ID: ${application.jobId}');

      if (job.employerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Unable to find employer for this job. Please try refreshing the page.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      // Show dialog to compose initial message
      final controller = TextEditingController();
      final initialMessage = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Message Employer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                  'Send a message regarding your application for "${job?.title ?? 'this job'}"'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Your message',
                  hintText: 'Hi, I wanted to follow up on my application...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Send Message'),
            ),
          ],
        ),
      );

      print(
          'DEBUG: User entered message: ${initialMessage?.isNotEmpty == true ? "Yes" : "No"}');

      if (initialMessage == null || initialMessage.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a message to send'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Create or find conversation with employer
      final conversationService = ConversationApiService();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creating conversation...'),
          backgroundColor: Colors.blue,
        ),
      );

      try {
        print('DEBUG: Creating conversation with employer: ${job.employerId}');
        final conversation = await conversationService.createConversation(
          participantIds: [job.employerId],
          jobId: job.id,
        );

        print('DEBUG: Conversation created with ID: ${conversation.id}');

        // Send the initial message
        print('DEBUG: Sending message...');
        await conversationService.sendMessage(
          conversationId: conversation.id,
          body: initialMessage,
        );

        print('DEBUG: Message sent successfully');

        // Navigate to the messaging screen
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MessagingScreen(),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (error) {
        print('DEBUG: API Error: $error');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send message: ${error.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (error) {
      print('DEBUG: General Error: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
}
