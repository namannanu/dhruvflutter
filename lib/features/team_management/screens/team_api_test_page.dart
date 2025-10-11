// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/direct_team_test_service.dart';

class TeamApiTestPage extends StatefulWidget {
  const TeamApiTestPage({super.key});

  @override
  State<TeamApiTestPage> createState() => _TeamApiTestPageState();
}

class _TeamApiTestPageState extends State<TeamApiTestPage> {
  final _authTokenController = TextEditingController();
  final _emailController = TextEditingController();
  final _businessIdController = TextEditingController();

  String _selectedRole = 'staff';
  String _selectedAccessLevel = 'view_only';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with your known values
    _businessIdController.text = '68e8d6caaf91efc4cf7f223e';
    _emailController.text = 'j@gmail.com';
  }

  @override
  void dispose() {
    _authTokenController.dispose();
    _emailController.dispose();
    _businessIdController.dispose();
    super.dispose();
  }

  Future<void> _testInvitation() async {
    final authToken = _authTokenController.text.trim();
    final email = _emailController.text.trim();
    final businessId = _businessIdController.text.trim();

    if (authToken.isEmpty || email.isEmpty || businessId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await DirectTeamTestService.testTeamInvitation(
        authToken: authToken,
        email: email,
        businessId: businessId,
        role: _selectedRole,
        accessLevel: _selectedAccessLevel,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test completed! Check console for results.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetTeamMembers() async {
    final authToken = _authTokenController.text.trim();

    if (authToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter auth token first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await DirectTeamTestService.getTeamMembers(authToken);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team members test completed! Check console.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCheckAccess() async {
    final authToken = _authTokenController.text.trim();

    if (authToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter auth token first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await DirectTeamTestService.checkUserAccess(authToken);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access check completed! Check console.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team API Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Direct Team API Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Auth Token Field
            TextFormField(
              controller: _authTokenController,
              decoration: const InputDecoration(
                labelText: 'Auth Token (Bearer)',
                hintText: 'Paste your JWT token here',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email to Invite',
                hintText: 'user@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),

            // Business ID Field
            TextFormField(
              controller: _businessIdController,
              decoration: const InputDecoration(
                labelText: 'Business ID',
                hintText: '68e8d6caaf91efc4cf7f223e',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),

            // Role Dropdown
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: ['staff', 'supervisor', 'manager', 'admin'].map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Access Level Dropdown
            DropdownButtonFormField<String>(
              value: _selectedAccessLevel,
              decoration: const InputDecoration(
                labelText: 'Access Level',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
              items: ['view_only', 'manage_operations', 'full_access']
                  .map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level.replaceAll('_', ' ').toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAccessLevel = value!;
                });
              },
            ),
            const SizedBox(height: 24),

            // Test Buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testInvitation,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Test Send Invitation'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testGetTeamMembers,
              icon: const Icon(Icons.group),
              label: const Text('Test Get Team Members'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testCheckAccess,
              icon: const Icon(Icons.security),
              label: const Text('Test Check My Access'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('1. Get your auth token from the browser network tab'),
                    Text('2. Paste it in the Auth Token field'),
                    Text('3. Enter the email you want to invite'),
                    Text('4. Click "Test Send Invitation"'),
                    Text('5. Check the console output for detailed results'),
                    Text(
                        '6. Test other functions to verify the invitation worked'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
