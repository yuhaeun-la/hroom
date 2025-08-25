import 'package:flutter/material.dart';

class PointsHistory {
  final String id;
  final String relationshipId;
  final String userId;
  final int pointsChange;
  final String reason;
  final String? ruleId;
  final String? logId;
  final DateTime createdAt;

  PointsHistory({
    required this.id,
    required this.relationshipId,
    required this.userId,
    required this.pointsChange,
    required this.reason,
    this.ruleId,
    this.logId,
    required this.createdAt,
  });

  factory PointsHistory.fromJson(Map<String, dynamic> json) {
    return PointsHistory(
      id: json['id'],
      relationshipId: json['relationship_id'],
      userId: json['user_id'],
      pointsChange: json['points_change'] ?? 0,
      reason: json['reason'] ?? '',
      ruleId: json['rule_id'],
      logId: json['log_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relationship_id': relationshipId,
      'user_id': userId,
      'points_change': pointsChange,
      'reason': reason,
      'rule_id': ruleId,
      'log_id': logId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // 포인트 변경 타입
  bool get isPositive => pointsChange > 0;
  bool get isNegative => pointsChange < 0;

  // 포인트 변경 색상
  Color get changeColor {
    if (isPositive) {
      return const Color(0xFF10B981); // 초록색 (획득)
    } else if (isNegative) {
      return const Color(0xFFEF4444); // 빨간색 (차감)
    }
    return const Color(0xFF6B7280); // 회색 (변경 없음)
  }

  // 포인트 변경 아이콘
  IconData get changeIcon {
    if (isPositive) {
      return Icons.trending_up;
    } else if (isNegative) {
      return Icons.trending_down;
    }
    return Icons.remove;
  }

  // 포인트 변경 텍스트
  String get changeText {
    if (pointsChange > 0) {
      return '+$pointsChange';
    }
    return pointsChange.toString();
  }

  // 포맷된 날짜
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return '오늘 ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '어제 ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${createdAt.month}/${createdAt.day}';
    }
  }

  // 포인트 변경 사유 아이콘
  IconData get reasonIcon {
    switch (reason.toLowerCase()) {
      case '규칙 완료':
      case 'rule_completion':
        return Icons.check_circle;
      case '보상':
      case 'reward':
        return Icons.card_giftcard;
      case '처벌':
      case 'punishment':
        return Icons.warning;
      case '보너스':
      case 'bonus':
        return Icons.star;
      case '수정':
      case 'adjustment':
        return Icons.edit;
      default:
        return Icons.circle;
    }
  }
}

// 사용자 포인트 정보
class UserPoints {
  final String userId;
  final String relationshipId;
  final int totalPoints;
  final int currentLevel;
  final int pointsToNextLevel;
  final int pointsInCurrentLevel;
  final String levelTitle;
  final Color levelColor;
  final DateTime lastUpdated;

  UserPoints({
    required this.userId,
    required this.relationshipId,
    required this.totalPoints,
    required this.currentLevel,
    required this.pointsToNextLevel,
    required this.pointsInCurrentLevel,
    required this.levelTitle,
    required this.levelColor,
    required this.lastUpdated,
  });

  factory UserPoints.fromTotalPoints({
    required String userId,
    required String relationshipId,
    required int totalPoints,
    DateTime? lastUpdated,
  }) {
    final levelInfo = _calculateLevel(totalPoints);
    
    return UserPoints(
      userId: userId,
      relationshipId: relationshipId,
      totalPoints: totalPoints,
      currentLevel: levelInfo['level'],
      pointsToNextLevel: levelInfo['pointsToNext'],
      pointsInCurrentLevel: levelInfo['pointsInLevel'],
      levelTitle: levelInfo['title'],
      levelColor: levelInfo['color'],
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  // 레벨 계산 로직
  static Map<String, dynamic> _calculateLevel(int totalPoints) {
    // 레벨별 필요 포인트 (누적)
    final levelRequirements = [
      0,    // 레벨 1
      100,  // 레벨 2
      300,  // 레벨 3
      600,  // 레벨 4
      1000, // 레벨 5
      1500, // 레벨 6
      2100, // 레벨 7
      2800, // 레벨 8
      3600, // 레벨 9
      4500, // 레벨 10
    ];

    final levelTitles = [
      '초보자',     // 레벨 1
      '견습생',     // 레벨 2
      '수련생',     // 레벨 3
      '숙련자',     // 레벨 4
      '전문가',     // 레벨 5
      '마스터',     // 레벨 6
      '그랜드마스터', // 레벨 7
      '전설',       // 레벨 8
      '신화',       // 레벨 9
      '완벽',       // 레벨 10
    ];

    final levelColors = [
      const Color(0xFF9CA3AF), // 회색
      const Color(0xFF10B981), // 초록
      const Color(0xFF3B82F6), // 파랑
      const Color(0xFF8B5CF6), // 보라
      const Color(0xFFF59E0B), // 노랑
      const Color(0xFFEF4444), // 빨강
      const Color(0xFFEC4899), // 핑크
      const Color(0xFF06B6D4), // 청록
      const Color(0xFFFBBF24), // 금색
      const Color(0xFF7C3AED), // 진보라
    ];

    int currentLevel = 1;
    int pointsInCurrentLevel = totalPoints;
    int pointsToNextLevel = levelRequirements[1] - totalPoints;

    for (int i = levelRequirements.length - 1; i >= 0; i--) {
      if (totalPoints >= levelRequirements[i]) {
        currentLevel = i + 1;
        pointsInCurrentLevel = totalPoints - levelRequirements[i];
        
        if (i + 1 < levelRequirements.length) {
          pointsToNextLevel = levelRequirements[i + 1] - totalPoints;
        } else {
          pointsToNextLevel = 0; // 최대 레벨
        }
        break;
      }
    }

    return {
      'level': currentLevel,
      'pointsInLevel': pointsInCurrentLevel,
      'pointsToNext': pointsToNextLevel,
      'title': levelTitles[currentLevel - 1],
      'color': levelColors[currentLevel - 1],
    };
  }

  // 레벨 진행률 (0.0 ~ 1.0)
  double get levelProgress {
    if (pointsToNextLevel == 0) return 1.0; // 최대 레벨
    
    final totalPointsForLevel = pointsInCurrentLevel + pointsToNextLevel;
    return pointsInCurrentLevel / totalPointsForLevel;
  }

  // 레벨업까지 남은 퍼센트
  double get progressPercentage => levelProgress * 100;

  // 최대 레벨 여부
  bool get isMaxLevel => pointsToNextLevel == 0;
}
