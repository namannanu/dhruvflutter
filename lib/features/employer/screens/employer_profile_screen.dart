import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/employer/screens/employer_billing_screen.dart';
import 'package:talent/features/shared/screens/messaging_screen.dart';
import 'package:talent/features/team_management/screens/team_api_test_page copy.dart';

class EmployerProfileScreen extends StatefulWidget {
  const EmployerProfileScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().loadEmployerFeedback(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _companyDescriptionController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    final appState = context.read<AppState>();
    final profile = appState.employerProfile;

    if (profile != null) {
      _nameController.text = profile.companyName;
      _phoneController.text = profile.phone;
      _companyNameController.text = profile.companyName;
      _companyDescriptionController.text = profile.description;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Implementation needed: Implement actual API call to update employer profile
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simulate API call

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    final appState = context.read<AppState>();
    try {
      await appState.logout();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMessaging() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MessagingScreen(),
      ),
    );
  }

  void _navigateToTeamManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TeamApiTestPage(),
      ),
    );
  }

  void _navigateToBusinessManager() {
    // Implementation needed: Implement business manager navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening business manager...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final profile = appState.employerProfile;
        final currentUser = appState.currentUser;
        final businesses = appState.businesses;
        final selectedBusiness =
            businesses.isNotEmpty ? businesses.first : null;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(context),
          body: RefreshIndicator(
            onRefresh: () async {
              await appState.refreshActiveRole();
              await appState.loadEmployerFeedback(forceRefresh: true);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileCard(context, profile, currentUser),
                  const SizedBox(height: 16),
                  _buildQuickStats(context, profile),
                  const SizedBox(height: 16),
                  _buildBusinessInfo(context, selectedBusiness, businesses),
                  const SizedBox(height: 16),
                  if (businesses.length > 1) ...[
                    _buildAllBusinessesOverview(context, businesses),
                    const SizedBox(height: 16),
                    _buildPortfolioStats(context, businesses),
                    const SizedBox(height: 16),
                  ],
                  _buildBusinessPerformance(context),
                  const SizedBox(height: 16),
                  _buildHiringActivity(context, profile),
                  const SizedBox(height: 16),
                  _buildWorkerReviews(context, appState),
                  const SizedBox(height: 16),
                  _buildTeamManagement(context),
                  const SizedBox(height: 16),
                  _buildAccountActions(context),
                  const SizedBox(height: 80), // Bottom padding
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Business Profile'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      leading: widget.onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            )
          : null,
      actions: [
        // Messaging button
        IconButton(
          icon: const Icon(Icons.message),
          onPressed: _showMessaging,
          tooltip: 'Messages',
        ),
        // Edit button
        IconButton(
          icon: Icon(_isEditing ? Icons.check : Icons.edit),
          onPressed: _isEditing
              ? _handleSave
              : () => setState(() => _isEditing = true),
          tooltip: _isEditing ? 'Save' : 'Edit',
        ),
        // Sign out button
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: _handleSignOut,
          tooltip: 'Sign Out',
        ),
      ],
    );
  }

  Widget _buildProfileCard(
      BuildContext context, EmployerProfile? profile, User? currentUser) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[500]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          profile?.companyName.isNotEmpty == true
                              ? profile!.companyName[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Verification badge
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Profile info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditing) ...[
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _companyNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Company Name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Company name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Your Name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Name is required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          profile?.companyName ?? 'Company Name',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentUser?.firstName ?? 'Owner Name',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${profile?.rating ?? 0.0}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(24 reviews)',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: Colors.grey[600], size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Downtown area',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.verified,
                              color: Colors.green, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Business',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Company Description
            if (_isEditing) ...[
              TextFormField(
                controller: _companyDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Company Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ] else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  profile?.description ??
                      'We are a growing company focused on providing excellent services and creating opportunities for talented workers.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Contact Info
            Column(
              children: [
                _buildInfoRow(
                    'Email:', currentUser?.email ?? 'email@company.com'),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Phone:',
                  profile?.phone ?? '+1 (555) 123-4567',
                  isEditing: _isEditing,
                  controller: _phoneController,
                ),
              ],
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isEditing = false, TextEditingController? controller}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isEditing && controller != null) ...[
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ),
        ] else ...[
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, EmployerProfile? profile) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${profile?.totalJobsPosted ?? 0}',
            label: 'Jobs Posted',
            color: Colors.blue[600]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '${profile?.totalHires ?? 0}',
            label: 'Workers Hired',
            color: Colors.green[600]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '${profile?.rating ?? 0.0}',
            label: 'Rating',
            color: Colors.purple[600]!,
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessInfo(BuildContext context,
      BusinessLocation? selectedBusiness, List<BusinessLocation> businesses) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Current Business',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (businesses.length > 1)
                  TextButton(
                    onPressed: _navigateToBusinessManager,
                    child: Text(
                      'Switch (${businesses.length} locations)',
                      style: TextStyle(color: Colors.blue[600]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedBusiness != null) ...[
              _buildInfoRow('Business Name:', selectedBusiness.name),
              const SizedBox(height: 8),
              _buildInfoRow('Address:', selectedBusiness.address),
              const SizedBox(height: 8),
              _buildInfoRow('Business Type:', selectedBusiness.description),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status:',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    selectedBusiness.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: selectedBusiness.isActive
                          ? Colors.green[600]
                          : Colors.red[600],
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'No business selected',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: _navigateToBusinessManager,
                    child: const Text('Select Business'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllBusinessesOverview(
      BuildContext context, List<BusinessLocation> businesses) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Business Locations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: _navigateToBusinessManager,
                  child: const Text('Manage All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...businesses.take(3).map((business) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                business.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                business.address,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              '0 jobs',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '0 hires',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
            if (businesses.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${businesses.length - 3} more locations',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioStats(
      BuildContext context, List<BusinessLocation> businesses) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Portfolio Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${businesses.length}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                        Text(
                          'Total Locations',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${businesses.where((b) => b.isActive).length}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                        Text(
                          'Active Locations',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '0',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[600],
                          ),
                        ),
                        Text(
                          'Total Jobs',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '0',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[600],
                          ),
                        ),
                        Text(
                          'Total Hires',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
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

  Widget _buildBusinessPerformance(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.business, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Business Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Portfolio Value:', 'Growing'),
            const SizedBox(height: 8),
            _buildInfoRow('Years in Business:', '5+ years'),
            const SizedBox(height: 8),
            _buildInfoRow('Total Employees:', '25-50'),
          ],
        ),
      ),
    );
  }

  Widget _buildHiringActivity(BuildContext context, EmployerProfile? profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Hiring Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('This month:', '3 hires'),
            const SizedBox(height: 8),
            _buildInfoRow('Response time:', '< 2 hours'),
            const SizedBox(height: 8),
            _buildInfoRow('Hire rate:', '85%'),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerReviews(BuildContext context, AppState appState) {
    final feedback = appState.employerFeedback;
    final isLoading = appState.isLoadingEmployerFeedback;

    if (isLoading && feedback.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (feedback.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reviews from Workers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text(
                'Workers you hire can share feedback here. Deliver great experiences to earn positive reviews.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reviews from Workers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...feedback.map((entry) {
              final workerName = entry.workerName ?? 'Worker';
              final timestamp =
                  DateFormat.yMMMd().format(entry.createdAt.toLocal());
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            workerName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        _buildRatingStars(entry.rating),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.comment.isEmpty
                          ? 'No comment provided'
                          : entry.comment,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timestamp,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (entry != feedback.last) ...[
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[200]),
                    ],
                  ],
                ),
              );
            }),
            if (isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;
        final isFull = rating >= value;
        final isHalf = !isFull && rating >= value - 0.5;
        return Icon(
          isFull
              ? Icons.star
              : isHalf
                  ? Icons.star_half
                  : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  Widget _buildTeamManagement(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(
            children: [
              Icon(Icons.group, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Team Management',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Manage your team members, assign roles and permissions across your business locations.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToTeamManagement,
              icon: const Icon(Icons.people, color: Colors.white),
              label: const Text(
                'Manage Team',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              'Billing & Payments',
              'Manage payment methods and billing',
              Colors.grey[50]!,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EmployerBillingScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              'Notification Settings',
              'Control how you receive updates',
              Colors.grey[50]!,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Opening notification settings...')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              'Sign Out',
              'Sign out of your account',
              Colors.red[50]!,
              _handleSignOut,
              textColor: Colors.red[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
      String title, String subtitle, Color backgroundColor, VoidCallback onTap,
      {Color? textColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: textColor ?? Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: textColor?.withValues(alpha: 0.7) ?? Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
