import '../config/supabase_config.dart';
import '../models/points_history.dart';

class PointsService {
  // 사용자의 현재 포인트 조회
  static Future<UserPoints> getUserPoints(String userId, String relationshipId) async {
    try {
      // points_history 테이블에서 해당 사용자의 모든 포인트 변경 내역 합산
      final response = await supabase
          .from('points_history')
          .select('points_change')
          .eq('user_id', userId)
          .eq('relationship_id', relationshipId);

      int totalPoints = 0;
      for (final record in response) {
        totalPoints += (record['points_change'] as int? ?? 0);
      }

      return UserPoints.fromTotalPoints(
        userId: userId,
        relationshipId: relationshipId,
        totalPoints: totalPoints,
      );
    } catch (e) {
      throw Exception('포인트 조회 실패: $e');
    }
  }

  // 포인트 추가 (규칙 완료, 보상 등)
  static Future<PointsHistory> addPoints({
    required String relationshipId,
    required String userId,
    required int points,
    required String reason,
    String? ruleId,
    String? logId,
  }) async {
    try {
      final response = await supabase
          .from('points_history')
          .insert({
            'relationship_id': relationshipId,
            'user_id': userId,
            'points_change': points,
            'reason': reason,
            'rule_id': ruleId,
            'log_id': logId,
          })
          .select()
          .single();

      return PointsHistory.fromJson(response);
    } catch (e) {
      throw Exception('포인트 추가 실패: $e');
    }
  }

  // 포인트 차감 (처벌, 보상 구매 등)
  static Future<PointsHistory> deductPoints({
    required String relationshipId,
    required String userId,
    required int points,
    required String reason,
    String? ruleId,
  }) async {
    try {
      // 현재 포인트 확인
      final currentPoints = await getUserPoints(userId, relationshipId);
      
      if (currentPoints.totalPoints < points) {
        throw Exception('포인트가 부족합니다. (현재: ${currentPoints.totalPoints}P, 필요: ${points}P)');
      }

      final response = await supabase
          .from('points_history')
          .insert({
            'relationship_id': relationshipId,
            'user_id': userId,
            'points_change': -points, // 음수로 저장
            'reason': reason,
            'rule_id': ruleId,
          })
          .select()
          .single();

      return PointsHistory.fromJson(response);
    } catch (e) {
      throw Exception('포인트 차감 실패: $e');
    }
  }

  // 포인트 히스토리 조회
  static Future<List<PointsHistory>> getPointsHistory({
    required String userId,
    required String relationshipId,
    int? limit,
  }) async {
    try {
      var query = supabase
          .from('points_history')
          .select()
          .eq('user_id', userId)
          .eq('relationship_id', relationshipId)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return response.map<PointsHistory>((json) => PointsHistory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('포인트 히스토리 조회 실패: $e');
    }
  }

  // 특정 기간의 포인트 통계
  static Future<Map<String, dynamic>> getPointsStats({
    required String userId,
    required String relationshipId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await supabase
          .from('points_history')
          .select('points_change, reason')
          .eq('user_id', userId)
          .eq('relationship_id', relationshipId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      int totalEarned = 0;
      int totalSpent = 0;
      int ruleCompletions = 0;
      int rewards = 0;
      int punishments = 0;

      for (final record in response) {
        final points = record['points_change'] as int;
        final reason = record['reason'] as String;

        if (points > 0) {
          totalEarned += points;
          if (reason.contains('규칙') || reason.contains('rule')) {
            ruleCompletions++;
          } else if (reason.contains('보상') || reason.contains('reward')) {
            rewards++;
          }
        } else {
          totalSpent += points.abs();
          if (reason.contains('처벌') || reason.contains('punishment')) {
            punishments++;
          }
        }
      }

      return {
        'totalEarned': totalEarned,
        'totalSpent': totalSpent,
        'netChange': totalEarned - totalSpent,
        'ruleCompletions': ruleCompletions,
        'rewards': rewards,
        'punishments': punishments,
        'transactions': response.length,
      };
    } catch (e) {
      throw Exception('포인트 통계 조회 실패: $e');
    }
  }

  // 이번 주 포인트 통계
  static Future<Map<String, dynamic>> getWeeklyPointsStats(String userId, String relationshipId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return getPointsStats(
      userId: userId,
      relationshipId: relationshipId,
      startDate: startOfWeek,
      endDate: endOfWeek,
    );
  }

  // 이번 달 포인트 통계
  static Future<Map<String, dynamic>> getMonthlyPointsStats(String userId, String relationshipId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return getPointsStats(
      userId: userId,
      relationshipId: relationshipId,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  // 레벨별 사용자 랭킹 (관계 내)
  static Future<List<Map<String, dynamic>>> getRelationshipRanking(String relationshipId) async {
    try {
      // 관계의 모든 사용자 포인트 계산
      final response = await supabase
          .from('points_history')
          .select('user_id, points_change')
          .eq('relationship_id', relationshipId);

      final Map<String, int> userPoints = {};
      
      for (final record in response) {
        final userId = record['user_id'] as String;
        final points = record['points_change'] as int;
        userPoints[userId] = (userPoints[userId] ?? 0) + points;
      }

      // 사용자 정보와 함께 랭킹 생성
      final ranking = <Map<String, dynamic>>[];
      
      for (final entry in userPoints.entries) {
        final userProfile = await supabase
            .from('users_profile')
            .select('display_name, role')
            .eq('id', entry.key)
            .single();

        final userPointsInfo = UserPoints.fromTotalPoints(
          userId: entry.key,
          relationshipId: relationshipId,
          totalPoints: entry.value,
        );

        ranking.add({
          'userId': entry.key,
          'displayName': userProfile['display_name'],
          'role': userProfile['role'],
          'totalPoints': entry.value,
          'level': userPointsInfo.currentLevel,
          'levelTitle': userPointsInfo.levelTitle,
          'levelColor': userPointsInfo.levelColor,
        });
      }

      // 포인트 순으로 정렬
      ranking.sort((a, b) => b['totalPoints'].compareTo(a['totalPoints']));

      return ranking;
    } catch (e) {
      throw Exception('랭킹 조회 실패: $e');
    }
  }

  // 오늘 획득한 포인트
  static Future<int> getTodayPoints(String userId, String relationshipId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final response = await supabase
          .from('points_history')
          .select('points_change')
          .eq('user_id', userId)
          .eq('relationship_id', relationshipId)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      int totalToday = 0;
      for (final record in response) {
        final points = record['points_change'] as int;
        if (points > 0) { // 양수 포인트만 계산 (획득한 포인트)
          totalToday += points;
        }
      }

      return totalToday;
    } catch (e) {
      throw Exception('오늘 포인트 조회 실패: $e');
    }
  }

  // 연속 달성 일수 계산
  static Future<int> getStreakDays(String userId, String relationshipId) async {
    try {
      final response = await supabase
          .from('daily_logs')
          .select('log_date, completed')
          .eq('relationship_id', relationshipId)
          .order('log_date', ascending: false)
          .limit(30); // 최근 30일

      int streak = 0;
      DateTime? lastDate;

      for (final record in response) {
        final logDate = DateTime.parse(record['log_date']);
        final completed = record['completed'] as bool;

        if (lastDate == null) {
          lastDate = logDate;
          if (completed) {
            streak = 1;
          } else {
            break; // 가장 최근 날짜가 미완료면 연속 기록 없음
          }
        } else {
          final dayDiff = lastDate.difference(logDate).inDays;
          
          if (dayDiff == 1 && completed) {
            streak++;
            lastDate = logDate;
          } else {
            break; // 연속이 끊어짐
          }
        }
      }

      return streak;
    } catch (e) {
      return 0; // 오류 시 0 반환
    }
  }
}
