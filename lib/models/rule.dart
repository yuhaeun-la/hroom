import 'package:flutter/material.dart';

class Rule {
  final String id;
  final String relationshipId;
  final String title;
  final String? description;
  final String category;
  final String difficulty;
  final String frequency;
  final int pointsReward;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rule({
    required this.id,
    required this.relationshipId,
    required this.title,
    this.description,
    required this.category,
    required this.difficulty,
    required this.frequency,
    required this.pointsReward,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rule.fromJson(Map<String, dynamic> json) {
    return Rule(
      id: json['id'],
      relationshipId: json['relationship_id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      difficulty: json['difficulty'],
      frequency: json['frequency'],
      pointsReward: json['points_reward'] ?? 10,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relationship_id': relationshipId,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'frequency': frequency,
      'points_reward': pointsReward,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Rule copyWith({
    String? title,
    String? description,
    String? category,
    String? difficulty,
    String? frequency,
    int? pointsReward,
    bool? isActive,
  }) {
    return Rule(
      id: id,
      relationshipId: relationshipId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      frequency: frequency ?? this.frequency,
      pointsReward: pointsReward ?? this.pointsReward,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

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

  // 빈도 한글 이름
  String get frequencyDisplayName {
    switch (frequency) {
      case 'daily':
        return '매일';
      case 'weekly':
        return '주간';
      case 'monthly':
        return '월간';
      default:
        return frequency;
    }
  }

  // 난이도 색상
  Color get difficultyColor {
    switch (difficulty) {
      case 'easy':
        return const Color(0xFF10B981); // 초록색
      case 'medium':
        return const Color(0xFFF59E0B); // 노란색
      case 'hard':
        return const Color(0xFFEF4444); // 빨간색
      default:
        return const Color(0xFF6B7280); // 회색
    }
  }

  // 카테고리 아이콘
  IconData get categoryIcon {
    switch (category) {
      case 'daily':
        return Icons.today;
      case 'health':
        return Icons.favorite;
      case 'study':
        return Icons.school;
      case 'behavior':
        return Icons.psychology;
      case 'exercise':
        return Icons.fitness_center;
      case 'hobby':
        return Icons.palette;
      default:
        return Icons.rule;
    }
  }
}
