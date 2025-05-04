import 'package:flutter/material.dart';

class CountdownPage extends StatelessWidget {
  final int countdown;

  const CountdownPage({
    Key? key,
    required this.countdown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$countdown', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Color(0xFF5A4FF3))),
          const SizedBox(height: 24),
          const Text('잠시 후 도전이 시작됩니다!', style: TextStyle(fontSize: 20, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text('준비하세요...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}