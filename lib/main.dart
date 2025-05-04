import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';

import 'models/challenge_room.dart';
import 'models/participant.dart';
import 'pages/room_list_page.dart';
import 'pages/lobby_page.dart';
import 'pages/countdown_page.dart';
import 'pages/challenge_page.dart';
import 'pages/results_page.dart';
import 'constants/enums.dart';
import 'utils/time_formatter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rush10',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const Rush10App(),
      debugShowCheckedModeBanner: false,
    );
  }
}



class Rush10App extends StatefulWidget {
  const Rush10App({super.key});

  @override
  State<Rush10App> createState() => _Rush10AppState();
}

class _Rush10AppState extends State<Rush10App> {
  Rush10Page currentPage = Rush10Page.roomList;
  int timeLeft = 600; // 10분
  int countdown = 5;
  DateTime? challengeStartTime;
  Timer? _timer;


  // 샘플 도전방 목록 추가
  List<ChallengeRoom> rooms = [
    ChallengeRoom(
      id: '1',
      title: '10분 내에 집 주변 한 바퀴 산책하기',
      description: '함께 집 주변을 산책해봐요! 운동도 되고 기분도 좋아질 거예요.',
      hostName: '김민수',
      participantCount: 3,
      startTime: DateTime.now().add(const Duration(minutes: 15)),
      code: 'RUSH429',
    ),
    ChallengeRoom(
      id: '2',
      title: '10분만에 방 정리하기',
      description: '지저분한 방을 함께 빠르게 정리해봐요!',
      hostName: '이지은',
      participantCount: 2,
      startTime: DateTime.now().add(const Duration(minutes: 30)),
      code: 'RUSH781',
    ),
    ChallengeRoom(
      id: '3',
      title: '10분 스트레칭 챌린지',
      description: '간단한 스트레칭으로 몸을 풀어봐요.',
      hostName: '박준호',
      participantCount: 5,
      startTime: DateTime.now().add(const Duration(hours: 1)),
      code: 'RUSH355',
    ),
  ];


  List<Participant> participants = [
    Participant(id: 1, name: '사용자', isHost: true),
    Participant(id: 2, name: '김민수', isHost: false),
    Participant(id: 3, name: '이지은', isHost: false),
  ];


  // 종료 대기중인 방 목록 추가
  List<ChallengeRoom> pendingRooms = [];

  File? selectedImage;
  String description = '';

  @override
  void initState() {
    super.initState();
    _startLobbyTimer();
  }

  void _startLobbyTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (challengeStartTime != null) {
        final now = DateTime.now();
        final diff = challengeStartTime!.difference(now);
        if (diff.inSeconds <= 5 && diff.inSeconds > 0 && currentPage == Rush10Page.lobby) {
          setState(() {
            currentPage = Rush10Page.countdown;
            countdown = diff.inSeconds;
          });
          _startCountdown();
        } else if (diff.isNegative && currentPage == Rush10Page.lobby) {
          // 만약 5초 이하를 놓쳤을 때 바로 도전 시작
          setState(() {
            currentPage = Rush10Page.challenge;
            timeLeft = 600;
          });
          _startTimer();
        } else {
          setState(() {}); // 남은 시간 갱신
        }
      }
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 1) {
        setState(() {
          countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          currentPage = Rush10Page.challenge;
          timeLeft = 600;
        });
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 1) {
        setState(() {
          timeLeft--;
        });
      } else {
        timer.cancel();
        setState(() {
          timeLeft = 0;
          currentPage = Rush10Page.results;
        });
      }
    });
  }

  void resetApp() {
    setState(() {
      currentPage = Rush10Page.lobby;
      timeLeft = 600;
      countdown = 5;
      challengeStartTime = null;
      description = '';
      participants = participants
          .map((p) => Participant(
                id: p.id,
                name: p.name,
                isHost: p.isHost,
                completed: false,
                photoBytes: null,
                photoFile: null,
                description: '',
              ))
          .toList();
    });
    _startLobbyTimer();
  }

  String formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String getLobbyCountdownText() {
    if (challengeStartTime == null) return '도전 시작 시각을 설정해주세요';
    final now = DateTime.now();
    final diff = challengeStartTime!.difference(now);
    if (diff.isNegative) return '곧 도전이 시작됩니다!';
    final min = diff.inMinutes;
    final sec = diff.inSeconds % 60;
    return '도전 시작까지 ${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _pickChallengeTime() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 5))),
    );
    if (time != null) {
      final picked = DateTime(today.year, today.month, today.day, time.hour, time.minute);
      if (picked.isAfter(now) && picked.isBefore(today.add(const Duration(days: 1)))) {
        setState(() {
          challengeStartTime = picked;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오늘 안의 미래 시간만 선택할 수 있습니다.')),
        );
      }
    }
  }

  Future<void> handleImageSelect() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.camera, 
      maxWidth: 600, 
      maxHeight: 600, 
      imageQuality: 80
    );
    
    if (picked != null) {
      // 모든 플랫폼에서 바이트 데이터로 변환
      final bytes = await picked.readAsBytes();
      
      setState(() {
        participants = participants.map((p) {
          if (p.id == 1) {
            return Participant(
              id: p.id,
              name: p.name,
              isHost: p.isHost,
              completed: false,
              photoBytes: bytes,
              description: description,
            );
          }
          return p;
        }).toList();
      });
      
      print('이미지 선택 완료: ${bytes.length} 바이트');
    }
  }

  // 방을 종료 대기중 목록에 추가하는 메서드
  void addToPendingRooms(ChallengeRoom room) {
    setState(() {
      // 이미 리스트에 있는지 확인
      final exists = pendingRooms.any((r) => r.id == room.id);
      if (!exists) {
        pendingRooms.add(room);
      }
    });
  }

  void handleSubmit() {
    final my = participants.firstWhere((p) => p.id == 1);
    final isPhotoReady = my.photoBytes != null;
    
    if (isPhotoReady && description.trim().isNotEmpty) {
      setState(() {
        participants = participants.map((p) {
          if (p.id == 1) {
            return Participant(
              id: p.id,
              name: p.name,
              isHost: p.isHost,
              completed: true,
              photoBytes: my.photoBytes,
              description: description,
            );
          }
          return p;
        }).toList();
      });
      
      // 임시 방 객체 생성 (기존 도전방 중 하나 사용 또는 새로 생성)
      final currentRoom = ChallengeRoom(
        id: 'current',
        title: '10분 내에 집 주변 한 바퀴 산책하기', // 현재 참여 중인 방 제목
        description: '함께 집 주변을 산책해봐요!',
        hostName: '김민수',
        participantCount: participants.length,
        startTime: DateTime.now().subtract(const Duration(minutes: 8)), // 8분 전에 시작했다고 가정
        code: 'RUSH429',
      );
      
      // 종료 대기중 목록에 추가
      addToPendingRooms(currentRoom);
      
      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증이 완료되었습니다!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // 2초 후 홈 화면으로 이동
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          currentPage = Rush10Page.roomList;
        });
      });
      
      print('인증 완료됨! 상태: ${participants.firstWhere((p) => p.id == 1).completed}');
    } else {
      // 필요한 정보가 없을 때 에러 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사진과 설명을 모두 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      print('인증 실패: 이미지=${isPhotoReady}, 설명=${description.trim().isNotEmpty}');
    }
  }


  // 이미지 위젯 생성 함수 수정
  Widget buildImageWidget(Participant p, {double? width, double? height, BoxFit? fit, BorderRadius? borderRadius}) {
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
    } else {
      return const SizedBox.shrink();
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // App header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 로고에 GestureDetector 추가 (커서 변경 포함)
                  MouseRegion(
                    cursor: SystemMouseCursors.click, // 마우스 커서를 클릭 포인터로 변경
                    child: GestureDetector(
                      onTap: () {
                        // 홈 화면(도전방 목록)으로 이동
                        setState(() {
                          currentPage = Rush10Page.roomList;
                        });
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                          children: [
                            TextSpan(text: 'Rush', style: TextStyle(color: Color(0xFF5A4FF3))),
                            TextSpan(text: '10', style: TextStyle(color: Color(0xFF8B9DFE))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (currentPage == Rush10Page.challenge)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7EAFE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Color(0xFF5A4FF3), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            formatTime(timeLeft),
                            style: const TextStyle(
                              color: Color(0xFF5A4FF3),
                              fontFamily: 'RobotoMono',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _renderPage(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderPage() {
    switch (currentPage) {
      case Rush10Page.roomList:
        return RoomListPage(
          rooms: rooms,
          pendingRooms: pendingRooms, // 추가
          onRoomSelected: (room) {
            setState(() {
              currentPage = Rush10Page.lobby;
              // 필요한 경우 선택된 room 정보 사용
            });
          },
        );
      case Rush10Page.lobby:
        return LobbyPage(
          participants: participants,
          challengeStartTime: challengeStartTime,
          onPickTime: _pickChallengeTime,
          getLobbyCountdownText: getLobbyCountdownText,
        );
      case Rush10Page.countdown:
        return CountdownPage(
          countdown: countdown,
        );
      case Rush10Page.challenge:
        return ChallengePage(
          timeLeft: timeLeft,
          description: description,
          onDescriptionChanged: (value) {
            setState(() {
              description = value;
            });
          },
          participants: participants,
          handleImageSelect: handleImageSelect,
          handleSubmit: handleSubmit,
          buildImageWidget: buildImageWidget,
        );
      case Rush10Page.results:
        return ResultsPage(
          participants: participants,
          resetApp: resetApp,
          buildImageWidget: buildImageWidget,
        );
    }
  }

}