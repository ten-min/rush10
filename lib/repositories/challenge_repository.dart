import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/challenge_room.dart';
import 'package:collection/collection.dart';

class ChallengeRepository {
  static const String _challengeRoomsKey = 'challenge_rooms';
  static const String _participantsKey = 'room_participants';

  // 싱글톤 패턴 구현
  static final ChallengeRepository _instance = ChallengeRepository._internal();
  static ChallengeRepository get instance => _instance;

  ChallengeRepository._internal();

  // 도전방 생성
  Future<ChallengeRoom> createRoom({
    required String title,
    required String description,
    required String hostName,
    required String hostId,
    required DateTime startTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 새로운 도전방 생성
    final room = ChallengeRoom(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      hostName: hostName,
      hostId: hostId,
      participantCount: 1, // 호스트만 있는 상태
      startTime: startTime,
      code: _generateRoomCode(),
      isCompleted: false,
      completedAt: null,
    );

    // 기존 도전방 목록 가져오기
    final roomsJson = prefs.getStringList(_challengeRoomsKey) ?? [];
    final rooms = roomsJson.map((json) => _decodeRoom(json)).toList();

    // 새 도전방 추가
    rooms.add(room);
    
    // 도전방 목록 저장
    await prefs.setStringList(
      _challengeRoomsKey,
      rooms.map((room) => _encodeRoom(room)).toList(),
    );

    // 참가자 목록 초기화 (호스트만)
    await _initializeParticipants(room.id, hostId);

    return room;
  }

  // 도전방 목록 조회
  Future<List<ChallengeRoom>> getRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final roomsJson = prefs.getStringList(_challengeRoomsKey) ?? [];
    return roomsJson.map((json) => _decodeRoom(json)).toList();
  }

  // 특정 도전방 조회
  Future<ChallengeRoom?> getRoomById(String roomId) async {
    final rooms = await getRooms();
    print('[DEBUG] getRoomById: 전체 rooms id=${rooms.map((r) => r.id).toList()}');
    return rooms.firstWhereOrNull((room) => room.id == roomId);
  }

  // 도전방 참가
  Future<bool> joinRoom(String roomId, String userId) async {
    print('[DEBUG] joinRoom 호출: roomId=$roomId, userId=$userId');
    final prefs = await SharedPreferences.getInstance();
    final room = await getRoomById(roomId);
    print('[DEBUG] getRoomById 결과: $room');
    if (room == null) {
      print('[ERROR] 존재하지 않는 방에 참가 시도: roomId=$roomId');
      return false;
    }

    // 이미 참가한 사용자인지 확인
    final participants = await getRoomParticipants(roomId);
    print('[DEBUG] 참가자 목록: $participants');
    
    if (participants.contains(userId)) {
      print('[DEBUG] 이미 참가한 사용자: userId=$userId');
      return true; // 이미 참가했으면 성공으로 처리
    }

    // 참가자 추가
    participants.add(userId);
    await prefs.setStringList('${_participantsKey}_$roomId', participants);
    print('[DEBUG] 참가자 추가 후: ${await getRoomParticipants(roomId)}');

    // 도전방 정보 업데이트 (참가자 수 증가)
    final updatedRoom = ChallengeRoom(
      id: room.id,
      title: room.title,
      description: room.description,
      hostName: room.hostName,
      hostId: room.hostId,
      participantCount: room.participantCount + 1,
      startTime: room.startTime,
      code: room.code,
      isCompleted: room.isCompleted,
      completedAt: room.completedAt,
    );

    // 도전방 목록 업데이트
    final rooms = await getRooms();
    final updatedRooms = rooms.map((r) => r.id == roomId ? updatedRoom : r).toList();
    await prefs.setStringList(
      _challengeRoomsKey,
      updatedRooms.map((room) => _encodeRoom(room)).toList(),
    );

    print('[DEBUG] 방 참가 완료: roomId=$roomId, userId=$userId');
    return true;
  }

  // 도전방 나가기
  Future<bool> leaveRoom(String roomId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final room = await getRoomById(roomId);
    
    if (room == null) return false;

    // 호스트는 나갈 수 없음
    if (room.hostId == userId) return false;

    // 참가자 목록에서 제거
    final participants = await getRoomParticipants(roomId);
    if (!participants.contains(userId)) return false;

    participants.remove(userId);
    await prefs.setStringList('${_participantsKey}_$roomId', participants);

    // 도전방 정보 업데이트 (참가자 수 감소)
    final updatedRoom = ChallengeRoom(
      id: room.id,
      title: room.title,
      description: room.description,
      hostName: room.hostName,
      hostId: room.hostId,
      participantCount: room.participantCount - 1,
      startTime: room.startTime,
      code: room.code,
      isCompleted: room.isCompleted,
      completedAt: room.completedAt,
    );

    // 도전방 목록 업데이트
    final rooms = await getRooms();
    final updatedRooms = rooms.map((r) => r.id == roomId ? updatedRoom : r).toList();
    await prefs.setStringList(
      _challengeRoomsKey,
      updatedRooms.map((room) => _encodeRoom(room)).toList(),
    );

    return true;
  }

  // 도전방 완료 처리
  Future<bool> completeRoom(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final room = await getRoomById(roomId);
    
    if (room == null) return false;

    // 도전방 정보 업데이트 (완료 처리)
    final updatedRoom = ChallengeRoom(
      id: room.id,
      title: room.title,
      description: room.description,
      hostName: room.hostName,
      hostId: room.hostId,
      participantCount: room.participantCount,
      startTime: room.startTime,
      code: room.code,
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    // 도전방 목록 업데이트
    final rooms = await getRooms();
    final updatedRooms = rooms.map((r) => r.id == roomId ? updatedRoom : r).toList();
    await prefs.setStringList(
      _challengeRoomsKey,
      updatedRooms.map((room) => _encodeRoom(room)).toList(),
    );

    return true;
  }

  // 도전방 삭제
  Future<bool> deleteRoom(String roomId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final room = await getRoomById(roomId);
    
    if (room == null) return false;

    // 호스트만 삭제 가능
    if (room.hostId != userId) return false;

    // 도전방 목록에서 제거
    final rooms = await getRooms();
    final updatedRooms = rooms.where((r) => r.id != roomId).toList();
    await prefs.setStringList(
      _challengeRoomsKey,
      updatedRooms.map((room) => _encodeRoom(room)).toList(),
    );

    // 참가자 목록 삭제
    await prefs.remove('${_participantsKey}_$roomId');

    return true;
  }

  // 도전방 참가자 목록 조회
  Future<List<String>> getRoomParticipants(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final participants = prefs.getStringList('${_participantsKey}_$roomId') ?? [];
    
    print('[DEBUG] getRoomParticipants: roomId=$roomId, participants=$participants');
    
    return participants;
  }

  // 도전방 참가자 목록 초기화
  Future<void> _initializeParticipants(String roomId, String hostId) async {
    final prefs = await SharedPreferences.getInstance();
    final participantsList = [hostId];
    
    print('[DEBUG] _initializeParticipants: roomId=$roomId, hostId=$hostId');
    
    await prefs.setStringList('${_participantsKey}_$roomId', participantsList);
    
    // 저장 후 확인
    final savedParticipants = prefs.getStringList('${_participantsKey}_$roomId') ?? [];
    print('[DEBUG] _initializeParticipants 저장 후: ${savedParticipants}');
  }
  
  // 모든 방 참가자 정보 조회 (디버깅용)
  Future<Map<String, List<String>>> getAllRoomParticipants() async {
    final prefs = await SharedPreferences.getInstance();
    final rooms = await getRooms();
    final result = <String, List<String>>{};
    
    for (final room in rooms) {
      final participants = await getRoomParticipants(room.id);
      result[room.id] = participants;
    }
    
    return result;
  }
  
  // 사용자가 참여한 모든 방 목록 조회
  Future<List<ChallengeRoom>> getUserRooms(String userId) async {
    final rooms = await getRooms();
    final userRooms = <ChallengeRoom>[];
    
    for (final room in rooms) {
      final participants = await getRoomParticipants(room.id);
      if (participants.contains(userId)) {
        userRooms.add(room);
      }
    }
    
    print('[DEBUG] getUserRooms: userId=$userId, 방 개수=${userRooms.length}');
    return userRooms;
  }
  
  // 모든 SharedPreferences 데이터 초기화 (디버깅용)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('[DEBUG] 모든 SharedPreferences 데이터가 초기화되었습니다.');
  }

  // 도전방 코드 생성
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = List.generate(6, (index) {
      return chars[random % chars.length];
    }).join();
    return 'RUSH$code';
  }

  // ChallengeRoom 객체를 JSON 문자열로 변환
  String _encodeRoom(ChallengeRoom room) {
    return jsonEncode({
      'id': room.id,
      'title': room.title,
      'description': room.description,
      'hostName': room.hostName,
      'hostId': room.hostId,
      'participantCount': room.participantCount,
      'startTime': room.startTime.toIso8601String(),
      'code': room.code,
      'isCompleted': room.isCompleted,
      'completedAt': room.completedAt?.toIso8601String(),
    });
  }

  // JSON 문자열을 ChallengeRoom 객체로 변환
  ChallengeRoom _decodeRoom(String json) {
    final map = jsonDecode(json);
    return ChallengeRoom(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      hostName: map['hostName'],
      hostId: map['hostId'],
      participantCount: map['participantCount'],
      startTime: DateTime.parse(map['startTime']),
      code: map['code'],
      isCompleted: map['isCompleted'],
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
    );
  }
} 