import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/reward_punishment.dart';
import '../../models/relationship.dart';
import '../../services/reward_service.dart';
import '../../services/relationship_service.dart';
import '../../providers/auth_provider.dart';
import 'create_reward_screen.dart';

class RewardsManagementScreen extends ConsumerStatefulWidget {
  const RewardsManagementScreen({super.key});

  @override
  ConsumerState<RewardsManagementScreen> createState() => _RewardsManagementScreenState();
}

class _RewardsManagementScreenState extends ConsumerState<RewardsManagementScreen>
    with SingleTickerProviderStateMixin {
  List<RewardPunishment> _rewards = [];
  List<RewardPunishment> _punishments = [];
  Relationship? _currentRelationship;
  bool _isLoading = true;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 현재 관계 조회
      final relationship = await RelationshipService.getCurrentRelationship(user.id);
      
      if (relationship != null) {
        // 보상 목록 조회
        final rewards = await RewardService.getRewards(
          relationshipId: relationship.id,
          type: 'reward',
        );
        
        // 처벌 목록 조회
        final punishments = await RewardService.getRewards(
          relationshipId: relationship.id,
          type: 'punishment',
        );
        
        setState(() {
          _currentRelationship = relationship;
          _rewards = rewards;
          _punishments = punishments;
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

  Future<void> _toggleRewardActive(RewardPunishment item) async {
    try {
      await RewardService.updateReward(
        rewardId: item.id,
        isActive: !item.isActive,
      );
      _loadData();
      _showSuccessSnackBar(
        item.isActive ? '${item.title}이(가) 비활성화되었습니다' : '${item.title}이(가) 활성화되었습니다',
      );
    } catch (e) {
      _showErrorSnackBar('상태 변경 실패: $e');
    }
  }

  Future<void> _deleteReward(RewardPunishment item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.isReward ? '보상' : '처벌'} 삭제'),
        content: Text('정말로 "${item.title}"을(를) 삭제하시겠습니까?'),
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
        await RewardService.deleteReward(item.id);
        _loadData();
        _showSuccessSnackBar('${item.title}이(가) 삭제되었습니다');
      } catch (e) {
        _showErrorSnackBar('삭제 실패: $e');
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
          '보상 & 처벌 관리',
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.card_giftcard),
              text: '보상 (${_rewards.length})',
            ),
            Tab(
              icon: const Icon(Icons.warning),
              text: '처벌 (${_punishments.length})',
            ),
          ],
          labelColor: const Color(0xFF6B46C1),
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: const Color(0xFF6B46C1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentRelationship == null
              ? _buildNoRelationshipMessage()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRewardsList(),
                    _buildPunishmentsList(),
                  ],
                ),
      floatingActionButton: _currentRelationship != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateRewardScreen(
                      relationshipId: _currentRelationship!.id,
                      initialType: _tabController.index == 0 ? 'reward' : 'punishment',
                    ),
                  ),
                ).then((_) => _loadData());
              },
              backgroundColor: const Color(0xFF6B46C1),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'new',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsList() {
    if (_rewards.isEmpty) {
      return _buildEmptyState('보상', Icons.card_giftcard);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rewards.length,
      itemBuilder: (context, index) {
        final reward = _rewards[index];
        return _buildRewardCard(reward);
      },
    );
  }

  Widget _buildPunishmentsList() {
    if (_punishments.isEmpty) {
      return _buildEmptyState('처벌', Icons.warning);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _punishments.length,
      itemBuilder: (context, index) {
        final punishment = _punishments[index];
        return _buildRewardCard(punishment);
      },
    );
  }

  Widget _buildEmptyState(String type, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '$type이 없습니다',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '멘티를 위한 첫 번째 $type을 만들어보세요',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(RewardPunishment item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: item.isActive 
            ? null 
            : Border.all(color: Colors.grey[300]!, width: 1),
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
            color: item.categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item.categoryIcon,
            color: item.categoryColor,
            size: 24,
          ),
        ),
        title: Text(
          item.title,
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: item.isActive ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null) ...[
              const SizedBox(height: 4),
              Text(
                item.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: item.isActive ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
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
                  item.categoryDisplayName,
                  item.categoryColor.withOpacity(0.1),
                  item.categoryColor,
                ),
                _buildChip(
                  '${item.pointsCost}P',
                  item.typeColor.withOpacity(0.1),
                  item.typeColor,
                ),
                if (item.isLimited) ...[
                  _buildChip(
                    '${item.remainingCount}/${item.limitCount}',
                    const Color(0xFFF59E0B).withOpacity(0.1),
                    const Color(0xFFF59E0B),
                  ),
                ],
                if (!item.isActive) ...[
                  _buildChip(
                    '비활성',
                    Colors.grey.withOpacity(0.1),
                    Colors.grey,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'toggle':
                _toggleRewardActive(item);
                break;
              case 'delete':
                _deleteReward(item);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    item.isActive ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(item.isActive ? '비활성화' : '활성화'),
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
