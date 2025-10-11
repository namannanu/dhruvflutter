// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';

class EmployerJobCreateScreen extends StatefulWidget {
  const EmployerJobCreateScreen({super.key});

  @override
  State<EmployerJobCreateScreen> createState() =>
      _EmployerJobCreateScreenState();
}

class _EmployerJobCreateScreenState extends State<EmployerJobCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  BusinessLocation? _selectedBusiness;

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _overtimeRateController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  final TextEditingController _customTitleController = TextEditingController();

  String? _selectedJobType;
  String _urgency = 'normal';
  String _frequency = 'once';
  bool _hasOvertime = false;
  bool _requestVerification = false;

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final Set<String> _selectedWorkDays = <String>{};
  bool _submitting = false;

  static const List<String> _jobTypes = <String>[
    'Dishwasher',
    'Server',
    'Cashier',
    'Cook',
    'Cleaner',
    'Warehouse Worker',
    'Sales Associate',
    'Food Prep',
    'Host/Hostess',
    'Other',
  ];

  static const List<String> _weekDays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static final List<_FrequencyOption> _frequencyOptions = <_FrequencyOption>[
    const _FrequencyOption(
        'once', 'One Time Job', 'Single shift or project', Icons.access_time),
    const _FrequencyOption(
        'weekly', 'Weekly', 'Select specific days of the week', Icons.repeat),
    const _FrequencyOption('monthly', 'Monthly',
        'Every month, recurring position', Icons.calendar_today_outlined),
    const _FrequencyOption(
        'custom', 'Custom Schedule', 'Choose specific days', Icons.schedule),
  ];

  static final List<_JobTemplate> _jobTemplates = <_JobTemplate>[
    const _JobTemplate(
      title: 'Morning Barista',
      description:
          'Prepare espresso drinks, maintain a clean station, and deliver friendly service.',
      requirements:
          '2+ years barista experience\nKnowledge of espresso machines\nExcellent customer service',
      suggestedRate: '20-24',
      frequency: 'weekly',
    ),
    const _JobTemplate(
      title: 'Front of House Server',
      description:
          'Welcome guests, manage table service, handle POS orders, and support closing duties.',
      requirements:
          'Experience with POS systems\nStrong customer focus\nEvening and weekend availability',
      suggestedRate: '18-22 + tips',
      frequency: 'weekly',
    ),
    const _JobTemplate(
      title: 'Kitchen Prep Cook',
      description:
          'Assist with daily prep, maintain kitchen cleanliness, and support line cooks during service.',
      requirements:
          'Knife skills\nFood handlers certification\nAbility to lift 25 lbs',
      suggestedRate: '19-25',
      frequency: 'weekly',
    ),
  ];

  static final Map<String, _JobSuggestion> _smartSuggestions =
      <String, _JobSuggestion>{
    'Dishwasher': const _JobSuggestion(
        rate: '15-20',
        peak: 'Evening shifts',
        location: 'Restaurant districts'),
    'Server': const _JobSuggestion(
        rate: '18-25', peak: 'Weekend shifts', location: 'Downtown areas'),
    'Cashier': const _JobSuggestion(
        rate: '14-18', peak: 'Holiday seasons', location: 'Shopping centers'),
    'Cook': const _JobSuggestion(
        rate: '20-28', peak: 'Lunch & dinner rush', location: 'Food districts'),
  };

  late final List<_TimeOption> _timeOptions;

  @override
  void initState() {
    super.initState();
    final businesses = context.read<AppState>().businesses;
    if (businesses.isNotEmpty) {
      _selectedBusiness = businesses.first;
      _locationController.text = businesses.first.address;
    }
    _timeOptions = _generateTimeOptions();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _hourlyRateController.dispose();
    _overtimeRateController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _customTitleController.dispose();
    super.dispose();
  }

  List<_TimeOption> _generateTimeOptions() {
    final List<_TimeOption> options = <_TimeOption>[];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        final String value =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        options.add(_TimeOption(value, _formatTimeLabel(value)));
      }
    }
    return options;
  }

  String _formatTimeLabel(String time24) {
    final parts = time24.split(':');
    final int hour = int.parse(parts[0]);
    final String minutes = parts[1];
    final String period = hour >= 12 ? 'PM' : 'AM';
    final int hour12 = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    return '$hour12:$minutes $period';
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Select time';
    final DateTime now = DateTime.now();
    final DateTime dt =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  TimeOfDay _parseTimeOfDay(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _openTimePicker({required bool isStart}) async {
    final TimeOfDay? initial = isStart ? _startTime : _endTime;
    final String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TimePickerSheet(
        popularTimes: _popularTimeOptions,
        timeOptions: _timeOptions,
        initialValue: initial != null ? _formatTimeValue(initial) : null,
      ),
    );
    if (result != null) {
      setState(() {
        final TimeOfDay time = _parseTimeOfDay(result);
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  String _formatTimeValue(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final DateTime initial = _selectedDate ?? DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTemplate() async {
    final _JobTemplate? template = await showModalBottomSheet<_JobTemplate>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pick a template',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 320,
                  child: ListView.builder(
                    itemCount: _jobTemplates.length,
                    itemBuilder: (context, index) {
                      final _JobTemplate template = _jobTemplates[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(template.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(template.description),
                              const SizedBox(height: 6),
                              Text(
                                  'Suggested rate: \$${template.suggestedRate}/hr'),
                            ],
                          ),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => Navigator.pop(context, template),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (template != null) {
      setState(() {
        _selectedJobType = template.title;
        _hourlyRateController.text = template.suggestedRate.split('-').first;
        _descriptionController.text = template.description;
        _requirementsController.text = template.requirements;
        _frequency = template.frequency;
      });
    }
  }

  _JobSuggestion? get _activeSuggestion {
    if (_selectedJobType == null) return null;
    return _smartSuggestions[_selectedJobType!];
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final businessLocation = _selectedBusiness;
    if (businessLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add a business location before posting jobs.')),
      );
      return;
    }
    if (_selectedJobType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a job type to continue')),
      );
      return;
    }
    if (_selectedJobType == 'Other' &&
        _customTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a job title for "Other"')),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a date for the shift')),
      );
      return;
    }
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select both start and end times')),
      );
      return;
    }
    if ((_frequency == 'weekly' ||
            _frequency == 'custom' ||
            _frequency == 'monthly') &&
        _selectedWorkDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pick at least one work day for recurring jobs')),
      );
      return;
    }
    final double? hourly = double.tryParse(_hourlyRateController.text.trim());
    if (hourly == null || hourly <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid hourly rate')),
      );
      return;
    }

    final DateTime startDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    DateTime endDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );
    if (!endDate.isAfter(startDate)) {
      endDate = endDate.add(const Duration(days: 1));
    }

    final List<String> tags = <String>[];
    if (_selectedJobType != null && _selectedJobType != 'Other') {
      tags.add(_selectedJobType!.toLowerCase());
    }
    if (_tagsController.text.trim().isNotEmpty) {
      tags.addAll(
        _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty),
      );
    }

    final descriptionBuffer = StringBuffer();
    final description = _descriptionController.text.trim();
    if (description.isNotEmpty) {
      descriptionBuffer.writeln(description);
    } else {
      // Ensure description is not empty for API requirements
      descriptionBuffer.writeln('Job details will be provided.');
    }
    if (_requirementsController.text.trim().isNotEmpty) {
      descriptionBuffer
          .writeln('\nRequirements:\n${_requirementsController.text.trim()}');
    }
    final String finalTitle = _selectedJobType == 'Other'
        ? _customTitleController.text.trim()
        : _selectedJobType!;

    double? overtimeRate;
    if (_hasOvertime) {
      overtimeRate = double.tryParse(_overtimeRateController.text.trim());
      overtimeRate ??= hourly * 1.5;
    }

    final String recurrence;
    switch (_frequency) {
      case 'weekly':
        recurrence = 'weekly';
        break;
      case 'monthly':
        recurrence = 'monthly';
        break;
      case 'custom':
        recurrence = 'custom';
        break;
      default:
        recurrence = 'one-time';
    }

    final String urgencyValue;
    switch (_urgency) {
      case 'urgent':
        urgencyValue = 'high';
        break;
      case 'emergency':
        urgencyValue = 'critical';
        break;
      default:
        urgencyValue = 'medium';
    }

    setState(() => _submitting = true);
    final appState = context.read<AppState>();

    try {
      // Create the job posting first
      final JobPosting job = await appState.createEmployerJob(
        title: finalTitle,
        description: descriptionBuffer.toString(),
        hourlyRate: hourly,
        business: businessLocation,
        start: startDate,
        end: endDate,
        locationDescription: _locationController.text.trim(),
        tags: tags.isEmpty ? null : tags,
        urgency: urgencyValue,
        verificationRequired: _requestVerification,
        hasOvertime: _hasOvertime,
        overtimeRate: overtimeRate,
        recurrence: recurrence,
        workDays: _selectedWorkDays.isEmpty
            ? null
            : _selectedWorkDays.map((day) => day.toLowerCase()).toList(),
      );

      // Process the payment
      await appState.processJobPostingPayment(
        jobId: job.id,
        amount: 50.0,
        currency: 'USD',
        paymentMethodId:
            'pm_card_default', // You might want to get this from a payment form
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      debugPrint('❌ EmployerJobCreateScreen: job publish failed: $error');

      String errorMessage = 'Failed to create job';
      if (error.toString().contains('description') &&
          error.toString().contains('required')) {
        errorMessage =
            'Job description is required. Please provide a detailed description.';
      } else if (error.toString().contains('validation failed')) {
        errorMessage = 'Please check all required fields and try again.';
      } else if (error.toString().contains('500')) {
        errorMessage =
            'Server error. Please check all fields are properly filled and try again.';
      } else {
        errorMessage = 'Failed to create job: $error';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final businesses = appState.businesses;

    if (businesses.isEmpty) {
      _selectedBusiness = null;
    } else if (_selectedBusiness == null ||
        !businesses.contains(_selectedBusiness)) {
      final selected = businesses.first;
      _selectedBusiness = selected;
      if (_locationController.text.trim().isEmpty ||
          _locationController.text == selected.address) {
        _locationController.text = selected.address;
      }
    }

    final _JobSuggestion? suggestion = _activeSuggestion;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.white,
                elevation: 0,
                titleSpacing: 0,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Post a Job',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _submitting ? null : _pickTemplate,
                        icon: const Icon(Icons.lightbulb_outline, size: 18),
                        label: const Text('Use template'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBusinessSelector(businesses),
                      const SizedBox(height: 16),
                      _buildJobTypeSection(),
                      const SizedBox(height: 16),
                      _buildFrequencySection(),
                      const SizedBox(height: 16),
                      _buildPaySection(suggestion),
                      const SizedBox(height: 16),
                      _buildLocationSection(),
                      const SizedBox(height: 16),
                      _buildScheduleSection(),
                      const SizedBox(height: 16),
                      _buildUrgencySection(),
                      const SizedBox(height: 16),
                      _buildDescriptionSection(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton.icon(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          icon: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle_outline),
          label:
              Text(_submitting ? 'Publishing…' : 'Continue to payment (\$50)'),
        ),
      ),
    );
  }

  Widget _buildBusinessSelector(List<BusinessLocation> businesses) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'Which business is hiring?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(' *',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            if (businesses.isEmpty)
              const Text('Add a business location to publish this job.',
                  style: TextStyle(color: Colors.redAccent))
            else
              DropdownButtonFormField<BusinessLocation>(
                value: _selectedBusiness,
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedBusiness = value;
                            if (_locationController.text.trim().isEmpty ||
                                _locationController.text == value.address) {
                              _locationController.text = value.address;
                            }
                          });
                        }
                      },
                items: businesses
                    .map(
                      (business) => DropdownMenuItem<BusinessLocation>(
                        key: ValueKey(business.id),
                        value: business,
                        child: Text(business.name),
                      ),
                    )
                    .toList(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Business',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What type of worker do you need?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _jobTypes.map((type) {
                final bool isSelected = _selectedJobType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedJobType = selected ? type : null;
                    });
                  },
                );
              }).toList(),
            ),
            if (_selectedJobType == 'Other')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextFormField(
                  controller: _customTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Custom job title',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How often do you need this worker?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Column(
              children: _frequencyOptions.map((option) {
                final bool selected = _frequency == option.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => setState(() => _frequency = option.value),
                    tileColor: selected ? Colors.blue.shade50 : null,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: selected ? Colors.blue : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(option.icon,
                        color: selected ? Colors.blue : Colors.grey.shade600),
                    title: Text(option.label,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(option.description),
                  ),
                );
              }).toList(),
            ),
            if (_frequency != 'once') _buildWorkDaySelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkDaySelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Select work days',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              if (_selectedWorkDays.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('* required',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WorkdayQuickButton(
                label: 'All days',
                onTap: () => setState(() => _selectedWorkDays
                  ..clear()
                  ..addAll(_weekDays)),
              ),
              _WorkdayQuickButton(
                label: 'Weekdays',
                onTap: () => setState(() {
                  _selectedWorkDays
                    ..clear()
                    ..addAll(_weekDays.take(5));
                }),
              ),
              _WorkdayQuickButton(
                label: 'Weekends',
                onTap: () => setState(() {
                  _selectedWorkDays
                    ..removeWhere((day) => !_weekDays.sublist(5).contains(day))
                    ..addAll(_weekDays.sublist(5));
                }),
              ),
              _WorkdayQuickButton(
                label: 'Clear',
                onTap: () => setState(() => _selectedWorkDays.clear()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekDays.map((day) {
              final bool selected = _selectedWorkDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedWorkDays.add(day);
                    } else {
                      _selectedWorkDays.remove(day);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaySection(_JobSuggestion? suggestion) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.attach_money, size: 20),
                SizedBox(width: 8),
                Text('Hourly rate',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hourlyRateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: 'USD ',
                labelText: 'Hourly rate',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Hourly rate is required';
                }
                if (double.tryParse(value.trim()) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _hasOvertime,
              onChanged: (value) => setState(() => _hasOvertime = value),
              title: const Text('Overtime available'),
              subtitle: const Text('Offer overtime pay for extra hours'),
            ),
            if (_hasOvertime)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextFormField(
                  controller: _overtimeRateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: 'USD ',
                    labelText: 'Overtime rate (per hour)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            if (suggestion != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smart suggestions for ${_selectedJobType!}',
                        style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Typical rate: \$${suggestion.rate}/hr'),
                    Text('Peak demand: ${suggestion.peak}'),
                    Text('Best locations: ${suggestion.location}'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.place_outlined, size: 20),
                SizedBox(width: 8),
                Text('Location',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Where will the worker report?',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Location is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 20),
                SizedBox(width: 8),
                Text('When do you need them?',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.today),
              label: Text(
                _selectedDate == null
                    ? 'Select date'
                    : DateFormat('EEEE, MMM d, yyyy').format(_selectedDate!),
              ),
              onPressed: _submitting ? null : _pickDate,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => _openTimePicker(isStart: true),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 8),
                        Text(_formatTimeOfDay(_startTime)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => _openTimePicker(isStart: false),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time_outlined),
                        const SizedBox(width: 8),
                        Text(_formatTimeOfDay(_endTime)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencySection() {
    final List<_UrgencyOption> options = <_UrgencyOption>[
      const _UrgencyOption(
          'normal', 'Normal', 'I can wait for the right person'),
      const _UrgencyOption('urgent', 'Urgent', 'I need someone today'),
      const _UrgencyOption(
          'emergency', 'Emergency', 'I need someone right now!'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How urgent is this?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...options.map((option) {
              final bool selected = option.value == _urgency;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => setState(() => _urgency = option.value),
                  tileColor: selected ? Colors.orange.shade50 : null,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: selected ? Colors.orange : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(option.label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(option.description),
                  trailing: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected ? Colors.orange : Colors.grey),
                ),
              );
            }),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _requestVerification,
              onChanged: (value) =>
                  setState(() => _requestVerification = value),
              title: const Text('Require worker verification'),
              subtitle: const Text('Only verified workers can apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('Job description',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(' *',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    'Describe the tasks, environment, or any special notes…',
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Job description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _requirementsController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'List requirements (one per line)',
                labelText: 'Requirements (optional)',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  List<_TimeOption> get _popularTimeOptions => const <_TimeOption>[
        _TimeOption('06:00', '6:00 AM'),
        _TimeOption('07:00', '7:00 AM'),
        _TimeOption('08:00', '8:00 AM'),
        _TimeOption('09:00', '9:00 AM'),
        _TimeOption('10:00', '10:00 AM'),
        _TimeOption('11:00', '11:00 AM'),
        _TimeOption('12:00', '12:00 PM'),
        _TimeOption('13:00', '1:00 PM'),
        _TimeOption('14:00', '2:00 PM'),
        _TimeOption('15:00', '3:00 PM'),
        _TimeOption('16:00', '4:00 PM'),
        _TimeOption('17:00', '5:00 PM'),
        _TimeOption('18:00', '6:00 PM'),
        _TimeOption('19:00', '7:00 PM'),
        _TimeOption('20:00', '8:00 PM'),
        _TimeOption('21:00', '9:00 PM'),
        _TimeOption('22:00', '10:00 PM'),
      ];
}

class _FrequencyOption {
  const _FrequencyOption(this.value, this.label, this.description, this.icon);

  final String value;
  final String label;
  final String description;
  final IconData icon;
}

class _UrgencyOption {
  const _UrgencyOption(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;
}

class _JobSuggestion {
  const _JobSuggestion(
      {required this.rate, required this.peak, required this.location});

  final String rate;
  final String peak;
  final String location;
}

class _JobTemplate {
  const _JobTemplate({
    required this.title,
    required this.description,
    required this.requirements,
    required this.suggestedRate,
    required this.frequency,
  });

  final String title;
  final String description;
  final String requirements;
  final String suggestedRate;
  final String frequency;
}

class _TimeOption {
  const _TimeOption(this.value, this.label);

  final String value;
  final String label;
}

class _WorkdayQuickButton extends StatelessWidget {
  const _WorkdayQuickButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      child: Text(label.toUpperCase()),
    );
  }
}

class _TimePickerSheet extends StatelessWidget {
  const _TimePickerSheet({
    required this.popularTimes,
    required this.timeOptions,
    this.initialValue,
  });

  final List<_TimeOption> popularTimes;
  final List<_TimeOption> timeOptions;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select time',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: popularTimes.length,
                itemBuilder: (context, index) {
                  final _TimeOption option = popularTimes[index];
                  final bool selected = option.value == initialValue;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(option.label),
                      selected: selected,
                      onSelected: (_) => Navigator.pop(context, option.value),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Pick custom time'),
              onTap: () async {
                final TimeOfDay now = TimeOfDay.now();
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: initialValue != null
                      ? TimeOfDay(
                          hour: int.parse(initialValue!.split(':')[0]),
                          minute: int.parse(initialValue!.split(':')[1]),
                        )
                      : now,
                );
                if (picked != null) {
                  final String value =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context, value);
                }
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: timeOptions.length,
                itemBuilder: (context, index) {
                  final _TimeOption option = timeOptions[index];
                  final bool selected = option.value == initialValue;
                  return ListTile(
                    onTap: () => Navigator.pop(context, option.value),
                    title: Text(option.label),
                    trailing: selected
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
