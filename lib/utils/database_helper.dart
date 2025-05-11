// database_helper.dart - 데이터 관리

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;
  
  static SharedPreferences? _prefs;
  
  // 싱글톤 패턴으로 구현
  DatabaseHelper._internal();
  
  // 현재 사용자 가져오기 (없으면 생성)
  Future<User> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id');
    final username = prefs.getString('current_user_name') ?? '사용자';
    
    if (userId == null) {
      final newUserId = Uuid().v4();
      await prefs.setString('current_user_id', newUserId);
      await prefs.setString('current_user_name', username);
      return User(
        userId: newUserId,
        username: username,
      );
    }
    
    return User(
      userId: userId,
      username: username,
      profileImage: prefs.getString('current_user_profile_image') ?? '',
    );
  }
  
  // 사용자 정보 업데이트
  Future<int> updateUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_name', user.username);
    if (user.profileImage.isNotEmpty) {
      await prefs.setString('current_user_profile_image', user.profileImage);
    }
    return 1;
  }
  
  // 모든 사용자 가져오기
  Future<List<User>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id');
    final username = prefs.getString('current_user_name') ?? '사용자';
    
    if (userId == null) {
      return [];
    }
    
    return [
      User(
        userId: userId,
        username: username,
        profileImage: prefs.getString('current_user_profile_image') ?? '',
      )
    ];
  }
  
  // 사용자 추가
  Future<int> insertUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', user.userId);
    await prefs.setString('current_user_name', user.username);
    if (user.profileImage.isNotEmpty) {
      await prefs.setString('current_user_profile_image', user.profileImage);
    }
    return 1;
  }
  
  // ID로 사용자 조회
  Future<User?> getUserById(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('current_user_id');
    
    if (currentUserId == userId) {
      return User(
        userId: userId,
        username: prefs.getString('current_user_name') ?? '사용자',
        profileImage: prefs.getString('current_user_profile_image') ?? '',
      );
    }
    return null;
  }
}