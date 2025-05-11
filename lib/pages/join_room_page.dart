import 'package:flutter/material.dart';
import '../models/challenge_room.dart';
import '../repositories/challenge_repository.dart';
import '../models/user.dart';
import 'package:collection/collection.dart';

class JoinRoomPage extends StatefulWidget {
  final User currentUser;
  final Function(ChallengeRoom) onRoomJoined;

  const JoinRoomPage({
    Key? key,
    required this.currentUser,
    required this.onRoomJoined,
  }) : super(key: key);

  @override
  State<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends State<JoinRoomPage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = '도전방 코드를 입력해주세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 도전방 목록 조회
      final rooms = await ChallengeRepository.instance.getRooms();
      
      // 코드로 도전방 찾기
      final room = rooms.firstWhereOrNull((room) => room.code == code);
      if (room == null) {
        setState(() {
          _errorMessage = '도전방을 찾을 수 없습니다';
        });
        return;
      }

      // 이미 시작된 도전방인지 확인
      if (DateTime.now().isAfter(room.startTime)) {
        throw Exception('이미 시작된 도전방입니다');
      }

      // 도전방 참가
      final success = await ChallengeRepository.instance.joinRoom(
        room.id,
        widget.currentUser.id,
      );

      if (success) {
        if (mounted) {
          widget.onRoomJoined(room);
        }
      } else {
        throw Exception('도전방 참가에 실패했습니다');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('도전방 참가하기'),
        backgroundColor: const Color(0xFF5A4FF3),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '도전방 코드 입력',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '도전방 호스트가 공유한 코드를 입력해주세요.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: '도전방 코드 입력 (예: RUSH123456)',
                prefixIcon: const Icon(Icons.key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF5A4FF3),
                    width: 2,
                  ),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _joinRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A4FF3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '참가하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 