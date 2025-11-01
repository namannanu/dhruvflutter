import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/state/app_state.dart';

class DebugApplicationsScreen extends StatefulWidget {
  const DebugApplicationsScreen({super.key});

  @override
  State<DebugApplicationsScreen> createState() => _DebugApplicationsScreenState();
}

class _DebugApplicationsScreenState extends State<DebugApplicationsScreen> {
  String _debugOutput = '';
  bool _isLoading = false;

  void _addDebugLine(String line) {
    setState(() {
      _debugOutput += '$line\n';
    });
  }

  Future<void> _testAuthentication() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    final appState = context.read<AppState>();
    
    _addDebugLine('=== AUTHENTICATION DEBUG ===');
    _addDebugLine('Current user: ${appState.currentUser?.email ?? 'None'}');
    _addDebugLine('User type: ${appState.currentUser?.type ?? 'None'}');
    _addDebugLine('User ID: ${appState.currentUser?.id ?? 'None'}');
    _addDebugLine('Has valid session: ${appState.hasValidSession}');
    
    // Check auth token
    final hasToken = appState.service.authToken != null;
    _addDebugLine('Auth token available: $hasToken');
    
    if (hasToken) {
      final tokenPreview = appState.service.authToken!.substring(
        0, 
        appState.service.authToken!.length > 20 ? 20 : appState.service.authToken!.length
      );
      _addDebugLine('Token preview: $tokenPreview...');
    }

    _addDebugLine('\n=== TESTING APPLICATIONS ENDPOINT ===');
    
    try {
      if (appState.currentUser != null) {
        _addDebugLine('Attempting to fetch applications...');
        await appState.loadWorkerApplications(appState.currentUser!.id);
        _addDebugLine('✅ Success! Found ${appState.workerApplications.length} applications');
        
        for (int i = 0; i < appState.workerApplications.length; i++) {
          final app = appState.workerApplications[i];
          _addDebugLine('  ${i + 1}. ${app.job?.title ?? 'Unknown Job'} - Status: ${app.status}');
        }
      } else {
        _addDebugLine('❌ No current user available');
      }
    } catch (error) {
      _addDebugLine('❌ Error: $error');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testRefreshAuth() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    final appState = context.read<AppState>();
    
    _addDebugLine('=== REFRESHING AUTHENTICATION ===');
    
    try {
      await appState.refreshActiveRole();
      _addDebugLine('✅ Auth refresh completed');
      
      _addDebugLine('Current user after refresh: ${appState.currentUser?.email ?? 'None'}');
      _addDebugLine('User type after refresh: ${appState.currentUser?.type ?? 'None'}');
      _addDebugLine('Auth token available after refresh: ${appState.service.authToken != null}');
      
    } catch (error) {
      _addDebugLine('❌ Auth refresh error: $error');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Worker Applications'),
        backgroundColor: Colors.red[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Debug Tools',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testAuthentication,
                      child: const Text('Test Authentication & Applications'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testRefreshAuth,
                      child: const Text('Refresh Authentication'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Debug Output',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _debugOutput.isEmpty 
                                ? 'Press a button above to start debugging...' 
                                : _debugOutput,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}