// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/services/image_optimization_service.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/employer/widgets/edit_business.dart';
import 'package:talent/features/employer/widgets/work_location_picker.dart';
import 'package:talent/features/shared/mixins/auto_refresh_mixin.dart';
import 'package:talent/features/shared/widgets/business_logo_avatar.dart';
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
      final appState = context.read<AppState>();
      
      // Use fast initialization instead of blocking refreshActiveRole
      await appState.fastInit();
    }
  }

  @override
  void initState() {
    super.initState();
    // Trigger fast initial data load - no blocking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Use fast init that shows cached data immediately
        context.read<AppState>().fastInit();
      }
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
    final currentUser = appState.currentUser;

    // Show loading if data is still null
    if (metrics == null || profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Employer Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final number = NumberFormat.compact();
    BusinessLocation? primaryBusiness;
    if (businesses.isNotEmpty) {
      final selectedBusinessId = currentUser?.selectedBusinessId;
      if (selectedBusinessId != null && selectedBusinessId.isNotEmpty) {
        primaryBusiness = businesses.firstWhere(
          (b) => b.id == selectedBusinessId,
          orElse: () => businesses.first,
        );
      } else {
        primaryBusiness = businesses.first;
      }
    }
    final primaryBusinessName =
        (primaryBusiness != null && primaryBusiness.name.isNotEmpty)
            ? primaryBusiness.name
            : (profile.companyName.isNotEmpty
                ? profile.companyName
                : 'Your business');

    final primaryLogoUrl = primaryBusiness?.logoSquareUrl ??
        primaryBusiness?.logoUrl ??
        primaryBusiness?.logoOriginalUrl;

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
                BusinessLogoAvatar(
                  logoUrl: primaryLogoUrl,
                  name: primaryBusinessName,
                ),
                const SizedBox(width: 12),
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
              title: 'Business locations',
              subtitle: 'Manage hiring context and analytics', style: TextStyle(fontSize: 10),
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
  final _logoUrlController = TextEditingController();

  PlaceDetails? _selectedPlace;
  double? _selectedRadiusMeters;
  String? _selectedLocationNotes;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _logoUrlController.addListener(_handleLogoChanged);
    _nameController.addListener(_handleNameChanged);
  }

  @override
  void dispose() {
    _logoUrlController.removeListener(_handleLogoChanged);
    _nameController.removeListener(_handleNameChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _phoneController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final appState = context.read<AppState>();
      final trimmedLogo = _logoUrlController.text.trim();
      await appState.addBusiness(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalController.text.trim(),
        phone: _phoneController.text.trim(),
        logoUrl: trimmedLogo.isEmpty ? null : trimmedLogo,
        // Include Google Places API location data if available
        latitude: _selectedPlace?.latitude,
        longitude: _selectedPlace?.longitude,
        placeId: _selectedPlace?.placeId,
        formattedAddress: _selectedPlace?.formattedAddress,
        allowedRadius:
            _selectedPlace != null ? (_selectedRadiusMeters ?? 150.0) : null,
        locationName: _selectedPlace?.name,
        locationNotes: _selectedPlace != null ? _selectedLocationNotes : null,
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

  void _handleLogoChanged() {
    setState(() {});
  }

  void _handleNameChanged() {
    setState(() {});
  }

  Future<void> _pickLogo() async {
    try {
      // Show dialog to indicate file picker is about to open
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening file picker...')),
      );

      const typeGroup = XTypeGroup(
        label: 'images',
        // UTIs for iOS
        uniformTypeIdentifiers: [
          'public.image',
          'public.jpeg',
          'public.png',
        ],
        // Extensions for other platforms
        // ignore: unnecessary_const
        extensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
      );

      final file = await openFile(
        acceptedTypeGroups: [typeGroup],
      );
      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
        return;
      }

      print('File selected: ${file.name}'); // Debug log

      final bytes = await file.readAsBytes();
      print('File size: ${bytes.length} bytes'); // Debug log

      if (bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected image is empty.')),
        );
        return;
      }

      final mime = file.mimeType ?? _lookupMimeType(file.name);
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      final optimized =
          ImageOptimizationService.optimizeDataUrl(dataUrl) ?? dataUrl;

      if (kDebugMode) {
        debugPrint(
          '📉 Optimized dashboard logo data URL to '
          '${optimized.length} chars (was ${dataUrl.length})',
        );
      }

      setState(() {
        _logoUrlController.text = optimized;
      });
    } catch (error, stackTrace) {
      print('Error picking logo: $error'); // Debug log
      print('Stack trace: $stackTrace'); // Debug log

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Failed to pick image'),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  static String _lookupMimeType(String? extension) {
    if (extension == null || extension.isEmpty) {
      return 'image/png';
    }
    final lower = extension.toLowerCase();
    final ext = lower.contains('.') ? lower.split('.').last : lower;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'image/png';
    }
  }

  void _applyPlaceDetails(
    PlaceDetails place, {
    double? allowedRadius,
    String? notes,
  }) {
    setState(() {
      _selectedPlace = place;
      _selectedRadiusMeters = allowedRadius ?? _selectedRadiusMeters ?? 150.0;
      _selectedLocationNotes = notes;
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
      initialRadiusMeters: _selectedRadiusMeters ?? 150.0,
      initialNotes: _selectedLocationNotes,
    );

    if (result != null) {
      _applyPlaceDetails(
        result.place,
        allowedRadius: result.allowedRadius,
        notes: result.notes,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final maxSheetHeight = mediaQuery.size.height * 0.9;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '➕ Add a new business',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.place_outlined),
                                title: Text(_selectedPlace!.name),
                                subtitle:
                                    Text(_selectedPlace!.formattedAddress),
                              ),
                              ListTile(
                                leading: const Icon(Icons.social_distance),
                                title: const Text('Allowed radius'),
                                subtitle: Text(
                                  '${(_selectedRadiusMeters ?? 150.0).toStringAsFixed(0)} meters',
                                ),
                              ),
                              if (_selectedLocationNotes != null &&
                                  _selectedLocationNotes!.isNotEmpty)
                                ListTile(
                                  leading:
                                      const Icon(Icons.sticky_note_2_outlined),
                                  title: const Text('Location notes'),
                                  subtitle: Text(_selectedLocationNotes!),
                                ),
                            ],
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
                        validator: (v) => v == null || v.isEmpty
                            ? 'Enter business name'
                            : null,
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _logoUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Logo image',
                                hintText: 'Paste URL or upload an image',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          BusinessLogoAvatar(
                            name: _nameController.text.isEmpty
                                ? 'Business'
                                : _nameController.text,
                            logoUrl: _logoUrlController.text.trim().isEmpty
                                ? null
                                : _logoUrlController.text.trim(),
                            size: 56,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _submitting ? null : _pickLogo,
                            icon: const Icon(Icons.file_upload_outlined),
                            label: const Text('Upload image'),
                          ),
                          if (_logoUrlController.text.trim().isNotEmpty)
                            TextButton.icon(
                              onPressed: _submitting
                                  ? null
                                  : () {
                                      _logoUrlController.clear();
                                    },
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paste an existing image link or upload a PNG, JPG, WEBP file. Uploaded images are converted to a data URL and saved with the business.',
                        style: Theme.of(context).textTheme.bodySmall,
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SafeArea(
                top: false,
                child: SizedBox(
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
              ),
            ],
          ),
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
                BusinessLogoAvatar(
                  name: business.name,
                  logoUrl: business.logoSquareUrl ??
                      business.logoUrl ??
                      business.logoOriginalUrl,
                  size: 44,
                ),
                const SizedBox(width: 12),
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
                            logoUrl: business.logoUrl,
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
