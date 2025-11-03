import 'package:flutter/foundation.dart';

@immutable
class EmployerFeedback {
  const EmployerFeedback({
    required this.id,
    required this.employerId,
    required this.workerId,
    required this.rating,
    required this.comment,
    required this.submittedAt,
    this.jobId,
  });

  final String id;
  final String employerId;
  final String workerId;
  final double rating;
  final String comment;
  final DateTime submittedAt;
  final String? jobId;

  factory EmployerFeedback.fromJson(Map<String, dynamic> json) {
    return EmployerFeedback(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      employerId: json['employerId'] as String? ?? '',
      workerId: json['workerId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? '') ??
          DateTime.now(),
      jobId: json['jobId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employerId': employerId,
      'workerId': workerId,
      'rating': rating,
      'comment': comment,
      'submittedAt': submittedAt.toIso8601String(),
      if (jobId != null) 'jobId': jobId,
    };
  }
}

@immutable
class JobPaymentRecord {
  const JobPaymentRecord({
    required this.id,
    required this.jobId,
    required this.employerId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.orderId,
    this.paymentId,
  });

  final String id;
  final String jobId;
  final String employerId;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final String? orderId;
  final String? paymentId;

  factory JobPaymentRecord.fromJson(Map<String, dynamic> json) {
    return JobPaymentRecord(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      jobId: json['jobId'] as String? ?? '',
      employerId: json['employerId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String? ?? 'unknown',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      orderId: json['orderId'] as String?,
      paymentId: json['paymentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'employerId': employerId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      if (orderId != null) 'orderId': orderId,
      if (paymentId != null) 'paymentId': paymentId,
    };
  }
}
