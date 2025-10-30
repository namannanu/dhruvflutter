// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../../../services/auth_token_manager.dart';

class TokenCacheTestPage extends StatefulWidget {
  const TokenCacheTestPage({super.key});

  @override
  State<TokenCacheTestPage> createState() => _TokenCacheTestPageState();
}

class _TokenCacheTestPageState extends State<TokenCacheTestPage> {
  String _logs = '';
  final AuthTokenManager _authManager = AuthTokenManager.instance;

  void _addLog(String message) {
    setState(() {
      _logs += '${DateTime.now().toLocal()}: $message\n';
    });
    print(message);
  }

  Future<void> _testTokenCaching() async {
    _addLog('🧪 Testing Token Caching System');

    // Test 1: Store login token
    _addLog('📝 Step 1: Storing login token with cache...');
    await _authManager.storeYourToken();

    // Test 2: Get cache status
    final cacheStatus = _authManager.getCacheStatus();
    _addLog('💾 Cache Status: $cacheStatus');

    // Test 3: Retrieve token (should use cache)
    _addLog('📝 Step 2: Retrieving token (should use cache)...');
    final token1 = await _authManager.getAuthToken();
    _addLog('🔑 Token retrieved: ${token1?.substring(0, 20)}...');

    // Test 4: Retrieve token again (should use memory cache)
    _addLog(
        '📝 Step 3: Retrieving token again (should be faster from cache)...');
    final token2 = await _authManager.getAuthToken();
    _addLog('🔑 Token retrieved: ${token2?.substring(0, 20)}...');

    // Test 5: Get user data (should use cache)
    _addLog('📝 Step 4: Getting user data (should use cache)...');
    final userData = await _authManager.getUserData();
    final userEmail = userData?['user']?['email'];
    _addLog('👤 User email: $userEmail');

    // Test 6: Get business data (should use cache)
    _addLog('📝 Step 5: Getting business data (should use cache)...');
    final businessData = await _authManager.getBusinessData();
    final businessId = businessData?.first['businessId'];
    _addLog('🏢 Business ID: $businessId');

    // Test 7: Clear cache and reload
    _addLog('📝 Step 6: Clearing cache and reloading...');
    await _authManager.reloadFromStorage();
    final cacheStatusAfterClear = _authManager.getCacheStatus();
    _addLog('💾 Cache Status After Clear: $cacheStatusAfterClear');

    // Test 8: Get token after cache clear (should reload from storage)
    _addLog('📝 Step 7: Getting token after cache clear...');
    final token3 = await _authManager.getAuthToken();
    _addLog('🔑 Token retrieved: ${token3?.substring(0, 20)}...');

    _addLog('✅ Token caching test completed!');
  }

  Future<void> _testTokenExpiry() async {
    _addLog('🧪 Testing Token Expiry System');

    // Check if token is expired
    final token = await _authManager.getAuthToken();
    if (token != null) {
      _addLog('✅ Token is valid and not expired');
    } else {
      _addLog('❌ Token is expired or not found');
    }
  }

  Future<void> _clearAllData() async {
    _addLog('🧹 Clearing all cached data...');
    await _authManager.clearAll();
    final cacheStatus = _authManager.getCacheStatus();
    _addLog('💾 Cache Status After Clear All: $cacheStatus');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Cache Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testTokenCaching,
                    child: const Text('Test Caching'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testTokenExpiry,
                    child: const Text('Test Expiry'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _clearAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All Data'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _logs.isEmpty ? 'Logs will appear here...' : _logs,
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
    );
  }
}
