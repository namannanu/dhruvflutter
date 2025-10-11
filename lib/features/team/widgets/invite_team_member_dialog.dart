// ignore_for_file: valid_regexps, avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';

/// Dialog used to invite a new team member with role + permission selections.
class InviteTeamMemberDialog extends StatefulWidget {
  const InviteTeamMemberDialog({super.key});

  @override
  State<InviteTeamMemberDialog> createState() => _InviteTeamMemberDialogState();
}

class _InviteTeamMemberDialogState extends State<InviteTeamMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRole = 'staff';
  String? _selectedBusinessId;
  final List<String> _selectedPermissions = [];

  final List<String> _availableRoles = [
    'staff',
    'supervisor',
    'manager',
    'admin',
  ];

  final Map<String, String> _availablePermissions = {
    // Business Management
    'create_business': 'Create Business',
    'edit_business': 'Edit Business',
    'delete_business': 'Delete Business',
    'view_business_analytics': 'View Business Analytics',

    // Job Management
    'create_jobs': 'Create Jobs',
    'edit_jobs': 'Edit Jobs',
    'delete_jobs': 'Delete Jobs',
    'view_jobs': 'View Jobs',
    'post_jobs': 'Post Jobs',

    // Worker & Application Management
    'hire_workers': 'Hire Workers',
    'fire_workers': 'Fire Workers',
    'view_applications': 'View Applications',
    'manage_applications': 'Manage Applications',
    'approve_applications': 'Approve Applications',
    'reject_applications': 'Reject Applications',

    // Schedule & Attendance Management
    'create_schedules': 'Create Schedules',
    'edit_schedules': 'Edit Schedules',
    'delete_schedules': 'Delete Schedules',
    'manage_schedules': 'Manage Schedules',
    'view_attendance': 'View Attendance',
    'manage_attendance': 'Manage Attendance',
    'approve_attendance': 'Approve Attendance',

    // Payment & Financial Management
    'view_payments': 'View Payments',
    'manage_payments': 'Manage Payments',
    'process_payments': 'Process Payments',
    'view_financial_reports': 'View Financial Reports',

    // Team Management
    'invite_team_members': 'Invite Team Members',
    'edit_team_members': 'Edit Team Members',
    'view_team_members': 'View Team Members',
    'manage_team_members': 'Manage Team Members',
    'remove_team_members': 'Remove Team Members',
    'manage_permissions': 'Manage Permissions',

    // Analytics & Reporting
    'view_analytics': 'View Analytics',
    'view_reports': 'View Reports',
    'export_data': 'Export Data',

    // System Administration
    'manage_settings': 'Manage Settings',
    'view_audit_logs': 'View Audit Logs',
    'manage_integrations': 'Manage Integrations',
  };

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _updatePermissionsForRole(_selectedRole);

    // Auto-select the current business if there's only one or if there's a selected business
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      final businesses = appState.businesses;

      if (businesses.isNotEmpty) {
        // First try to use the currently selected business
        final selectedBusinessId = appState.currentUser?.selectedBusinessId;
        if (selectedBusinessId != null && selectedBusinessId.isNotEmpty) {
          final selectedBusiness = businesses.firstWhere(
            (b) => b.id == selectedBusinessId,
            orElse: () => businesses.first,
          );
          setState(() {
            _selectedBusinessId = selectedBusiness.id;
          });
        } else {
          // If no selected business, use the first one
          setState(() {
            _selectedBusinessId = businesses.first.id;
          });
        }
      }
    });
  }

  void _updatePermissionsForRole(String role) {
    setState(() {
      _selectedPermissions.clear();

      switch (role.toLowerCase()) {
        case 'admin':
          _selectedPermissions.addAll(_availablePermissions.keys);
          break;
        case 'manager':
          _selectedPermissions.addAll([
            'edit_business',
            'view_business_analytics',
            'create_jobs',
            'edit_jobs',
            'view_jobs',
            'post_jobs',
            'hire_workers',
            'view_applications',
            'manage_applications',
            'approve_applications',
            'reject_applications',
            'create_schedules',
            'edit_schedules',
            'manage_schedules',
            'view_attendance',
            'manage_attendance',
            'approve_attendance',
            'view_payments',
            'manage_payments',
            'process_payments',
            'view_financial_reports',
            'invite_team_members',
            'edit_team_members',
            'view_team_members',
            'view_analytics',
            'view_reports',
            'export_data',
          ]);
          break;
        case 'supervisor':
          _selectedPermissions.addAll([
            'view_jobs',
            'post_jobs',
            'view_applications',
            'manage_applications',
            'create_schedules',
            'edit_schedules',
            'manage_schedules',
            'view_attendance',
            'manage_attendance',
            'view_payments',
            'view_team_members',
            'view_analytics',
            'view_reports',
          ]);
          break;
        case 'staff':
        default:
          _selectedPermissions.addAll([
            'view_jobs',
            'view_applications',
            'view_attendance',
            'view_analytics',
          ]);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final businesses = appState.businesses;

    return AlertDialog(
      title: const Text('Invite Team Member'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Email is required';
                  }
                  final pattern =
                      RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}\$');
                  if (!pattern.hasMatch(value!)) {
                    return 'Enter a valid email address';
                  }

                  // Check if user is trying to invite themselves
                  final appState = context.read<AppState>();
                  final currentUserEmail = appState.currentUser?.email;
                  if (currentUserEmail != null &&
                      currentUserEmail.toLowerCase() ==
                          value.trim().toLowerCase()) {
                    return 'You cannot invite yourself as a team member';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedBusinessId,
                decoration: const InputDecoration(
                  labelText: 'Business',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select a business'),
                items: businesses.map((business) {
                  return DropdownMenuItem(
                    value: business.id,
                    child: Text(business.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBusinessId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a business';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: _availableRoles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                    _updatePermissionsForRole(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Permissions',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: _availablePermissions.entries.map((entry) {
                      return CheckboxListTile(
                        title: Text(entry.value),
                        value: _selectedPermissions.contains(entry.key),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedPermissions.add(entry.key);
                            } else {
                              _selectedPermissions.remove(entry.key);
                            }
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            print('DEBUG: Send Invitation button pressed');
            print('DEBUG: Form valid: ${_formKey.currentState?.validate()}');
            print('DEBUG: Selected business ID: $_selectedBusinessId');
            print('DEBUG: Email: ${_emailController.text}');
            print('DEBUG: Role: $_selectedRole');
            print('DEBUG: Permissions: $_selectedPermissions');

            if (_formKey.currentState!.validate()) {
              if (_selectedBusinessId == null || _selectedBusinessId!.isEmpty) {
                print('DEBUG: No business selected, showing error');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a business first'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              print('DEBUG: Form validation passed, closing dialog');
              final result = {
                'email': _emailController.text.trim(),
                'businessId': _selectedBusinessId,
                'role': _selectedRole,
                'permissions': List<String>.from(_selectedPermissions),
              };
              print('DEBUG: Returning result: $result');
              Navigator.of(context).pop(result);
            } else {
              print('DEBUG: Form validation failed');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
          ),
          child: const Text(
            'Send Invitation',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
