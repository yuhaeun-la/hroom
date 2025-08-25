import 'package:flutter/material.dart';

class DailyLog {
  final String id;
  final String relationshipId;
  final String ruleId;
  final String? ruleTitle; // 규칙이 삭제된 경우를 위한 백업
  final DateTime date;
  final bool completed;
  final DateTime? completedAt;
  final String? note;
  final String? photoUrl;
  final int pointsEarned;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyLog({
    required this.id,
    required this.relationshipId,
    required this.ruleId,
    this.ruleTitle,
    required this.date,
    required this.completed,
    this.completedAt,
    this.note,
    this.photoUrl,
    required this.pointsEarned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      id: json['id'],
      relationshipId: json['relationship_id'],
      ruleId: json['rule_id'],
      ruleTitle: json['rule_title'],
      date: DateTime.parse(json['log_date']),
      completed: json['completed'] ?? false,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      note: null, // 임시로 null 처리 (notes 컬럼 없음)
      photoUrl: json['proof_image_url'], // 데이터베이스 컬럼명에 맞춤
      pointsEarned: json['points_earned'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : DateTime.parse(json['created_at']), // updated_at이 없으면 created_at 사용
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relationship_id': relationshipId,
      'rule_id': ruleId,
      'rule_title': ruleTitle,
      'log_date': date.toIso8601String().split('T')[0], // YYYY-MM-DD 형식
      'completed': completed,
      'completed_at': completedAt?.toIso8601String(),
      'notes': note, // 데이터베이스 컬럼명에 맞춤
      'proof_image_url': photoUrl, // 데이터베이스 컬럼명에 맞춤
      'points_earned': pointsEarned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DailyLog copyWith({
    bool? completed,
    DateTime? completedAt,
    String? note,
    String? photoUrl,
    int? pointsEarned,
  }) {
    return DailyLog(
      id: id,
      relationshipId: relationshipId,
      ruleId: ruleId,
      ruleTitle: ruleTitle,
      date: date,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      note: note ?? this.note,
      photoUrl: photoUrl ?? this.photoUrl,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // 완료 상태 색상
  Color get statusColor {
    if (completed) {
      return const Color(0xFF10B981); // 초록색
    }
    return const Color(0xFF6B7280); // 회색
  }

  // 완료 상태 아이콘
  IconData get statusIcon {
    if (completed) {
      return Icons.check_circle;
    }
    return Icons.radio_button_unchecked;
  }

  // 오늘 날짜인지 확인
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  // 이번 주인지 확인
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // 이번 달인지 확인
  bool get isThisMonth {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // 포맷된 날짜 (MM/dd)
  String get formattedDate {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  // 포맷된 완료 시간
  String? get formattedCompletedTime {
    if (completedAt == null) return null;
    
    final time = completedAt!;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// 체크리스트 아이템 (규칙 + 오늘의 로그)
class ChecklistItem {
  final String ruleId;
  final String ruleTitle;
  final String? ruleDescription;
  final String category;
  final String difficulty;
  final int pointsReward;
  final IconData categoryIcon;
  final Color difficultyColor;
  final DailyLog? todayLog;

  ChecklistItem({
    required this.ruleId,
    required this.ruleTitle,
    this.ruleDescription,
    required this.category,
    required this.difficulty,
    required this.pointsReward,
    required this.categoryIcon,
    required this.difficultyColor,
    this.todayLog,
  });

  bool get isCompleted => todayLog?.completed ?? false;
  
  String? get note => todayLog?.note;
  
  String? get photoUrl => todayLog?.photoUrl;
  
  DateTime? get completedAt => todayLog?.completedAt;

  // 카테고리 한글 이름
  String get categoryDisplayName {
    switch (category) {
      case 'daily':
        return '일상';
      case 'health':
        return '건강';
      case 'study':
        return '공부';
      case 'behavior':
        return '행동';
      case 'exercise':
        return '운동';
      case 'hobby':
        return '취미';
      default:
        return category;
    }
  }

  // 난이도 한글 이름
  String get difficultyDisplayName {
    switch (difficulty) {
      case 'easy':
        return '쉬움';
      case 'medium':
        return '보통';
      case 'hard':
        return '어려움';
      default:
        return difficulty;
    }
  }
}
