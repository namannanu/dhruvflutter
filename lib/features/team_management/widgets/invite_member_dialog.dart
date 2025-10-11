// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../services/team_invitation_service.dart';

class InviteMemberDialog extends StatefulWidget {
  final String businessId;
  final String? authToken; // Add auth token parameter

  const InviteMemberDialog({
    super.key,
    required this.businessId,
    this.authToken,
  });

  @override
  State<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<InviteMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final TeamInvitationService _teamService = TeamInvitationService();

  String _selectedRole = 'staff';
  String _selectedAccessLevel = 'view_only';
  bool _isSubmitting = false;

  final List<String> _roles = [
    'staff',
    'supervisor',
    'manager',
    'admin',
  ];

  final Map<String, String> _accessLevels = {
    'view_only': 'View Only',
    'manage_operations': 'Manage Operations',
    'full_access': 'Full Access',
  };

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  Future<void> _submitInvitation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('🎯 SUBMITTING INVITATION');
      print('📧 Email: ${_emailController.text.trim()}');
      print('🏢 Business ID: ${widget.businessId}');
      print('👤 Role: $_selectedRole');
      print('🔑 Access Level: $_selectedAccessLevel');

      final result = await _teamService.inviteTeamMember(
        userEmail: _emailController.text.trim(),
        businessId: widget.businessId,
        role: _selectedRole,
        accessLevel: _selectedAccessLevel,
        authToken: widget.authToken,
      );

      if (mounted) {
        if (result != null) {
          Navigator.pop(context, true);

          // Show detailed success message
          final message = result['message'] as String? ?? '';
          String successMessage =
              '✅ Invitation sent to ${_emailController.text.trim()}';

          if (message.toLowerCase().contains('notification')) {
            successMessage += '\n📧 Email notification sent successfully';
          } else {
            successMessage +=
                '\n⚠️ User needs to sign up first to receive notifications';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to send invitation. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite Team Member'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'user@example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(_capitalizeFirstLetter(role)),
                  );
                }).toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedAccessLevel,
                decoration: const InputDecoration(
                  labelText: 'Access Level',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                items: _accessLevels.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() {
                          _selectedAccessLevel = value!;
                        });
                      },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Notification Info',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.blue),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Email notifications are only sent to users who already have an account. New users will receive access once they sign up.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitInvitation,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Invitation'),
        ),
      ],
    );
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
