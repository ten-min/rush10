import 'package:flutter/material.dart';
import '../models/participant.dart';

class ResultsPage extends StatelessWidget {
  final List<Participant> participants;
  final Function() resetApp;
  final Function(Participant, {double? width, double? height, BoxFit? fit, BorderRadius? borderRadius}) buildImageWidget;

  const ResultsPage({
    Key? key,
    required this.participants,
    required this.resetApp,
    required this.buildImageWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final successCount = participants.where((p) => p.completed).length;
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
            children: [
              const Text('도전 완료!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text('총 $successCount명이 도전에 성공했습니다', style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.emoji_events, color: Color(0xFF5A4FF3)),
                    SizedBox(width: 8),
                    Text('도전 결과', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: participants.map((p) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              color: const Color(0xFFF6F7FB),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFE7EAFE),
                                    child: Text(p.name.substring(0, 1), style: const TextStyle(color: Color(0xFF5A4FF3), fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  if (p.completed)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                                          SizedBox(width: 4),
                                          Text('성공', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.close, color: Colors.red, size: 16),
                                          SizedBox(width: 4),
                                          Text('실패', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (p.completed && p.photoBytes != null)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildImageWidget(p, width: double.infinity, height: 120, fit: BoxFit.cover, borderRadius: BorderRadius.circular(8)),
                                  if (p.description.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(p.description, style: const TextStyle(fontSize: 14)),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5A4FF3),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          onPressed: resetApp,
          child: const Text('새로운 도전 시작하기'),
        ),
      ],
    );
  }
}