import 'dart:async';
import 'package:flutter/material.dart';

class ChallengeTimer extends ChangeNotifier {
  static final ChallengeTimer instance = ChallengeTimer._internal();
  ChallengeTimer._internal();

  Timer? _timer;
  int _secondsLeft = 0;
  bool _isRunning = false;

  int get secondsLeft => _secondsLeft;
  bool get isRunning => _isRunning;

  void start(int seconds) {
    _timer?.cancel();
    _secondsLeft = seconds;
    _isRunning = true;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        _secondsLeft--;
        notifyListeners();
      } else {
        stop();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void reset(int seconds) {
    stop();
    start(seconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
} 