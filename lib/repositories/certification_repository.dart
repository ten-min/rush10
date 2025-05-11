import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/certification_post.dart';

class CertificationRepository {
  // 싱글톤 패턴 구현
  static final CertificationRepository _instance = CertificationRepository._internal();
  static CertificationRepository get instance => _instance;

  CertificationRepository._internal();

  // 인증 게시물 생성 (Firestore에 저장)
  Future<CertificationPost> createPost({
    required String roomId,
    required String userId,
    required String username,
    required String description,
    required Uint8List photoBytes,
    String? profileImagePath,
  }) async {
    // 고유 ID 생성
    final id = const Uuid().v4();
    final hasPhoto = photoBytes.isNotEmpty;
    print('[DEBUG] CertificationRepository.createPost - hasPhoto=$hasPhoto, photoBytes길이=${photoBytes.length}');

    // 인증 게시물 생성
    final post = CertificationPost(
      id: id,
      roomId: roomId,
      userId: userId,
      username: username,
      description: description,
      photoBytes: hasPhoto ? photoBytes : null, // 사진이 있는 경우에만 photoBytes 설정
      profileImagePath: profileImagePath,
      createdAt: DateTime.now(),
      isCompleted: true,
    );

    // Firestore에 저장 (사진은 base64로 저장)
    await FirebaseFirestore.instance.collection('certifications').doc(id).set({
      'id': id,
      'roomId': roomId,
      'userId': userId,
      'username': username,
      'description': description,
      'photoBase64': hasPhoto ? base64Encode(photoBytes) : null,
      'profileImagePath': profileImagePath,
      'createdAt': DateTime.now().toIso8601String(),
      'isCompleted': true,
    });
    print('[DEBUG] 인증 저장 완료 - 사용자 ID: $userId, 방 ID: $roomId, 인증 ID: $id');
    return post;
  }

  // 특정 방의 인증 게시물 목록 조회 (Firestore)
  Future<List<CertificationPost>> getPostsByRoomId(String roomId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('certifications')
        .where('roomId', isEqualTo: roomId)
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      Uint8List? photoBytes;
      if (data['photoBase64'] != null) {
        try {
          photoBytes = base64Decode(data['photoBase64']);
        } catch (e) {
          print('이미지 디코딩 오류: $e');
        }
      }
      return CertificationPost.fromJson(data, photoData: photoBytes);
    }).toList();
  }

  // 특정 사용자의 인증 게시물 목록 조회 (Firestore)
  Future<List<CertificationPost>> getPostsByUserId(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('certifications')
        .where('userId', isEqualTo: userId)
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      Uint8List? photoBytes;
      if (data['photoBase64'] != null) {
        try {
          photoBytes = base64Decode(data['photoBase64']);
        } catch (e) {
          print('이미지 디코딩 오류: $e');
        }
      }
      return CertificationPost.fromJson(data, photoData: photoBytes);
    }).toList();
  }

  // 특정 인증 게시물 조회 (Firestore)
  Future<CertificationPost?> getPostById(String postId) async {
    final doc = await FirebaseFirestore.instance.collection('certifications').doc(postId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    Uint8List? photoBytes;
    if (data['photoBase64'] != null) {
      try {
        photoBytes = base64Decode(data['photoBase64']);
      } catch (e) {
        print('이미지 디코딩 오류: $e');
      }
    }
    return CertificationPost.fromJson(data, photoData: photoBytes);
  }

  // 사용자가 특정 방에 인증 게시물을 이미 작성했는지 확인 (Firestore)
  Future<bool> hasUserCertifiedRoom(String roomId, String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('certifications')
        .where('roomId', isEqualTo: roomId)
        .where('userId', isEqualTo: userId)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }
} 