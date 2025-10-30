import 'package:flutter/material.dart';

enum NotificationType { application, hire, payment, schedule, message, system, attendance }

enum NotificationPriority { low, medium, high }

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.data,
    this.actionUrl,
    this.isRead = false,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? actionUrl;
  final bool isRead;
  final Map<String, dynamic> data;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    String stringValue(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    bool boolValue(dynamic value) {
      if (value is bool) return value;
      final str = stringValue(value).toLowerCase();
      return str == 'true' || str == '1' || str == 'yes';
    }

    DateTime dateTimeValue(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(stringValue(value)) ?? DateTime.now();
    }

    NotificationType parseType(String value) {
      switch (value.toLowerCase()) {
        case 'application':
          return NotificationType.application;
        case 'hire':
          return NotificationType.hire;
        case 'payment':
          return NotificationType.payment;
        case 'schedule':
          return NotificationType.schedule;
        case 'message':
          return NotificationType.message;
        case 'attendance':
          return NotificationType.attendance;
        case 'system':
        default:
          return NotificationType.system;
      }
    }

    NotificationPriority parsePriority(String value) {
      switch (value.toLowerCase()) {
        case 'low':
          return NotificationPriority.low;
        case 'high':
          return NotificationPriority.high;
        case 'medium':
        default:
          return NotificationPriority.medium;
      }
    }

    return AppNotification(
      id: stringValue(json['id'] ?? json['_id']),
      userId: stringValue(json['user'] ?? json['userId']),
      type: parseType(stringValue(json['type'])),
      priority: parsePriority(stringValue(json['priority'])),
      title: stringValue(json['title']),
      message: stringValue(json['message'] ?? json['body']),
      createdAt: dateTimeValue(json['createdAt']),
      actionUrl: json['actionUrl']?.toString(),
      isRead: boolValue(json['isRead'] ?? (json['readAt'] != null)),
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }
}

@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.participantIds,
    required this.jobId,
    required this.title,
    required this.lastMessagePreview,
    required this.unreadCount,
    required this.updatedAt,
  });

  final String id;
  final List<String> participantIds;
  final String? jobId;
  final String title;
  final String lastMessagePreview;
  final int unreadCount;
  final DateTime updatedAt;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    String stringValue(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    int intValue(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(stringValue(value)) ?? 0;
    }

    List<String> stringList(dynamic value) {
      if (value is List) {
        return value.map(stringValue).where((item) => item.isNotEmpty).toList();
      }
      return const <String>[];
    }

    DateTime dateTimeValue(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(stringValue(value)) ?? DateTime.now();
    }

    return Conversation(
      id: stringValue(json['id'] ?? json['_id']),
      participantIds:
          stringList(json['participants'] ?? json['participantIds']),
      jobId: stringValue(json['job'] ?? json['jobId']).isNotEmpty
          ? stringValue(json['job'] ?? json['jobId'])
          : null,
      title: stringValue(json['title'] ?? 'Conversation'),
      lastMessagePreview:
          stringValue(json['lastMessageSnippet'] ?? json['lastMessagePreview']),
      unreadCount: intValue(json['unreadCount'] ?? 0),
      updatedAt: dateTimeValue(json['updatedAt'] ?? json['lastMessageAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantIds': participantIds,
      'jobId': jobId,
      'title': title,
      'lastMessagePreview': lastMessagePreview,
      'unreadCount': unreadCount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

@immutable
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.sentAt,
    this.isRead = false,
    this.isActionRequired = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime sentAt;
  final bool isRead;
  final bool isActionRequired;

  factory Message.fromJson(Map<String, dynamic> json) {
    String stringValue(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    bool boolValue(dynamic value) {
      if (value is bool) return value;
      final str = stringValue(value).toLowerCase();
      return str == 'true' || str == '1' || str == 'yes';
    }

    DateTime dateTimeValue(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(stringValue(value)) ?? DateTime.now();
    }

    return Message(
      id: stringValue(json['id'] ?? json['_id']),
      conversationId:
          stringValue(json['conversation'] ?? json['conversationId']),
      senderId: stringValue(json['sender'] ?? json['senderId']),
      body: stringValue(json['body'] ?? json['content']),
      sentAt: dateTimeValue(json['createdAt'] ?? json['sentAt']),
      isRead: boolValue(json['isRead']),
      isActionRequired: boolValue(json['isActionRequired']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'body': body,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
      'isActionRequired': isActionRequired,
    };
  }
}
