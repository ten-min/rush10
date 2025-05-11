import 'dart:typed_data';

class CertificationPost {
  final String id;
  final String roomId; // 해당 도전방 ID
  final String userId; // 작성자 ID
  final String username; // 작성자 이름
  final String description; // 인증 설명
  final Uint8List? photoBytes; // 인증 사진 바이트 데이터
  final String? profileImagePath; // 프로필 사진 경로
  final DateTime createdAt; // 작성 시간
  final bool isCompleted; // 인증 완료 여부

  CertificationPost({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    required this.description,
    this.photoBytes,
    this.profileImagePath,
    required this.createdAt,
    this.isCompleted = true,
  });

  // JSON 직렬화를 위한 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'userId': userId,
      'username': username,
      'description': description,
      'photoBytes': photoBytes != null ? photoBytes!.toString() : null, // 사진 데이터는 별도로 저장해야 함
      'profileImagePath': profileImagePath,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  // JSON에서 객체 생성
  factory CertificationPost.fromJson(Map<String, dynamic> json, {Uint8List? photoData}) {
    return CertificationPost(
      id: json['id'],
      roomId: json['roomId'],
      userId: json['userId'],
      username: json['username'],
      description: json['description'],
      photoBytes: photoData, // 외부에서 주입되는 사진 데이터
      profileImagePath: json['profileImagePath'],
      createdAt: DateTime.parse(json['createdAt']),
      isCompleted: json['isCompleted'] ?? true,
    );
  }

  // 객체 복사 및 수정을 위한 메서드
  CertificationPost copyWith({
    String? id,
    String? roomId,
    String? userId,
    String? username,
    String? description,
    Uint8List? photoBytes,
    String? profileImagePath,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return CertificationPost(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      description: description ?? this.description,
      photoBytes: photoBytes ?? this.photoBytes,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
} 