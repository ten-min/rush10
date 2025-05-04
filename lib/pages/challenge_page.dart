import 'package:flutter/material.dart';
import '../models/participant.dart';
import '../utils/time_formatter.dart';

class ChallengePage extends StatelessWidget {
  final int timeLeft;
  final String description;
  final Function(String) onDescriptionChanged;
  final List<Participant> participants;
  final Function() handleImageSelect;
  final Function() handleSubmit;
  final Function(Participant, {double? width, double? height, BoxFit? fit, BorderRadius? borderRadius}) buildImageWidget;

  const ChallengePage({
    Key? key,
    required this.timeLeft,
    required this.description,
    required this.onDescriptionChanged,
    required this.participants,
    required this.handleImageSelect,
    required this.handleSubmit,
    required this.buildImageWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final my = participants.firstWhere((p) => p.id == 1);
    final isPhotoReady = my.photoBytes != null;

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
              const Text('10분 도전 중', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(formatTime(timeLeft), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'RobotoMono')),
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
                const Text('인증하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: handleImageSelect,
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(color: isPhotoReady ? Colors.green : Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF6F7FB),
                    ),
                    child: isPhotoReady
                        ? Stack(
                            children: [
                              buildImageWidget(my, width: double.infinity, height: 140, fit: BoxFit.cover, borderRadius: BorderRadius.circular(12)),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    // 이 부분은 StatefulWidget에서 처리해야 합니다.
                                    // 이벤트 핸들러를 전달받아 사용하는 방식으로 변경해야 합니다.
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.camera_alt, color: Colors.grey, size: 40),
                              SizedBox(height: 8),
                              Text('사진 촬영 또는 업로드', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: '도전에 대한 설명을 남겨주세요...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: const Color(0xFFF6F7FB),
                  ),
                  onChanged: onDescriptionChanged,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: (isPhotoReady && description.trim().isNotEmpty) ? const Color(0xFF5A4FF3) : Colors.grey[300],
            foregroundColor: (isPhotoReady && description.trim().isNotEmpty) ? Colors.white : Colors.grey,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          onPressed: (isPhotoReady && description.trim().isNotEmpty) 
          ? handleSubmit 
          : null,
          child: const Text('인증 완료하기'),
        ),
      ],
    );
  }
}