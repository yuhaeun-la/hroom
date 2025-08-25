import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/reward_punishment.dart';
import '../../models/relationship.dart';
import '../../models/points_history.dart';
import '../../services/reward_service.dart';
import '../../services/relationship_service.dart';
import '../../services/points_service.dart';
import '../../providers/auth_provider.dart';

class RewardShopScreen extends ConsumerStatefulWidget {
  const RewardShopScreen({super.key});

  @override
  ConsumerState<RewardShopScreen> createState() => _RewardShopScreenState();
}

class _RewardShopScreenState extends ConsumerState<RewardShopScreen> {
  List<RewardPunishment> _rewards = [];
  List<RewardPurchase> _purchases = [];
  Relationship? _currentRelationship;
  UserPoints? _userPoints;
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
        // 활성 보상 목록 조회
        final rewards = await RewardService.getActiveRewards(relationship.id);
        
        // 사용자 포인트 정보 조회
        final userPoints = await PointsService.getUserPoints(user.id, relationship.id);
        
        // 구매 내역 조회
        final purchases = await RewardService.getPurchaseHistory(
          relationshipId: relationship.id,
          userId: user.id,
        );
        
        setState(() {
          _currentRelationship = relationship;
          _rewards = rewards;
          _userPoints = userPoints;
          _purchases = purchases;
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

  List<RewardPunishment> get _filteredRewards {
    if (_selectedCategory == 'all') {
      return _rewards;
    }
    return _rewards.where((reward) => reward.category == _selectedCategory).toList();
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

  Future<void> _purchaseReward(RewardPunishment reward) async {
    final user = ref.read(authProvider).user;
    if (user == null || _currentRelationship == null || _userPoints == null) return;

    // 포인트 부족 체크
    if (_userPoints!.totalPoints < reward.pointsCost) {
      _showErrorSnackBar('포인트가 부족합니다. (현재: ${_userPoints!.totalPoints}P, 필요: ${reward.pointsCost}P)');
      return;
    }

    // 구매 가능 여부 체크
    if (!reward.canPurchase) {
      _showErrorSnackBar('구매할 수 없는 보상입니다.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보상 구매'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정말로 "${reward.title}"을(를) 구매하시겠습니까?'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('비용:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${reward.pointsCost}P', style: const TextStyle(color: Colors.red)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('구매 후 잔액:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_userPoints!.totalPoints - reward.pointsCost}P'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('구매하기'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await RewardService.purchaseReward(
          relationshipId: _currentRelationship!.id,
          rewardId: reward.id,
          userId: user.id,
        );
        
        _loadData(); // 데이터 새로고침
        _showSuccessSnackBar('${reward.title} 구매 완료! 멘토의 승인을 기다려주세요.');
      } catch (e) {
        _showErrorSnackBar('구매 실패: $e');
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
          '보상 상점',
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
                    // 포인트 정보
                    _buildPointsHeader(),
                    
                    // 카테고리 필터
                    _buildCategoryFilter(),
                    
                    // 보상 목록
                    Expanded(
                      child: _filteredRewards.isEmpty
                          ? _buildEmptyState()
                          : _buildRewardsList(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPointsHeader() {
    if (_userPoints == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10B981),
            Color(0xFF059669),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보유 포인트',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  '${_userPoints!.totalPoints}P',
                  style: GoogleFonts.notoSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Lv.${_userPoints!.currentLevel}',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userPoints!.levelTitle,
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      {'id': 'all', 'name': '전체', 'icon': Icons.all_inclusive},
      ...RewardService.getRewardCategories(),
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
                  color: isSelected ? const Color(0xFF10B981) : Colors.white,
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
                      color: isSelected ? Colors.white : const Color(0xFF10B981),
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
              Icons.card_giftcard,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == 'all' ? '보상이 없습니다' : '해당 카테고리에 보상이 없습니다',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '멘토에게 보상을 요청해보세요',
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

  Widget _buildRewardsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRewards.length,
      itemBuilder: (context, index) {
        final reward = _filteredRewards[index];
        return _buildRewardCard(reward);
      },
    );
  }

  Widget _buildRewardCard(RewardPunishment reward) {
    final canAfford = _userPoints != null && _userPoints!.totalPoints >= reward.pointsCost;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: !canAfford 
            ? Border.all(color: Colors.grey[300]!, width: 1)
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
        onTap: canAfford && reward.canPurchase ? () => _purchaseReward(reward) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 아이콘
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: reward.categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  reward.categoryIcon,
                  color: canAfford ? reward.categoryColor : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // 보상 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.title,
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: canAfford ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
                      ),
                    ),
                    if (reward.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        reward.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: canAfford ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
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
                          reward.categoryDisplayName,
                          reward.categoryColor.withOpacity(0.1),
                          canAfford ? reward.categoryColor : Colors.grey,
                        ),
                        if (reward.isLimited) ...[
                          _buildChip(
                            '${reward.remainingCount}/${reward.limitCount}',
                            const Color(0xFFF59E0B).withOpacity(0.1),
                            canAfford ? const Color(0xFFF59E0B) : Colors.grey,
                          ),
                        ],
                        if (!reward.canPurchase) ...[
                          _buildChip(
                            '품절',
                            Colors.red.withOpacity(0.1),
                            Colors.red,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // 가격
              Column(
                children: [
                  Text(
                    '${reward.pointsCost}P',
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: canAfford ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!canAfford) ...[
                    const Text(
                      '포인트 부족',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ] else if (!reward.canPurchase) ...[
                    const Text(
                      '구매불가',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      '구매하기',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
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
