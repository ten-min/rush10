// database_helper.dart - 데이터 관리

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;
  
  // 싱글톤 패턴으로 구현
  DatabaseHelper._internal();
  
  // 현재 사용자 가져오기 (Firestore에서)
  Future<User> getCurrentUser({required String userId, required String nickname, required String email, String? profileImageUrl}) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      return User.fromFirestore(doc);
    } else {
      // Firestore에 새 사용자 생성 (nickname, email, profileImageUrl 모두 외부에서 받은 값 사용)
      final now = DateTime.now();
      final newUser = User(
        id: userId,
        email: email,
        nickname: nickname,
        profileImageUrl: profileImageUrl,
        createdAt: now,
        updatedAt: now,
      );
      await FirebaseFirestore.instance.collection('users').doc(userId).set(newUser.toFirestore());
      return newUser;
    }
  }
  
  // 사용자 정보 업데이트
  Future<int> updateUser(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.id).update(user.toFirestore());
    return 1;
  }
  
  // 모든 사용자 가져오기 (예시: 전체 users 컬렉션 조회)
  Future<List<User>> getAllUsers() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('users').get();
    return querySnapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
  }
  
  // 사용자 추가
  Future<int> insertUser(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.id).set(user.toFirestore());
    return 1;
  }
  
  // ID로 사용자 조회
  Future<User?> getUserById(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      return User.fromFirestore(doc);
    }
    return null;
  }
}