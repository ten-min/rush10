import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/challenge_room.dart';
import '../models/user.dart';
import '../repositories/challenge_repository.dart';
import '../pages/certification_board_page.dart';

class CompletedChallengesPage extends StatefulWidget {
  final User currentUser;

  const CompletedChallengesPage({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<CompletedChallengesPage> createState() => _CompletedChallengesPageState();
}

class _CompletedChallengesPageState extends State<CompletedChallengesPage> {
  List<ChallengeRoom>? _completedRooms;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedRooms();
  }

  Future<void> _loadCompletedRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 사용자가 참여한 모든 방 로드
      final userRooms = await ChallengeRepository.instance.getUserRooms(widget.currentUser.userId);
      
      // 현재 시간 기준으로 종료된 방만 필터링 (10분 도전 시간 지난 방)
      final now = DateTime.now();
      final completed = userRooms.where((room) {
        final endTime = room.startTime.add(const Duration(minutes: 10));
        return now.isAfter(endTime);
      }).toList();
      
      setState(() {
        _completedRooms = completed;
        _isLoading = false;
      });
      
      print('[DEBUG] 완료된 도전 방 로드: ${completed.length}개');
    } catch (e) {
      print('[ERROR] 완료된 방 로드 중 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '완료된 도전 목록',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5A4FF3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _completedRooms == null || _completedRooms!.isEmpty
              ? _buildEmptyState()
              : _buildCompletedList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '완료된 도전이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '10분 도전이 완료되면 여기에 표시됩니다',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedList() {
    // 시작 시간 기준 내림차순 정렬 (최신순)
    final sortedRooms = List<ChallengeRoom>.from(_completedRooms!)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedRooms.length,
      itemBuilder: (context, index) {
        final room = sortedRooms[index];
        final endTime = room.startTime.add(const Duration(minutes: 10));
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              // 인증 목록 페이지로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CertificationBoardPage(
                    room: room,
                    currentUserId: widget.currentUser.userId,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A4FF3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '완료됨',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5A4FF3),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('yyyy년 MM월 dd일 HH:mm').format(room.startTime),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    room.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    room.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Color(0xFF5A4FF3)),
                      const SizedBox(width: 4),
                      Text(
                        '도전 종료: ${DateFormat('HH:mm').format(endTime)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5A4FF3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // 인증 목록 페이지로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CertificationBoardPage(
                              room: room,
                              currentUserId: widget.currentUser.userId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('인증 결과 보기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A4FF3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 