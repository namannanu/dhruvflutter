import 'package:flutter/material.dart';
import 'lib/location_crash_test_page.dart';

void main() {
  runApp(const LocationTestApp());
}

class LocationTestApp extends StatelessWidget {
  const LocationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Crash Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LocationCrashTestPage(),
    );
  }
}
