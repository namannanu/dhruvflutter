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
          profilePictureUrl: profile.profilePictureSmall,
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
