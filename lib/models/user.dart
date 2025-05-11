// user.dart - 사용자 모델

import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String nickname;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.nickname,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Firestore에서 데이터를 가져올 때 사용하는 팩토리 메서드
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      email: data['email'] ?? '',
      nickname: data['nickname'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Firestore에 데이터를 저장할 때 사용하는 메서드
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // 사용자 정보 저장
  Future<void> save() async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(id);
    await docRef.set(toFirestore());
  }

  // 사용자 정보 업데이트
  Future<void> update() async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(id);
    await docRef.update(toFirestore());
  }

  // 사용자 정보 삭제
  Future<void> delete() async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(id);
    await docRef.delete();
  }

  // ID로 사용자 정보 가져오기
  static Future<User?> getById(String id) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(id);
    final doc = await docRef.get();
    if (doc.exists) {
      return User.fromFirestore(doc);
    }
    return null;
  }

  // 이메일로 사용자 정보 가져오기
  static Future<User?> getByEmail(String email) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      return User.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  User copyWith({
    String? id,
    String? email,
    String? nickname,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}