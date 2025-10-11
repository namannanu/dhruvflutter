import 'package:flutter/material.dart';

@immutable
class BudgetCategory {
  const BudgetCategory({
    required this.id,
    required this.name,
    required this.allocated,
    required this.actual,
    required this.alertLevel,
  });

  final String id;
  final String name;
  final double allocated;
  final double actual;
  final double alertLevel;

  double get variance => actual - allocated;

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      allocated: (json['allocated'] as num?)?.toDouble() ?? 0.0,
      actual: (json['actual'] as num?)?.toDouble() ?? 0.0,
      alertLevel: (json['alertLevel'] as num?)?.toDouble() ?? 80.0,
    );
  }
}

@immutable
class BudgetAlert {
  const BudgetAlert({
    required this.id,
    required this.categoryId,
    required this.message,
    required this.severity,
    required this.createdAt,
  });

  final String id;
  final String categoryId;
  final String message;
  final String severity;
  final DateTime createdAt;

  factory BudgetAlert.fromJson(Map<String, dynamic> json) {
    return BudgetAlert(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'info',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

@immutable
class BudgetOverview {
  const BudgetOverview({
    required this.month,
    required this.totalBudget,
    required this.totalSpend,
    required this.projectedSpend,
    required this.categories,
    required this.alerts,
  });

  final DateTime month;
  final double totalBudget;
  final double totalSpend;
  final double projectedSpend;
  final List<BudgetCategory> categories;
  final List<BudgetAlert> alerts;

  double get remaining => totalBudget - totalSpend;

  factory BudgetOverview.fromJson(Map<String, dynamic> json) {
    final budget =
        json['budget'] is Map ? json['budget'] as Map<String, dynamic> : json;
    final month =
        DateTime.tryParse(budget['month']?.toString() ?? '') ?? DateTime.now();
    final totalBudget =
        ((budget['monthlyBudget'] ?? budget['totalBudget']) as num?)
                ?.toDouble() ??
            0.0;
    final totalSpend = (budget['totalSpend'] as num?)?.toDouble() ?? 0.0;
    final projectedSpend =
        (budget['projectedSpend'] as num?)?.toDouble() ?? totalSpend;

    final categories = <BudgetCategory>[];
    if (budget['categories'] is List) {
      for (final category in budget['categories'] as List) {
        if (category is Map) {
          categories
              .add(BudgetCategory.fromJson(category as Map<String, dynamic>));
        }
      }
    }

    final alerts = <BudgetAlert>[];
    if (budget['alerts'] is List) {
      for (final alert in budget['alerts'] as List) {
        if (alert is Map) {
          alerts.add(BudgetAlert.fromJson(alert as Map<String, dynamic>));
        }
      }
    }

    return BudgetOverview(
      month: month,
      totalBudget: totalBudget,
      totalSpend: totalSpend,
      projectedSpend: projectedSpend,
      categories: categories,
      alerts: alerts,
    );
  }
}
