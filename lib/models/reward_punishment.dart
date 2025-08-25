import 'package:flutter/material.dart';

class RewardPunishment {
  final String id;
  final String relationshipId;
  final String title;
  final String? description;
  final String type; // 'reward' 또는 'punishment'
  final String category;
  final int pointsCost; // 보상 구매 비용 또는 처벌 포인트 차감
  final bool isActive;
  final bool isLimited; // 제한된 수량인지
  final int? limitCount; // 제한 수량 (null이면 무제한)
  final int purchaseCount; // 구매/사용된 횟수
  final DateTime createdAt;
  final DateTime updatedAt;

  RewardPunishment({
    required this.id,
    required this.relationshipId,
    required this.title,
    this.description,
    required this.type,
    required this.category,
    required this.pointsCost,
    required this.isActive,
    required this.isLimited,
    this.limitCount,
    required this.purchaseCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RewardPunishment.fromJson(Map<String, dynamic> json) {
    return RewardPunishment(
      id: json['id'],
      relationshipId: json['relationship_id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      category: json['category'],
      pointsCost: json['points_cost'] ?? 0,
      isActive: json['is_active'] ?? true,
      isLimited: json['is_limited'] ?? false,
      limitCount: json['limit_count'],
      purchaseCount: json['purchase_count'] ?? 0,
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
      'type': type,
      'category': category,
      'points_cost': pointsCost,
      'is_active': isActive,
      'is_limited': isLimited,
      'limit_count': limitCount,
      'purchase_count': purchaseCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 보상인지 확인
  bool get isReward => type == 'reward';
  
  // 처벌인지 확인
  bool get isPunishment => type == 'punishment';

  // 구매 가능 여부
  bool get canPurchase {
    if (!isActive) return false;
    if (!isLimited) return true;
    return limitCount != null && purchaseCount < limitCount!;
  }

  // 남은 수량
  int? get remainingCount {
    if (!isLimited || limitCount == null) return null;
    return limitCount! - purchaseCount;
  }

  // 타입별 색상
  Color get typeColor {
    return isReward 
        ? const Color(0xFF10B981) // 초록색 (보상)
        : const Color(0xFFEF4444); // 빨간색 (처벌)
  }

  // 타입별 아이콘
  IconData get typeIcon {
    return isReward 
        ? Icons.card_giftcard 
        : Icons.warning;
  }

  // 카테고리별 아이콘
  IconData get categoryIcon {
    switch (category) {
      case 'food':
        return Icons.restaurant;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'experience':
        return Icons.celebration;
      case 'freedom':
        return Icons.free_breakfast;
      case 'service':
        return Icons.room_service;
      case 'physical':
        return Icons.fitness_center;
      case 'restriction':
        return Icons.block;
      default:
        return Icons.star;
    }
  }

  // 카테고리 한글 이름
  String get categoryDisplayName {
    switch (category) {
      case 'food':
        return '음식';
      case 'entertainment':
        return '오락';
      case 'shopping':
        return '쇼핑';
      case 'experience':
        return '체험';
      case 'freedom':
        return '자유시간';
      case 'service':
        return '서비스';
      case 'physical':
        return '신체활동';
      case 'restriction':
        return '제한';
      default:
        return category;
    }
  }

  // 카테고리별 색상
  Color get categoryColor {
    switch (category) {
      case 'food':
        return const Color(0xFFF59E0B); // 주황색
      case 'entertainment':
        return const Color(0xFF8B5CF6); // 보라색
      case 'shopping':
        return const Color(0xFFEC4899); // 핑크색
      case 'experience':
        return const Color(0xFF06B6D4); // 청록색
      case 'freedom':
        return const Color(0xFF10B981); // 초록색
      case 'service':
        return const Color(0xFF3B82F6); // 파란색
      case 'physical':
        return const Color(0xFFEF4444); // 빨간색
      case 'restriction':
        return const Color(0xFF6B7280); // 회색
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  RewardPunishment copyWith({
    String? title,
    String? description,
    String? category,
    int? pointsCost,
    bool? isActive,
    bool? isLimited,
    int? limitCount,
    int? purchaseCount,
  }) {
    return RewardPunishment(
      id: id,
      relationshipId: relationshipId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type,
      category: category ?? this.category,
      pointsCost: pointsCost ?? this.pointsCost,
      isActive: isActive ?? this.isActive,
      isLimited: isLimited ?? this.isLimited,
      limitCount: limitCount ?? this.limitCount,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// 구매/사용 내역
class RewardPurchase {
  final String id;
  final String relationshipId;
  final String rewardId;
  final String userId;
  final String rewardTitle;
  final int pointsSpent;
  final String status; // 'pending', 'approved', 'used', 'expired'
  final DateTime purchasedAt;
  final DateTime? usedAt;
  final String? note;

  RewardPurchase({
    required this.id,
    required this.relationshipId,
    required this.rewardId,
    required this.userId,
    required this.rewardTitle,
    required this.pointsSpent,
    required this.status,
    required this.purchasedAt,
    this.usedAt,
    this.note,
  });

  factory RewardPurchase.fromJson(Map<String, dynamic> json) {
    return RewardPurchase(
      id: json['id'],
      relationshipId: json['relationship_id'],
      rewardId: json['reward_id'],
      userId: json['user_id'],
      rewardTitle: json['reward_title'],
      pointsSpent: json['points_spent'] ?? 0,
      status: json['status'] ?? 'pending',
      purchasedAt: DateTime.parse(json['purchased_at']),
      usedAt: json['used_at'] != null ? DateTime.parse(json['used_at']) : null,
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relationship_id': relationshipId,
      'reward_id': rewardId,
      'user_id': userId,
      'reward_title': rewardTitle,
      'points_spent': pointsSpent,
      'status': status,
      'purchased_at': purchasedAt.toIso8601String(),
      'used_at': usedAt?.toIso8601String(),
      'note': note,
    };
  }

  // 상태별 색상
  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B); // 노란색 (대기중)
      case 'approved':
        return const Color(0xFF10B981); // 초록색 (승인됨)
      case 'used':
        return const Color(0xFF6B7280); // 회색 (사용됨)
      case 'expired':
        return const Color(0xFFEF4444); // 빨간색 (만료됨)
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  // 상태 한글 이름
  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return '승인 대기';
      case 'approved':
        return '사용 가능';
      case 'used':
        return '사용 완료';
      case 'expired':
        return '만료됨';
      default:
        return status;
    }
  }

  // 사용 가능 여부
  bool get canUse => status == 'approved';
}
