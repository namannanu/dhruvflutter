// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';

@immutable
class JobPaymentRecord {
  const JobPaymentRecord({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.reference,
    required this.createdAt,
    this.description,
    this.updatedAt,
    this.jobId,
    this.jobTitle,
    this.businessName,
  });

  final String id;
  final double amount;
  final String currency;
  final String status;
  final String reference;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? description;
  final String? jobId;
  final String? jobTitle;
  final String? businessName;

  factory JobPaymentRecord.fromJson(Map<String, dynamic> json) {
    String? _string(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      final text = value.toString();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    final job = json['job'];
    String? jobId;
    String? jobTitle;
    String? businessName;

    if (job is Map<String, dynamic>) {
      jobId = _string(job['id']) ?? _string(job['_id']);
      jobTitle = _string(job['title']);
      businessName = _string(job['businessName']);
    }

    final metadata = json['metadata'];
    if (jobId == null && metadata is Map<String, dynamic>) {
      jobId = _string(metadata['jobId']) ?? _string(metadata['job']);
    }

    return JobPaymentRecord(
      id: _string(json['id']) ?? _string(json['_id']) ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: _string(json['currency']) ?? 'INR',
      status: _string(json['status']) ?? 'pending',
      description: _string(json['description']),
      reference: _string(json['reference']) ?? '',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      jobId: jobId,
      jobTitle: jobTitle,
      businessName: businessName,
    );
  }
}
