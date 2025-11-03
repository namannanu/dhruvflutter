// ignore_for_file: avoid_print

import 'package:talent/core/models/job.dart';


void main() {
  print('Testing logo type error...');

  // Simulate JSON that might cause the logo type error
  final testJson1 = {
    'title': 'Test Job',
    'description': 'Test Description',
    'employerId': 'emp123',
    'businessId': 'bus123',
    'business': {
      'name': 'Test Business',
      'logo':
          'https://example.com/logo.png' // String logo instead of nested object
    },
    'hourlyRate': 25.0,
    'scheduleStart': '2024-01-01T09:00:00Z',
    'scheduleEnd': '2024-01-01T17:00:00Z',
    'postedAt': '2024-01-01T08:00:00Z',
    'applicantsCount': 5
  };

  final testJson2 = {
    'title': 'Test Job 2',
    'description': 'Test Description 2',
    'employerId': 'emp123',
    'businessId': 'bus123',
    'business': {
      'name': 'Test Business',
      'logo': 10 // Integer logo - this might cause the error
    },
    'hourlyRate': 25.0,
    'scheduleStart': '2024-01-01T09:00:00Z',
    'scheduleEnd': '2024-01-01T17:00:00Z',
    'postedAt': '2024-01-01T08:00:00Z',
    'applicantsCount':
        'five' // String applicantsCount - this might also cause the error
  };

  print('\n=== Testing with string logo ===');
  try {
    final job1 = JobPosting.fromJson(testJson1);
    print('Successfully created job1: ${job1.title}');
  } catch (e) {
    print('Error creating job1: $e');
  }

  print('\n=== Testing with integer logo ===');
  try {
    final job2 = JobPosting.fromJson(testJson2);
    print('Successfully created job2: ${job2.title}');
  } catch (e) {
    print('Error creating job2: $e');
  }

  print('\nTest completed.');
}
