import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/participant.dart';
import 'package:collection/collection.dart';
import '../repositories/challenge_repository.dart';
import '../models/user.dart';
import '../models/challenge_room.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/database_helper.dart';
import '../pages/challenge_page.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' show File;
import 'widgets/participant_tile.dart';
import '../utils/challenge_timer.dart';
import '../utils/time_utils.dart';
import '../pages/room_list_page.dart';
import '../main.dart';  // MyApp 접근
import '../pages/certification_board_page.dart';
import '../repositories/certification_repository.dart';

class LobbyPage extends StatefulWidget {
  final DateTime? challengeStartTime;
  final Function() onPickTime;
  final Function() getLobbyCountdownText;
  final User currentUser;
  final ChallengeRoom room;
  final VoidCallback? onRoomDeleted;

  const LobbyPage({
    Key? key,
    required this.challengeStartTime,
    required this.onPickTime,
    required this.getLobbyCountdownText,
    required this.currentUser,
    required this.room,
    this.onRoomDeleted,
  }) : super(key: key);

  // 정적 메서드 추가 - 간단한 LobbyPage 생성용
  static Widget create({
    required ChallengeRoom room,
    required User currentUser,
  }) {
    return LobbyPage(
      challengeStartTime: room.startTime,
      onPickTime: () {},
      getLobbyCountdownText: () => '도전 중',
      currentUser: currentUser,
      room: room,
    );
  }

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  int timeLeft = 600;
  int countdown = 0;
  List<Participant>? participants;
  bool isLoading = false;
  Timer? _timer;
  bool _showCountdown = false;
  bool _navigated = false;
  bool _hasUserCertified = false; // 사용자가 인증했는지 여부

  @override
  void initState() {
    super.initState();
    _loadParticipants();
    _startLobbyTimer();
    _checkUserCertification(); // 사용자 인증 여부 확인
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadParticipants() async {
    final ids = await ChallengeRepository.instance.getRoomParticipants(widget.room.id);
    
    // 항상 최신 사용자 정보를 가져오기 위해 데이터베이스에서 직접 조회
    final currentUser = await DatabaseHelper.instance.getCurrentUser();
    final otherUsers = await Future.wait(
      ids.where((id) => id != currentUser.userId)
        .map((id) => DatabaseHelper.instance.getUserById(id))
    );
    
    setState(() {
      participants = [
        // 현재 사용자는 항상 최신 정보 사용
        Participant(
          id: currentUser.userId,
          name: currentUser.username,
          isHost: currentUser.userId == widget.room.hostId,
          profileImage: currentUser.profileImage,
        ),
        // 다른 사용자들
        ...otherUsers.where((user) => user != null).map((user) => 
          Participant(
            id: user!.userId,
            name: user.username,
            isHost: user.userId == widget.room.hostId,
            profileImage: user.profileImage,
          )
        )
      ];
    });
  }

  Future<void> _joinRoom() async {
    setState(() { isLoading = true; });
    final success = await ChallengeRepository.instance.joinRoom(widget.room.id, widget.currentUser.userId);
    if (success) {
      await _loadParticipants();
      setState(() { isLoading = false; });
    } else {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참가에 실패했습니다.')),
      );
    }
  }

  Future<void> _leaveRoom() async {
    setState(() { isLoading = true; });
    final success = await ChallengeRepository.instance.leaveRoom(widget.room.id, widget.currentUser.userId);
    if (success) {
      await _loadParticipants();
      setState(() { isLoading = false; });
    } else {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참가 해제에 실패했습니다.')),
      );
    }
  }

  void _goToChallengePage() async {
    print('[DEBUG] 인증하기 버튼 클릭 - _goToChallengePage 호출됨');
    
    // 타이머 설정
    final now = DateTime.now();
    final start = widget.room.startTime;
    final end = start.add(const Duration(minutes: 10));
    final seconds = end.difference(now).inSeconds.clamp(0, 600);
    
    // 타이머 초기화 및 시작
    ChallengeTimer.instance.stop();
    ChallengeTimer.instance.start(seconds);
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengePage(
          currentUserId: widget.currentUser.userId,
          description: '',
          onDescriptionChanged: (value) {}, // 필요시 상태 관리
          participants: participants ?? [
            Participant(
              id: widget.currentUser.userId,
              name: widget.currentUser.username,
              isHost: widget.currentUser.userId == widget.room.hostId,
              profileImage: widget.currentUser.profileImage,
            )
          ],
          handleImageSelect: () {}, // 필요시 구현
          handleSubmit: () {}, // 필요시 구현
          buildImageWidget: (p, {width, height, fit, borderRadius}) {
            if (p.photoBytes != null) {
              return ClipRRect(
                borderRadius: borderRadius ?? BorderRadius.circular(8),
                child: Image.memory(
                  p.photoBytes!,
                  width: width,
                  height: height,
                  fit: fit ?? BoxFit.cover,
                ),
              );
            } else if (p.profileImage != null && p.profileImage!.isNotEmpty) {
              if (kIsWeb) {
                try {
                  final bytes = base64Decode(p.profileImage!);
                  return ClipRRect(
                    borderRadius: borderRadius ?? BorderRadius.circular(8),
                    child: Image.memory(
                      bytes,
                      width: width,
                      height: height,
                      fit: fit ?? BoxFit.cover,
                    ),
                  );
                } catch (_) {
                  return SizedBox(width: width, height: height);
                }
              } else {
                return ClipRRect(
                  borderRadius: borderRadius ?? BorderRadius.circular(8),
                  child: Image.file(
                    File(p.profileImage!),
                    width: width,
                    height: height,
                    fit: fit ?? BoxFit.cover,
                  ),
                );
              }
            } else {
              return SizedBox(width: width, height: height);
            }
          },
          room: widget.room,
          currentUser: widget.currentUser,
          onBackToHome: () {
            // 정적 메서드를 통해 홈 화면으로 이동
            MyApp.goToHome();
            Navigator.of(context).pop();
          },
          onBackToLobby: () {
            // 단순히 이전 화면으로 돌아가기
            Navigator.of(context).pop();
          },
        ),
      ),
    ).then((_) {
      // ChallengePage에서 돌아왔을 때 인증 상태 확인
      _checkUserCertification();
      print('[DEBUG] ChallengePage에서 돌아옴 - 인증 상태 확인 (_hasUserCertified: $_hasUserCertified)');
    });
  }

  String getLobbyTimerText() {
    final now = DateTime.now();
    final start = widget.room.startTime;
    
    // 시작 시간이 과거인 경우 (이미 시작됨)
    if (now.isAfter(start)) {
      final end = start.add(const Duration(minutes: 10));
      
      // 10분이 지났는지 확인
      if (now.isAfter(end)) {
        return '인증 시간이 종료되었습니다.';
      } else {
        // 남은 인증 시간 표시
        final diff = end.difference(now);
        final min = diff.inMinutes;
        final sec = diff.inSeconds % 60;
        return '인증 마감까지 ${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
      }
    } 
    // 시작 시간이 미래인 경우 (아직 시작 안됨)
    else {
      final diff = start.difference(now);
      final min = diff.inMinutes;
      final sec = diff.inSeconds % 60;
      return '도전 시작까지 ${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
  }

  Widget buildProfileAvatar(Participant p) {
    if (kIsWeb && p.profileImage != null && p.profileImage.isNotEmpty) {
      try {
        final bytes = base64Decode(p.profileImage);
        return CircleAvatar(backgroundImage: MemoryImage(bytes), radius: 18);
      } catch (_) {
        return defaultAvatar(p.name);
      }
    } else if (!kIsWeb && p.profileImage != null && p.profileImage.isNotEmpty) {
      return CircleAvatar(backgroundImage: FileImage(File(p.profileImage)), radius: 18);
    } else {
      return defaultAvatar(p.name);
    }
  }

  Widget defaultAvatar(String name) => CircleAvatar(
    backgroundColor: const Color(0xFFE7EAFE),
    radius: 18,
    child: Text(name.substring(0, 1), style: const TextStyle(color: Color(0xFF5A4FF3), fontWeight: FontWeight.bold)),
  );

  void _startLobbyTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.room.startTime != null) {
        final now = DateTime.now();
        final diff = widget.room.startTime.difference(now);
        final currentUserId = widget.currentUser.userId;
        final isAlreadyJoined = participants?.any((p) => p.id == currentUserId) ?? false;
        
        // 로비 화면에서 카운트다운 띄우기
        if (isAlreadyJoined) {
          // 5초 이하로 남았을 때 카운트다운 표시 (시작 전에만)
          if (diff.inSeconds <= 5 && diff.inSeconds > 0 && !now.isAfter(widget.room.startTime)) {
            setState(() {
              _showCountdown = true;
              countdown = diff.inSeconds;
            });
          } 
          // 0초가 되면 카운트다운 종료
          else if (diff.inSeconds <= 0 && _showCountdown) {
            setState(() {
              _showCountdown = false;
            });
          } else if (diff.inSeconds > 5) {
            // 5초 이상 남았을 때는 카운트다운 숨김
            setState(() {
              _showCountdown = false;
            });
          }
        }
        
        // 로비 상태일 때 1초마다 setState로 build를 갱신
        setState(() {}); // build를 강제로 트리거
      }
    });
  }

  // 사용자가 이미 인증했는지 확인
  Future<void> _checkUserCertification() async {
    try {
      print('[DEBUG] _checkUserCertification 호출됨 - 사용자ID: ${widget.currentUser.userId}, 방ID: ${widget.room.id}');
      
      final hasCertified = await CertificationRepository.instance.hasUserCertifiedRoom(
        widget.room.id, 
        widget.currentUser.userId
      );
      
      print('[DEBUG] 인증 확인 결과: hasCertified=$hasCertified (이전 값: $_hasUserCertified)');
      
      setState(() {
        _hasUserCertified = hasCertified;
      });
      
      print('[DEBUG] 사용자 인증 확인: ${widget.currentUser.userId}, 인증됨=$_hasUserCertified');
    } catch (e) {
      print('[ERROR] 인증 확인 중 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (participants == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // 디버그 정보 추가 - 참가자와 현재 사용자 정보 정확하게 비교
    print('[DEBUG] LobbyPage.build: 참가자 목록 = $participants');
    print('[DEBUG] LobbyPage.build: 현재 사용자 ID = ${widget.currentUser.userId}');
    
    final isHost = widget.currentUser.userId == widget.room.hostId;
    final String currentUserId = widget.currentUser.userId;
    
    // 참가자 목록에서 현재 사용자 ID를 정확히 확인 - ID 문자열 비교
    bool isAlreadyJoined = false;
    for (final p in participants!) {
      print('[DEBUG] 참가자 ID 비교: 참가자=${p.id}, 현재사용자=$currentUserId, 일치=${p.id == currentUserId}');
      if (p.id == currentUserId) {
        isAlreadyJoined = true;
        break;
      }
    }
    
    print('[DEBUG] LobbyPage.build: isAlreadyJoined = $isAlreadyJoined');
    
    // 인증하기 버튼 활성화 조건 수정
    // 시작 시간이 지났으면 인증 가능
    final bool canCertify = DateTime.now().isAfter(widget.room.startTime);
    
    // 5초 이하 카운트다운 표시 오버레이
    if (_showCountdown && countdown > 0) {
      return Stack(
        children: [
          // 기존 로비 화면
          _buildLobbyContent(isHost, isAlreadyJoined, canCertify),
          
          // 카운트다운 오버레이
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$countdown',
                    style: const TextStyle(
                      fontSize: 96,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '도전이 곧 시작됩니다!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    // 일반 로비 화면
    return _buildLobbyContent(isHost, isAlreadyJoined, canCertify);
  }
  
  // 로비 화면 콘텐츠 메서드 분리
  Widget _buildLobbyContent(bool isHost, bool isAlreadyJoined, bool canCertify) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF5A4FF3),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('오늘의 도전', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(widget.room.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 8),
                Text(widget.room.description, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 16),
                Text(getLobbyTimerText(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                // 도전 완료 시간이 지났으면 인증 게시판 버튼 표시 (버튼 제거)
                if (isHost)
                  (widget.challengeStartTime == null)
                    ? Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: widget.onPickTime,
                            child: const Text('도전 시작 시각을 설정해주세요', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text('시작 시각: ${DateFormat('HH:mm').format(widget.challengeStartTime!)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      )
                else if (widget.challengeStartTime != null)
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text('시작 시각: ${DateFormat('HH:mm').format(widget.challengeStartTime!)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text('방장이 아직 시작 시각을 설정하지 않았어요', style: TextStyle(color: Colors.white)),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.people, color: Color(0xFF5A4FF3)),
                        SizedBox(width: 8),
                        Text('참가자', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...participants!.map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ParticipantTile(
                            participant: p,
                          ),
                        )),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('초대 코드', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F7FB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(widget.room.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isAlreadyJoined)
                      ...[
                        const Text('참가중', style: TextStyle(color: Color(0xFF5A4FF3), fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        isHost
                          ? ElevatedButton(
                              onPressed: isLoading || DateTime.now().isAfter(widget.room.startTime)
                                  ? null
                                  : () async {
                                setState(() { isLoading = true; });
                                final success = await ChallengeRepository.instance.deleteRoom(widget.room.id, widget.currentUser.userId);
                                setState(() { isLoading = false; });
                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('도전방이 삭제되었습니다.'), backgroundColor: Colors.red),
                                  );
                                  if (widget.onRoomDeleted != null) widget.onRoomDeleted!();
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('방 삭제에 실패했습니다.'), backgroundColor: Colors.red),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[400],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('방 삭제'),
                            )
                          : ElevatedButton(
                              onPressed: isLoading ? null : _leaveRoom,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                    ),
                                  )
                                : const Text('참가 해제'),
                            ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: canCertify && !isLoading && !_hasUserCertified
                              ? _goToChallengePage
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A4FF3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(_hasUserCertified ? '인증 완료됨' : '인증하기', style: const TextStyle(fontSize: 16)),
                        ),
                      ],
                    if (!isAlreadyJoined)
                      ElevatedButton(
                        onPressed: isLoading ? null : _joinRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A4FF3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('참가하기'),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // 인증 목록 보기 버튼을 다시 추가
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // 인증 게시판 페이지로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CertificationBoardPage(
                      room: widget.room,
                      currentUserId: widget.currentUser.userId,
                    ),
                  ),
                ).then((_) {
                  // 인증 게시판에서 돌아온 후 인증 상태 재확인
                  _checkUserCertification();
                });
              },
              icon: const Icon(Icons.format_list_bulleted, color: Colors.white),
              label: const Text('인증 목록 보기', style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A4FF3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void resetPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  print('shared_preferences가 초기화되었습니다!');
}