// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/state/app_state.dart';

class WorkerPrivacySettingsScreen extends StatefulWidget {
  const WorkerPrivacySettingsScreen({super.key});

  @override
  State<WorkerPrivacySettingsScreen> createState() =>
      _WorkerPrivacySettingsScreenState();
}

class _WorkerPrivacySettingsScreenState
    extends State<WorkerPrivacySettingsScreen> {
  bool _showProfileToEmployers = true;
  bool _allowLocationAccess = true;
  bool _shareWorkHistory = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final appState = context.read<AppState>();
    final profile = appState.workerProfile;
    if (profile != null) {
      setState(() {
        _showProfileToEmployers = profile.isVisible ?? true;
        _allowLocationAccess = profile.locationEnabled ?? true;
        _shareWorkHistory = profile.shareWorkHistory ?? true;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final appState = context.read<AppState>();
      await appState.updatePrivacySettings(
        isVisible: _showProfileToEmployers,
        locationEnabled: _allowLocationAccess,
        shareWorkHistory: _shareWorkHistory,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy settings updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update settings: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Control how your information is shared with employers and the app.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          SwitchListTile(
            title: const Text('Show Profile to Employers'),
            subtitle: const Text(
              'Make your profile visible to employers searching for workers',
            ),
            value: _showProfileToEmployers,
            onChanged: (value) =>
                setState(() => _showProfileToEmployers = value),
          ),
          SwitchListTile(
            title: const Text('Allow Location Access'),
            subtitle: const Text(
              'Enable location services for job matching and attendance',
            ),
            value: _allowLocationAccess,
            onChanged: (value) => setState(() => _allowLocationAccess = value),
          ),
          SwitchListTile(
            title: const Text('Share Work History'),
            subtitle: const Text(
              'Allow employers to see your past work experience and ratings',
            ),
            value: _shareWorkHistory,
            onChanged: (value) => setState(() => _shareWorkHistory = value),
          ),
          const Divider(height: 32),
          ListTile(
            title: const Text('Delete Account'),
            subtitle: const Text(
              'Permanently remove your account and all associated data',
            ),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: _showDeleteAccountDialog,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data, including work history '
          'and earnings information, will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final appState = context.read<AppState>();
        await appState.deleteAccount();

        if (!mounted) return;
        // Navigate to login screen after successful deletion
        unawaited(Navigator.pushNamedAndRemoveUntil(
            context, '/login', (route) => false));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}
