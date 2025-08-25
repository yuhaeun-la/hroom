import 'package:flutter/material.dart';

class RelationshipStats {
  final String relationshipId;
  final String mentorId;
  final String menteeId;
  final int totalLogs;
  final int completedLogs;
  final double completionRate;
  final int journalEntries;
  final DateTime? lastActivity;

  RelationshipStats({
    required this.relationshipId,
    required this.mentorId,
    required this.menteeId,
    required this.totalLogs,
    required this.completedLogs,
    required this.completionRate,
    required this.journalEntries,
    this.lastActivity,
  });

  factory RelationshipStats.fromJson(Map<String, dynamic> json) {
    return RelationshipStats(
      relationshipId: json['relationship_id'],
      mentorId: json['mentor_id'] ?? json['dom_id'],
      menteeId: json['mentee_id'] ?? json['sub_id'],
      totalLogs: json['total_logs'] ?? 0,
      completedLogs: json['completed_logs'] ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      journalEntries: json['journal_entries'] ?? 0,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'])
          : null,
    );
  }

  // 성장 지수 색상 결정
  Color get growthGaugeColor {
    if (completionRate >= 71) {
      return const Color(0xFF10B981); // 초록색
    } else if (completionRate >= 31) {
      return const Color(0xFFF59E0B); // 노란색
    } else {
      return const Color(0xFFEF4444); // 빨간색
    }
  }

  // 멘토링 온도 결정 (0-100)
  double get mentoringTemperature {
    double baseTemp = completionRate * 0.6; // 완료율 60% 가중치
    double activityBonus = journalEntries > 0 ? 20.0 : 0.0; // 일지 작성 보너스
    double recentActivityBonus = lastActivity != null &&
            DateTime.now().difference(lastActivity!).inDays <= 3
        ? 20.0
        : 0.0; // 최근 활동 보너스

    return (baseTemp + activityBonus + recentActivityBonus).clamp(0.0, 100.0);
  }

  // 온도계 색상
  Color get temperatureColor {
    double temp = mentoringTemperature;
    if (temp >= 70) {
      return const Color(0xFFDC2626); // 뜨거움 (빨간색)
    } else if (temp >= 40) {
      return const Color(0xFFF59E0B); // 따뜻함 (주황색)
    } else {
      return const Color(0xFF3B82F6); // 차가움 (파란색)
    }
  }

  // 온도 상태 텍스트
  String get temperatureStatus {
    double temp = mentoringTemperature;
    if (temp >= 70) {
      return '열정적이에요 🔥';
    } else if (temp >= 40) {
      return '따뜻해요 ☀️';
    } else {
      return '노력이 필요해요 ❄️';
    }
  }
}
