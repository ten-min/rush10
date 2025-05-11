import 'package:flutter/material.dart';
import '../models/user.dart';
import '../repositories/challenge_repository.dart';
import '../models/challenge_room.dart';

class CreateRoomPage extends StatefulWidget {
  final User currentUser;

  const CreateRoomPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _startTime = DateTime.now().add(const Duration(minutes: 5));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final room = await ChallengeRepository.instance.createRoom(
        title: _titleController.text,
        description: _descriptionController.text,
        hostName: widget.currentUser.nickname,
        hostId: widget.currentUser.id,
        startTime: _startTime,
      );

      if (mounted) {
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('도전방이 생성되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );

        // 대기실로 이동
        Navigator.pop(context, room);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectStartTime() async {
    final now = DateTime.now();
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );

    if (time != null) {
      final today = DateTime(now.year, now.month, now.day);
      final picked = DateTime(
        today.year,
        today.month,
        today.day,
        time.hour,
        time.minute,
      );

      if (picked.isBefore(now)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('시작 시간은 현재 시간 이후여야 합니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _startTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('도전방 만들기'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 제목 입력
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '도전 제목',
                    hintText: '예) 10분 산책하기',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '제목을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 설명 입력
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '도전 설명',
                    hintText: '도전에 대해 자세히 설명해주세요',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '설명을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 시작 시간 선택
                ListTile(
                  title: const Text('시작 시간'),
                  subtitle: Text(
                    '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 24),
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: _selectStartTime,
                  tileColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 32),

                // 생성 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _createRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A4FF3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                          '도전방 만들기',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 