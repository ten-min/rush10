import 'package:flutter/material.dart';

class ChallengeRoom {
  final String id;
  final String title;
  final String description;
  final String hostName;
  final String hostId;
  final int participantCount;
  final DateTime startTime;
  final String code;
  final bool isCompleted;
  final DateTime? completedAt;

  ChallengeRoom({
    required this.id,
    required this.title,
    required this.description,
    required this.hostName,
    required this.hostId,
    this.participantCount = 1,
    required this.startTime,
    required this.code,
    this.isCompleted = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'hostName': hostName,
      'hostId': hostId,
      'participantCount': participantCount,
      'startTime': startTime.toIso8601String(),
      'code': code,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory ChallengeRoom.fromJson(Map<String, dynamic> json) {
    return ChallengeRoom(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      hostName: json['hostName'],
      hostId: json['hostId'],
      participantCount: json['participantCount'],
      startTime: DateTime.parse(json['startTime']),
      code: json['code'],
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }

  ChallengeRoom copyWith({
    String? id,
    String? title,
    String? description,
    String? hostName,
    String? hostId,
    int? participantCount,
    DateTime? startTime,
    String? code,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return ChallengeRoom(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      hostName: hostName ?? this.hostName,
      hostId: hostId ?? this.hostId,
      participantCount: participantCount ?? this.participantCount,
      startTime: startTime ?? this.startTime,
      code: code ?? this.code,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}