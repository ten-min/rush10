// user.dart - 사용자 모델

class User {
  final int? id;  // 데이터베이스 ID (자동 생성)
  final String userId;  // 사용자 고유 ID
  final String username;  // 사용자 이름
  final String profileImage;  // 프로필 이미지 경로 (선택 사항)
  final DateTime createdAt;  // 생성 시간

  User({
    this.id,
    required this.userId,
    required this.username,
    this.profileImage = '',
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  // JSON 변환을 위한 메소드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // 맵에서 사용자 객체로 변환
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      userId: map['userId'],
      username: map['username'],
      profileImage: map['profileImage'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // 복사본 생성 (정보 업데이트용)
  User copyWith({
    int? id,
    String? userId,
    String? username,
    String? profileImage,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}