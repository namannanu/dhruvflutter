import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/team_access.dart';
import '../../../core/providers/team_provider.dart';

class GrantAccessDialog extends StatefulWidget {
  final String currentUserId;

  const GrantAccessDialog({super.key, required this.currentUserId});

  @override
  State<GrantAccessDialog> createState() => _GrantAccessDialogState();
}

class _GrantAccessDialogState extends State<GrantAccessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userEmailController = TextEditingController();
  final _managedUserController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedAccessLevel = 'view_only';
  String _selectedRole = 'viewer';
  String _selectedAccessScope = 'user_specific';
  DateTime? _expiresAt;
  TeamPermissions _permissions = TeamPermissions.viewOnly();
  bool _isSubmitting = false;
  List<TeamMember> _searchResults = [];
  TeamMember? _selectedUser;
  bool _isSearching = false;

  final List<String> _accessLevels = [
    'view_only',
    'manage_operations',
    'full_access'
  ];
  final List<String> _roles = ['viewer', 'staff', 'manager', 'admin', 'custom'];
  final List<String> _accessScopes = [
    'user_specific',
    'business_specific',
    'all_owner_businesses',
    'independent_operator'
  ];

  @override
  void dispose() {
    _userEmailController.dispose();
    _managedUserController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
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
                      'Grant Team Access',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Give a team member access to user data',
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
                      // Target User (who gets access)
                      Text(
                        'Team Member (who gets access)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _userEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Team member email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        onChanged: _searchUsers,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email or User ID';
                          }
                          return null;
                        },
                      ),

                      // Search Results
                      if (_isSearching) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                      ],

                      if (_searchResults.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: _searchResults.map((user) {
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(user.initials),
                                ),
                                title: Text(user.name),
                                subtitle: Text(user.email),
                                trailing: Text(user.userId),
                                onTap: () => _selectUser(user),
                                selected: _selectedUser?.userId == user.userId,
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // User being managed
                      Text(
                        'User Data Access (whose data to access)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _managedUserController,
                        decoration: const InputDecoration(
                          labelText: 'User ID to manage',
                          border: OutlineInputBorder(),
                          helperText: 'The user whose data will be accessible',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter User ID';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Access Level Selection
                      Text(
                        'Access Level',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedAccessLevel,
                        decoration: const InputDecoration(
                          labelText: 'Access Level',
                          border: OutlineInputBorder(),
                        ),
                        items: _accessLevels.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(_getAccessLevelDisplayName(level)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedAccessLevel = value;
                              _permissions =
                                  _getPermissionsForAccessLevel(value);
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Access Scope Selection
                      Text(
                        'Access Scope',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedAccessScope,
                        decoration: const InputDecoration(
                          labelText: 'Access Scope',
                          border: OutlineInputBorder(),
                        ),
                        items: _accessScopes.map((scope) {
                          return DropdownMenuItem(
                            value: scope,
                            child: Text(_getAccessScopeDisplayName(scope)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedAccessScope = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

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

                      // Expiration Date
                      Text(
                        'Access Expiration (Optional)',
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

                      // Reason
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason (Optional)',
                          border: OutlineInputBorder(),
                          helperText: 'Why is this access being granted?',
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                          helperText: 'Additional notes or instructions',
                        ),
                        maxLines: 3,
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
                          : const Text('Grant Access'),
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
      switch (permission) {
        case 'canCreateJobs':
          _permissions = TeamPermissions(
            canCreateJobs: value,
            canEditJobs: _permissions.canEditJobs,
            canDeleteJobs: _permissions.canDeleteJobs,
            canViewJobs: _permissions.canViewJobs,
            canHireWorkers: _permissions.canHireWorkers,
            canViewApplications: _permissions.canViewApplications,
            canManageApplications: _permissions.canManageApplications,
            canCreateAttendance: _permissions.canCreateAttendance,
            canViewAttendance: _permissions.canViewAttendance,
            canEditAttendance: _permissions.canEditAttendance,
            canManageEmployment: _permissions.canManageEmployment,
            canViewEmployment: _permissions.canViewEmployment,
            canViewPayments: _permissions.canViewPayments,
            canProcessPayments: _permissions.canProcessPayments,
            canManageTeam: _permissions.canManageTeam,
            canViewReports: _permissions.canViewReports,
          );
          break;
        // Add other cases as needed...
      }
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

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);
      final results = await teamProvider.searchUsers(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
      }
    }
  }

  void _selectUser(TeamMember user) {
    setState(() {
      _selectedUser = user;
      _userEmailController.text = user.email;
      _searchResults.clear();
    });
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
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a team member')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);
      final success = await teamProvider.grantAccess(
        currentUserId: widget.currentUserId,
        userEmail: _userEmailController.text.trim(),
        managedUserEmail: _managedUserController.text.trim().isEmpty
            ? null
            : _managedUserController.text.trim(),
        accessLevel: _selectedAccessLevel,
        role: _selectedRole,
        permissions: _permissions,
        accessScope: _selectedAccessScope,
        expiresAt: _expiresAt,
        reason: _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Access granted successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to grant access: ${teamProvider.error}'),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getAccessLevelDisplayName(String level) {
    switch (level) {
      case 'view_only':
        return 'View Only';
      case 'manage_operations':
        return 'Manage Operations';
      case 'full_access':
        return 'Full Access';
      default:
        return level;
    }
  }

  String _getAccessScopeDisplayName(String scope) {
    switch (scope) {
      case 'user_specific':
        return 'User Specific';
      case 'business_specific':
        return 'Business Specific';
      case 'all_owner_businesses':
        return 'All Owner Businesses';
      case 'independent_operator':
        return 'Independent Operator';
      default:
        return scope;
    }
  }

  TeamPermissions _getPermissionsForAccessLevel(String accessLevel) {
    switch (accessLevel) {
      case 'full_access':
        return TeamPermissions.fullAccess();
      case 'manage_operations':
        return TeamPermissions.manageOperations();
      case 'view_only':
        return TeamPermissions.viewOnly();
      default:
        return TeamPermissions.viewOnly();
    }
  }
}
