import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/emotional_journal.dart';
import '../../models/relationship.dart';
import '../../services/journal_service.dart';
import '../../services/relationship_service.dart';
import '../../providers/auth_provider.dart';

class CreateJournalScreen extends ConsumerStatefulWidget {
  final EmotionalJournal? existingJournal; // 수정 모드인 경우

  const CreateJournalScreen({
    super.key,
    this.existingJournal,
  });

  @override
  ConsumerState<CreateJournalScreen> createState() => _CreateJournalScreenState();
}

class _CreateJournalScreenState extends ConsumerState<CreateJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  
  String _selectedMood = 'happy';
  int _moodIntensity = 3;
  List<String> _selectedTags = [];
  DateTime _selectedDate = DateTime.now();
  bool _isPrivate = false;
  bool _isLoading = false;
  Relationship? _currentRelationship;

  @override
  void initState() {
    super.initState();
    _loadRelationship();
    
    // 수정 모드인 경우 기존 데이터 로드
    if (widget.existingJournal != null) {
      final journal = widget.existingJournal!;
      _titleController.text = journal.title;
      _contentController.text = journal.content;
      _selectedMood = journal.mood;
      _moodIntensity = journal.moodIntensity;
      _selectedTags = List.from(journal.tags);
      _selectedDate = journal.date;
      _isPrivate = journal.isPrivate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadRelationship() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    try {
      final relationship = await RelationshipService.getCurrentRelationship(user.id);
      setState(() {
        _currentRelationship = relationship;
      });
    } catch (e) {
      _showErrorSnackBar('관계 정보 로드 실패: $e');
    }
  }

  Future<void> _saveJournal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentRelationship == null) {
      _showErrorSnackBar('관계 정보를 찾을 수 없습니다');
      return;
    }

    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      if (widget.existingJournal != null) {
        // 수정 모드
        await JournalService.updateJournal(
          journalId: widget.existingJournal!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          mood: _selectedMood,
          moodIntensity: _moodIntensity,
          tags: _selectedTags,
          isPrivate: _isPrivate,
        );
      } else {
        // 생성 모드
        await JournalService.createJournal(
          relationshipId: _currentRelationship!.id,
          userId: user.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          mood: _selectedMood,
          moodIntensity: _moodIntensity,
          tags: _selectedTags,
          date: _selectedDate,
          isPrivate: _isPrivate,
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('저장 실패: $e');
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
              Icons.check_circle,
              color: Colors.green[600],
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(widget.existingJournal != null ? '일지 수정 완료!' : '일지 작성 완료!'),
          ],
        ),
        content: Text('감정 일지가 성공적으로 ${widget.existingJournal != null ? '수정' : '작성'}되었습니다.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pop(); // 작성 화면 닫기
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

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  void _addCommonTag(String tag) {
    if (!_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
      });
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
          widget.existingJournal != null ? '일지 수정' : '새 일지 작성',
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
              // 날짜 선택 (생성 모드에서만)
              if (widget.existingJournal == null) ...[
                _buildSectionTitle('날짜', Icons.calendar_today),
                const SizedBox(height: 8),
                _buildDateSelection(),
                const SizedBox(height: 24),
              ],

              // 제목
              _buildSectionTitle('제목', Icons.title),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '오늘의 감정을 한 줄로 표현해보세요',
                  prefixIcon: Icon(Icons.text_fields),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '제목을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 감정 선택
              _buildSectionTitle('오늘의 감정', Icons.mood),
              const SizedBox(height: 12),
              _buildMoodSelection(),
              const SizedBox(height: 24),

              // 감정 강도
              _buildSectionTitle('감정의 강도', Icons.tune),
              const SizedBox(height: 12),
              _buildIntensitySelection(),
              const SizedBox(height: 24),

              // 내용
              _buildSectionTitle('상세 내용', Icons.edit_note),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '오늘 하루 어떤 일이 있었나요?\n어떤 감정을 느꼈는지 자세히 써보세요...',
                  prefixIcon: Icon(Icons.notes, size: 20),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '내용을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 태그
              _buildSectionTitle('태그', Icons.local_offer),
              const SizedBox(height: 8),
              _buildTagSelection(),
              const SizedBox(height: 24),

              // 프라이빗 설정
              _buildSectionTitle('공개 설정', Icons.visibility),
              const SizedBox(height: 12),
              _buildPrivacySelection(),
              const SizedBox(height: 32),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveJournal,
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
                          widget.existingJournal != null ? '수정하기' : '저장하기',
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

  Widget _buildDateSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() {
              _selectedDate = date;
            });
          }
        },
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF6B46C1)),
            const SizedBox(width: 12),
            Text(
              '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF9CA3AF), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: EmotionalJournal.availableMoods.map((mood) {
        final isSelected = _selectedMood == mood['id'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedMood = mood['id'] as String;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? (mood['color'] as Color) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? (mood['color'] as Color) : const Color(0xFFE5E7EB),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  mood['icon'] as IconData,
                  color: isSelected ? Colors.white : (mood['color'] as Color),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  mood['name'] as String,
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

  Widget _buildIntensitySelection() {
    final selectedMood = EmotionalJournal.availableMoods
        .firstWhere((mood) => mood['id'] == _selectedMood);
    
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
                '${selectedMood['name']}의 강도',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (selectedMood['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  EmotionalJournal(
                    id: '',
                    relationshipId: '',
                    userId: '',
                    title: '',
                    content: '',
                    mood: _selectedMood,
                    moodIntensity: _moodIntensity,
                    tags: [],
                    date: DateTime.now(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ).intensityDisplayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: selectedMood['color'] as Color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: _moodIntensity.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: selectedMood['color'] as Color,
            onChanged: (value) {
              setState(() {
                _moodIntensity = value.round();
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '매우 약함',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '매우 강함',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 태그 입력
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  hintText: '태그 추가...',
                  prefixIcon: Icon(Icons.add),
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addTag,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('추가', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // 선택된 태그들
        if (_selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B46C1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#$tag',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        
        // 추천 태그들
        const Text(
          '추천 태그',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EmotionalJournal.commonTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: isSelected ? null : () => _addCommonTag(tag),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF9CA3AF) 
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected 
                        ? Colors.white 
                        : const Color(0xFF374151),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrivacySelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Switch(
            value: _isPrivate,
            onChanged: (value) {
              setState(() {
                _isPrivate = value;
              });
            },
            activeColor: const Color(0xFFEF4444),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPrivate ? '비공개 일지' : '공개 일지',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPrivate 
                      ? '멘토가 볼 수 없는 나만의 일지입니다'
                      : '멘토와 공유되는 일지입니다',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
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
