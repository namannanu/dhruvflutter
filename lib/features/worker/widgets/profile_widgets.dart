// ignore_for_file: prefer_single_quotes

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:talent/core/models/user.dart';
import 'package:talent/features/shared/widgets/profile_picture_avatar.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});

  final WorkerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfilePictureAvatar(
          firstName: profile.firstName,
          lastName: profile.lastName,
          profilePictureUrl: profile.profilePictureUrl,
          size: 80,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.firstName} ${profile.lastName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(profile.email),
                ],
              ),
            ],
          ),
        ),
           Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    profile.isVerified ? Icons.verified : Icons.verified_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    profile.isVerified ? 'Verified' : 'Pending',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
               
      ],
    );
  }
}

class ReadOnlyProfileDetails extends StatelessWidget {
  const ReadOnlyProfileDetails({super.key, required this.profile});

  final WorkerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _infoCard('Bio', profile.bio),
        _infoCard('Experience', profile.experience),
        _chipCard('Skills', profile.skills),
        _chipCard('Languages', profile.languages),
        _AvailabilitySection(availability: profile.availability),
      ],
    );
  }

  Widget _infoCard(String title, String content) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(content.isEmpty ? 'Not provided' : content),
      ),
    );
  }

  Widget _chipCard(String title, List<String> items) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Wrap(
          spacing: 8,
          children: items.isEmpty
              ? [const Chip(label: Text('Not added'))]
              : items.map((e) => Chip(label: Text(e))).toList(),
        ),
      ),
    );
  }
}

class _AvailabilitySection extends StatelessWidget {
  const _AvailabilitySection({required this.availability});

  final List<Map<String, dynamic>> availability;

  bool _coerceBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'available';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final hasAvailability = availability.isNotEmpty;

    return Card(
      child: hasAvailability
          ? Column(
              children: availability.map((day) {
                final rawSlots = (day['timeSlots'] as List?) ?? const [];
                final slots = rawSlots
                    .whereType<Map>()
                    .map((slot) {
                      final start = slot['startTime']?.toString() ?? '--';
                      final end = slot['endTime']?.toString() ?? '--';
                      return '$start - $end';
                    })
                    .where((label) => label.contains('-'))
                    .toList();

                final isAvailable = _coerceBool(day['isAvailable']) ||
                    (_coerceBool(day['available']) ||
                        _coerceBool(day['active']));

                final subtitle = isAvailable
                    ? (slots.isNotEmpty
                        ? slots.join(', ')
                        : 'Available (no time slots set)')
                    : 'Not available';

                return ListTile(
                  title: Text(
                    (day['day'] as String?)?.toUpperCase() ?? 'UNKNOWN',
                  ),
                  subtitle: Text(subtitle),
                );
              }).toList(),
            )
          : const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No availability schedule added yet. Update your profile to let employers know when you can work.',
              ),
            ),
    );
  }
}

class EarningsSummary extends StatelessWidget {
  const EarningsSummary({super.key, required this.profile});
  final WorkerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _EarningTile(label: 'Weekly', value: profile.weeklyEarnings),
            _EarningTile(label: 'Total', value: profile.totalEarnings),
          ],
        ),
      ),
    );
  }
}

class _EarningTile extends StatelessWidget {
  const _EarningTile({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.simpleCurrency();
    return Column(
      children: [
        Text(label),
        Text(
          formatter.format(value),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
