import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/rule.dart';
import '../../models/relationship.dart';
import '../../services/rule_service.dart';
import '../../services/relationship_service.dart';
import '../../providers/auth_provider.dart';
import 'create_rule_screen.dart';
import 'edit_rule_screen.dart';

class RulesManagementScreen extends ConsumerStatefulWidget {
  const RulesManagementScreen({super.key});

  @override
  ConsumerState<RulesManagementScreen> createState() => _RulesManagementScreenState();
}

class _RulesManagementScreenState extends ConsumerState<RulesManagementScreen> {
  List<Rule> _rules = [];
  Relationship? _currentRelationship;
  bool _isLoading = true;
  String _selectedCategory = 'all';

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
        // 규칙 목록 조회
        final rules = await RuleService.getRulesByRelationship(relationship.id);
        
        setState(() {
          _currentRelationship = relationship;
          _rules = rules;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('데이터 로드 실패: $e');
    }
  }

  List<Rule> get _filteredRules {
    if (_selectedCategory == 'all') {
      return _rules;
    }
    return _rules.where((rule) => rule.category == _selectedCategory).toList();
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

  Future<void> _toggleRuleActive(Rule rule) async {
    try {
      await RuleService.toggleRuleActive(rule.id, !rule.isActive);
      _loadData(); // 데이터 새로고침
      _showSuccessSnackBar(
        rule.isActive ? '규칙이 비활성화되었습니다' : '규칙이 활성화되었습니다',
      );
    } catch (e) {
      _showErrorSnackBar('규칙 상태 변경 실패: $e');
    }
  }

  Future<void> _deleteRule(Rule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('규칙 삭제'),
        content: Text('정말로 "${rule.title}" 규칙을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await RuleService.deleteRule(rule.id);
        _loadData();
        _showSuccessSnackBar('규칙이 삭제되었습니다');
      } catch (e) {
        _showErrorSnackBar('규칙 삭제 실패: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(authProvider).profile;
    
    // 멘토가 아닌 경우 접근 제한
    if (userProfile == null || !userProfile.isMentor) {
      return Scaffold(
        appBar: AppBar(title: const Text('접근 제한')),
        body: const Center(
          child: Text(
            '멘토만 접근 가능한 화면입니다',
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
          '규칙 관리',
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
                    // 카테고리 필터
                    _buildCategoryFilter(),
                    
                    // 규칙 목록
                    Expanded(
                      child: _filteredRules.isEmpty
                          ? _buildEmptyState()
                          : _buildRulesList(),
                    ),
                  ],
                ),
      floatingActionButton: _currentRelationship != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateRuleScreen(
                      relationshipId: _currentRelationship!.id,
                    ),
                  ),
                ).then((_) => _loadData());
              },
              backgroundColor: const Color(0xFF6B46C1),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                '새 규칙',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
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
              '멘티와 관계를 먼저 연결해주세요',
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

  Widget _buildCategoryFilter() {
    final categories = [
      {'id': 'all', 'name': '전체', 'icon': Icons.all_inclusive},
      ...RuleService.getAvailableCategories(),
    ];

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['id'] as String;
                });
              },
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6B46C1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      color: isSelected ? Colors.white : const Color(0xFF6B46C1),
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF374151),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
              Icons.rule,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == 'all' ? '규칙이 없습니다' : '해당 카테고리에 규칙이 없습니다',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '멘티를 위한 첫 번째 목표를 설정해보세요',
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

  Widget _buildRulesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRules.length,
      itemBuilder: (context, index) {
        final rule = _filteredRules[index];
        return _buildRuleCard(rule);
      },
    );
  }

  Widget _buildRuleCard(Rule rule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: rule.difficultyColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            rule.categoryIcon,
            color: rule.difficultyColor,
            size: 24,
          ),
        ),
        title: Text(
          rule.title,
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: rule.isActive ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rule.description != null) ...[
              const SizedBox(height: 4),
              Text(
                rule.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: rule.isActive ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildChip(
                  rule.categoryDisplayName,
                  rule.difficultyColor.withOpacity(0.1),
                  rule.difficultyColor,
                ),
                _buildChip(
                  rule.difficultyDisplayName,
                  rule.difficultyColor.withOpacity(0.1),
                  rule.difficultyColor,
                ),
                _buildChip(
                  rule.frequencyDisplayName,
                  const Color(0xFF3B82F6).withOpacity(0.1),
                  const Color(0xFF3B82F6),
                ),
                _buildChip(
                  '${rule.pointsReward}P',
                  const Color(0xFFF59E0B).withOpacity(0.1),
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditRuleScreen(rule: rule),
                  ),
                ).then((_) => _loadData());
                break;
              case 'toggle':
                _toggleRuleActive(rule);
                break;
              case 'delete':
                _deleteRule(rule);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('수정'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    rule.isActive ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(rule.isActive ? '비활성화' : '활성화'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('삭제', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
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
