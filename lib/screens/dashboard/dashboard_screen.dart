import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/relationship_stats.dart';
import '../../models/relationship.dart';
import '../../models/user_profile.dart';
import '../../widgets/dashboard/growth_gauge.dart';
import '../../widgets/dashboard/mentoring_thermometer.dart';
import '../../providers/auth_provider.dart';
import '../../services/relationship_service.dart';
import '../../services/daily_log_service.dart';
import '../../services/points_service.dart';
import '../../services/journal_service.dart';
import '../../models/daily_log.dart';
import '../../models/points_history.dart';
import '../../models/recent_activity.dart';
import '../../config/supabase_config.dart';
import '../relationship/create_invitation_screen.dart';
import '../relationship/join_invitation_screen.dart';
import '../rules/rules_management_screen.dart';
import '../checklist/daily_checklist_screen.dart';
import '../points/points_screen.dart';
import '../rewards/rewards_management_screen.dart';
import '../rewards/reward_shop_screen.dart';
import '../journal/journal_list_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  RelationshipStats? _stats;
  Relationship? _currentRelationship;
  bool _isLoading = true;
  List<ChecklistItem> _todayChecklist = [];
  double _todayProgress = 0.0;
  int _todayPoints = 0;
  UserPoints? _userPoints;
  int _totalJournals = 0;
  int _weeklyCompletedRules = 0;
  int _totalActiveRules = 0;
  List<RecentActivity> _recentActivities = [];
  List<double> _weeklyProgressData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 현재 관계 조회
      final relationship = await RelationshipService.getCurrentRelationship(user.id);
      
      if (relationship != null) {
        // 실제 데이터 로드
        await _loadRealData(relationship.id, user.id);
        
        // 실제 데이터로 RelationshipStats 생성
          _stats = RelationshipStats(
          relationshipId: relationship.id,
          mentorId: relationship.mentorId,
          menteeId: relationship.menteeId,
          totalLogs: _totalActiveRules,
          completedLogs: _weeklyCompletedRules,
          completionRate: _totalActiveRules > 0 
              ? (_weeklyCompletedRules / _totalActiveRules * 100) 
              : 0.0,
          journalEntries: _totalJournals,
          lastActivity: DateTime.now(),
        );
      }

      setState(() {
        _currentRelationship = relationship;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRealData(String relationshipId, String userId) async {
    try {
      // 포인트 정보
      final userPoints = await PointsService.getUserPoints(userId, relationshipId);
      
      // 오늘의 체크리스트
      final todayChecklist = await DailyLogService.getTodayChecklist(relationshipId);
      
      // 일지 개수 (최근 30일)
      final journals = await JournalService.getJournals(
        relationshipId: relationshipId,
        userId: userId,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
      );
      
      // 최근 7일간 완료된 규칙 수 계산
      int weeklyCompleted = 0;
      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dayChecklist = await DailyLogService.getTodayChecklist(relationshipId);
        weeklyCompleted += dayChecklist.where((item) => item.isCompleted).length;
      }
      
      // 오늘 진행률 계산
      final completedToday = todayChecklist.where((item) => item.isCompleted).length;
      final totalToday = todayChecklist.length;
      final todayProgress = totalToday > 0 ? (completedToday / totalToday) : 0.0;
      
      // 오늘 획득 포인트 계산
      final todayPoints = todayChecklist
          .where((item) => item.isCompleted)
          .fold<int>(0, (sum, item) => sum + item.pointsReward);

      // 최근 활동 로드
      final recentActivities = await _loadRecentActivities(relationshipId, userId);
      
      // 주간 진행률 데이터 로드
      final weeklyProgressData = await _loadWeeklyProgressData(relationshipId);

      setState(() {
        _userPoints = userPoints;
        _todayChecklist = todayChecklist;
        _todayProgress = todayProgress;
        _todayPoints = todayPoints;
        _totalJournals = journals.length;
        _weeklyCompletedRules = weeklyCompleted;
        _totalActiveRules = totalToday * 7; // 일주일치 총 규칙 수
        _recentActivities = recentActivities;
        _weeklyProgressData = weeklyProgressData;
      });
    } catch (e) {
      print('실제 데이터 로드 실패: $e');
    }
  }

  Future<List<RecentActivity>> _loadRecentActivities(String relationshipId, String userId) async {
    List<RecentActivity> activities = [];

    try {
      // 최근 완료된 규칙들 (최근 7일)
      final completedLogs = await supabase
          .from('daily_logs')
          .select('''
            id,
            completed_at,
            rule_id,
            rules (
              id,
              title
            )
          ''')
          .eq('completed', true)
          .gte('completed_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
          .order('completed_at', ascending: false)
          .limit(5);

      for (final log in completedLogs) {
        if (log['completed_at'] != null && log['rules'] != null) {
          activities.add(RecentActivity(
            id: log['id'],
            title: '${log['rules']['title']} 완료',
            description: '규칙 달성',
            timestamp: DateTime.parse(log['completed_at']),
            type: ActivityType.ruleCompleted,
            icon: Icons.check_circle,
            color: const Color(0xFF10B981),
          ));
        }
      }

      // 최근 작성된 일지들 (최근 7일)
      final recentJournals = await supabase
          .from('emotional_journals')
          .select('id, title, created_at')
          .eq('relationship_id', relationshipId)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
          .order('created_at', ascending: false)
          .limit(3);

      for (final journal in recentJournals) {
        activities.add(RecentActivity(
          id: journal['id'],
          title: '감정 일지 작성',
          description: journal['title'] ?? '일지 작성',
          timestamp: DateTime.parse(journal['created_at']),
          type: ActivityType.journalCreated,
          icon: Icons.edit,
          color: const Color(0xFF3B82F6),
        ));
      }

      // 최근 포인트 히스토리 (보상 관련)
      final recentRewards = await supabase
          .from('points_history')
          .select('id, points_change, reason, created_at')
          .eq('user_id', userId)
          .gt('points_change', 0)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
          .order('created_at', ascending: false)
          .limit(3);

      for (final reward in recentRewards) {
        activities.add(RecentActivity(
          id: reward['id'],
          title: '포인트 획득',
          description: '${reward['reason']} (+${reward['points_change']}P)',
          timestamp: DateTime.parse(reward['created_at']),
          type: ActivityType.rewardReceived,
          icon: Icons.star,
          color: const Color(0xFFF59E0B),
        ));
      }

      // 시간순으로 정렬하고 최대 5개만 반환
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return activities.take(5).toList();

    } catch (e) {
      print('최근 활동 로드 실패: $e');
      return [];
    }
  }

  Future<List<double>> _loadWeeklyProgressData(String relationshipId) async {
    List<double> weeklyProgress = [];

    try {
      // 최근 7일간의 진행률 계산
      for (int i = 6; i >= 0; i--) {
        final targetDate = DateTime.now().subtract(Duration(days: i));
        final dateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
        
        // 해당 날짜의 규칙들 조회
        final rulesResponse = await supabase
            .from('rules')
            .select('id')
            .eq('relationship_id', relationshipId)
            .eq('is_active', true);

        if (rulesResponse.isEmpty) {
          weeklyProgress.add(0.0);
          continue;
        }

        final ruleIds = rulesResponse.map((rule) => rule['id']).toList();
        final totalRules = ruleIds.length;

        // 해당 날짜에 완료된 규칙들 조회
        final completedLogsResponse = await supabase
            .from('daily_logs')
            .select('id')
            .inFilter('rule_id', ruleIds)
            .eq('log_date', dateStr)
            .eq('completed', true);

        final completedCount = completedLogsResponse.length;
        final progressRate = totalRules > 0 ? completedCount / totalRules : 0.0;
        
        weeklyProgress.add(progressRate);
      }

      return weeklyProgress;
    } catch (e) {
      print('주간 진행률 로드 실패: $e');
      // 기본값 반환 (7일간 0.0)
      return List.generate(7, (index) => 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userProfile = authState.profile;

    if (userProfile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '안녕하세요, ${userProfile.displayName}님!',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            Text(
              userProfile.isMentor ? '멘토로 로그인됨' : '멘티로 로그인됨',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          // 멘토인 경우 규칙 관리 버튼 표시
          if (userProfile != null && userProfile.isMentor && _currentRelationship != null)
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RulesManagementScreen(),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.rule, color: Color(0xFF6B46C1)),
              tooltip: '규칙 관리',
            ),
          // 멘토인 경우 보상 관리 버튼 표시
          if (userProfile != null && userProfile.isMentor && _currentRelationship != null)
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RewardsManagementScreen(),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.card_giftcard, color: Color(0xFF10B981)),
              tooltip: '보상 & 처벌 관리',
            ),
          // 멘티인 경우 체크리스트 버튼 표시
          if (userProfile != null && !userProfile.isMentor && _currentRelationship != null)
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DailyChecklistScreen(),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.assignment_turned_in, color: Color(0xFF10B981)),
              tooltip: '오늘의 체크리스트',
            ),
          // 멘티인 경우 보상 상점 버튼 표시
          if (userProfile != null && !userProfile.isMentor && _currentRelationship != null)
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RewardShopScreen(),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.store, color: Color(0xFFEC4899)),
              tooltip: '보상 상점',
            ),
          // 포인트 화면 버튼 (모든 사용자)
          if (userProfile != null && _currentRelationship != null)
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PointsScreen(),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.stars, color: Color(0xFFFBBF24)),
              tooltip: '포인트 & 레벨',
            ),
          // 감정 일지 버튼 (모든 사용자)
          if (userProfile != null && _currentRelationship != null)
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const JournalListScreen(),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.book, color: Color(0xFF8B5CF6)),
              tooltip: '감정 일지',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Color(0xFF6B7280)),
                      SizedBox(width: 8),
                      Text('로그아웃'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentRelationship == null
              ? _buildNoRelationshipScreen(userProfile!)
              : _stats == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 성장 현황 카드
                  _buildGrowthStatusCard(),
                  const SizedBox(height: 20),

                  // 대시보드 그리드
                  if (MediaQuery.of(context).size.width > 600)
                    // 태블릿/데스크톱 레이아웃
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GrowthGauge(
                            percentage: _stats!.completionRate,
                            color: _stats!.growthGaugeColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MentoringThermometer(
                            temperature: _stats!.mentoringTemperature,
                            color: _stats!.temperatureColor,
                            status: _stats!.temperatureStatus,
                          ),
                        ),
                      ],
                    )
                  else
                    // 모바일 레이아웃
                    Column(
                      children: [
                        GrowthGauge(
                          percentage: _stats!.completionRate,
                          color: _stats!.growthGaugeColor,
                        ),
                        const SizedBox(height: 20),
                        MentoringThermometer(
                          temperature: _stats!.mentoringTemperature,
                          color: _stats!.temperatureColor,
                          status: _stats!.temperatureStatus,
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // 최근 활동
                  _buildRecentActivity(),

                  const SizedBox(height: 20),

                  // 주간 진행률 차트
                  _buildWeeklyProgress(),
                ],
              ),
            ),
    );
  }

  Widget _buildGrowthStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B46C1),
            Color(0xFF9333EA),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B46C1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.dashboard_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Dashboard',
                style: GoogleFonts.notoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildGrowthStatusItem(
                  '오늘 완료',
                  '${_todayChecklist.where((item) => item.isCompleted).length}/${_todayChecklist.length}',
                  Icons.check_circle,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildGrowthStatusItem(
                  '현재 포인트',
                  '${_userPoints?.totalPoints ?? 0}P',
                  Icons.stars,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildGrowthStatusItem(
                  '감정 일지',
                  '${_totalJournals}개',
                  Icons.book,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthStatusItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                color: Color(0xFF6B46C1),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '최근 활동',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentActivities.isEmpty)
            _buildEmptyActivity()
          else
            ..._recentActivities.map((activity) => _buildActivityItem(
              activity.title,
              activity.timeAgo,
              activity.icon,
              activity.color,
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32,horizontal: 40),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 48,
            color:  Color(0xFF9CA3AF),
          ),
          SizedBox(height: 12),
          Text(
            '아직 활동 기록이 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 3),
          Text(
            '규칙을 완료하거나 일지를 작성해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFD1D5DB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: Color(0xFF6B46C1),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '주간 진행률',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 간단한 주간 진행률 바 차트
          _weeklyProgressData.isEmpty 
            ? _buildEmptyWeeklyProgress()
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  final days = ['월', '화', '수', '목', '금', '토', '일'];
                  final heights = _weeklyProgressData;
              return Column(
                children: [
                  Container(
                    width: 30,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 30,
                        height: 100 * (index < heights.length ? heights[index] : 0.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B46C1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getLastActivityText() {
    if (_stats!.lastActivity == null) return '활동 없음';

    final difference = DateTime.now().difference(_stats!.lastActivity!);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.transparent),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.logout,
                color: Color(0xFF6B46C1),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                '로그아웃',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            '정말 로그아웃하시겠습니까?\n자동 로그인이 설정되어 있다면 다음에 자동으로 로그인됩니다.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '취소',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoRelationshipScreen(UserProfile userProfile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // 환영 메시지
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: userProfile.isMentor 
                    ? [const Color(0xFF6B46C1), const Color(0xFF9333EA)]
                    : [const Color(0xFF10B981), const Color(0xFF34D399)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  userProfile.isMentor ? Icons.psychology : Icons.school,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  '${userProfile.displayName}님, 환영합니다!',
                  style: GoogleFonts.notoSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userProfile.isMentor 
                      ? '멘토로서 특별한 관계를 시작해보세요'
                      : '멘티로서 새로운 여정을 시작해보세요',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // 역할별 안내
          if (userProfile.isMentor) ...[
            _buildMentorInstructions(),
          ] else ...[
            _buildMenteeInstructions(),
          ],

          const SizedBox(height: 32),

          // 액션 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => userProfile.isMentor 
                        ? const CreateInvitationScreen()
                        : const JoinInvitationScreen(),
                  ),
                ).then((_) => _loadData()); // 화면 복귀 시 데이터 새로고침
              },
              icon: Icon(userProfile.isMentor ? Icons.add : Icons.key),
              label: Text(
                userProfile.isMentor ? '초대 코드 생성' : '초대 코드 입력',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: userProfile.isMentor 
                    ? const Color(0xFF6B46C1)
                    : const Color(0xFFEC4899),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWeeklyProgress() {
    return Container(
      height: 140,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 12),
          Text(
            '주간 진행률 데이터가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '규칙을 생성하고 완료해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFD1D5DB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Color(0xFF6B46C1),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '멘토 시작 가이드',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '1', 
            '초대 코드 생성', 
            '멘티와 연결하기 위한 고유 코드를 만들어요',
          ),
          _buildInstructionStep(
            '2', 
            '코드 공유', 
            '멘티에게 초대 코드를 안전하게 전달해요',
          ),
          _buildInstructionStep(
            '3', 
            '관계 시작', 
            '멘티가 코드를 입력하면 자동으로 연결됩니다',
          ),
          _buildInstructionStep(
            '4', 
            '규칙 관리', 
            '함께 규칙을 만들고 성장해나가요',
          ),
        ],
      ),
    );
  }

  Widget _buildMenteeInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.favorite,
                color: Color(0xFFEC4899),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '멘티 시작 가이드',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '1', 
            '멘토로부터 초대 코드 받기', 
            '멘토가 생성한 6자리 초대 코드를 받아요',
          ),
          _buildInstructionStep(
            '2', 
            '초대 코드 입력', 
            '받은 코드를 정확히 입력해주세요',
          ),
          _buildInstructionStep(
            '3', 
            '관계 연결', 
            '멘토와 자동으로 연결되어 관계가 시작됩니다',
          ),
          _buildInstructionStep(
            '4', 
            '규칙 따르기', 
            '멘토가 설정한 목표를 달성하며 성장해요',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF6B46C1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B46C1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
