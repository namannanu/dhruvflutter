import 'package:flutter/material.dart';
import 'features/team_management/screens/team_management_page.dart';

void main() {
  runApp(const TeamManagementTestApp());
}

class TeamManagementTestApp extends StatelessWidget {
  const TeamManagementTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Management Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TeamManagementTestHome(),
    );
  }
}

class TeamManagementTestHome extends StatelessWidget {
  const TeamManagementTestHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Team Management Test'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Team Management System',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            Text(
              'This is a standalone test for the team management functionality.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            TeamManagementButton(),
          ],
        ),
      ),
    );
  }
}

class TeamManagementButton extends StatelessWidget {
  const TeamManagementButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }
}
