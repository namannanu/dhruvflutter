import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/team_access.dart';
import '../../../core/providers/team_provider.dart';

class EditAccessDialog extends StatefulWidget {
  final TeamAccess teamAccess;
  final String currentUserId;

  const EditAccessDialog({
    super.key,
    required this.teamAccess,
    required this.currentUserId,
  });

  @override
  State<EditAccessDialog> createState() => _EditAccessDialogState();
}

class _EditAccessDialogState extends State<EditAccessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  late String _selectedRole;
  DateTime? _expiresAt;
  late TeamPermissions _permissions;
  bool _isSubmitting = false;

  final List<String> _roles = ['viewer', 'staff', 'manager', 'admin'];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.teamAccess.role;
    _expiresAt = widget.teamAccess.expiresAt;
    _permissions = widget.teamAccess.permissions;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Team Access',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Modify permissions for ${widget.teamAccess.managedUser?.name ?? 'team member'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              child: Text(
                                  widget.teamAccess.managedUser?.initials ??
                                      'U'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.teamAccess.managedUser?.name ??
                                        'Unknown User',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    'UserID: ${widget.teamAccess.managedUserId}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    'Current Role: ${widget.teamAccess.roleDisplayName}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Role Selection
                      Text(
                        'Role & Permissions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: _roles.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRole = value;
                              _permissions = _getPermissionsForRole(value);
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Custom Permissions
                      Text(
                        'Custom Permissions',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      _buildPermissionsGrid(),

                      const SizedBox(height: 20),

                      // Current Expiration
                      if (widget.teamAccess.expiresAt != null) ...[
                        Text(
                          'Current Expiration',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.teamAccess.isExpired
                                ? Colors.red.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.teamAccess.isExpired
                                  ? Colors.red.shade200
                                  : Colors.orange.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.teamAccess.isExpired
                                    ? Icons.error
                                    : Icons.schedule,
                                color: widget.teamAccess.isExpired
                                    ? Colors.red
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.teamAccess.isExpired
                                    ? 'Expired on ${_formatDate(widget.teamAccess.expiresAt!)}'
                                    : 'Expires on ${_formatDate(widget.teamAccess.expiresAt!)}',
                                style: TextStyle(
                                  color: widget.teamAccess.isExpired
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // New Expiration Date
                      Text(
                        'Update Expiration Date',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: Text(
                          _expiresAt != null
                              ? 'Expires: ${_formatDate(_expiresAt!)}'
                              : 'No expiration date',
                        ),
                        trailing: _expiresAt != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _expiresAt = null;
                                  });
                                },
                              )
                            : null,
                        onTap: _selectExpirationDate,
                      ),

                      const SizedBox(height: 16),

                      // Reason for changes
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason for changes (Optional)',
                          border: OutlineInputBorder(),
                          helperText: 'Why are these changes being made?',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update Access'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionsGrid() {
    final permissionItems = [
      (
        'Jobs',
        [
          ('Create Jobs', 'canCreateJobs'),
          ('Edit Jobs', 'canEditJobs'),
          ('Delete Jobs', 'canDeleteJobs'),
          ('View Jobs', 'canViewJobs'),
        ]
      ),
      (
        'Applications',
        [
          ('View Applications', 'canViewApplications'),
          ('Manage Applications', 'canManageApplications'),
          ('Hire Workers', 'canHireWorkers'),
        ]
      ),
      (
        'Attendance',
        [
          ('Create Attendance', 'canCreateAttendance'),
          ('View Attendance', 'canViewAttendance'),
          ('Edit Attendance', 'canEditAttendance'),
        ]
      ),
      (
        'Other',
        [
          ('Manage Employment', 'canManageEmployment'),
          ('View Employment', 'canViewEmployment'),
          ('View Payments', 'canViewPayments'),
          ('Process Payments', 'canProcessPayments'),
          ('Manage Team', 'canManageTeam'),
          ('View Team Reports', 'canViewTeamReports'),
        ]
      ),
    ];

    return Column(
      children: permissionItems.map((category) {
        return ExpansionTile(
          title: Text(category.$1),
          initiallyExpanded: true,
          children: category.$2.map((permission) {
            return CheckboxListTile(
              title: Text(permission.$1),
              value: _getPermissionValue(permission.$2),
              onChanged: (value) {
                _updatePermission(permission.$2, value ?? false);
              },
              dense: true,
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  bool _getPermissionValue(String permission) {
    switch (permission) {
      case 'canCreateJobs':
        return _permissions.canCreateJobs;
      case 'canEditJobs':
        return _permissions.canEditJobs;
      case 'canDeleteJobs':
        return _permissions.canDeleteJobs;
      case 'canViewJobs':
        return _permissions.canViewJobs;
      case 'canHireWorkers':
        return _permissions.canHireWorkers;
      case 'canViewApplications':
        return _permissions.canViewApplications;
      case 'canManageApplications':
        return _permissions.canManageApplications;
      case 'canCreateAttendance':
        return _permissions.canCreateAttendance;
      case 'canViewAttendance':
        return _permissions.canViewAttendance;
      case 'canEditAttendance':
        return _permissions.canEditAttendance;
      case 'canManageEmployment':
        return _permissions.canManageEmployment;
      case 'canViewEmployment':
        return _permissions.canViewEmployment;
      case 'canViewPayments':
        return _permissions.canViewPayments;
      case 'canProcessPayments':
        return _permissions.canProcessPayments;
      case 'canManageTeam':
        return _permissions.canManageTeam;
      case 'canViewTeamReports':
        return _permissions.canViewReports;
      default:
        return false;
    }
  }

  void _updatePermission(String permission, bool value) {
    setState(() {
      // Create a new TeamPermissions object with the updated value
      _permissions = TeamPermissions(
        canCreateJobs:
            permission == 'canCreateJobs' ? value : _permissions.canCreateJobs,
        canEditJobs:
            permission == 'canEditJobs' ? value : _permissions.canEditJobs,
        canDeleteJobs:
            permission == 'canDeleteJobs' ? value : _permissions.canDeleteJobs,
        canViewJobs:
            permission == 'canViewJobs' ? value : _permissions.canViewJobs,
        canHireWorkers: permission == 'canHireWorkers'
            ? value
            : _permissions.canHireWorkers,
        canViewApplications: permission == 'canViewApplications'
            ? value
            : _permissions.canViewApplications,
        canManageApplications: permission == 'canManageApplications'
            ? value
            : _permissions.canManageApplications,
        canCreateAttendance: permission == 'canCreateAttendance'
            ? value
            : _permissions.canCreateAttendance,
        canViewAttendance: permission == 'canViewAttendance'
            ? value
            : _permissions.canViewAttendance,
        canEditAttendance: permission == 'canEditAttendance'
            ? value
            : _permissions.canEditAttendance,
        canManageEmployment: permission == 'canManageEmployment'
            ? value
            : _permissions.canManageEmployment,
        canViewEmployment: permission == 'canViewEmployment'
            ? value
            : _permissions.canViewEmployment,
        canViewPayments: permission == 'canViewPayments'
            ? value
            : _permissions.canViewPayments,
        canProcessPayments: permission == 'canProcessPayments'
            ? value
            : _permissions.canProcessPayments,
        canManageTeam:
            permission == 'canManageTeam' ? value : _permissions.canManageTeam,
        canViewReports: permission == 'canViewReports'
            ? value
            : _permissions.canViewReports,
      );
    });
  }

  TeamPermissions _getPermissionsForRole(String role) {
    switch (role) {
      case 'admin':
        return TeamPermissions.fullAccess();
      case 'manager':
        return TeamPermissions.manageOperations();
      case 'staff':
        return TeamPermissions.viewOnly();
      case 'viewer':
        return TeamPermissions.viewOnly();
      default:
        return TeamPermissions.viewOnly();
    }
  }

  void _selectExpirationDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _expiresAt = date;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if anything has changed
    bool hasChanges = false;
    if (_selectedRole != widget.teamAccess.role) hasChanges = true;
    if (_expiresAt != widget.teamAccess.expiresAt) hasChanges = true;

    // Check if permissions have changed (simplified check)
    if (!_permissionsEqual(_permissions, widget.teamAccess.permissions)) {
      hasChanges = true;
    }

    if (!hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes detected')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);
      final success = await teamProvider.updateAccess(
        identifier: widget.teamAccess.id,
        role: _selectedRole != widget.teamAccess.role ? _selectedRole : null,
        permissions:
            !_permissionsEqual(_permissions, widget.teamAccess.permissions)
                ? _permissions
                : null,
        expiresAt:
            _expiresAt != widget.teamAccess.expiresAt ? _expiresAt : null,
        reason: _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : null,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Access updated successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update access: ${teamProvider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  bool _permissionsEqual(TeamPermissions a, TeamPermissions b) {
    return a.canCreateJobs == b.canCreateJobs &&
        a.canEditJobs == b.canEditJobs &&
        a.canDeleteJobs == b.canDeleteJobs &&
        a.canViewJobs == b.canViewJobs &&
        a.canHireWorkers == b.canHireWorkers &&
        a.canViewApplications == b.canViewApplications &&
        a.canManageApplications == b.canManageApplications &&
        a.canCreateAttendance == b.canCreateAttendance &&
        a.canViewAttendance == b.canViewAttendance &&
        a.canEditAttendance == b.canEditAttendance &&
        a.canManageEmployment == b.canManageEmployment &&
        a.canViewEmployment == b.canViewEmployment &&
        a.canViewPayments == b.canViewPayments &&
        a.canProcessPayments == b.canProcessPayments &&
        a.canManageTeam == b.canManageTeam &&
        a.canViewReports == b.canViewReports;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
