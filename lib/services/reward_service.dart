import '../config/supabase_config.dart';
import '../models/reward_punishment.dart';
import 'points_service.dart';
import 'package:flutter/material.dart';

class RewardService {
  // 관계의 모든 보상/처벌 조회
  static Future<List<RewardPunishment>> getRewards({
    required String relationshipId,
    String? type, // 'reward' 또는 'punishment' 또는 null(전체)
    bool? activeOnly,
  }) async {
    try {
      var query = supabase
          .from('rewards_punishments')
          .select()
          .eq('relationship_id', relationshipId);

      if (type != null) {
        query = query.eq('type', type);
      }

      if (activeOnly == true) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('created_at', ascending: false);
      return response.map<RewardPunishment>((json) => RewardPunishment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('보상/처벌 조회 실패: $e');
    }
  }

  // 보상만 조회
  static Future<List<RewardPunishment>> getActiveRewards(String relationshipId) async {
    return getRewards(
      relationshipId: relationshipId,
      type: 'reward',
      activeOnly: true,
    );
  }

  // 처벌만 조회
  static Future<List<RewardPunishment>> getActivePunishments(String relationshipId) async {
    return getRewards(
      relationshipId: relationshipId,
      type: 'punishment',
      activeOnly: true,
    );
  }

  // 새 보상/처벌 생성
  static Future<RewardPunishment> createReward({
    required String relationshipId,
    required String title,
    String? description,
    required String type, // 'reward' 또는 'punishment'
    required String category,
    required int pointsCost,
    bool isLimited = false,
    int? limitCount,
  }) async {
    try {
      final response = await supabase
          .from('rewards_punishments')
          .insert({
            'relationship_id': relationshipId,
            'title': title,
            'description': description,
            'type': type,
            'category': category,
            'points_cost': pointsCost,
            'is_active': true,
            'is_limited': isLimited,
            'limit_count': limitCount,
            'purchase_count': 0,
          })
          .select()
          .single();

      return RewardPunishment.fromJson(response);
    } catch (e) {
      throw Exception('보상/처벌 생성 실패: $e');
    }
  }

  // 보상/처벌 수정
  static Future<RewardPunishment> updateReward({
    required String rewardId,
    String? title,
    String? description,
    String? category,
    int? pointsCost,
    bool? isActive,
    bool? isLimited,
    int? limitCount,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;
      if (pointsCost != null) updates['points_cost'] = pointsCost;
      if (isActive != null) updates['is_active'] = isActive;
      if (isLimited != null) updates['is_limited'] = isLimited;
      if (limitCount != null) updates['limit_count'] = limitCount;
      
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await supabase
          .from('rewards_punishments')
          .update(updates)
          .eq('id', rewardId)
          .select()
          .single();

      return RewardPunishment.fromJson(response);
    } catch (e) {
      throw Exception('보상/처벌 수정 실패: $e');
    }
  }

  // 보상/처벌 삭제 (비활성화)
  static Future<void> deleteReward(String rewardId) async {
    try {
      await supabase
          .from('rewards_punishments')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', rewardId);
    } catch (e) {
      throw Exception('보상/처벌 삭제 실패: $e');
    }
  }

  // 보상 구매
  static Future<RewardPurchase> purchaseReward({
    required String relationshipId,
    required String rewardId,
    required String userId,
    String? note,
  }) async {
    try {
      // 보상 정보 조회
      final rewardResponse = await supabase
          .from('rewards_punishments')
          .select()
          .eq('id', rewardId)
          .single();

      final reward = RewardPunishment.fromJson(rewardResponse);

      // 구매 가능 여부 확인
      if (!reward.canPurchase) {
        throw Exception('구매할 수 없는 보상입니다');
      }

      // 포인트 차감
      await PointsService.deductPoints(
        relationshipId: relationshipId,
        userId: userId,
        points: reward.pointsCost,
        reason: '보상 구매: ${reward.title}',
      );

      // 구매 내역 생성
      final purchaseResponse = await supabase
          .from('reward_purchases')
          .insert({
            'relationship_id': relationshipId,
            'reward_id': rewardId,
            'user_id': userId,
            'reward_title': reward.title,
            'points_spent': reward.pointsCost,
            'status': 'pending', // Dom 승인 대기
            'purchased_at': DateTime.now().toIso8601String(),
            'note': note,
          })
          .select()
          .single();

      // 구매 횟수 증가
      await supabase
          .from('rewards_punishments')
          .update({
            'purchase_count': reward.purchaseCount + 1,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', rewardId);

      return RewardPurchase.fromJson(purchaseResponse);
    } catch (e) {
      throw Exception('보상 구매 실패: $e');
    }
  }

  // 구매 내역 조회
  static Future<List<RewardPurchase>> getPurchaseHistory({
    required String relationshipId,
    String? userId,
    String? status,
  }) async {
    try {
      var query = supabase
          .from('reward_purchases')
          .select()
          .eq('relationship_id', relationshipId);

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('purchased_at', ascending: false);
      return response.map<RewardPurchase>((json) => RewardPurchase.fromJson(json)).toList();
    } catch (e) {
      throw Exception('구매 내역 조회 실패: $e');
    }
  }

  // 구매 승인/거부 (Dom 전용)
  static Future<RewardPurchase> approvePurchase({
    required String purchaseId,
    required bool approved,
    String? note,
  }) async {
    try {
      final newStatus = approved ? 'approved' : 'expired';
      
      final response = await supabase
          .from('reward_purchases')
          .update({
            'status': newStatus,
            'note': note,
          })
          .eq('id', purchaseId)
          .select()
          .single();

      return RewardPurchase.fromJson(response);
    } catch (e) {
      throw Exception('구매 승인/거부 실패: $e');
    }
  }

  // 보상 사용 처리 (Dom 전용)
  static Future<RewardPurchase> markAsUsed({
    required String purchaseId,
    String? note,
  }) async {
    try {
      final response = await supabase
          .from('reward_purchases')
          .update({
            'status': 'used',
            'used_at': DateTime.now().toIso8601String(),
            'note': note,
          })
          .eq('id', purchaseId)
          .select()
          .single();

      return RewardPurchase.fromJson(response);
    } catch (e) {
      throw Exception('사용 처리 실패: $e');
    }
  }

  // 사용 가능한 카테고리 목록
  static List<Map<String, dynamic>> getRewardCategories() {
    return [
      {
        'id': 'food',
        'name': '음식',
        'icon': Icons.restaurant,
        'color': const Color(0xFFF59E0B),
      },
      {
        'id': 'entertainment',
        'name': '오락',
        'icon': Icons.movie,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'id': 'shopping',
        'name': '쇼핑',
        'icon': Icons.shopping_bag,
        'color': const Color(0xFFEC4899),
      },
      {
        'id': 'experience',
        'name': '체험',
        'icon': Icons.celebration,
        'color': const Color(0xFF06B6D4),
      },
      {
        'id': 'freedom',
        'name': '자유시간',
        'icon': Icons.free_breakfast,
        'color': const Color(0xFF10B981),
      },
      {
        'id': 'service',
        'name': '서비스',
        'icon': Icons.room_service,
        'color': const Color(0xFF3B82F6),
      },
    ];
  }

  static List<Map<String, dynamic>> getPunishmentCategories() {
    return [
      {
        'id': 'physical',
        'name': '신체활동',
        'icon': Icons.fitness_center,
        'color': const Color(0xFFEF4444),
      },
      {
        'id': 'restriction',
        'name': '제한',
        'icon': Icons.block,
        'color': const Color(0xFF6B7280),
      },
      {
        'id': 'service',
        'name': '서비스',
        'icon': Icons.cleaning_services,
        'color': const Color(0xFF3B82F6),
      },
    ];
  }
}
