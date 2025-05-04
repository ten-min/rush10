import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/participant.dart';

class LobbyPage extends StatelessWidget {
  final List<Participant> participants;
  final DateTime? challengeStartTime;
  final Function() onPickTime;
  final Function() getLobbyCountdownText;

  const LobbyPage({
    Key? key,
    required this.participants,
    required this.challengeStartTime,
    required this.onPickTime,
    required this.getLobbyCountdownText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isHost = participants.firstWhere((p) => p.id == 1).isHost;
    
    return Column(
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
              const Text('10분 내에 집 주변 한 바퀴 산책하기 🏃‍♂️', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 16),
              if (challengeStartTime != null)
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text('시작 시각: ${DateFormat('HH:mm').format(challengeStartTime!)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  ...participants.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFE7EAFE),
                              child: Text(p.name.substring(0, 1), style: const TextStyle(color: Color(0xFF5A4FF3), fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Text(p.name, style: const TextStyle(fontSize: 15)),
                            if (p.isHost)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE7EAFE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('방장', style: TextStyle(color: Color(0xFF5A4FF3), fontSize: 12)),
                                ),
                              ),
                          ],
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
                        child: const Text('RUSH429', style: TextStyle(fontWeight: FontWeight.bold)),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(getLobbyCountdownText().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (isHost)
                    ElevatedButton(
                      onPressed: onPickTime,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A4FF3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('시작 시각 설정'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}