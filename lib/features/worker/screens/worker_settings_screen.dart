// ignore_for_file: use_build_context_synchronously, unawaited_futures

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/shared/widgets/section_header.dart';
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
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(
            title: 'Worker settings',
            subtitle: 'Manage your profile, alerts, and preferences',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          _SettingsBlock(
            title: 'Profile & account',
            subtitle: 'Keep your personal details current',
            children: [
              _SettingsTileCard(
                icon: Icons.person_outline,
                title: 'Edit profile',
                subtitle: 'Update skills, experience, and availability',
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
          _SettingsBlock(
            title: 'Notifications',
            subtitle: 'Choose how you hear about new jobs',
            children: [
              _SettingsToggleCard(
                icon: Icons.notifications_active_outlined,
                title: 'Push notifications',
                subtitle: 'Receive alerts for new jobs and updates',
                value: appState.workerProfile?.notificationsEnabled ?? false,
                iconColor: theme.colorScheme.primary,
                onChanged: (value) async {
                  await _updateNotificationSetting(
                    pushEnabled: value,
                    successMessage: 'Push notifications settings updated',
                    failurePrefix: 'Failed to update push notifications',
                  );
                },
              ),
              _SettingsToggleCard(
                icon: Icons.email_outlined,
                title: 'Email notifications',
                subtitle: 'Receive job updates via email',
                value:
                    appState.workerProfile?.emailNotificationsEnabled ?? true,
                iconColor: theme.colorScheme.secondary,
                onChanged: (value) async {
                  await _updateNotificationSetting(
                    emailEnabled: value,
                    successMessage: 'Email notifications settings updated',
                    failurePrefix: 'Failed to update email notifications',
                  );
                },
              ),
            ],
          ),
          _SettingsBlock(
            title: 'Privacy & security',
            subtitle: 'Control who sees your information',
            children: [
              _SettingsTileCard(
                icon: Icons.security_outlined,
                title: 'Privacy settings',
                subtitle: 'Manage visibility and data sharing',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerPrivacySettingsScreen(),
                    ),
                  );
                },
              ),
              _SettingsTileCard(
                icon: Icons.password_outlined,
                title: 'Change password',
                subtitle: 'Add extra security to your account',
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
          _SettingsBlock(
            title: 'Support & about',
            subtitle: 'Get help and learn more about the app',
            children: [
              _SettingsTileCard(
                icon: Icons.help_outline,
                title: 'Help & support',
                subtitle: 'Browse guides or contact support',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerHelpSupportScreen(),
                    ),
                  );
                },
              ),
              _SettingsTileCard(
                icon: Icons.info_outline,
                title: 'About',
                subtitleWidget: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version;
                    return Text(
                      version != null
                          ? 'Version $version'
                          : 'Loading version…',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
                onTap: () async {
                  final packageInfo = await PackageInfo.fromPlatform();
                  if (!mounted) return;
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
          _SettingsBlock(
            title: 'Feedback',
            subtitle: 'Share how employers work with you',
            children: [
              _SettingsTileCard(
                icon: Icons.feedback_outlined,
                title: 'Employer feedback',
                subtitle: 'Send feedback about your job experiences',
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
          _SettingsBlock(
            title: 'Account',
            subtitle: 'Quick actions for your account access',
            children: [
              _SettingsTileCard(
                icon: Icons.logout,
                iconColor: theme.colorScheme.error,
                titleColor: theme.colorScheme.error,
                title: 'Sign out',
                subtitle: 'Log out from this device',
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign out'),
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

class _SettingsBlock extends StatelessWidget {
  const _SettingsBlock({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          style: const TextStyle(fontSize: 10),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SettingsTileCard extends StatelessWidget {
  const _SettingsTileCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary;
    final textColor = titleColor ?? theme.colorScheme.onSurface;
    final hasTap = onTap != null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBadge(icon: icon, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    if (subtitleWidget != null) ...[
                      const SizedBox(height: 4),
                      subtitleWidget!,
                    ] else if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasTap)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleCard extends StatelessWidget {
  const _SettingsToggleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        secondary: _IconBadge(icon: icon, color: color),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(12),
      child: Icon(icon, color: color),
    );
  }
}
