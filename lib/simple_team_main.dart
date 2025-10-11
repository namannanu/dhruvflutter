import 'package:flutter/material.dart';
import 'features/team_management/screens/team_management_page.dart';
import 'services/auth_token_manager.dart';

void main() {
  runApp(const SimpleTeamApp());
}

class SimpleTeamApp extends StatelessWidget {
  const SimpleTeamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SimpleHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SimpleHomePage extends StatefulWidget {
  const SimpleHomePage({super.key});

  @override
  State<SimpleHomePage> createState() => _SimpleHomePageState();
}

class _SimpleHomePageState extends State<SimpleHomePage> {
  String _tokenStatus = 'Checking...';
  String? _businessId;

  @override
  void initState() {
    super.initState();
    _checkTokenStatus();
  }

  Future<void> _checkTokenStatus() async {
    try {
      final token = await AuthTokenManager.instance.getAuthToken();
      final businessId = await AuthTokenManager.instance.getFirstBusinessId();

      setState(() {
        if (token != null && businessId != null) {
          _tokenStatus = 'Token Ready ✅';
          _businessId = businessId;
        } else {
          _tokenStatus = 'No token found, storing your login token...';
          _storeTokenAndRecheck();
        }
      });
    } catch (e) {
      setState(() {
        _tokenStatus = 'Error: $e';
      });
    }
  }

  Future<void> _storeTokenAndRecheck() async {
    try {
      await AuthTokenManager.instance.storeYourToken();
      await _checkTokenStatus();
    } catch (e) {
      setState(() {
        _tokenStatus = 'Failed to store token: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Team Management Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Authentication Status:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              _tokenStatus,
              style: TextStyle(
                fontSize: 16,
                color:
                    _tokenStatus.contains('✅') ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            if (_businessId != null)
              Text(
                'Business ID: $_businessId',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeamManagementPage(),
                  ),
                );
              },
              icon: const Icon(Icons.group),
              label: const Text('Open Team Management'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _checkTokenStatus,
              child: const Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }
}
