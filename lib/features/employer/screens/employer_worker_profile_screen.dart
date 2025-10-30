// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';

class EmployerWorkerProfileScreen extends StatefulWidget {
  const EmployerWorkerProfileScreen({super.key, required this.application});

  final Application application;

  @override
  State<EmployerWorkerProfileScreen> createState() =>
      _EmployerWorkerProfileScreenState();
}

class _EmployerWorkerProfileScreenState
    extends State<EmployerWorkerProfileScreen> {
  WorkerProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String? _extractWorkerId(String? value) {
    if (value == null) return null;
    final match = RegExp(r'[0-9a-fA-F]{24}').firstMatch(value);
    return match?.group(0);
  }

  Future<void> _loadProfile() async {
    final workerUser = widget.application.worker;
    String? workerId;
    for (final candidate in [widget.application.workerId, workerUser?.id]) {
      final extracted = _extractWorkerId(candidate);
      if (extracted != null && extracted.isNotEmpty) {
        workerId = extracted;
        break;
      }
    }

    if (workerId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final appState = context.read<AppState>();
      final profile = await appState.fetchWorkerProfileSnapshot(workerId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to fetch worker profile for $workerId: $error');
      debugPrint(stackTrace.toString());
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Candidate profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null && _error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Candidate profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load worker details. ${_error!}',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final profile = _profile;
    final workerUser = widget.application.worker;
    final fullName = _composeName(
      first: profile?.firstName ?? workerUser?.firstName,
      last: profile?.lastName ?? workerUser?.lastName,
      fallback: widget.application.workerName,
    );
    final email = _firstNonEmpty([
      profile?.email,
      workerUser?.email,
      widget.application.worker?.email,
    ]);
    final phone = _firstNonEmpty([
      profile?.phone,
      workerUser?.phone,
    ]);
    final rawWorkerId = _firstNonEmpty([
          profile?.id,
          widget.application.workerId,
          workerUser?.id,
        ]);
    final workerId = rawWorkerId != null
        ? (_extractWorkerId(rawWorkerId) ?? rawWorkerId)
        : 'unknown';
    final displayWorkerId = _formatIdentifier(workerId);
    final experience = _firstNonEmpty([
          profile?.experience,
          widget.application.workerExperience,
        ]) ??
        'Experience details not provided.';
    final bio = _firstNonEmpty([profile?.bio]);
    final skills = profile != null && profile.skills.isNotEmpty
        ? profile.skills
        : widget.application.workerSkills;
    final languages = profile?.languages ?? const <String>[];
    final availability = profile?.availability ?? const <Map<String, dynamic>>[];
    final rating = profile?.rating;
    final completedJobs = profile?.completedJobs;
    final verified = profile?.isVerified ?? false;
    final submittedLabel =
        DateFormat.yMMMd().add_jm().format(widget.application.submittedAt);
    final message = _firstNonEmpty([
          widget.application.note,
          widget.application.message,
        ]) ??
        'No message provided by the applicant.';
    final job = widget.application.job;

    return Scaffold(
      appBar: AppBar(title: const Text('Candidate profile')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryCard(
                      fullName: fullName,
                      workerId: displayWorkerId,
                      email: email,
                      phone: phone,
                      rating: rating,
                      completedJobs: completedJobs,
                      verified: verified,
                      submittedLabel: submittedLabel,
                    ),
                    const SizedBox(height: 16),
                    _ExperienceCard(experience: experience, bio: bio),
                    if (skills.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SkillCard(skills: skills),
                    ],
                    if (languages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _LanguageCard(languages: languages),
                    ],
                    const SizedBox(height: 16),
                    _MessageCard(message: message),
                    if (availability.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _AvailabilityCard(availability: availability),
                    ],
                    if (job != null) ...[
                      const SizedBox(height: 16),
                      _JobSnapshotCard(job: job),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatIdentifier(String raw) {
    final trimmed = raw.trim();
    final match = RegExp(r"(?:_id|id)\s*[:=]\s*'?([A-Za-z0-9]+)'?").firstMatch(trimmed);
    final value = match != null ? match.group(1)! : trimmed;
    if (value.length <= 12) {
      return value;
    }
    final prefix = value.substring(0, 6);
    final suffix = value.substring(value.length - 4);
    return '$prefix…$suffix';
  }

  static String _composeName({
    String? first,
    String? last,
    required String fallback,
  }) {
    final parts = <String>[];
    if (first != null && first.trim().isNotEmpty) {
      parts.add(first.trim());
    }
    if (last != null && last.trim().isNotEmpty) {
      parts.add(last.trim());
    }
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    return fallback.trim().isEmpty ? 'Worker' : fallback.trim();
  }

  static String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      if (value == null) continue;
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'null') {
        return trimmed;
      }
    }
    return null;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.fullName,
    required this.workerId,
    required this.email,
    required this.phone,
    required this.rating,
    required this.completedJobs,
    required this.verified,
    required this.submittedLabel,
  });

  final String fullName;
  final String workerId;
  final String? email;
  final String? phone;
  final double? rating;
  final int? completedJobs;
  final bool verified;
  final String submittedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metaChips = <Widget>[
      _ProfileMetaChip(
        icon: Icons.badge_outlined,
        label: 'ID: $workerId',
      ),
      _ProfileMetaChip(
        icon: Icons.calendar_today_outlined,
        label: 'Applied: $submittedLabel',
      ),
    ];

    if (email != null && email!.isNotEmpty) {
      metaChips.add(
        _ProfileMetaChip(icon: Icons.email_outlined, label: email!),
      );
    }
    if (phone != null && phone!.isNotEmpty) {
      metaChips.add(
        _ProfileMetaChip(icon: Icons.phone_outlined, label: phone!),
      );
    }
    if (completedJobs != null) {
      metaChips.add(
        _ProfileMetaChip(
          icon: Icons.work_outline,
          label: 'Completed jobs: $completedJobs',
        ),
      );
    }
    if (rating != null && rating! > 0) {
      metaChips.add(
        _ProfileMetaChip(
          icon: Icons.star_rate_outlined,
          label: 'Rating: ${rating!.toStringAsFixed(1)}',
        ),
      );
    }
    metaChips.add(
      _ProfileMetaChip(
        icon: verified ? Icons.verified_outlined : Icons.shield_outlined,
        label: verified ? 'Verified' : 'Not verified',
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Text(_initials(fullName)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: theme.textTheme.headlineSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (email != null && email!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            email!,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metaChips,
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    final initials = (first + last).trim();
    return initials.isEmpty ? '?' : initials.toUpperCase();
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.experience, this.bio});

  final String experience;
  final String? bio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Experience', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              experience,
              style: theme.textTheme.bodyMedium,
            ),
            if (bio != null && bio!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Bio', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                bio!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.skills});

  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Skills', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: skills
                  .map((skill) => Chip(
                        avatar:
                            const Icon(Icons.star_outline, size: 16),
                        label: Text(skill),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.languages});

  final List<String> languages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Languages', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: languages
                  .map((language) => Chip(label: Text(language)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Message to employer', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.availability});

  final List<Map<String, dynamic>> availability;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = availability.map((day) {
      final dayLabel = (day['day'] ?? '').toString();
      final isAvailable = day['isAvailable'] == true;
      final slots = (day['timeSlots'] as List?) ?? const [];
      final slotLabels = slots
          .map((slot) {
            final slotMap = slot as Map<String, dynamic>;
            final start = slotMap['startTime']?.toString() ?? '--';
            final end = slotMap['endTime']?.toString() ?? '--';
            return '$start - $end';
          })
          .join(', ');
      final subtitle = isAvailable
          ? (slotLabels.isEmpty ? 'Available' : slotLabels)
          : 'Not available';
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          isAvailable ? Icons.check_circle_outline : Icons.remove_circle_outline,
          color: isAvailable ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        title: Text(dayLabel.toUpperCase()),
        subtitle: Text(subtitle),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Availability', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _JobSnapshotCard extends StatelessWidget {
  const _JobSnapshotCard({required this.job});

  final JobPosting job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduleLabel =
        '${DateFormat.MMMd().add_jm().format(job.scheduleStart)} - '
        '${DateFormat.MMMd().add_jm().format(job.scheduleEnd)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job applied to', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(job.title),
              subtitle: Text(job.businessName),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${job.hourlyRate.toStringAsFixed(0)}/hr',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.status.name,
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scheduleLabel,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (job.locationSummary != null && job.locationSummary!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place_outlined, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job.locationSummary!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class _ProfileMetaChip extends StatelessWidget {
  const _ProfileMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
