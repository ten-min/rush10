// Complete fixed solution for the timer issue in room_list_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/challenge_room.dart';
import '../models/user.dart';
import 'join_room_page.dart';
import '../repositories/challenge_repository.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'widgets/room_card.dart';
import 'widgets/common_button.dart';
import 'widgets/horizontal_room_card.dart';
import '../constants/strings.dart';
import 'completed_challenges_page.dart';

class RoomListPage extends StatefulWidget {
  final List<ChallengeRoom> rooms;
  final List<ChallengeRoom> waitingRooms; // 시작 대기중인 방 목록
  final List<ChallengeRoom> runningRooms; // 종료 대기중인 방 목록
  final Function(ChallengeRoom) onRoomSelected;
  final User currentUser;

  const RoomListPage({
    Key? key,
    required this.rooms,
    required this.waitingRooms,
    required this.runningRooms,
    required this.onRoomSelected,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showJoinRoomPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JoinRoomPage(
          currentUser: widget.currentUser,
          onRoomJoined: (room) {
            Navigator.pop(context);
            widget.onRoomSelected(room);
          },
        ),
      ),
    );
  }

  void _showCreateRoomPage(BuildContext context) {
    // TODO: 실제 CreateRoomPage가 있으면 아래 주석 해제
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => CreateRoomPage(
    //       currentUser: widget.currentUser,
    //       onRoomCreated: (room) {
    //         Navigator.pop(context);
    //         // 새로고침 등 필요시 추가
    //       },
    //     ),
    //   ),
    // );
    // 임시: 생성 기능 안내
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('도전방 생성 기능은 곧 지원됩니다!')),
    );
  }

  void _navigateToCompletedChallenges(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompletedChallengesPage(
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 버튼 영역
          Row(
            children: [
              CommonButton(
                text: AppStrings.joinRoom,
                icon: Icons.login,
                onPressed: () => _showJoinRoomPage(context),
                expanded: true,
              ),
              const SizedBox(width: 16),
              CommonButton(
                text: '완료 목록',
                icon: Icons.history,
                onPressed: () => _navigateToCompletedChallenges(context),
                expanded: true,
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 시작 대기중 섹션
          if (widget.waitingRooms.isNotEmpty) ...[
            const Text(
              '시작 대기중',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A4FF3),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: _HorizontalScrollWithWheel(
                height: 120,
                builder: (controller) => ListView.builder(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  primary: false,
                  itemCount: widget.waitingRooms.length,
                  itemBuilder: (context, index) {
                    final room = widget.waitingRooms[index];
                    final now = DateTime.now();
                    final timeLeft = room.startTime.difference(now);
                    String timeLeftText;
                    if (timeLeft.isNegative) {
                      timeLeftText = '곧 시작';
                    } else {
                      final minutes = timeLeft.inMinutes;
                      final seconds = timeLeft.inSeconds % 60;
                      timeLeftText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                    }
                    return HorizontalRoomCard(
                      room: room,
                      onTap: () => widget.onRoomSelected(room),
                      statusText: AppStrings.waiting,
                      timerText: timeLeftText,
                      statusColor: const Color(0xFF5A4FF3),
                      isWaiting: true,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 종료 대기중 섹션
          if (widget.runningRooms.isNotEmpty) ...[
            const Text(
              '종료 대기중',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A4FF3),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: _HorizontalScrollWithWheel(
                height: 120,
                builder: (controller) => ListView.builder(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  primary: false,
                  itemCount: widget.runningRooms.length,
                  itemBuilder: (context, index) {
                    final room = widget.runningRooms[index];
                    final now = DateTime.now();
                    final endTime = room.startTime.add(const Duration(minutes: 10));
                    final timeLeft = endTime.difference(now);
                    String timeLeftText;
                    if (timeLeft.isNegative) {
                      timeLeftText = '인증 검증중';
                    } else {
                      final minutes = timeLeft.inMinutes;
                      final seconds = timeLeft.inSeconds % 60;
                      timeLeftText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                    }
                    return HorizontalRoomCard(
                      room: room,
                      onTap: () => widget.onRoomSelected(room),
                      statusText: AppStrings.running,
                      timerText: timeLeftText,
                      statusColor: Colors.orange,
                      isRunning: true,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          const Text(
            '도전방 목록',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(widget.rooms.length, (index) {
            final room = widget.rooms[index];
            return RoomCard(
              room: room,
              onTap: () => widget.onRoomSelected(room),
              isJoined: false,
              isWaiting: false,
              isRunning: false,
            );
          }),
        ],
      ),
    );
  }
}

class _HorizontalScrollWithWheel extends StatefulWidget {
  final double height;
  final Widget Function(ScrollController controller) builder;

  const _HorizontalScrollWithWheel({
    Key? key,
    required this.height,
    required this.builder,
  }) : super(key: key);

  @override
  State<_HorizontalScrollWithWheel> createState() => _HorizontalScrollWithWheelState();
}

class _HorizontalScrollWithWheelState extends State<_HorizontalScrollWithWheel> {
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          // 마우스 휠을 좌우 스크롤로 변환 (부드러운 애니메이션)
          final newOffset = (_controller.offset + event.scrollDelta.dy).clamp(
            0.0,
            _controller.position.maxScrollExtent,
          );
          _controller.animateTo(
            newOffset,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      },
      child: SizedBox(
        height: widget.height,
        child: Scrollbar(
          thumbVisibility: true,
          controller: _controller,
          child: widget.builder(_controller),
        ),
      ),
    );
  }
}