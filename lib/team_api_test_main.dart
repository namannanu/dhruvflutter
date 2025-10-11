import 'package:flutter/material.dart';
import 'features/team_management/screens/team_api_test_page.dart';

void main() {
  runApp(const TeamApiTestApp());
}

class TeamApiTestApp extends StatelessWidget {
  const TeamApiTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team API Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TeamApiTestPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
