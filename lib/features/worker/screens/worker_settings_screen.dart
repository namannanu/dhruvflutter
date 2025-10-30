// ignore_for_file: use_build_context_synchronously, unawaited_futures

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/worker/screens/worker_privacy_settings_screen.dart';
import 'package:talent/features/worker/screens/worker_profile_screen_new.dart';
import 'package:talent/features/worker/widgets/feedback_dialog.dart';

class WorkerSettingsScreen extends StatefulWidget {
  const WorkerSettingsScreen({super.key});

  @override
  State<WorkerSettingsScreen> createState() => _WorkerSettingsScreenState();
}

class _WorkerSettingsScreenState extends State<WorkerSettingsScreen> {
  Future<void> _updateNotificationSetting({
    bool? pushEnabled,
    bool? emailEnabled,
    required String successMessage,
    required String failurePrefix,
  }) async {
    try {
      await context.read<AppState>().updateWorkerNotificationSettings(
            pushEnabled: pushEnabled,
            emailEnabled: emailEnabled,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$failurePrefix: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile Section
          _SettingsSection(
            title: 'Profile & Account',
            items: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Edit Profile'),
                subtitle: const Text('Update your personal information'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // Notifications Section
          _SettingsSection(
            title: 'Notifications',
            items: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive alerts for new jobs and updates'),
                value: appState.workerProfile?.notificationsEnabled ?? false,
                onChanged: (bool value) async {
                  await _updateNotificationSetting(
                    pushEnabled: value,
                    successMessage: 'Push notifications settings updated',
                    failurePrefix: 'Failed to update push notifications',
                  );
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.email_outlined),
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive job updates via email'),
                value:
                    appState.workerProfile?.emailNotificationsEnabled ?? true,
                onChanged: (bool value) async {
                  await _updateNotificationSetting(
                    emailEnabled: value,
                    successMessage: 'Email notifications settings updated',
                    failurePrefix: 'Failed to update email notifications',
                  );
                },
              ),
            ],
          ),

          // Privacy & Security
          _SettingsSection(
            title: 'Privacy & Security',
            items: [
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Privacy Settings'),
                subtitle: const Text('Control your data and visibility'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerPrivacySettingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.password_outlined),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const WorkerChangePasswordScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // Support & About
          _SettingsSection(
            title: 'Support & About',
            items: [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerHelpSupportScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                subtitle: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text('Version ${snapshot.data!.version}');
                    }
                    return const Text('Loading version...');
                  },
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final packageInfo = await PackageInfo.fromPlatform();
                  showAboutDialog(
                    context: context,
                    applicationName: packageInfo.appName,
                    applicationVersion:
                        '${packageInfo.version} (${packageInfo.buildNumber})',
                    applicationIcon: const Icon(Icons.info_outline, size: 48),
                  );
                },
              ),
            ],
          ),

          // Feedback Section
          _SettingsSection(
            title: 'Feedback',
            items: [
              ListTile(
                leading: const Icon(Icons.feedback_outlined),
                title: const Text('Employer Feedback'),
                subtitle: const Text('Share your experience with employers'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context
                      .read<AppState>()
                      .loadWorkerEmploymentHistory(forceRefresh: true);
                  showDialog<void>(
                    context: context,
                    builder: (context) => const FeedbackDialog(),
                  );
                },
              ),
            ],
          ),

          // Account Actions
          _SettingsSection(
            title: 'Account',
            items: [
              ListTile(
                leading: Icon(Icons.logout, color: theme.colorScheme.error),
                title: Text(
                  'Sign Out',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('SIGN OUT'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    try {
                      await context.read<AppState>().logout();
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to sign out: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WorkerChangePasswordScreen extends StatelessWidget {
  const WorkerChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: const Center(
        child: Text('Change password screen coming soon.'),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...items,
        const Divider(),
      ],
    );
  }
}

class WorkerHelpSupportScreen extends StatelessWidget {
  const WorkerHelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Need assistance? Use the options below to connect with the support team.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          const Card(
            child: ListTile(
              leading: Icon(Icons.live_help_outlined),
              title: Text('Help Center'),
              subtitle: Text(
                'Browse quick guides and answers for common questions.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.mail_outline),
              title: Text('Email Support'),
              subtitle: Text(
                'Send us a message and we will respond as soon as possible.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.phone_in_talk_outlined),
              title: Text('Call Support'),
              subtitle: Text(
                'Speak with a support specialist during business hours.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
