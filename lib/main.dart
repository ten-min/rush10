import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'dart:js' as js;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';
import '../models/challenge_room.dart';
import 'models/participant.dart';
import 'pages/room_list_page.dart';
import 'pages/lobby_page.dart';
import 'pages/countdown_page.dart';
import 'pages/challenge_page.dart';
import 'pages/results_page.dart';
import 'constants/enums.dart';
import 'utils/time_utils.dart';

// 새로 추가된 import
import 'utils/database_helper.dart';
import 'models/participant_extended.dart';
import 'pages/user_profile_page.dart';
import 'repositories/challenge_repository.dart';
import 'repositories/certification_repository.dart';
import 'models/certification_post.dart';
import 'pages/certification_board_page.dart';
import 'pages/create_room_page.dart';
import 'utils/challenge_timer.dart';
import 'pages/widgets/app_bar_profile.dart';
import 'pages/widgets/create_room_fab.dart';
import 'pages/completed_challenges_page.dart';

// 전역 Navigator Key 추가
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 카카오 SDK 초기화는 모바일에서만 필요, 웹에서는 index.html에서 처리

  final prefs = await SharedPreferences.getInstance();
  // await prefs.clear();

  runApp(const MyApp());
} 

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  // 정적 상태 관리를 위한 변수
  static _MyHomePageState? _instance;
  
  // 인스턴스 설정
  static void setInstance(_MyHomePageState instance) {
    _instance = instance;
  }
  
  // 홈으로 이동
  static void goToHome() {
    if (_instance != null && _instance!.mounted) {
      _instance!.setState(() {
        _instance!.currentPage = Rush10Page.roomList;
      });
    }
  }
  
  // 로비로 이동
  static void goToLobby() {
    if (_instance != null && _instance!.mounted) {
      _instance!.setState(() {
        _instance!.currentPage = Rush10Page.lobby;
      });
    }
  }
  
  // 챌린지로 이동
  static void goToChallenge() {
    if (_instance != null && _instance!.mounted) {
      _instance!.setState(() {
        _instance!.currentPage = Rush10Page.challenge;
        
        // 타이머 설정
        if (_instance!.selectedRoom != null) {
          final now = DateTime.now();
          final start = _instance!.selectedRoom!.startTime;
          final end = start.add(const Duration(minutes: 10));
          final seconds = end.difference(now).inSeconds.clamp(0, 600);
          ChallengeTimer.instance.start(seconds);
          print('goToChallenge: 타이머 시작, seconds=$seconds');
        }
      });
    }
  }
  
  // 선택된 방 설정
  static void setSelectedRoom(ChallengeRoom room) {
    if (_instance != null && _instance!.mounted) {
      _instance!.setState(() {
        _instance!.selectedRoom = room;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // 전역 Navigator Key 설정
      title: 'Rush10',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginGate extends StatefulWidget {
  const LoginGate({Key? key}) : super(key: key);
  @override
  State<LoginGate> createState() => _LoginGateState();
}

class _LoginGateState extends State<LoginGate> {
  User? _currentUser;
  bool _isLoggedIn = false;
  String? _email;
  String? _kakaoUserId;
  String? _nickname;
  String? _profileImageUrl;
  bool _needsSignup = false;

  @override
  void initState() {
    super.initState();
    _checkKakaoLogin();
  }

  Future<void> _checkKakaoLogin() async {
    try {
      final kakaoUser = await kakao.UserApi.instance.me();
      final userId = kakaoUser.id.toString();
      final email = kakaoUser.kakaoAccount?.email;
      final profileImageUrl = kakaoUser.kakaoAccount?.profile?.profileImageUrl;
      // Firestore에서 users 문서 존재 여부 확인
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      String nickname;
      if (doc.exists && doc.data()?['nickname'] != null && (doc.data()?['nickname'] as String).trim().isNotEmpty) {
        nickname = doc.data()!['nickname'];
      } else {
        nickname = kakaoUser.kakaoAccount?.profile?.nickname ?? '사용자';
      }

      setState(() {
        _email = email;
        _kakaoUserId = userId;
        _nickname = nickname;
        _profileImageUrl = profileImageUrl;
      });

      await saveKakaoUserToFirestore(kakaoUser);

      if (!doc.exists) {
        setState(() {
          _needsSignup = true;
          _isLoggedIn = false;
          _currentUser = null;
        });
        return;
      }
      // 기존 회원이면 정상 로그인
      final user = await DatabaseHelper.instance.getCurrentUser(
        userId: _kakaoUserId!,
        nickname: _nickname!,
        email: _email!,
        profileImageUrl: _profileImageUrl,
      );
      setState(() {
        _currentUser = user;
        _isLoggedIn = true;
        _needsSignup = false;
      });
    } catch (_) {
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  Future<void> saveKakaoUserToFirestore(kakao.User kakaoUser) async {
    final userId = kakaoUser.id.toString();
    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final doc = await docRef.get();

    if (!doc.exists) {
      final now = DateTime.now();
      final nickname = kakaoUser.kakaoAccount?.profile?.nickname ?? '사용자';
      final email = kakaoUser.kakaoAccount?.email ?? '';
      final profileImageUrl = kakaoUser.kakaoAccount?.profile?.profileImageUrl ?? '';
      await docRef.set({
        'email': email,
        'nickname': nickname,
        'profileImageUrl': profileImageUrl,
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }

  Future<void> _loginWithKakao() async {
    try {
      if (await kakao.isKakaoTalkInstalled()) {
        await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }
      await _checkKakaoLogin();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오 로그인 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 웹용 카카오 로그인 함수
  void kakaoWebLogin() {
    final kakao = js.context['Kakao'];
    if (kakao == null) {
      print('Kakao JS SDK가 로드되지 않았습니다.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kakao JS SDK가 로드되지 않았습니다.'), backgroundColor: Colors.red),
      );
      return;
    }
    final auth = kakao['Auth'];
    if (auth == null) {
      print('Kakao.Auth 객체가 없습니다.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kakao.Auth 객체가 없습니다.'), backgroundColor: Colors.red),
      );
      return;
    }
    auth.callMethod('login', [js.JsObject.jsify({
      'success': (res) {
        final jsonString = js.context['JSON'].callMethod('stringify', [res]);
        print('카카오 웹 로그인 성공: $jsonString');
        setState(() {
          _isLoggedIn = true;
        });
        // 로그인 성공 후 사용자 식별자 요청
        getKakaoUserIdAndCheckSignup();
      },
      'fail': (err) {
        final errString = js.context['JSON'].callMethod('stringify', [err]);
        print('카카오 웹 로그인 실패: $errString');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카카오 웹 로그인 실패: $errString'), backgroundColor: Colors.red),
        );
      }
    })]);
  }

  // 카카오 사용자 식별자(user id) 요청 + 회원가입 여부 확인
  void getKakaoUserIdAndCheckSignup() async {
    final kakao = js.context['Kakao'];
    if (kakao == null) return;
    final api = kakao['API'];
    if (api == null) return;
    api.callMethod('request', [js.JsObject.jsify({
      'url': '/v2/user/me',
      'success': (res) async {
        final userId = res['id'].toString();
        final nickname = res['kakao_account']?['profile']?['nickname'] ?? '사용자';
        final email = res['kakao_account']?['email'] ?? '';
        final profileImageUrl = res['kakao_account']?['profile']?['profile_image_url'] ?? '';
        final now = DateTime.now();

        // Firestore에서 users 문서 존재 여부 확인
        final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
        final doc = await docRef.get();

        if (!doc.exists) {
          await docRef.set({
            'email': email,
            'nickname': nickname,
            'profileImageUrl': profileImageUrl,
            'createdAt': now,
            'updatedAt': now,
          });
        }

        if (!doc.exists) {
          setState(() {
            _kakaoUserId = userId;
            _nickname = nickname;
            _email = email;
            _profileImageUrl = profileImageUrl;
            _needsSignup = true;
            _isLoggedIn = false;
            _currentUser = null;
          });
          return;
        }

        // Firestore에서 유저 정보 읽어오기
        final user = await DatabaseHelper.instance.getCurrentUser(
          userId: userId,
          nickname: nickname,
          email: email,
          profileImageUrl: profileImageUrl,
        );

        setState(() {
          _kakaoUserId = userId;
          _nickname = nickname;
          _email = email;
          _profileImageUrl = profileImageUrl;
          _currentUser = user;
          _isLoggedIn = true;
          _needsSignup = false;
        });
      },
      'fail': (err) {
        final errString = js.context['JSON'].callMethod('stringify', [err]);
        print('카카오 사용자 정보 조회 실패: $errString');
      }
    })]);
  }

  // 회원가입 완료 처리 (닉네임 저장)
  Future<void> completeSignup() async {
    if (_kakaoUserId == null || _nickname == null || _nickname!.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kakao_user_id', _kakaoUserId!);
    await prefs.setString('nickname', _nickname!);
    await prefs.setString('current_user_name', _nickname!);
    print('회원가입 완료: $_kakaoUserId, 닉네임: $_nickname');
    await FirebaseFirestore.instance.collection('users').doc(_kakaoUserId!).set({
      'email': _email ?? '',
      'nickname': _nickname!,
      'profileImageUrl': _profileImageUrl ?? '',
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    }, SetOptions(merge: true));

    // Firestore에 저장한 값을 직접 읽어옴
    final user = await DatabaseHelper.instance.getCurrentUser(
      userId: _kakaoUserId!,
      nickname: _nickname!,
      email: _email ?? '',
      profileImageUrl: _profileImageUrl,
    );

    setState(() {
      _needsSignup = false;
      _isLoggedIn = true;
      _currentUser = user;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('회원가입이 완료되었습니다!'), backgroundColor: Colors.green),
    );

    // 강제 화면 전환
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MyHomePage(currentUser: user)),
    );
  }

  // 앱 시작 시 저장된 user id 불러오기 예시 (원하면 자동 로그인 등에 활용 가능)
  Future<void> loadKakaoUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('kakao_user_id');
    print('저장된 카카오 user id: $userId');
    // 필요시 setState 등으로 활용
  }

  // 카카오 로그아웃 함수 (웹/모바일 모두 지원)
  Future<void> kakaoLogout() async {
    try {
      // 웹 환경: JS SDK 사용
      final kakao = js.context['Kakao'];
      if (kakao != null && kakao['Auth'] != null) {
        kakao['Auth'].callMethod('logout');
        print('카카오 웹 로그아웃 성공');
      } else {
        // 모바일: Flutter SDK 사용
        await kakao.UserApi.instance.logout();
        print('카카오 모바일 로그아웃 성공');
      }
      
      // 로그아웃 후 로그인 페이지로 이동
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginGate()),
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃 되었습니다.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      print('카카오 로그아웃 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오 로그아웃 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 회원탈퇴 함수
  Future<void> withdrawUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _kakaoUserId;
      
      // Firestore에서 사용자 데이터 삭제
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      
      // 로컬 저장소 데이터 삭제
      await prefs.remove('kakao_user_id');
      await prefs.remove('nickname');
      await prefs.remove('current_user_name');
      await prefs.remove('current_user_id');
      await prefs.remove('current_user_profile_image');
      
      print('회원탈퇴: 사용자 정보 삭제 완료');
      
      // 회원탈퇴 후 로그인 페이지로 이동
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginGate()),
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원탈퇴가 완료되었습니다.'), backgroundColor: Colors.red),
      );
    } catch (e) {
      print('회원탈퇴 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원탈퇴 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final maxContentWidth = 700.0;
        Widget content;
        if (_needsSignup) {
          content = Scaffold(
            backgroundColor: const Color(0xFFF6F7FB),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('회원가입', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    const Text('닉네임을 입력해 주세요'),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '닉네임',
                      ),
                      onChanged: (v) => setState(() => _nickname = v),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: (_nickname != null && _nickname!.trim().isNotEmpty)
                          ? completeSignup
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(180, 48),
                        backgroundColor: const Color(0xFF5A4FF3),
                      ),
                      child: const Text('회원가입 완료', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (_isLoggedIn && _currentUser != null) {
          content = Stack(
            children: [
              MyHomePage(currentUser: _currentUser!),
            ],
          );
        } else {
          content = Scaffold(
            backgroundColor: const Color(0xFFF6F7FB),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/kakao_logo.png', width: 80, height: 80),
                  const SizedBox(height: 24),
                  const Text('Rush10에 오신 것을 환영합니다!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE500),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(220, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: _loginWithKakao,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/kakao_logo.png', width: 28, height: 28),
                        const SizedBox(width: 12),
                        const Text('카카오로 로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE500),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(220, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () {
                      kakaoWebLogin();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/kakao_logo.png', width: 28, height: 28),
                        const SizedBox(width: 12),
                        const Text('카카오로 로그인(웹)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (isDesktop) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: content,
            ),
          );
        } else {
          return content;
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final User currentUser;
  const MyHomePage({super.key, required this.currentUser});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late User currentUser;
  Rush10Page currentPage = Rush10Page.roomList;
  int timeLeft = 600; // 10분
  int countdown = 5;
  DateTime? challengeStartTime;
  Timer? _timer;

  // 도전방 목록을 ChallengeRepository에서 불러와 관리
  List<ChallengeRoom> rooms = [];
  List<ChallengeRoom> pendingRooms = [];

  File? selectedImage;
  String description = ''; // 빈 문자열로 초기화

  ChallengeRoom? selectedRoom;

  List<String> selectedRoomParticipants = [];

  bool _navigated = false;
  bool isSubmitting = false;

  List<Participant> _renderChallengePageParticipants = [];

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;
    MyApp.setInstance(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 프로필 페이지로 이동하는 메서드
  void _navigateToProfilePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          user: currentUser,
          onUserUpdated: _updateCurrentUser,
        ),
      ),
    );
  }

  // 사용자 정보 업데이트 콜백
  void _updateCurrentUser(User updatedUser) async {
    final latest = await DatabaseHelper.instance.getCurrentUser(
      userId: updatedUser.id,
      nickname: updatedUser.nickname,
      email: updatedUser.email,
      profileImageUrl: updatedUser.profileImageUrl,
    );
    print('[DEBUG] 프로필 변경 후 최신 currentUser: id=${latest.id}, name=${latest.nickname}, profileImage=${latest.profileImageUrl}');
    setState(() {
      currentUser = latest;
    });
  }

  void _startCountdown(int seconds) {
    ChallengeTimer.instance.start(seconds);
  }

  void _startChallenge(int seconds) {
    ChallengeTimer.instance.start(seconds);
    setState(() {
      currentPage = Rush10Page.challenge;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 1) {
          timeLeft--;
        } else {
          timer.cancel();
          timeLeft = 0;
          currentPage = Rush10Page.results;
        }
      });
    });
  }

  // 기존 'resetApp' 메서드 수정
  void resetApp() {
    setState(() {
      currentPage = Rush10Page.lobby;
      timeLeft = 600;
      countdown = 5;
      challengeStartTime = null;
      description = '';
    });
    // _startLobbyTimer(); // 삭제: LobbyPage에서 관리
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

  // handleImageSelect 메서드 수정
  Future<void> handleImageSelect() async {
    print('[DEBUG] handleImageSelect 호출됨');
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery, // 갤러리에서 선택 (카메라 대신)
      maxWidth: 600, 
      maxHeight: 600, 
      imageQuality: 80
    );
    
    if (picked != null) {
      print('[DEBUG] 이미지 선택됨: ${picked.path}');
      // 모든 플랫폼에서 바이트 데이터로 변환
      final bytes = await picked.readAsBytes();
      print('[DEBUG] 이미지 바이트 데이터 불러옴: ${bytes.length} 바이트');
      
      setState(() {
        // 파일 저장
        selectedImage = File(picked.path);
        // description은 초기화하지 않음
        
        // ChallengePage에서 사용하는 Participant 목록 업데이트
        if (currentPage == Rush10Page.challenge && _renderChallengePageParticipants.isNotEmpty) {
          print('[DEBUG] 참가자 목록 이미지 업데이트 시작');
          // 현재 페이지가 ChallengePage인 경우에 Participant 객체 업데이트
          _renderChallengePageParticipants[0] = Participant(
            id: currentUser.id,
            name: currentUser.nickname,
            isHost: currentUser.id == selectedRoom!.hostId,
            profileImageUrl: currentUser.profileImageUrl ?? '',
            photoBytes: bytes, // 실제 바이트 데이터 설정
          );
          print('[DEBUG] 참가자 목록 이미지 업데이트 완료');
        }
      });
    } else {
      print('[DEBUG] 이미지 선택 취소됨');
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

  // 극도로 단순화된 인증 처리 함수
  void _simpleSubmit() {
    print('\n');
    print('[SIMPLE] 인증 처리 함수 호출됨!!!');
    
    try {
      // 즉시 로비로 이동
      setState(() {
        currentPage = Rush10Page.lobby;
        print('[SIMPLE] 로비 페이지로 이동 완료!');
      });
      
      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증이 완료되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('[ERROR] 페이지 이동 중 오류: $e');
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

  // ParticipantExtended용 이미지 위젯 (기존 함수와 함께 사용)
  Widget buildExtendedImageWidget(ParticipantExtended p, {double? width, double? height, BoxFit? fit, BorderRadius? borderRadius}) {
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

  // 도전방 목록 불러오기
  Future<void> _loadRooms() async {
    final loadedRooms = await ChallengeRepository.instance.getRooms();
    setState(() {
      rooms = loadedRooms;
    });
  }

  // 도전방 생성 후 목록 새로고침
  Future<void> _onRoomCreated() async {
    await _loadRooms();
    setState(() {
      currentPage = Rush10Page.roomList;
    });
  }

  // 도전방 참가 후 목록 새로고침
  Future<void> _onRoomJoined(ChallengeRoom room) async {
    await _loadRooms();
    setState(() {
      currentPage = Rush10Page.lobby;
      // 필요한 경우 선택된 room 정보 사용
    });
  }

  // 샘플 도전방 자동 추가 함수
  Future<void> insertSampleRoomsIfNeeded() async {
    final repo = ChallengeRepository.instance;
    final rooms = await repo.getRooms();
    if (rooms.isEmpty) {
      await repo.createRoom(
        title: '10분 산책 챌린지',
        description: '함께 10분 산책해요!',
        hostName: '샘플호스트1',
        hostId: 'sample_host_1',
        startTime: DateTime.now().add(const Duration(minutes: 1)),
      );
      await repo.createRoom(
        title: '정리정돈 미션',
        description: '방을 10분만에 정리해봅시다!',
        hostName: '샘플호스트2',
        hostId: 'sample_host_2',
        startTime: DateTime.now().add(const Duration(minutes: 2)),
      );
      await repo.createRoom(
        title: '10분 스트레칭 챌린지',
        description: '간단한 스트레칭으로 몸을 풀어요.',
        hostName: '샘플호스트3',
        hostId: 'sample_host_3',
        startTime: DateTime.now().add(const Duration(minutes: 3)),
      );
    }
  }

  // LobbyPage로 이동 시 참가자 목록을 DB에서 불러와 전달
  Future<List<Participant>> _getParticipantsForRoom(ChallengeRoom room) async {
    final ids = await ChallengeRepository.instance.getRoomParticipants(room.id);

    // currentUser의 최신 정보 사용
    return ids.map((id) {
      if (id == currentUser.id) {
        return Participant(
          id: id,
          name: currentUser.nickname,
          isHost: id == room.hostId,
          profileImageUrl: currentUser.profileImageUrl ?? '',
        );
      } else {
        // 샘플 호스트 등
        return Participant(
          id: id,
          name: id,
          isHost: id == room.hostId,
          profileImageUrl: '',
        );
      }
    }).toList();
  }

  // 참가중인 방과 참가하지 않은 방 분리
  Future<Map<String, List<ChallengeRoom>>> _splitRoomsByParticipation() async {
    List<ChallengeRoom> allRooms = await ChallengeRepository.instance.getRooms();
    List<ChallengeRoom> joinedRooms = [];
    List<ChallengeRoom> notJoinedRooms = [];
    
    // 결과 출력 디버깅 추가
    print('[DEBUG] 전체 방 개수: ${allRooms.length}');
    
    for (final room in allRooms) {
      final participants = await ChallengeRepository.instance.getRoomParticipants(room.id);
      print('[DEBUG] 방 ID: ${room.id}, 참가자: $participants, 현재 사용자: ${currentUser.id}');
      
      if (participants.contains(currentUser.id)) {
        joinedRooms.add(room);
      } else {
        notJoinedRooms.add(room);
      }
    }
    
    print('[DEBUG] 참가 중인 방: ${joinedRooms.length}, 참가하지 않은 방: ${notJoinedRooms.length}');
    return {
      'joined': joinedRooms,
      'notJoined': notJoinedRooms,
    };
  }

  String getLobbyCountdownText() {
    if (selectedRoom == null) return '도전 시작 시각을 설정해주세요';
    final now = DateTime.now();
    final diff = selectedRoom!.startTime.difference(now);
    if (diff.isNegative) return '곧 도전이 시작됩니다!';
    final min = diff.inMinutes;
    final sec = diff.inSeconds % 60;
    return '도전 시작까지 ${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final maxContentWidth = 900.0;
        Widget scaffold = Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          appBar: _buildAppBar(),
          body: currentPage == Rush10Page.challenge 
              ? _renderPage() // 챌린지 페이지는 자체 스크롤을 가지므로 추가 스크롤 제거
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _renderPage(),
                ),
          floatingActionButton: (currentPage == Rush10Page.roomList)
              ? CreateRoomFAB(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateRoomPage(
                          currentUser: currentUser,
                        ),
                      ),
                    );
                    if (result != null) {
                      // 방 생성 후 목록 새로고침
                      await _onRoomCreated();
                    }
                  },
                )
              : null,
        );
        if (isDesktop) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: scaffold,
            ),
          );
        } else {
          return scaffold;
        }
      },
    );
  }

  // 앱바 빌드 함수
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
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
      actions: [
        if (currentPage == Rush10Page.challenge)
          Container(
            margin: const EdgeInsets.only(right: 16),
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
        Row(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 2,
              ),
              onPressed: () async {
                try {
                  // 웹 환경: JS SDK 사용
                  final kakao = js.context['Kakao'];
                  if (kakao != null && kakao['Auth'] != null) {
                    kakao['Auth'].callMethod('logout');
                    print('카카오 웹 로그아웃 성공');
                  } else {
                    // 모바일: Flutter SDK 사용
                    await kakao.UserApi.instance.logout();
                    print('카카오 모바일 로그아웃 성공');
                  }
                  
                  // 로그아웃 후 로그인 페이지로 이동
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginGate()),
                    );
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('로그아웃 되었습니다.'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  print('카카오 로그아웃 실패: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('카카오 로그아웃 실패: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('로그아웃'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              onPressed: () async {
                try {
                  final prefs = await SharedPreferences.getInstance();
                  final userId = currentUser.id;
                  
                  // Firestore에서 사용자 데이터 삭제
                  await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                  
                  // 로컬 저장소 데이터 삭제
                  await prefs.remove('kakao_user_id');
                  await prefs.remove('nickname');
                  await prefs.remove('current_user_name');
                  await prefs.remove('current_user_id');
                  await prefs.remove('current_user_profile_image');
                  
                  print('회원탈퇴: 사용자 정보 삭제 완료');
                  
                  // 회원탈퇴 후 로그인 페이지로 이동
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginGate()),
                    );
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('회원탈퇴가 완료되었습니다.'), backgroundColor: Colors.red),
                  );
                } catch (e) {
                  print('회원탈퇴 실패: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('회원탈퇴 실패: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('회원탈퇴'),
            ),
            const SizedBox(width: 16),
            if (currentPage == Rush10Page.roomList || currentPage == Rush10Page.lobby)
              AppBarProfile(
                profileImageUrl: currentUser.profileImageUrl,
                nickname: currentUser.nickname,
                onTap: _navigateToProfilePage,
              ),
          ],
        ),
      ],
    );
  }

  Widget _renderPage() {
    print('[DEBUG] _renderPage 호출됨 - currentPage=$currentPage');
    
    switch (currentPage) {
      case Rush10Page.roomList:
        return FutureBuilder<Map<String, List<ChallengeRoom>>>(
          future: _splitRoomsByParticipation(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final joinedRooms = snapshot.data!['joined']!;
            final notJoinedRooms = snapshot.data!['notJoined']!;
            final now = DateTime.now();
            
            // 시작 대기중인 방 (시작 전)
            final waitingRooms = joinedRooms.where((room) => room.startTime.isAfter(now)).toList();
            
            // 진행 중인 방 (시작 후, 종료 전 - 10분 이내)
            final runningRooms = joinedRooms.where((room) {
              final endTime = room.startTime.add(const Duration(minutes: 10));
              return !room.startTime.isAfter(now) && now.isBefore(endTime);
            }).toList();
            
            return RoomListPage(
              rooms: notJoinedRooms,
              waitingRooms: waitingRooms,
              runningRooms: runningRooms,
              currentUser: currentUser,
              onRoomSelected: _onRoomSelected,
            );
          },
        );
      case Rush10Page.lobby:
        if (selectedRoom == null) return const SizedBox.shrink();
        return LobbyPage(
          challengeStartTime: selectedRoom!.startTime,
          onPickTime: _pickChallengeTime,
          getLobbyCountdownText: getLobbyCountdownText,
          currentUser: currentUser,
          room: selectedRoom!,
          onRoomDeleted: () {
            setState(() {
              currentPage = Rush10Page.roomList;
              selectedRoom = null;
            });
          },
        );
      case Rush10Page.countdown:
        return const CountdownPage();
      case Rush10Page.challenge:
        print('[DEBUG-RENDER] _renderPage: Challenge 페이지 렌더링 시작');
        print('[DEBUG-RENDER] selectedRoom: ${selectedRoom?.id}');
        
        // 도전방 정보가 없으면 빈 화면을 보여줌 (레이아웃 오류 방지)
        if (selectedRoom == null) {
          print('[DEBUG-RENDER] selectedRoom이 null임');
          return const Center(
            child: Text('도전방 정보를 불러올 수 없습니다', style: TextStyle(color: Colors.grey)),
          );
        }
        
        // ChallengeTimer 설정 확인
        final timer = ChallengeTimer.instance;
        if (!timer.isRunning) {
          print('[DEBUG-RENDER] 타이머가 실행 중이 아니어서 시작함');
          final now = DateTime.now();
          final start = selectedRoom!.startTime;
          final end = start.add(const Duration(minutes: 10));
          final seconds = end.difference(now).inSeconds.clamp(0, 600);
          timer.start(seconds);
        }
        
        // Participant 목록 초기화 (이미지 선택에서 사용됨)
        _renderChallengePageParticipants = [
          Participant(
            id: currentUser.id,
            name: currentUser.nickname,
            isHost: currentUser.id == selectedRoom!.hostId,
            profileImageUrl: currentUser.profileImageUrl ?? '',
            photoBytes: null, // 초기에는 null로 설정
          )
        ];
        
        // 이미지가 선택되어 있으면 바이트 데이터 설정
        if (selectedImage != null) {
          print('[DEBUG-RENDER] 선택된 이미지가 있음, 바이트 데이터 설정');
          // 비동기 작업이지만 UI 업데이트를 위해 즉시 Future 처리
          selectedImage!.readAsBytes().then((bytes) {
            if (_renderChallengePageParticipants.isNotEmpty) {
              setState(() {
                _renderChallengePageParticipants[0] = Participant(
                  id: currentUser.id,
                  name: currentUser.nickname,
                  isHost: currentUser.id == selectedRoom!.hostId,
                  profileImageUrl: currentUser.profileImageUrl ?? '',
                  photoBytes: bytes, // 실제 바이트 데이터
                );
              });
              print('[DEBUG-RENDER] 이미지 바이트 데이터 설정 완료: ${bytes.length} 바이트');
            }
          });
        }
        
        print('[DEBUG-RENDER] ChallengePage 위젯 생성 시작');
        print('[DEBUG-RENDER] _simpleSubmit 함수: ${_simpleSubmit.runtimeType}');
        print('[DEBUG-RENDER] _simpleImageSelect 함수: ${_simpleImageSelect.runtimeType}');
        
        final challengePage = ChallengePage(
          currentUserId: currentUser.id,
          description: description,
          onDescriptionChanged: (value) { 
            print('[DEBUG-INPUT] 설명 변경됨: "$value"');
            setState(() { 
              description = value; 
            });
          },
          participants: _renderChallengePageParticipants,
          handleImageSelect: _simpleImageSelect,
          handleSubmit: _simpleSubmit,
          buildImageWidget: buildImageWidget,
          room: selectedRoom!,
          currentUser: currentUser,
          isSubmitting: isSubmitting,
          onBackToHome: () {
            setState(() { currentPage = Rush10Page.roomList; });
          },
          onBackToLobby: () {
            setState(() { currentPage = Rush10Page.lobby; });
          },
        );
        
        print('[DEBUG-RENDER] ChallengePage 위젯 생성 완료');
        
        return WillPopScope(
          onWillPop: () async {
            print('[DEBUG-RENDER] ChallengePage - WillPopScope 호출됨');
            setState(() { currentPage = Rush10Page.lobby; });
            return false;
          },
          child: challengePage,
        );
      case Rush10Page.results:
        return ResultsPage(
          participants: [
            Participant(
              id: currentUser.id,
              name: currentUser.nickname,
              isHost: true,
            )
          ],
          resetApp: resetApp,
          buildImageWidget: buildImageWidget,
        );
    }
  }

  // 이미 참가한 방인지 확인하는 도우미 메서드
  Future<bool> _isAlreadyJoined(String roomId) async {
    final participants = await ChallengeRepository.instance.getRoomParticipants(roomId);
    return participants.contains(currentUser.id);
  }

  // onRoomSelected 함수 (방 선택 시 호출)
  void _onRoomSelected(ChallengeRoom room) async {
    print('[DEBUG] 방 선택됨: roomId=${room.id}, 현재 사용자: ${currentUser.id}');
    
    try {
      // 방에 참가 시도
      final alreadyJoined = await _isAlreadyJoined(room.id);
      print('[DEBUG] 이미 참가 여부: $alreadyJoined');
      
      if (!alreadyJoined) {
        print('[DEBUG] 새로운 방 참가 시도: ${room.id}');
        
        // 참가 전 참가자 목록 확인
        final beforeParticipants = await ChallengeRepository.instance.getRoomParticipants(room.id);
        print('[DEBUG] 참가 전 참가자 목록: $beforeParticipants');
        
        // 참가 시도
        final joinSuccess = await ChallengeRepository.instance.joinRoom(room.id, currentUser.id);
        
        // 참가 후 참가자 목록 확인
        final afterParticipants = await ChallengeRepository.instance.getRoomParticipants(room.id);
        print('[DEBUG] 참가 후 참가자 목록: $afterParticipants');
        
        if (joinSuccess) {
          print('[DEBUG] 방 참가 성공! roomId=${room.id}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('방에 참가했습니다.'), backgroundColor: Colors.green)
          );
        } else {
          print('[ERROR] 방 참가 실패! roomId=${room.id}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('방 참가에 실패했습니다. 다시 시도해주세요.'), backgroundColor: Colors.red)
          );
          return;
        }
      } else {
        print('[DEBUG] 이미 참가한 방입니다. roomId=${room.id}');
      }
      
      // 참가자 목록 업데이트
      final participants = await ChallengeRepository.instance.getRoomParticipants(room.id);
      print('[DEBUG] 최종 참가자 목록: $participants');
      
      setState(() {
        currentPage = Rush10Page.lobby;
        selectedRoom = room;
        selectedRoomParticipants = participants;
      });
    } catch (e) {
      print('[ERROR] 방 참가 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e'), backgroundColor: Colors.red)
      );
    }
  }

  // 이미지 선택 함수 - 프로필 이미지 선택과 동일하게 구현
  void _simpleImageSelect() async {
    // 프로필 이미지 선택과 완전히 동일한 코드 구현
    print('[DEBUG] 이미지 선택 시작 (프로필 이미지 선택 코드와 동일하게 구현)');
    
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 90,
    );

    if (image != null) {
      print('[DEBUG] 이미지 선택됨: ${image.path}');
      
      // 이미지 데이터 읽기
      final bytes = await image.readAsBytes();
      print('[DEBUG] 이미지 데이터 크기: ${bytes.length} 바이트');
      
      // UI 업데이트
      setState(() {
        selectedImage = File(image.path);
        
        // 참가자 목록 업데이트
        if (_renderChallengePageParticipants.isNotEmpty) {
          _renderChallengePageParticipants[0] = Participant(
            id: currentUser.id,
            name: currentUser.nickname,
            isHost: currentUser.id == selectedRoom?.hostId,
            profileImageUrl: currentUser.profileImageUrl ?? '',
            photoBytes: bytes,
          );
          
          // 로그 출력
          print('[DEBUG] 참가자 이미지 업데이트됨');
        }
      });
      
      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지가 선택되었습니다'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      print('[DEBUG] 이미지 선택 취소됨');
    }
  }
}