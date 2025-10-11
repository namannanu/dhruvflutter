import 'package:flutter/material.dart';
import '../../../services/auth_token_manager.dart';

class TokenTestPage extends StatefulWidget {
  const TokenTestPage({super.key});

  @override
  State<TokenTestPage> createState() => _TokenTestPageState();
}

class _TokenTestPageState extends State<TokenTestPage> {
  String _status = 'Ready to test';
  String? _token;
  String? _businessId;
  Map<String, String> _userInfo = {};

  @override
  void initState() {
    super.initState();
    _checkStoredData();
  }

  Future<void> _checkStoredData() async {
    final token = await AuthTokenManager.instance.getAuthToken();
    final businessId = await AuthTokenManager.instance.getFirstBusinessId();
    final userInfo = await AuthTokenManager.instance.getUserInfo();

    setState(() {
      _token = token;
      _businessId = businessId;
      _userInfo = userInfo;
      _status =
          token != null ? 'Token found in storage!' : 'No token in storage';
    });
  }

  Future<void> _storeYourLoginToken() async {
    setState(() {
      _status = 'Storing your login token...';
    });

    try {
      await AuthTokenManager.instance.storeYourToken();
      await _checkStoredData();
      setState(() {
        _status = '✅ Your login token stored successfully!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error storing token: $e';
      });
    }
  }

  Future<void> _clearAll() async {
    await AuthTokenManager.instance.clearAll();
    await _checkStoredData();
    setState(() {
      _status = '🧹 All data cleared';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Integration Test'),
        backgroundColor: Colors.blue[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (_token != null) ...[
                      const Text(
                        '🔑 Auth Token:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_token!.substring(0, 30)}...',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_businessId != null) ...[
                      const Text(
                        '🏢 Business ID:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _businessId!,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_userInfo.isNotEmpty) ...[
                      const Text(
                        '👤 User Info:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...(_userInfo.entries.map(
                          (entry) => Text('${entry.key}: ${entry.value}'))),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _storeYourLoginToken,
              icon: const Icon(Icons.login),
              label: const Text('Store Your Login Token'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _checkStoredData,
              icon: const Icon(Icons.refresh),
              label: const Text('Check Stored Data'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.clear),
              label: const Text('Clear All Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to test:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                        '1. Click "Store Your Login Token" to save the token from your login'),
                    Text('2. Navigate to Team Management'),
                    Text('3. Token should be automatically loaded'),
                    Text(
                        '4. You can now invite team members without manual token entry'),
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
