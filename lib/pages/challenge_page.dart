import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/participant.dart';
import '../models/challenge_room.dart';
import '../models/user.dart';
import '../utils/challenge_timer.dart';
import '../utils/time_utils.dart';
import '../pages/lobby_page.dart';
import '../pages/room_list_page.dart';
import '../main.dart'; // Rush10App과 navigatorKey 접근
import '../repositories/certification_repository.dart'; // 추가: 인증 저장소
import 'package:image_picker/image_picker.dart';

class ChallengePage extends StatefulWidget {
  final String currentUserId;
  final String description;
  final Function(String) onDescriptionChanged;
  final List<Participant> participants;
  final VoidCallback handleImageSelect;
  final VoidCallback handleSubmit;
  final Widget Function(Participant, {double? width, double? height, BoxFit? fit, BorderRadius? borderRadius}) buildImageWidget;
  final ChallengeRoom room;
  final User currentUser;
  final VoidCallback? onBackToHome;
  final VoidCallback? onBackToLobby;
  bool isSubmitting; // final 키워드 제거됨 - 인증 제출 중인지 여부

  ChallengePage({
    Key? key,
    required this.currentUserId,
    required this.description,
    required this.onDescriptionChanged,
    required this.participants,
    required this.handleImageSelect,
    required this.handleSubmit,
    required this.buildImageWidget,
    required this.room,
    required this.currentUser,
    this.onBackToHome,
    this.onBackToLobby,
    this.isSubmitting = false, // 기본값 false
  }) : super(key: key);

  @override
  State<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  late ChallengeTimer timer;
  late TextEditingController _textController;
  Uint8List? _localPhotoBytes; // 로컬에서 선택된 이미지 바이트 관리

  @override
  void initState() {
    super.initState();
    timer = ChallengeTimer.instance;
    timer.addListener(_onTick);
    _textController = TextEditingController(text: widget.description);
    
    // 첫 프레임이 렌더링된 후에 타이머 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final start = widget.room.startTime;
      final end = start.add(const Duration(minutes: 10));
      final seconds = end.difference(now).inSeconds.clamp(0, 600);
      
      // 디버그 로그 추가
      print('ChallengePage - initState: 타이머 시작, seconds=$seconds, 현재 시간=$now, 시작 시간=$start, 종료 시간=$end');
      print('ChallengePage - initState: 참가자 정보=${widget.participants}');
      
      timer.start(seconds);
    });
  }

  void _onTick() => setState(() {});

  @override
  void dispose() {
    timer.removeListener(_onTick);
    _textController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChallengePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부에서 description이 변경되면 컨트롤러 업데이트
    if (widget.description != oldWidget.description) {
      print('[DEBUG] didUpdateWidget - description 변경: "${oldWidget.description}" -> "${widget.description}"');
      _textController.text = widget.description;
      // 텍스트 컨트롤러 업데이트 후 상태 갱신
      setState(() {});
    }
  }

  // 이미지 선택 함수 직접 구현
  Future<void> _selectImage() async {
    print('[LOCAL-DEBUG] _selectImage 함수 호출됨');
    try {
      final picker = ImagePicker();
      print('[LOCAL-DEBUG] 이미지 선택 창 열기 시도');
      
      // 이미지 선택 팝업 직접 호출
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('갤러리에서 선택'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('카메라로 촬영'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickFromCamera();
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('[LOCAL-DEBUG] 이미지 선택 메뉴 표시 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 선택 기능 오류: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // 갤러리에서 이미지 선택
  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );
      
      await _processSelectedImage(image);
    } catch (e) {
      print('[LOCAL-DEBUG] 갤러리에서 이미지 선택 오류: $e');
    }
  }
  
  // 카메라로 사진 촬영
  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );
      
      await _processSelectedImage(image);
    } catch (e) {
      print('[LOCAL-DEBUG] 카메라로 사진 촬영 오류: $e');
    }
  }
  
  // 이미지 처리 공통 로직
  Future<void> _processSelectedImage(XFile? image) async {
    if (image != null) {
      print('[LOCAL-DEBUG] 이미지 선택 성공: ${image.path}');
      try {
        final bytes = await image.readAsBytes();
        print('[LOCAL-DEBUG] 이미지 바이트 크기: ${bytes.length}');
        
        // 이미지 데이터를 로컬 상태로 관리
        setState(() {
          _localPhotoBytes = bytes;
        });
        
        // 부모에게 알림 (상태 업데이트)
        widget.handleImageSelect();
        
        // 성공 메시지
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미지가 추가되었습니다'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        print('[LOCAL-DEBUG] 이미지 처리 오류: $e');
      }
    } else {
      print('[LOCAL-DEBUG] 이미지 선택 취소됨');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로그 간소화
    print('[DEBUG] ChallengePage 빌드 - ${widget.room.id}');
    
    // 로컬 이미지가 있으면 그것을 우선 사용
    final my = widget.participants.firstWhere(
      (p) => p.id == widget.currentUserId, 
      orElse: () => widget.participants.first
    );
    
    // 로컬 상태에 이미지가 있는지 확인
    final isPhotoReady = _localPhotoBytes != null || my.photoBytes != null;
    
    // TextField의 현재 값을 직접 확인하여 실시간 내용 반영 (controller가 더 정확할 수 있음)
    final hasDescription = _textController.text.trim().isNotEmpty;
    
    // 인증 가능 조건: 사진이 있거나 설명이 있어야 함 (둘 중 하나만 있어도 됨)
    final canSubmit = isPhotoReady || hasDescription;
    
    print('[DEBUG] ChallengePage.build() - 참가자 정보: ${widget.participants}, my: $my');
    print('[DEBUG] ChallengePage.build() - 인증 버튼 활성화 조건: isPhotoReady=$isPhotoReady (photoBytes=${my.photoBytes != null ? "있음(${my.photoBytes!.length}바이트)" : "없음"}), hasDescription=$hasDescription (controller.text="${_textController.text}"), canSubmit=$canSubmit');

    return WillPopScope(
      onWillPop: () async {
        print('[DEBUG] ChallengePage - 물리적 뒤로가기 버튼 눌림');
        // 그냥 이전 화면으로 돌아가기
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF5A4FF3)),
            onPressed: () {
              print('[DEBUG] ChallengePage - 뒤로가기 버튼 클릭');
              // 단순히 이전 화면으로 돌아가기
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                print('[DEBUG] ChallengePage - 홈으로 버튼 클릭');
                // 홈으로 가기 처리
                Navigator.of(context).popUntil((route) => route.isFirst);
                // 추가로 홈 상태를 설정
                MyApp.goToHome();
              },
              icon: const Icon(Icons.home, color: Color(0xFF5A4FF3)),
              label: const Text('홈으로', style: TextStyle(color: Color(0xFF5A4FF3))),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: SafeArea(
          child: SizedBox.expand(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('10분 도전 중', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 8),
                          Text(formatTime(timer.secondsLeft), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'RobotoMono')),
                        ],
                      ),
                    ),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.65,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 제목
                          const Text('인증하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          
                          // 설명 입력 필드
                          const Text('인증 설명', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: InputDecoration(
                              hintText: '도전에 대한 설명을 남겨주세요...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: const Color(0xFFF6F7FB),
                            ),
                            onChanged: (value) {
                              print('[DEBUG] TextField 내용 변경: "$value"');
                              widget.onDescriptionChanged(value);
                              // 상태 즉시 갱신하여 버튼 활성화 여부를 업데이트
                              setState(() {});
                            },
                            maxLines: 2,
                            controller: _textController,
                          ),
                          const SizedBox(height: 16),
                          
                          // 인증 사진 제목
                          const Text('인증 사진 (선택사항)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                          const SizedBox(height: 8),
                          
                          // 선택된 이미지 표시 영역 - InkWell로 감싸기
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _selectImage, // 로컬 함수 사용
                              borderRadius: BorderRadius.circular(12),
                              child: Ink(
                                width: double.infinity,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F7FB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isPhotoReady ? Colors.green : Colors.grey[300]!),
                                ),
                                child: isPhotoReady 
                                  ? _localPhotoBytes != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          _localPhotoBytes!,
                                          width: double.infinity,
                                          height: 150,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : widget.buildImageWidget(
                                        my, 
                                        width: double.infinity, 
                                        height: 150, 
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(12)
                                      )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.add_photo_alternate, size: 48, color: Color(0xFF5A4FF3)),
                                        SizedBox(height: 8),
                                        Text(
                                          '클릭하여 사진 추가',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF5A4FF3),
                                          ),
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canSubmit ? const Color(0xFF5A4FF3) : Colors.grey[300], 
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: !canSubmit || widget.isSubmitting ? null : () async {
                        print('\n');
                        print('[DEBUG-BUTTON] ========== 인증 버튼 클릭 이벤트 ==========');
                        print('[DEBUG-BUTTON] 인증 데이터 저장 및 로비로 이동합니다');
                        
                        // 로딩 상태 표시
                        setState(() {
                          widget.isSubmitting = true; // 제출 중 상태로 변경
                        });
                        
                        try {
                          // 인증 데이터 생성 및 저장
                          Uint8List? photoBytes;
                          
                          // 참가자 목록에서 현재 사용자의 사진 가져오기
                          final my = widget.participants.firstWhere(
                            (p) => p.id == widget.currentUserId, 
                            orElse: () => widget.participants.first
                          );
                          
                          if (my.photoBytes != null) {
                            photoBytes = my.photoBytes;
                            print('[DEBUG-BUTTON] 이미지 바이트 데이터 확인: ${photoBytes?.length} 바이트');
                          } else if (_localPhotoBytes != null) {
                            // 로컬에서 선택한 이미지 사용
                            photoBytes = _localPhotoBytes;
                            print('[DEBUG-BUTTON] 로컬 이미지 바이트 데이터 확인: ${photoBytes?.length} 바이트');
                          } else {
                            print('[DEBUG-BUTTON] 이미지 바이트 데이터 없음');
                          }
                          
                          if (photoBytes == null || photoBytes.isEmpty) {
                            print('[DEBUG-BUTTON] 유효한 이미지 없음, 텍스트만 저장합니다.');
                          }
                          
                          // 빈 바이트 배열 대신 null을 전달
                          final actualPhotoBytes = (photoBytes != null && photoBytes.isNotEmpty) ? photoBytes : Uint8List(0);
                          
                          // CertificationRepository를 사용하여 인증 데이터 저장
                          final result = await CertificationRepository.instance.createPost(
                            roomId: widget.room.id,
                            userId: widget.currentUserId,
                            username: widget.currentUser.nickname,
                            description: _textController.text.trim(),
                            photoBytes: actualPhotoBytes,
                            profileImagePath: widget.currentUser.profileImageUrl,
                          );
                          
                          print('[DEBUG-BUTTON] 인증 저장 완료! ID: ${result.id}');
                          
                          // 성공 메시지 표시
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('인증이 완료되었습니다!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          
                          // 로딩 상태 해제하고 이전 화면으로 돌아가기
                          if (mounted) {
                            setState(() {
                              widget.isSubmitting = false;
                            });
                            
                            // 이전 화면으로 돌아가기
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          print('[ERROR] 인증 저장 중 오류 발생: $e');
                          print(e.toString());
                          
                          // 오류 메시지 표시
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('인증 저장 중 오류가 발생했습니다: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            
                            // 로딩 상태 해제
                            setState(() {
                              widget.isSubmitting = false;
                            });
                          }
                        }
                      },
                      child: widget.isSubmitting
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Text(
                            '인증 완료하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}