import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/challenge_room.dart';

class RoomListPage extends StatelessWidget {
  final List<ChallengeRoom> rooms;
  final Function(ChallengeRoom) onRoomSelected;
  final List<ChallengeRoom> pendingRooms; // 종료 대기중인 방 목록


  const RoomListPage({
    Key? key,
    required this.rooms,
    required this.onRoomSelected,
    this.pendingRooms = const [], // 기본값 빈 리스트
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

                // 종료 대기중 섹션 (상단에 배치)
        if (pendingRooms.isNotEmpty) ...[
          const Text(
            '종료 대기중',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A4FF3),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: pendingRooms.isEmpty ? 0 : 100, // 높이 조정
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pendingRooms.length,
              itemBuilder: (context, index) {
                final room = pendingRooms[index];
                final now = DateTime.now();
                final endTime = room.startTime.add(const Duration(minutes: 10)); // 시작 시간 + 10분
                final timeLeft = endTime.difference(now);
                
                // 남은 시간 계산 및 포맷
                String timeLeftText;
                if (timeLeft.isNegative) {
                  timeLeftText = '인증 검증중';
                } else {
                  final minutes = timeLeft.inMinutes;
                  final seconds = timeLeft.inSeconds % 60;
                  timeLeftText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                }
                
                return Container(
                  width: 240,
                  margin: const EdgeInsets.only(right: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EAFE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          room.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A4FF3),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5A4FF3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeLeftText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24), // 섹션 간 간격
        ],



        const Text(
          '도전방 목록',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final startTime = DateFormat('HH:mm').format(room.startTime);
              
              return GestureDetector(
                onTap: () => onRoomSelected(room),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF5A4FF3),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                room.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    startTime,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.description,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFFE7EAFE),
                                      radius: 14,
                                      child: Text(
                                        room.hostName.substring(0, 1),
                                        style: const TextStyle(
                                          color: Color(0xFF5A4FF3),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${room.hostName} 님',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      color: Color(0xFF5A4FF3),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text('${room.participantCount}명'),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}