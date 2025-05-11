import 'package:flutter/material.dart';
import '../utils/challenge_timer.dart';

class CountdownPage extends StatefulWidget {
  const CountdownPage({Key? key}) : super(key: key);

  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  late ChallengeTimer timer;

  @override
  void initState() {
    super.initState();
    timer = ChallengeTimer.instance;
    timer.addListener(_onTick);
  }

  void _onTick() => setState(() {});

  @override
  void dispose() {
    timer.removeListener(_onTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${timer.secondsLeft}', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Color(0xFF5A4FF3))),
          const SizedBox(height: 24),
          const Text('잠시 후 도전이 시작됩니다!', style: TextStyle(fontSize: 20, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text('준비하세요...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
