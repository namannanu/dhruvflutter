// ignore_for_file: unused_import, unused_field

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/worker/models/availability.dart';
import 'package:talent/features/worker/widgets/availability_schedule.dart';

class WorkPreferencesWidget extends StatefulWidget {
  const WorkPreferencesWidget({super.key});

  @override
  State<WorkPreferencesWidget> createState() => _WorkPreferencesWidgetState();
}

class _WorkPreferencesWidgetState extends State<WorkPreferencesWidget> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late final TextEditingController _minPayController;
  late final TextEditingController _maxDistanceController;
  bool _isAvailableForFullTime = false;
  bool _isAvailableForPartTime = false;
  bool _isAvailableForTemporary = false;
  String _weekAvailability = 'All week';
  List<DayAvailability> _availability = [];

  // Week availability options
  static const List<String> _weekAvailabilityOptions = [
    'All week',
    'Weekdays only',
    'Weekends only',
    'Monday to Friday',
    'Saturday and Sunday',
    'Flexible schedule',
  ];

  @override
  void initState() {
    super.initState();
    _minPayController = TextEditingController();
    _maxDistanceController = TextEditingController();
    _initializeAvailability();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreferences();
    });
  }

  void _loadPreferences() {
    if (!mounted) return;
    final appState = context.read<AppState>();
    final profile = appState.workerProfile;
    if (profile == null) return;

    setState(() {
      _minPayController.text = profile.minimumPay?.toString() ?? '';
      _maxDistanceController.text = profile.maxTravelDistance?.toString() ?? '';
      _isAvailableForFullTime = profile.availableForFullTime;
      _isAvailableForPartTime = profile.availableForPartTime;
      _isAvailableForTemporary = profile.availableForTemporary;
      _weekAvailability = profile.weekAvailability;
    });
  }

  void _initializeAvailability() {
    final appState = context.read<AppState>();
    final profile = appState.workerProfile;
    if (profile != null) {
      final availabilityMaps = (profile.availability as List)
          .whereType<Map<String, dynamic>>()
          .toList();
      _availability = availabilityMaps.map(DayAvailability.fromMap).toList();
    }
    if (_availability.isEmpty) {
      _availability = [
        DayAvailability(day: 'Monday'),
        DayAvailability(day: 'Tuesday'),
        DayAvailability(day: 'Wednesday'),
        DayAvailability(day: 'Thursday'),
        DayAvailability(day: 'Friday'),
        DayAvailability(day: 'Saturday'),
        DayAvailability(day: 'Sunday'),
      ];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final availabilityPayload =
          _availability.map((day) => day.toMap()).toList();

      await context.read<AppState>().updateWorkerPreferences(
            minimumPay: double.tryParse(_minPayController.text),
            maxTravelDistance: double.tryParse(_maxDistanceController.text),
            availableForFullTime: _isAvailableForFullTime,
            availableForPartTime: _isAvailableForPartTime,
            availableForTemporary: _isAvailableForTemporary,
            weekAvailability: _weekAvailability,
            availability: availabilityPayload,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work preferences updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating preferences: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Availability Schedule
              AvailabilitySchedule(
                availability: _availability,
                onAvailabilityChanged: (newAvailability) {
                  setState(() {
                    _availability = newAvailability;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Pay & Distance Section
              Text(
                'Pay & Distance',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minPayController,
                decoration: const InputDecoration(
                  labelText: 'Minimum hourly pay (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxDistanceController,
                decoration: const InputDecoration(
                  labelText: 'Maximum travel distance (miles)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Week Availability Section
              Text(
                'Week Availability',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _weekAvailability,
                decoration: const InputDecoration(
                  labelText: 'When are you generally available?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_view_week),
                ),
                items: _weekAvailabilityOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _weekAvailability = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Job Types Section
              Text(
                'Job Types',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Available for full-time'),
                      value: _isAvailableForFullTime,
                      onChanged: (value) =>
                          setState(() => _isAvailableForFullTime = value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Available for part-time'),
                      value: _isAvailableForPartTime,
                      onChanged: (value) =>
                          setState(() => _isAvailableForPartTime = value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Available for temporary/contract'),
                      value: _isAvailableForTemporary,
                      onChanged: (value) =>
                          setState(() => _isAvailableForTemporary = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Preferences'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
