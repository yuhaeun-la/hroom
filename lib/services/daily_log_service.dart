import '../config/supabase_config.dart';
import '../models/daily_log.dart';
import '../models/rule.dart';
import 'points_service.dart';

class DailyLogService {
  // 특정 날짜의 체크리스트 가져오기
  static Future<List<ChecklistItem>> getTodayChecklist(String relationshipId) async {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    try {
      // 활성 규칙 조회
      final rulesResponse = await supabase
          .from('rules')
          .select()
          .eq('relationship_id', relationshipId)
          .eq('is_active', true)
          .eq('frequency', 'daily') // 일일 규칙만
          .order('created_at', ascending: false);

      final rules = rulesResponse.map<Rule>((json) => Rule.fromJson(json)).toList();

      // 오늘의 로그 조회
      final logsResponse = await supabase
          .from('daily_logs')
          .select()
          .eq('relationship_id', relationshipId)
          .eq('log_date', todayString);

      final logs = logsResponse.map<DailyLog>((json) => DailyLog.fromJson(json)).toList();

      // 체크리스트 아이템 생성
      final checklistItems = <ChecklistItem>[];
      
      print('체크리스트 생성: 규칙 수 = ${rules.length}, 로그 수 = ${logs.length}'); // 디버그
      
      for (final rule in rules) {
        final todayLog = logs.where((log) => log.ruleId == rule.id).firstOrNull;
        
        print('규칙 ${rule.title}: 로그 존재 = ${todayLog != null}, 완료 = ${todayLog?.completed}, 포인트 = ${rule.pointsReward}'); // 디버그
        
        checklistItems.add(ChecklistItem(
          ruleId: rule.id,
          ruleTitle: rule.title,
          ruleDescription: rule.description,
          category: rule.category,
          difficulty: rule.difficulty,
          pointsReward: rule.pointsReward,
          categoryIcon: rule.categoryIcon,
          difficultyColor: rule.difficultyColor,
          todayLog: todayLog,
        ));
      }

      return checklistItems;
    } catch (e) {
      throw Exception('체크리스트 조회 실패: $e');
    }
  }

  // 규칙 완료 처리
  static Future<DailyLog> completeRule({
    required String relationshipId,
    required String ruleId,
    required String ruleTitle,
    required int pointsEarned,
    required String userId, // Sub의 사용자 ID 추가
    String? note,
    String? photoUrl,
  }) async {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    try {
      // 이미 오늘 로그가 있는지 확인
      final existingLogs = await supabase
          .from('daily_logs')
          .select()
          .eq('relationship_id', relationshipId)
          .eq('rule_id', ruleId)
          .eq('log_date', todayString);

      if (existingLogs.isNotEmpty) {
        // 기존 로그 업데이트
        final response = await supabase
            .from('daily_logs')
                      .update({
            'completed': true,
            // 'notes': note, // 임시로 주석 처리 (컬럼 없음)
            // 'proof_image_url': photoUrl, // 임시로 주석 처리
          })
            .eq('id', existingLogs.first['id'])
            .select()
            .single();

        final dailyLog = DailyLog.fromJson(response);
        
        // 포인트 적립 (이미 완료된 경우 중복 적립 방지)
        if (!existingLogs.first['completed']) {
          await PointsService.addPoints(
            relationshipId: relationshipId,
            userId: userId,
            points: pointsEarned,
            reason: '규칙 완료: $ruleTitle',
            ruleId: ruleId,
            logId: dailyLog.id,
          );
        }
        
        return dailyLog;
      } else {
        // 새 로그 생성
        final response = await supabase
            .from('daily_logs')
            .insert({
              'relationship_id': relationshipId,
              'rule_id': ruleId,
              'log_date': todayString,
              'completed': true,
              // 'notes': note, // 임시로 주석 처리 (컬럼 없음)
              // 'proof_image_url': photoUrl, // 임시로 주석 처리
            })
            .select()
            .single();

        final dailyLog = DailyLog.fromJson(response);
        
        // 포인트 적립
        await PointsService.addPoints(
          relationshipId: relationshipId,
          userId: userId,
          points: pointsEarned,
          reason: '규칙 완료: $ruleTitle',
          ruleId: ruleId,
          logId: dailyLog.id,
        );
        
        return dailyLog;
      }
    } catch (e) {
      throw Exception('규칙 완료 처리 실패: $e');
    }
  }

  // 규칙 완료 취소
  static Future<DailyLog> uncompleteRule({
    required String relationshipId,
    required String ruleId,
  }) async {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    try {
      final response = await supabase
          .from('daily_logs')
          .update({
            'completed': false,
            // 'notes': null, // 임시로 주석 처리 (컬럼 없음)
            // 'proof_image_url': null, // 임시로 주석 처리
          })
          .eq('relationship_id', relationshipId)
          .eq('rule_id', ruleId)
          .eq('log_date', todayString)
          .select()
          .single();

      return DailyLog.fromJson(response);
    } catch (e) {
      throw Exception('규칙 완료 취소 실패: $e');
    }
  }

  // 특정 기간의 로그 조회
  static Future<List<DailyLog>> getLogsByDateRange({
    required String relationshipId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startString = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endString = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final response = await supabase
          .from('daily_logs')
          .select()
          .eq('relationship_id', relationshipId)
          .gte('log_date', startString)
          .lte('log_date', endString)
          .order('log_date', ascending: false);

      return response.map<DailyLog>((json) => DailyLog.fromJson(json)).toList();
    } catch (e) {
      throw Exception('로그 조회 실패: $e');
    }
  }

  // 이번 주 완료 통계
  static Future<Map<String, dynamic>> getWeeklyStats(String relationshipId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    try {
      final logs = await getLogsByDateRange(
        relationshipId: relationshipId,
        startDate: startOfWeek,
        endDate: endOfWeek,
      );

      final completedLogs = logs.where((log) => log.completed).toList();
      final totalPoints = completedLogs.fold<int>(0, (sum, log) => sum + log.pointsEarned);

      return {
        'totalRules': logs.length,
        'completedRules': completedLogs.length,
        'completionRate': logs.isEmpty ? 0.0 : (completedLogs.length / logs.length),
        'totalPoints': totalPoints,
        'avgPointsPerDay': totalPoints / 7,
      };
    } catch (e) {
      throw Exception('주간 통계 조회 실패: $e');
    }
  }

  // 오늘의 진행률 계산
  static double calculateTodayProgress(List<ChecklistItem> items) {
    if (items.isEmpty) return 0.0;
    
    final completedCount = items.where((item) => item.isCompleted).length;
    return completedCount / items.length;
  }

  // 오늘 획득한 총 포인트
  static int calculateTodayPoints(List<ChecklistItem> items) {
    return items
        .where((item) => item.isCompleted)
        .fold<int>(0, (sum, item) => sum + item.pointsReward);
  }

  // 규칙에 노트 추가
  static Future<DailyLog> addNoteToRule({
    required String relationshipId,
    required String ruleId,
    required String note,
  }) async {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    try {
      final response = await supabase
          .from('daily_logs')
          .update({
            // 'notes': note, // 임시로 주석 처리 (컬럼 없음)
            'completed': true, // 일단 완료 상태만 업데이트
          })
          .eq('relationship_id', relationshipId)
          .eq('rule_id', ruleId)
          .eq('log_date', todayString)
          .select()
          .single();

      return DailyLog.fromJson(response);
    } catch (e) {
      throw Exception('노트 추가 실패: $e');
    }
  }
}
