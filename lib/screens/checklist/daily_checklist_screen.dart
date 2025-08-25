import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/daily_log.dart';
import '../../models/relationship.dart';
import '../../services/daily_log_service.dart';
import '../../services/relationship_service.dart';
import '../../providers/auth_provider.dart';

class DailyChecklistScreen extends ConsumerStatefulWidget {
  const DailyChecklistScreen({super.key});

  @override
  ConsumerState<DailyChecklistScreen> createState() => _DailyChecklistScreenState();
}

class _DailyChecklistScreenState extends ConsumerState<DailyChecklistScreen> {
  List<ChecklistItem> _checklistItems = [];
  Relationship? _currentRelationship;
  bool _isLoading = true;
  double _todayProgress = 0.0;
  int _todayPoints = 0;

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
      print('체크리스트: 사용자 ID = ${user.id}'); // 디버그
      
      // 현재 관계 조회
      final relationship = await RelationshipService.getCurrentRelationship(user.id);
      print('체크리스트: 조회된 관계 = $relationship'); // 디버그
      
      if (relationship != null) {
        // 오늘의 체크리스트 조회
        final checklistItems = await DailyLogService.getTodayChecklist(relationship.id);
        print('체크리스트: 조회된 아이템 수 = ${checklistItems.length}'); // 디버그
        
        setState(() {
          _currentRelationship = relationship;
          _checklistItems = checklistItems;
          _todayProgress = DailyLogService.calculateTodayProgress(checklistItems);
          _todayPoints = DailyLogService.calculateTodayPoints(checklistItems);
          _isLoading = false;
        });
        
        print('체크리스트: 계산된 포인트 = $_todayPoints'); // 디버그
        print('체크리스트: 완료된 아이템 수 = ${checklistItems.where((item) => item.isCompleted).length}'); // 디버그
      } else {
        print('체크리스트: 관계가 null입니다'); // 디버그
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('체크리스트: 오류 발생 = $e'); // 디버그
      setState(() => _isLoading = false);
      _showErrorSnackBar('데이터 로드 실패: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleRule(ChecklistItem item) async {
    if (_currentRelationship == null) return;
    
    final user = ref.read(authProvider).user;
    if (user == null) return;

    try {
      if (item.isCompleted) {
        // 완료 취소
        await DailyLogService.uncompleteRule(
          relationshipId: _currentRelationship!.id,
          ruleId: item.ruleId,
        );
        _showSuccessSnackBar('${item.ruleTitle} 완료를 취소했습니다');
      } else {
        // 완료 처리
        print('체크리스트: 규칙 완료 시도 - ${item.ruleTitle}, 포인트: ${item.pointsReward}'); // 디버그
        await DailyLogService.completeRule(
          relationshipId: _currentRelationship!.id,
          ruleId: item.ruleId,
          ruleTitle: item.ruleTitle,
          pointsEarned: item.pointsReward,
          userId: user.id, // 사용자 ID 전달
        );
        print('체크리스트: 규칙 완료 성공'); // 디버그
        _showSuccessSnackBar('${item.ruleTitle} 완료! +${item.pointsReward}P');
      }
      
      _loadData(); // 데이터 새로고침
    } catch (e) {
      _showErrorSnackBar('처리 실패: $e');
    }
  }

  Future<void> _showNoteDialog(ChecklistItem item) async {
    final noteController = TextEditingController(text: item.note ?? '');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('노트 추가 - ${item.ruleTitle}'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '오늘의 수행에 대한 메모를 작성하세요',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(noteController.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (result != null && _currentRelationship != null) {
      try {
        await DailyLogService.addNoteToRule(
          relationshipId: _currentRelationship!.id,
          ruleId: item.ruleId,
          note: result,
        );
        _loadData();
        _showSuccessSnackBar('노트가 저장되었습니다');
      } catch (e) {
        _showErrorSnackBar('노트 저장 실패: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(authProvider).profile;
    
    // 멘티가 아닌 경우 접근 제한
    if (userProfile == null || userProfile.isMentor) {
      return Scaffold(
        appBar: AppBar(title: const Text('접근 제한')),
        body: const Center(
          child: Text(
            '멘티만 접근 가능한 화면입니다',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          '오늘의 체크리스트',
          style: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: Color(0xFF6B7280)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentRelationship == null
              ? _buildNoRelationshipMessage()
              : Column(
                  children: [
                    // 진행률 요약
                    _buildProgressSummary(),
                    
                    // 체크리스트
                    Expanded(
                      child: _checklistItems.isEmpty
                          ? _buildEmptyState()
                          : _buildChecklistView(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildNoRelationshipMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link_off,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 16),
            Text(
              '연결된 관계가 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '멘토와 관계를 먼저 연결해주세요',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary() {
    final completedCount = _checklistItems.where((item) => item.isCompleted).length;
    final totalCount = _checklistItems.length;

    return Container(
      margin: const EdgeInsets.all(16),
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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘의 진행률',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedCount / $totalCount',
                    style: GoogleFonts.notoSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '획득 포인트',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_todayPoints}P',
                    style: GoogleFonts.notoSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFBBF24),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 진행률 바
          LinearProgressIndicator(
            value: _todayProgress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '${(_todayProgress * 100).toInt()}% 완료',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '오늘 수행할 규칙이 없습니다',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '멘토가 목표를 설정해주면 여기에 표시됩니다',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _checklistItems.length,
      itemBuilder: (context, index) {
        final item = _checklistItems[index];
        return _buildChecklistCard(item);
      },
    );
  }

  Widget _buildChecklistCard(ChecklistItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: item.isCompleted 
            ? Border.all(color: const Color(0xFF10B981), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _toggleRule(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 체크박스
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: item.isCompleted 
                      ? const Color(0xFF10B981) 
                      : Colors.transparent,
                  border: Border.all(
                    color: item.isCompleted 
                        ? const Color(0xFF10B981) 
                        : const Color(0xFFD1D5DB),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: item.isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // 카테고리 아이콘
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.difficultyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.categoryIcon,
                  color: item.difficultyColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              
              // 규칙 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.ruleTitle,
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: item.isCompleted 
                            ? const Color(0xFF10B981)
                            : const Color(0xFF374151),
                        decoration: item.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                    ),
                    if (item.ruleDescription != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.ruleDescription!,
                        style: TextStyle(
                          fontSize: 14,
                          color: item.isCompleted 
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF9CA3AF),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildChip(
                          item.categoryDisplayName,
                          item.difficultyColor.withOpacity(0.1),
                          item.difficultyColor,
                        ),
                        const SizedBox(width: 8),
                        _buildChip(
                          item.difficultyDisplayName,
                          item.difficultyColor.withOpacity(0.1),
                          item.difficultyColor,
                        ),
                        const SizedBox(width: 8),
                        _buildChip(
                          '${item.pointsReward}P',
                          const Color(0xFFFBBF24).withOpacity(0.1),
                          const Color(0xFFFBBF24),
                        ),
                      ],
                    ),
                    if (item.isCompleted && item.completedAt != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '완료: ${item.todayLog!.formattedCompletedTime}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (item.note != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.note,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.note!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // 노트 버튼
              IconButton(
                onPressed: () => _showNoteDialog(item),
                icon: Icon(
                  Icons.note_add,
                  color: item.note != null 
                      ? const Color(0xFF6B46C1) 
                      : Colors.grey[400],
                ),
                tooltip: '노트 추가',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
