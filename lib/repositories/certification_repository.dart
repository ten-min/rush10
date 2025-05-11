import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/certification_post.dart';

class CertificationRepository {
  static const String _certificationsKey = 'certifications';
  static const String _photosKey = 'certification_photos';

  // 싱글톤 패턴 구현
  static final CertificationRepository _instance = CertificationRepository._internal();
  static CertificationRepository get instance => _instance;

  CertificationRepository._internal();

  // 인증 게시물 생성
  Future<CertificationPost> createPost({
    required String roomId,
    required String userId,
    required String username,
    required String description,
    required Uint8List photoBytes,
    String? profileImagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 고유 ID 생성
    final id = const Uuid().v4();
    
    // 빈 바이트 배열인지 확인 (사진 없음)
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

    // 이미지 데이터를 별도로 저장 (base64 인코딩) - 사진이 있는 경우에만
    if (hasPhoto) {
      await prefs.setString('${_photosKey}_$id', base64Encode(photoBytes));
    }

    // 인증 게시물 목록 가져오기
    final postsJson = prefs.getStringList(_certificationsKey) ?? [];
    final posts = postsJson.map((json) => _decodePost(json)).toList();
    
    // 이전 인증이 있으면 제거 (사용자당 인증 한 개만 유지하기 위함)
    String? oldPostId;
    for (int i = 0; i < posts.length; i++) {
      if (posts[i].userId == userId && posts[i].roomId == roomId) {
        oldPostId = posts[i].id;
        posts.removeAt(i);
        break;
      }
    }
    
    // 제거된 인증의 이미지 데이터도 삭제
    if (oldPostId != null) {
      await prefs.remove('${_photosKey}_$oldPostId');
      print('[DEBUG] 사용자의 이전 인증 데이터를 삭제했습니다. (ID: $oldPostId)');
    }

    // 새 게시물 추가
    posts.add(post);
    
    // 게시물 목록 저장
    await prefs.setStringList(
      _certificationsKey,
      posts.map((post) => _encodePost(post)).toList(),
    );
    
    print('[DEBUG] 인증 저장 완료 - 사용자 ID: $userId, 방 ID: $roomId, 인증 ID: $id');

    return post;
  }

  // 특정 방의 인증 게시물 목록 조회
  Future<List<CertificationPost>> getPostsByRoomId(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = prefs.getStringList(_certificationsKey) ?? [];
    final posts = await Future.wait(
      postsJson.map((json) async {
        final post = _decodePost(json);
        if (post.roomId == roomId) {
          final photoStr = prefs.getString('${_photosKey}_${post.id}');
          Uint8List? photoBytes;
          if (photoStr != null) {
            try {
              photoBytes = base64Decode(photoStr);
            } catch (e) {
              print('이미지 디코딩 오류: $e');
            }
          }
          return CertificationPost.fromJson(jsonDecode(json), photoData: photoBytes);
        }
        return null;
      }),
    );
    
    // null이 아닌 게시물만 필터링하여 반환
    return posts.where((post) => post != null).cast<CertificationPost>().toList();
  }

  // 특정 사용자의 인증 게시물 목록 조회
  Future<List<CertificationPost>> getPostsByUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = prefs.getStringList(_certificationsKey) ?? [];
    final posts = await Future.wait(
      postsJson.map((json) async {
        final post = _decodePost(json);
        if (post.userId == userId) {
          final photoStr = prefs.getString('${_photosKey}_${post.id}');
          Uint8List? photoBytes;
          if (photoStr != null) {
            try {
              photoBytes = base64Decode(photoStr);
            } catch (e) {
              print('이미지 디코딩 오류: $e');
            }
          }
          return CertificationPost.fromJson(jsonDecode(json), photoData: photoBytes);
        }
        return null;
      }),
    );
    
    // null이 아닌 게시물만 필터링하여 반환
    return posts.where((post) => post != null).cast<CertificationPost>().toList();
  }

  // 특정 인증 게시물 조회
  Future<CertificationPost?> getPostById(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = prefs.getStringList(_certificationsKey) ?? [];
    
    for (final json in postsJson) {
      final post = _decodePost(json);
      if (post.id == postId) {
        final photoStr = prefs.getString('${_photosKey}_$postId');
        Uint8List? photoBytes;
        if (photoStr != null) {
          try {
            photoBytes = base64Decode(photoStr);
          } catch (e) {
            print('이미지 디코딩 오류: $e');
          }
        }
        return CertificationPost.fromJson(jsonDecode(json), photoData: photoBytes);
      }
    }
    
    return null;
  }

  // 사용자가 특정 방에 인증 게시물을 이미 작성했는지 확인
  Future<bool> hasUserCertifiedRoom(String roomId, String userId) async {
    final posts = await getPostsByRoomId(roomId);
    return posts.any((post) => post.userId == userId);
  }

  // CertificationPost 객체를 JSON 문자열로 변환
  String _encodePost(CertificationPost post) {
    return jsonEncode({
      'id': post.id,
      'roomId': post.roomId,
      'userId': post.userId,
      'username': post.username,
      'description': post.description,
      'profileImagePath': post.profileImagePath,
      'createdAt': post.createdAt.toIso8601String(),
      'isCompleted': post.isCompleted,
    });
  }

  // JSON 문자열을 CertificationPost 객체로 변환 (이미지 데이터 없이)
  CertificationPost _decodePost(String json) {
    final map = jsonDecode(json);
    return CertificationPost(
      id: map['id'],
      roomId: map['roomId'],
      userId: map['userId'],
      username: map['username'],
      description: map['description'],
      profileImagePath: map['profileImagePath'],
      createdAt: DateTime.parse(map['createdAt']),
      isCompleted: map['isCompleted'] ?? true,
    );
  }
} 