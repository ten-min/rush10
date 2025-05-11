// participant_extended.dart - 확장된 참가자 모델

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
// 기존 모델과의 호환성을 위한 import
import '../models/participant.dart';

class ParticipantExtended {
  final String participantId;  // 참가자 고유 ID
  final User user;             // 연결된 사용자 정보
  final bool isHost;           // 방장 여부
  bool completed;              // 도전 완료 여부
  Uint8List? photoBytes;       // 사진 데이터
  File? photoFile;             // 사진 파일
  String description;          // 설명
  DateTime? completedAt;       // 완료 시간
  
  ParticipantExtended({
    required this.participantId,
    required this.user,
    required this.isHost,
    this.completed = false,
    this.photoBytes,
    this.photoFile,
    this.description = '',
    this.completedAt,
  });
  
  // 기존 Participant와 호환되는 팩토리 메서드
  factory ParticipantExtended.fromParticipant(
    Participant participant, 
    User user,
  ) {
    return ParticipantExtended(
      participantId: participant.id.toString(),
      user: user,
      isHost: participant.isHost,
      completed: participant.completed,
      photoBytes: participant.photoBytes,
      photoFile: participant.photoFile,
      description: participant.description,
    );
  }
  
  // Participant로 변환 (호환성 유지)
  Participant toParticipant() {
    return Participant(
      id: participantId,
      name: user.username,
      isHost: isHost,
      completed: completed,
      photoBytes: photoBytes,
      photoFile: photoFile,
      description: description,
    );
  }
  
  // 복사본 생성 (정보 업데이트용)
  ParticipantExtended copyWith({
    String? participantId,
    User? user,
    bool? isHost,
    bool? completed,
    Uint8List? photoBytes,
    File? photoFile,
    String? description,
    DateTime? completedAt,
  }) {
    return ParticipantExtended(
      participantId: participantId ?? this.participantId,
      user: user ?? this.user,
      isHost: isHost ?? this.isHost,
      completed: completed ?? this.completed,
      photoBytes: photoBytes ?? this.photoBytes,
      photoFile: photoFile ?? this.photoFile,
      description: description ?? this.description,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

