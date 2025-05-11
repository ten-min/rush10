String formatTime(int seconds) {
  final mins = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds % 60).toString().padLeft(2, '0');
  return '$mins:$secs';
}

String getLobbyCountdownText(DateTime? challengeStartTime) {
  if (challengeStartTime == null) return '도전 시작 시각을 설정해주세요';
  final now = DateTime.now();
  final diff = challengeStartTime.difference(now);
  if (diff.isNegative) return '곧 도전이 시작됩니다!';
  final min = diff.inMinutes;
  final sec = diff.inSeconds % 60;
  return '도전 시작까지  ${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

// 인증 게시판에서 사용할 날짜시간 포맷팅 함수
String formatDateTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);
  
  if (difference.inDays > 0) {
    // 하루 이상 지났으면 'yyyy.MM.dd HH:mm' 형식으로 표시
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  } else if (difference.inHours > 0) {
    // 몇 시간 전
    return '${difference.inHours}시간 전';
  } else if (difference.inMinutes > 0) {
    // 몇 분 전
    return '${difference.inMinutes}분 전';
  } else {
    // 방금 전
    return '방금 전';
  }
} 