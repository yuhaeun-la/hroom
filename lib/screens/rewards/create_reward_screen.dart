import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/reward_service.dart';

class CreateRewardScreen extends StatefulWidget {
  final String relationshipId;
  final String initialType; // 'reward' 또는 'punishment'

  const CreateRewardScreen({
    super.key,
    required this.relationshipId,
    required this.initialType,
  });

  @override
  State<CreateRewardScreen> createState() => _CreateRewardScreenState();
}

class _CreateRewardScreenState extends State<CreateRewardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late String _selectedType;
  String _selectedCategory = '';
  int _pointsCost = 10;
  bool _isLimited = false;
  int _limitCount = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    
    // 기본 카테고리 설정
    final categories = _selectedType == 'reward' 
        ? RewardService.getRewardCategories()
        : RewardService.getPunishmentCategories();
    
    if (categories.isNotEmpty) {
      _selectedCategory = categories.first['id'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createReward() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await RewardService.createReward(
        relationshipId: widget.relationshipId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        type: _selectedType,
        category: _selectedCategory,
        pointsCost: _pointsCost,
        isLimited: _isLimited,
        limitCount: _isLimited ? _limitCount : null,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('생성 실패: $e');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _selectedType == 'reward' ? Icons.card_giftcard : Icons.warning,
              color: _selectedType == 'reward' ? Colors.green : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text('${_selectedType == 'reward' ? '보상' : '처벌'} 생성 완료!'),
          ],
        ),
        content: Text('새로운 ${_selectedType == 'reward' ? '보상' : '처벌'} "${_titleController.text}"이(가) 생성되었습니다.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pop(); // 생성 화면 닫기
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          '새 ${_selectedType == 'reward' ? '보상' : '처벌'} 만들기',
          style: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타입 선택
              _buildSectionTitle('타입', Icons.category),
              const SizedBox(height: 8),
              _buildTypeSelection(),
              const SizedBox(height: 24),

              // 제목
              _buildSectionTitle('제목', Icons.title),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: _selectedType == 'reward' 
                      ? '예: 좋아하는 음식 주문하기' 
                      : '예: 팔굽혀펴기 20개',
                  prefixIcon: const Icon(Icons.text_fields),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '제목을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 설명
              _buildSectionTitle('상세 설명 (선택사항)', Icons.description),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '자세한 설명을 작성해주세요',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // 카테고리 선택
              _buildSectionTitle('카테고리', Icons.folder),
              const SizedBox(height: 12),
              _buildCategorySelection(),
              const SizedBox(height: 24),

              // 포인트 설정
              _buildSectionTitle(
                _selectedType == 'reward' ? '구매 비용' : '차감 포인트', 
                Icons.stars,
              ),
              const SizedBox(height: 12),
              _buildPointsSelection(),
              const SizedBox(height: 24),

              // 수량 제한 설정
              _buildSectionTitle('수량 제한', Icons.inventory),
              const SizedBox(height: 12),
              _buildLimitSelection(),
              const SizedBox(height: 32),

              // 생성 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createReward,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          '${_selectedType == 'reward' ? '보상' : '처벌'} 생성하기',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B46C1), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelection() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = 'reward';
                final categories = RewardService.getRewardCategories();
                if (categories.isNotEmpty) {
                  _selectedCategory = categories.first['id'];
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedType == 'reward' 
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedType == 'reward' 
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE5E7EB),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.card_giftcard,
                    color: _selectedType == 'reward' 
                        ? const Color(0xFF10B981)
                        : const Color(0xFF9CA3AF),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '보상',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _selectedType == 'reward' 
                          ? const Color(0xFF10B981)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = 'punishment';
                final categories = RewardService.getPunishmentCategories();
                if (categories.isNotEmpty) {
                  _selectedCategory = categories.first['id'];
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedType == 'punishment' 
                    ? const Color(0xFFEF4444).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedType == 'punishment' 
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFE5E7EB),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning,
                    color: _selectedType == 'punishment' 
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF9CA3AF),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '처벌',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _selectedType == 'punishment' 
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelection() {
    final categories = _selectedType == 'reward' 
        ? RewardService.getRewardCategories()
        : RewardService.getPunishmentCategories();
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories.map((category) {
        final isSelected = _selectedCategory == category['id'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category['id'] as String;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6B46C1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF6B46C1) : const Color(0xFFE5E7EB),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category['icon'] as IconData,
                  color: isSelected ? Colors.white : category['color'] as Color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  category['name'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPointsSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedType == 'reward' ? '구매 비용' : '차감 포인트',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              Text(
                '${_pointsCost}P',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _selectedType == 'reward' 
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: _pointsCost.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: const Color(0xFF6B46C1),
            onChanged: (value) {
              setState(() {
                _pointsCost = value.round();
              });
            },
          ),
          Text(
            _selectedType == 'reward' 
                ? '멘티가 이 보상을 구매하는데 필요한 포인트입니다'
                : '멘티에게서 차감될 포인트입니다',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _isLimited,
                onChanged: (value) {
                  setState(() {
                    _isLimited = value ?? false;
                  });
                },
                activeColor: const Color(0xFF6B46C1),
              ),
              const Text(
                '수량 제한 설정',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          if (_isLimited) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  '제한 수량: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _limitCount.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: const Color(0xFF6B46C1),
                    onChanged: (value) {
                      setState(() {
                        _limitCount = value.round();
                      });
                    },
                  ),
                ),
                Text(
                  '$_limitCount개',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const Text(
              '설정한 수량만큼만 구매/사용할 수 있습니다',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ] else ...[
            const Text(
              '무제한으로 구매/사용할 수 있습니다',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
