import 'package:flutter/material.dart';

class RecentActivity {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final ActivityType type;
  final IconData icon;
  final Color color;

  RecentActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.icon,
    required this.color,
  });

  String get timeAgo {
    final now = DateTime.now();
    // UTC 시간을 로컬 시간으로 변환
    final localTimestamp = timestamp.toLocal();
    final difference = now.difference(localTimestamp);

    // 음수가 나오면 (미래 시간이면) 0분 전으로 처리
    if (difference.isNegative) {
      return '방금 전';
    }

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${difference.inDays ~/ 7}주 전';
    }
  }
}

enum ActivityType {
  ruleCompleted,     // 규칙 완료
  journalCreated,    // 일지 작성
  rewardReceived,    // 보상 받음
  ruleCreated,       // 규칙 생성
  relationshipStarted, // 관계 시작
}
