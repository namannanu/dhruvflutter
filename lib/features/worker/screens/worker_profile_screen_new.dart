import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/worker_profile.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/worker/widgets/profile_form.dart';
import 'package:talent/features/worker/widgets/profile_widgets.dart';
import 'package:talent/features/worker/widgets/work_preferences_widget.dart';

enum ProfileTab {
  profile,
  workPreferences;

  String get label {
    switch (this) {
      case ProfileTab.profile:
        return 'Profile';
      case ProfileTab.workPreferences:
        return 'Work Preferences';
    }
  }
}

class WorkerProfileScreen extends StatefulWidget {
  final ProfileTab initialTab;

  const WorkerProfileScreen({
    super.key,
    this.initialTab = ProfileTab.profile,
  });

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _skillsController = TextEditingController();
  final _languagesController = TextEditingController();
  final _profilePictureUrlController = TextEditingController();
  bool _isEditing = false;

  // Form state
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ProfileTab.values.length,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshActiveRole();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    _languagesController.dispose();
    _profilePictureUrlController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeFormWithProfile(WorkerProfile? profile) {
    if (profile == null) return;

    try {
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _phoneController.text = profile.phone;
      _bioController.text = profile.bio;
      _experienceController.text = profile.experience;
      _skillsController.text = profile.skills.join(', ');
      _languagesController.text = profile.languages.join(', ');
      _profilePictureUrlController.text = profile.profilePictureSmall ?? 'null';
      _notificationsEnabled = profile.notificationsEnabled;


      
    } catch (error) {
      debugPrint('Error initializing profile form: $error');
      
    }
  }

  void _startEditing() {
    _initializeFormWithProfile(context.read<AppState>().workerProfile);
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _saveChanges(AppState appState) async {
    if (!_formKey.currentState!.validate()) return;

    final newFirstName = _firstNameController.text.trim();
    final newLastName = _lastNameController.text.trim();
    final newPhone = _phoneController.text.trim();
    final newBio = _bioController.text.trim();
    final newExperience = _experienceController.text.trim();
    final newSkills = _commaSeparated(_skillsController.text);
    final newLanguages = _commaSeparated(_languagesController.text);
    final newProfilePictureUrl = _profilePictureUrlController.text.trim();

   
    await appState.updateWorkerProfile(
      firstName: newFirstName,
      lastName: newLastName,
      phone: newPhone,
      bio: newBio,
      experience: newExperience,
      skills: newSkills,
      languages: newLanguages,
      notificationsEnabled: _notificationsEnabled,
      profilePictureUrl: newProfilePictureUrl.isEmpty ? null : newProfilePictureUrl,
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
    final workerProfile = appState.workerProfile;

    if (workerProfile == null) {
      return const Center(child: CircularProgressIndicator());
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
                      _startEditing();
                    }
                  },
            icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: ProfileTab.values.map((tab) => Tab(text: tab.label)).toList(),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Profile Tab
            RefreshIndicator(
              onRefresh: () => context.read<AppState>().refreshActiveRole(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileHeader(profile: workerProfile),
                    const SizedBox(height: 16),
                    EarningsSummary(profile: workerProfile),
                    const SizedBox(height: 24),
                    if (_isEditing)
                      EditableProfileForm(
                          formKey: _formKey,
                          firstNameController: _firstNameController,
                          lastNameController: _lastNameController,
                          phoneController: _phoneController,
                          bioController: _bioController,
                          experienceController: _experienceController,
                          skillsController: _skillsController,
                          languagesController: _languagesController,
                          profilePictureUrlController: _profilePictureUrlController,
                         
                          notificationsEnabled: _notificationsEnabled,
                          onNotificationsChanged: (value) {
                            setState(() => _notificationsEnabled = value);
                          })
                    else
                      ReadOnlyProfileDetails(profile: workerProfile),
                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isBusy
                                    ? null
                                    : () => _saveChanges(appState),
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
                      ),
                  ],
                ),
              ),
            ),
            // Work Preferences Tab
            const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: WorkPreferencesWidget(),
            ),
          ],
        ),
      ),
    );
  }
}
