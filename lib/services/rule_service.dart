import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
import '../models/rule.dart';


class RuleService {
  // 관계의 모든 규칙 조회
  static Future<List<Rule>> getRulesByRelationship(String relationshipId) async {
    try {
      final response = await supabase
          .from('rules')
          .select()
          .eq('relationship_id', relationshipId)
          .order('created_at', ascending: false);

      return response.map<Rule>((json) => Rule.fromJson(json)).toList();
    } catch (e) {
      throw Exception('규칙 조회 실패: $e');
    }
  }

  // 활성화된 규칙만 조회
  static Future<List<Rule>> getActiveRules(String relationshipId) async {
    try {
      final response = await supabase
          .from('rules')
          .select()
          .eq('relationship_id', relationshipId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response.map<Rule>((json) => Rule.fromJson(json)).toList();
    } catch (e) {
      throw Exception('활성 규칙 조회 실패: $e');
    }
  }

  // 카테고리별 규칙 조회
  static Future<List<Rule>> getRulesByCategory(
    String relationshipId, 
    String category,
  ) async {
    try {
      final response = await supabase
          .from('rules')
          .select()
          .eq('relationship_id', relationshipId)
          .eq('category', category)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response.map<Rule>((json) => Rule.fromJson(json)).toList();
    } catch (e) {
      throw Exception('카테고리별 규칙 조회 실패: $e');
    }
  }

  // 새 규칙 생성
  static Future<Rule> createRule({
    required String relationshipId,
    required String title,
    String? description,
    required String category,
    required String difficulty,
    required String frequency,
    required int pointsReward,
  }) async {
    try {
      final response = await supabase
          .from('rules')
          .insert({
            'relationship_id': relationshipId,
            'title': title,
            'description': description,
            'category': category,
            'difficulty': difficulty,
            'frequency': frequency,
            'points_reward': pointsReward,
            'is_active': true,
          })
          .select()
          .single();

      return Rule.fromJson(response);
    } catch (e) {
      throw Exception('규칙 생성 실패: $e');
    }
  }

  // 규칙 수정
  static Future<Rule> updateRule({
    required String ruleId,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    String? frequency,
    int? pointsReward,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;
      if (difficulty != null) updates['difficulty'] = difficulty;
      if (frequency != null) updates['frequency'] = frequency;
      if (pointsReward != null) updates['points_reward'] = pointsReward;
      if (isActive != null) updates['is_active'] = isActive;
      
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await supabase
          .from('rules')
          .update(updates)
          .eq('id', ruleId)
          .select()
          .single();

      return Rule.fromJson(response);
    } catch (e) {
      throw Exception('규칙 수정 실패: $e');
    }
  }

  // 규칙 삭제 (실제로는 비활성화)
  static Future<void> deleteRule(String ruleId) async {
    try {
      await supabase
          .from('rules')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ruleId);
    } catch (e) {
      throw Exception('규칙 삭제 실패: $e');
    }
  }

  // 규칙 활성화/비활성화 토글
  static Future<Rule> toggleRuleActive(String ruleId, bool isActive) async {
    try {
      final response = await supabase
          .from('rules')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ruleId)
          .select()
          .single();

      return Rule.fromJson(response);
    } catch (e) {
      throw Exception('규칙 상태 변경 실패: $e');
    }
  }

  // 규칙 상세 조회
  static Future<Rule?> getRuleById(String ruleId) async {
    try {
      final response = await supabase
          .from('rules')
          .select()
          .eq('id', ruleId)
          .single();

      return Rule.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // 사용 가능한 카테고리 목록
  static List<Map<String, dynamic>> getAvailableCategories() {
    return [
      {
        'id': 'daily',
        'name': '일상',
        'icon': Icons.today,
        'color': const Color(0xFF3B82F6),
      },
      {
        'id': 'health',
        'name': '건강',
        'icon': Icons.favorite,
        'color': const Color(0xFFEF4444),
      },
      {
        'id': 'exercise',
        'name': '운동',
        'icon': Icons.fitness_center,
        'color': const Color(0xFF10B981),
      },
      {
        'id': 'study',
        'name': '공부',
        'icon': Icons.school,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'id': 'behavior',
        'name': '행동',
        'icon': Icons.psychology,
        'color': const Color(0xFFF59E0B),
      },
      {
        'id': 'hobby',
        'name': '취미',
        'icon': Icons.palette,
        'color': const Color(0xFFEC4899),
      },
    ];
  }

  // 난이도 목록
  static List<Map<String, dynamic>> getDifficultyLevels() {
    return [
      {
        'id': 'easy',
        'name': '쉬움',
        'color': const Color(0xFF10B981),
        'points': 5,
      },
      {
        'id': 'medium',
        'name': '보통',
        'color': const Color(0xFFF59E0B),
        'points': 10,
      },
      {
        'id': 'hard',
        'name': '어려움',
        'color': const Color(0xFFEF4444),
        'points': 20,
      },
    ];
  }

  // 빈도 목록
  static List<Map<String, dynamic>> getFrequencyOptions() {
    return [
      {
        'id': 'daily',
        'name': '매일',
        'description': '매일 실행해야 하는 규칙',
      },
      {
        'id': 'weekly',
        'name': '주간',
        'description': '주에 한 번 실행하는 규칙',
      },
      {
        'id': 'monthly',
        'name': '월간',
        'description': '월에 한 번 실행하는 규칙',
      },
    ];
  }
}
