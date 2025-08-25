import 'package:flutter/material.dart';

class EmotionalJournal {
  final String id;
  final String relationshipId;
  final String userId;
  final String title;
  final String content;
  final String mood; // 'happy', 'sad', 'angry', 'anxious', 'excited', 'calm', 'confused'
  final int moodIntensity; // 1-5 (낮음-높음)
  final List<String> tags; // 선택적 태그들
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPrivate; // Sub만 볼 수 있는지 여부

  const EmotionalJournal({
    required this.id,
    required this.relationshipId,
    required this.userId,
    required this.title,
    required this.content,
    required this.mood,
    required this.moodIntensity,
    required this.tags,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.isPrivate = false,
  });

  factory EmotionalJournal.fromJson(Map<String, dynamic> json) {
    return EmotionalJournal(
      id: json['id'] as String,
      relationshipId: json['relationship_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      mood: json['mood'] as String,
      moodIntensity: json['mood_intensity'] as int,
      tags: List<String>.from(json['tags'] ?? []),
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isPrivate: json['is_private'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relationship_id': relationshipId,
      'user_id': userId,
      'title': title,
      'content': content,
      'mood': mood,
      'mood_intensity': moodIntensity,
      'tags': tags,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD 형식
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_private': isPrivate,
    };
  }

  // 감정별 아이콘
  IconData get moodIcon {
    switch (mood) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_very_dissatisfied;
      case 'angry':
        return Icons.sentiment_dissatisfied;
      case 'anxious':
        return Icons.sentiment_neutral;
      case 'excited':
        return Icons.celebration;
      case 'calm':
        return Icons.self_improvement;
      case 'confused':
        return Icons.help_outline;
      default:
        return Icons.sentiment_neutral;
    }
  }

  // 감정별 색상
  Color get moodColor {
    switch (mood) {
      case 'happy':
        return const Color(0xFFFECA57);
      case 'sad':
        return const Color(0xFF54A0FF);
      case 'angry':
        return const Color(0xFFFF6B6B);
      case 'anxious':
        return const Color(0xFFFF9FF3);
      case 'excited':
        return const Color(0xFF5F27CD);
      case 'calm':
        return const Color(0xFF00D2D3);
      case 'confused':
        return const Color(0xFF9C88FF);
      default:
        return const Color(0xFF636E72);
    }
  }

  // 감정 이름 (한국어)
  String get moodDisplayName {
    switch (mood) {
      case 'happy':
        return '행복';
      case 'sad':
        return '슬픔';
      case 'angry':
        return '화남';
      case 'anxious':
        return '불안';
      case 'excited':
        return '흥분';
      case 'calm':
        return '평온';
      case 'confused':
        return '혼란';
      default:
        return '보통';
    }
  }

  // 강도별 설명
  String get intensityDisplayName {
    switch (moodIntensity) {
      case 1:
        return '매우 약함';
      case 2:
        return '약함';
      case 3:
        return '보통';
      case 4:
        return '강함';
      case 5:
        return '매우 강함';
      default:
        return '보통';
    }
  }

  // 이용 가능한 모든 감정들
  static List<Map<String, dynamic>> get availableMoods {
    return [
      {
        'id': 'happy',
        'name': '행복',
        'icon': Icons.sentiment_very_satisfied,
        'color': const Color(0xFFFECA57),
      },
      {
        'id': 'excited',
        'name': '흥분',
        'icon': Icons.celebration,
        'color': const Color(0xFF5F27CD),
      },
      {
        'id': 'calm',
        'name': '평온',
        'icon': Icons.self_improvement,
        'color': const Color(0xFF00D2D3),
      },
      {
        'id': 'sad',
        'name': '슬픔',
        'icon': Icons.sentiment_very_dissatisfied,
        'color': const Color(0xFF54A0FF),
      },
      {
        'id': 'angry',
        'name': '화남',
        'icon': Icons.sentiment_dissatisfied,
        'color': const Color(0xFFFF6B6B),
      },
      {
        'id': 'anxious',
        'name': '불안',
        'icon': Icons.sentiment_neutral,
        'color': const Color(0xFFFF9FF3),
      },
      {
        'id': 'confused',
        'name': '혼란',
        'icon': Icons.help_outline,
        'color': const Color(0xFF9C88FF),
      },
    ];
  }

  // 자주 사용되는 태그들
  static List<String> get commonTags {
    return [
      '관계',
      '사랑',
      '신뢰',
      '규칙',
      '성취',
      '실패',
      '보상',
      '처벌',
      '성장',
      '소통',
      '감사',
      '반성',
      '목표',
      '일상',
      '특별한날',
    ];
  }

  EmotionalJournal copyWith({
    String? id,
    String? relationshipId,
    String? userId,
    String? title,
    String? content,
    String? mood,
    int? moodIntensity,
    List<String>? tags,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPrivate,
  }) {
    return EmotionalJournal(
      id: id ?? this.id,
      relationshipId: relationshipId ?? this.relationshipId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      moodIntensity: moodIntensity ?? this.moodIntensity,
      tags: tags ?? this.tags,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}
