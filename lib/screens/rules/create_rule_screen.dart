import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rule_service.dart';

class CreateRuleScreen extends StatefulWidget {
  final String relationshipId;

  const CreateRuleScreen({
    super.key,
    required this.relationshipId,
  });

  @override
  State<CreateRuleScreen> createState() => _CreateRuleScreenState();
}

class _CreateRuleScreenState extends State<CreateRuleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'daily';
  String _selectedDifficulty = 'medium';
  String _selectedFrequency = 'daily';
  int _pointsReward = 10;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createRule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await RuleService.createRule(
        relationshipId: widget.relationshipId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        frequency: _selectedFrequency,
        pointsReward: _pointsReward,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('규칙 생성 실패: $e');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('규칙 생성 완료!'),
          ],
        ),
        content: Text('새로운 규칙 "${_titleController.text}"이(가) 생성되었습니다.'),
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
          '새 규칙 만들기',
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
              // 규칙 제목
              _buildSectionTitle('규칙 제목', Icons.title),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '예: 매일 물 8잔 마시기',
                  prefixIcon: Icon(Icons.text_fields),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '규칙 제목을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 규칙 설명
              _buildSectionTitle('상세 설명 (선택사항)', Icons.description),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '규칙에 대한 자세한 설명을 작성해주세요',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // 카테고리 선택
              _buildSectionTitle('카테고리', Icons.category),
              const SizedBox(height: 12),
              _buildCategorySelection(),
              const SizedBox(height: 24),

              // 난이도 선택
              _buildSectionTitle('난이도', Icons.speed),
              const SizedBox(height: 12),
              _buildDifficultySelection(),
              const SizedBox(height: 24),

              // 빈도 선택
              _buildSectionTitle('실행 빈도', Icons.schedule),
              const SizedBox(height: 12),
              _buildFrequencySelection(),
              const SizedBox(height: 24),

              // 포인트 설정
              _buildSectionTitle('보상 포인트', Icons.stars),
              const SizedBox(height: 12),
              _buildPointsSelection(),
              const SizedBox(height: 32),

              // 생성 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createRule,
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
                      : const Text(
                          '규칙 생성하기',
                          style: TextStyle(
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
      crossAxisAlignment: CrossAxisAlignment.end,
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

  Widget _buildCategorySelection() {
    final categories = RuleService.getAvailableCategories();
    
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

  Widget _buildDifficultySelection() {
    final difficulties = RuleService.getDifficultyLevels();
    
    return Column(
      children: difficulties.map((difficulty) {
        final isSelected = _selectedDifficulty == difficulty['id'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDifficulty = difficulty['id'] as String;
                _pointsReward = difficulty['points'] as int;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (difficulty['color'] as Color).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? difficulty['color'] as Color
                      : const Color(0xFFE5E7EB),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: difficulty['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      difficulty['name'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected 
                            ? difficulty['color'] as Color
                            : const Color(0xFF374151),
                      ),
                    ),
                  ),
                  Text(
                    '${difficulty['points']}P',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: difficulty['color'] as Color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrequencySelection() {
    final frequencies = RuleService.getFrequencyOptions();
    
    return SizedBox(
      width: double.infinity, // 전체 너비 사용
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: frequencies.map((frequency) {
        final isSelected = _selectedFrequency == frequency['id'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedFrequency = frequency['id'] as String;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF6B46C1).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF6B46C1)
                      : const Color(0xFFE5E7EB),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    frequency['name'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? const Color(0xFF6B46C1)
                          : const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    frequency['description'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected 
                          ? const Color(0xFF6B46C1).withOpacity(0.8)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
          );
        }).toList(),
      ),
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
              const Text(
                '포인트',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              Text(
                '${_pointsReward}P',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: _pointsReward.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: const Color(0xFF6B46C1),
            onChanged: (value) {
              setState(() {
                _pointsReward = value.round();
              });
            },
          ),
          const Text(
            '목표 달성 시 멘티가 받을 포인트를 설정하세요',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
