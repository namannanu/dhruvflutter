import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/employer/widgets/edit_business.dart';
import 'package:talent/features/employer/widgets/work_location_picker.dart';
import 'package:talent/features/shared/mixins/auto_refresh_mixin.dart';
import 'package:talent/features/shared/widgets/section_header.dart';

class EmployerDashboardScreen extends StatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  State<EmployerDashboardScreen> createState() =>
      _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen>
    with AutoRefreshMixin<EmployerDashboardScreen> {
  @override
  Future<void> refreshData() async {
    if (mounted) {
      await context.read<AppState>().refreshActiveRole();
    }
  }

  @override
  void initState() {
    super.initState();
    // Trigger initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Show loading state
    if (appState.isBusy) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check if user is actually an employer
    if (appState.currentUser?.type != UserType.employer) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Employer Access Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                  'Please login as an employer to access this dashboard.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final metrics = appState.employerMetrics;
    final profile = appState.employerProfile;
    final businesses = appState.businesses;

    // Show loading if data is still null
    if (metrics == null || profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Employer Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final number = NumberFormat.compact();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () {
              Navigator.pushNamed(context, '/team-management');
            },
            tooltip: 'Team Management',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshData(),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.companyName,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.description.isNotEmpty
                            ? profile.description
                            : 'Add a company description to attract more talent',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rating ${profile.rating.toStringAsFixed(1)} ★'),
                    Text(
                      '${profile.totalJobsPosted} jobs · ${profile.totalHires} hires',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Open jobs',
                        value: metrics.openJobs.toString(),
                        icon: Icons.work_outline,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MetricTile(
                        label: 'Applicants',
                        value: number.format(metrics.totalApplicants),
                        icon: Icons.group_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Hires',
                        value: number.format(metrics.totalHires),
                        icon: Icons.celebration_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MetricTile(
                        label: 'Avg response time',
                        value:
                            '${metrics.averageResponseTimeHours.toStringAsFixed(1)} h',
                        icon: Icons.timer_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Free postings left',
                        value: metrics.freePostingsRemaining.toString(),
                        icon: Icons.redeem_outlined,
                        highlight: metrics.freePostingsRemaining == 0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MetricTile(
                        label: 'Premium plan',
                        value: metrics.premiumActive ? 'Active' : 'Trial',
                        icon: Icons.workspace_premium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            const SectionHeader(
              title: 'Recent jobs',
              subtitle: 'Monitor health across open postings',
            ),
            const SizedBox(height: 12),
            if (metrics.recentJobSummaries.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No recent jobs. Create your first job posting!'),
                ),
              )
            else
              ...metrics.recentJobSummaries.map(
                (job) => Card(
                  child: ListTile(
                    title: Text(job.title),
                    subtitle: Text(
                      '${job.applicants} applicants · ${job.hires} hires',
                    ),
                    trailing: Chip(
                      label: Text(
                        job.status[0].toUpperCase() + job.status.substring(1),
                      ),
                    ),
                    onTap: () => context.read<AppState>().selectJob(job.jobId),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Business locations',
              subtitle: 'Manage hiring context and analytics',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_business),
              label: const Text('Add Business'),
              onPressed: () async {
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => const _AddBusiness(),
                );
                // Refresh the business list after modal is closed
                if (result == true && context.mounted) {
                  await context.read<AppState>().refreshActiveRole();
                }
              },
            ),
            const SizedBox(height: 12),
            if (businesses.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Add a business to start posting jobs.'),
                ),
              )
            else
              ...businesses
                  .map((business) => _BusinessTile(business: business)),
          ],
        ),
      ),
    );
  }
}

class _AddBusiness extends StatefulWidget {
  const _AddBusiness();

  @override
  State<_AddBusiness> createState() => _AddBusinessState();
}

class _AddBusinessState extends State<_AddBusiness> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalController = TextEditingController();
  final _phoneController = TextEditingController();

  PlaceDetails? _selectedPlace;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final appState = context.read<AppState>();
      await appState.addBusiness(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business added successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add business: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _applyPlaceDetails(PlaceDetails place) {
    setState(() {
      _selectedPlace = place;
    });

    final street = place.streetAddress ?? place.formattedAddress;
    if (street.isNotEmpty) {
      _addressController.text = street;
    }

    final city = place.city;
    if (city != null && city.isNotEmpty) {
      _cityController.text = city;
    }

    final state = place.stateShort ?? place.state;
    if (state != null && state.isNotEmpty) {
      _stateController.text = state;
    }

    final postal = place.postalCode;
    if (postal != null && postal.isNotEmpty) {
      _postalController.text = postal;
    }
  }

  Future<void> _pickLocation() async {
    if (_submitting) return;
    final result = await showWorkLocationPicker(
      context,
      initialPlace: _selectedPlace,
    );

    if (result != null) {
      _applyPlaceDetails(result.place);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '➕ Add a new business',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickLocation,
                      icon: const Icon(Icons.map_outlined),
                      label: Text(
                        _selectedPlace == null
                            ? 'Search address with Google Maps'
                            : 'Update address from Google Maps',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedPlace != null) ...[
                      Card(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.2),
                        child: ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: Text(_selectedPlace!.name),
                          subtitle: Text(_selectedPlace!.formattedAddress),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Business name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter business name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Street address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter business address'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Enter city' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Enter state' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _postalController,
                      decoration: const InputDecoration(
                        labelText: 'Postal code',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter postal code' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add_business),
                        label: Text(_submitting ? 'Adding…' : 'Add Business'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        highlight ? theme.colorScheme.error : theme.colorScheme.primary;

    return Card(
      color: highlight ? theme.colorScheme.errorContainer : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: highlight ? theme.colorScheme.onErrorContainer : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessTile extends StatelessWidget {
  const _BusinessTile({required this.business});

  final BusinessLocation business;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      Text(business.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        business.fullAddress,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: business.isActive,
                  onChanged: (value) async {
                    try {
                      await context.read<AppState>().updateBusiness(
                            business.id,
                            isActive: value,
                          );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update business: $e'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.work_outline, size: 18),
                const SizedBox(width: 8),
                Text('${business.jobCount} jobs · ${business.hireCount} hires'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Connect to PATCH /users/{id} to set selected business.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Make default'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () async {
                    final result = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => EditBusiness(business: business),
                    );
                    if (result == true && context.mounted) {
                      await context.read<AppState>().refreshActiveRole();
                    }
                  },
                  child: const Text('Manage'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
