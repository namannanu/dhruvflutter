// ignore_for_file: prefer_single_quotes, avoid_print

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/user.dart';
import 'package:talent/core/state/app_state.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  bool _isEditing = false;
  bool _notificationsEnabled = true;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _skillsController = TextEditingController();
  final _languagesController = TextEditingController();

  List<_DayAvailability> _availability = [];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  void _startEditing(WorkerProfile profile) {
    _firstNameController.text = profile.firstName;
    _lastNameController.text = profile.lastName;
    _phoneController.text = profile.phone;
    _bioController.text = profile.bio;
    _experienceController.text = profile.experience;
    _skillsController.text = profile.skills.join(', ');
    _languagesController.text = profile.languages.join(', ');

    _availability = (profile.availability as List)
        .map((day) => _DayAvailability.fromMap(day as Map<String, dynamic>))
        .toList();

    _notificationsEnabled = profile.notificationsEnabled;
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _saveChanges(AppState appState, WorkerProfile profile) async {
    final newFirstName = _firstNameController.text.trim();
    final newLastName = _lastNameController.text.trim();
    final newPhone = _phoneController.text.trim();
    final newBio = _bioController.text.trim();
    final newExperience = _experienceController.text.trim();
    final newSkills = _commaSeparated(_skillsController.text);
    final newLanguages = _commaSeparated(_languagesController.text);

    final availabilityPayload =
        _availability.map((day) => day.toMap()).toList();

    await appState.updateWorkerProfile(
      firstName: newFirstName,
      lastName: newLastName,
      phone: newPhone,
      bio: newBio,
      experience: newExperience,
      skills: newSkills,
      languages: newLanguages,
      availability: availabilityPayload,
      notificationsEnabled: _notificationsEnabled,
    );

    if (!mounted) return;
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  List<String> _commaSeparated(String value) {
    return value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.workerProfile;

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isBusy = appState.isBusy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            onPressed: isBusy
                ? null
                : () {
                    if (_isEditing) {
                      _cancelEditing();
                    } else {
                      _startEditing(profile);
                    }
                  },
            icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().refreshActiveRole(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(profile: profile),
              const SizedBox(height: 16),
              _EarningsSummary(profile: profile),
              const SizedBox(height: 24),
              if (_isEditing)
                _EditableProfileForm(
                  firstNameController: _firstNameController,
                  lastNameController: _lastNameController,
                  phoneController: _phoneController,
                  bioController: _bioController,
                  experienceController: _experienceController,
                  skillsController: _skillsController,
                  languagesController: _languagesController,
                  availability: _availability,
                  onAvailabilityChanged: (value) {
                    setState(() => _availability = value);
                  },
                  notificationsEnabled: _notificationsEnabled,
                  onNotificationsChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                )
              else
                _ReadOnlyProfileDetails(profile: profile),
              if (_isEditing)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => _saveChanges(appState, profile),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isBusy ? null : _cancelEditing,
                        icon: const Icon(Icons.undo),
                        label: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Profile Header ----------------
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final WorkerProfile profile;

  @override
  Widget build(BuildContext context) {
    final parts = profile.firstName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((p) => p.substring(0, 1)).join();

    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(initials,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.white)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.firstName,
                  style: Theme.of(context).textTheme.titleLarge),
              Text(profile.lastName,
                  style: Theme.of(context).textTheme.titleLarge),
              Text(profile.email),
              Row(
                children: [
                  Icon(profile.isVerified
                      ? Icons.verified
                      : Icons.verified_outlined),
                  const SizedBox(width: 4),
                  Text(profile.isVerified ? 'Verified' : 'Pending'),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------- Read-only profile ----------------
class _ReadOnlyProfileDetails extends StatelessWidget {
  const _ReadOnlyProfileDetails({required this.profile});

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

// ---------------- Editable Form ----------------
class _EditableProfileForm extends StatelessWidget {
  const _EditableProfileForm({
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.bioController,
    required this.experienceController,
    required this.skillsController,
    required this.languagesController,
    required this.availability,
    required this.onAvailabilityChanged,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController bioController;
  final TextEditingController experienceController;
  final TextEditingController skillsController;
  final TextEditingController languagesController;
  final List<_DayAvailability> availability;
  final ValueChanged<List<_DayAvailability>> onAvailabilityChanged;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
            controller: firstNameController,
            decoration: const InputDecoration(labelText: 'First Name')),
        TextField(
            controller: lastNameController,
            decoration: const InputDecoration(labelText: 'Last Name')),
        TextField(
            controller: phoneController,
            decoration: const InputDecoration(labelText: 'Phone')),
        TextField(
            controller: bioController,
            decoration: const InputDecoration(labelText: 'Bio')),
        TextField(
            controller: experienceController,
            decoration: const InputDecoration(labelText: 'Experience')),
        TextField(
            controller: skillsController,
            decoration:
                const InputDecoration(labelText: 'Skills (comma separated)')),
        TextField(
            controller: languagesController,
            decoration: const InputDecoration(
                labelText: 'Languages (comma separated)')),
        const SizedBox(height: 12),
        ...availability.map((day) => _DayEditor(
              day: day,
              onChanged: (updated) {
                final newList = [...availability];
                final index = newList.indexWhere((d) => d.day == updated.day);
                if (index != -1) newList[index] = updated;
                onAvailabilityChanged(newList);
              },
            )),
        SwitchListTile(
          value: notificationsEnabled,
          onChanged: onNotificationsChanged,
          title: const Text('Enable notifications'),
        )
      ],
    );
  }
}

// ---------------- Availability Section ----------------
class _AvailabilitySection extends StatelessWidget {
  const _AvailabilitySection({required this.availability});

  final List<Map<String, dynamic>> availability;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: availability.map((day) {
          final slots = (day['timeSlots'] as List)
              .map((s) =>
                  '${(s as Map<String, dynamic>)['startTime'] as String} - ${s['endTime'] as String}')
              .join(', ');

          return ListTile(
            title: Text(day['day'] as String),
            subtitle:
                Text((day['isAvailable'] as bool) ? slots : 'Not available'),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------- Models ----------------
class _DayAvailability {
  final String day;
  bool isAvailable;
  List<_TimeSlot> timeSlots;

  _DayAvailability(
      {required this.day, this.isAvailable = false, List<_TimeSlot>? timeSlots})
      : timeSlots = timeSlots ?? [];

  Map<String, dynamic> toMap() => {
        'day': day,
        'isAvailable': isAvailable,
        'timeSlots': timeSlots.map((e) => e.toMap()).toList(),
      };

  static _DayAvailability fromMap(Map<String, dynamic> map) {
    return _DayAvailability(
      day: map['day'] as String,
      isAvailable: (map['isAvailable'] as bool?) ?? false,
      timeSlots: (map['timeSlots'] as List?)
              ?.map((t) => _TimeSlot.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class _TimeSlot {
  final String startTime;
  final String endTime;

  _TimeSlot(this.startTime, this.endTime);

  Map<String, dynamic> toMap() => {'startTime': startTime, 'endTime': endTime};

  static _TimeSlot fromMap(Map<String, dynamic> map) {
    return _TimeSlot(map['startTime'] as String, map['endTime'] as String);
  }
}

class _DayEditor extends StatelessWidget {
  const _DayEditor({required this.day, required this.onChanged});

  final _DayAvailability day;
  final ValueChanged<_DayAvailability> onChanged;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(day.day.toUpperCase()),
      trailing: Switch(
        value: day.isAvailable,
        onChanged: (val) {
          day.isAvailable = val;
          onChanged(day);
        },
      ),
      children: [
        ...day.timeSlots.map((slot) => ListTile(
              title: Text('${slot.startTime} - ${slot.endTime}'),
            )),
        TextButton(
          onPressed: () {
            day.timeSlots.add(_TimeSlot('09:00', '17:00'));
            onChanged(day);
          },
          child: const Text('Add slot'),
        )
      ],
    );
  }
}

class _EarningsSummary extends StatelessWidget {
  const _EarningsSummary({required this.profile});
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
        Text(formatter.format(value),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
