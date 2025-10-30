// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/foundation.dart';

@immutable
class EmployerFeedback {
  const EmployerFeedback({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    this.workerId,
    this.workerName,
    this.employerId,
    this.employerName,
    this.jobId,
    this.jobTitle,
  });

  final String id;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? workerId;
  final String? workerName;
  final String? employerId;
  final String? employerName;
  final String? jobId;
  final String? jobTitle;

  factory EmployerFeedback.fromJson(Map<String, dynamic> json) {
    String? _string(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    String? _resolvePersonName(dynamic person) {
      if (person is Map<String, dynamic>) {
        final first = _string(person['firstName']);
        final last = _string(person['lastName']);
        final fullName = [first, last]
            .where((value) => value != null && value.isNotEmpty)
            .join(' ');
        if (fullName.isNotEmpty) {
          return fullName;
        }
        final alt = _string(person['fullName']);
        if (alt != null && alt.isNotEmpty) {
          return alt;
        }
      }
      return null;
    }

    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    final worker = json['worker'];
    final employer = json['employer'];
    final job = json['job'];

    return EmployerFeedback(
      id: _string(json['id']) ?? _string(json['_id']) ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: _string(json['comment']) ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? _parseDate(json['updatedAt']) : null,
      workerId: worker is Map<String, dynamic>
          ? _string(worker['id']) ?? _string(worker['_id'])
          : _string(json['workerId']),
      workerName: _resolvePersonName(worker),
      employerId: employer is Map<String, dynamic>
          ? _string(employer['id']) ?? _string(employer['_id'])
          : _string(json['employerId']),
      employerName: _resolvePersonName(employer),
      jobId: job is Map<String, dynamic>
          ? _string(job['id']) ?? _string(job['_id'])
          : _string(json['jobId']),
      jobTitle: job is Map<String, dynamic>
          ? _string(job['title'])
          : _string(json['jobTitle']),
    );
  }
}
