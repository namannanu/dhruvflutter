import 'package:flutter/foundation.dart';

@immutable
class Metrics {
  const Metrics({
    this.views = 0,
    this.saves = 0,
    this.shares = 0,
    this.clicks = 0,
    this.applications = 0,
    this.hires = 0,
  });

  final int views;
  final int saves;
  final int shares;
  final int clicks;
  final int applications;
  final int hires;

  factory Metrics.fromJson(Map<String, dynamic> json) {
    return Metrics(
      views: json['views'] as int? ?? 0,
      saves: json['saves'] as int? ?? 0,
      shares: json['shares'] as int? ?? 0,
      clicks: json['clicks'] as int? ?? 0,
      applications: json['applications'] as int? ?? 0,
      hires: json['hires'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'views': views,
      'saves': saves,
      'shares': shares,
      'clicks': clicks,
      'applications': applications,
      'hires': hires,
    };
  }

  Metrics copyWith({
    int? views,
    int? saves,
    int? shares,
    int? clicks,
    int? applications,
    int? hires,
  }) {
    return Metrics(
      views: views ?? this.views,
      saves: saves ?? this.saves,
      shares: shares ?? this.shares,
      clicks: clicks ?? this.clicks,
      applications: applications ?? this.applications,
      hires: hires ?? this.hires,
    );
  }
}
