import 'package:flutter/material.dart';

class ChallengeRoom {
  final String id;
  final String title;
  final String description;
  final String hostName;
  final int participantCount;
  final DateTime startTime;
  final String code;

  ChallengeRoom({
    required this.id,
    required this.title,
    required this.description,
    required this.hostName,
    required this.participantCount,
    required this.startTime,
    required this.code,
  });
}