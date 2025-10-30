import 'package:flutter/material.dart';
import 'features/team_management/screens/token_cache_test_page.dart';

void main() {
  runApp(const TokenCacheTestApp());
}

class TokenCacheTestApp extends StatelessWidget {
  const TokenCacheTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Token Cache Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TokenCacheTestPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
