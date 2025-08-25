import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/emotional_journal.dart';
import '../../models/relationship.dart';
import '../../services/journal_service.dart';
import '../../services/relationship_service.dart';
import '../../providers/auth_provider.dart';
import 'create_journal_screen.dart';
import 'journal_detail_screen.dart';

class JournalListScreen extends ConsumerStatefulWidget {
  const JournalListScreen({super.key});

  @override
  ConsumerState<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends ConsumerState<JournalListScreen> {
  List<EmotionalJournal> _journals = [];
  Relationship? _currentRelationship;
  bool _isLoading = true;
  String _selectedMood = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        // 일지 목록 조회
        await _loadJournals(relationship.id, user.id);
        
        setState(() {
          _currentRelationship = relationship;
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

  Future<void> _loadJournals(String relationshipId, String userId) async {
    try {
      List<EmotionalJournal> journals;
      
      if (_searchQuery.isNotEmpty) {
        // 검색
        journals = await JournalService.searchJournals(
          relationshipId: relationshipId,
          query: _searchQuery,
          userId: userId,
        );
      } else {
        // 일반 조회
        journals = await JournalService.getJournals(
          relationshipId: relationshipId,
          userId: userId,
          mood: _selectedMood == 'all' ? null : _selectedMood,
        );
      }
      
      setState(() {
        _journals = journals;
      });
    } catch (e) {
      _showErrorSnackBar('일지 조회 실패: $e');
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

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    if (_currentRelationship != null) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        _loadJournals(_currentRelationship!.id, user.id);
      }
    }
  }

  void _onMoodFilterChanged(String mood) {
    setState(() {
      _selectedMood = mood;
    });
    
    if (_currentRelationship != null) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        _loadJournals(_currentRelationship!.id, user.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(authProvider).profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          '감정 일지',
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
                    // 검색바
                    _buildSearchBar(),
                    
                    // 감정 필터
                    _buildMoodFilter(),
                    
                    // 일지 목록
                    Expanded(
                      child: _journals.isEmpty
                          ? _buildEmptyState()
                          : _buildJournalsList(),
                    ),
                  ],
                ),
      floatingActionButton: userProfile != null && !userProfile.isMentor && _currentRelationship != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateJournalScreen(),
                  ),
                ).then((_) => _loadData());
              },
              backgroundColor: const Color(0xFF6B46C1),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit),
              label: const Text('일지 작성'),
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: '일지 제목이나 내용 검색...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(Icons.clear, color: Color(0xFF6B7280)),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildMoodFilter() {
    final moods = [
      {'id': 'all', 'name': '전체', 'icon': Icons.all_inclusive, 'color': const Color(0xFF6B7280)},
      ...EmotionalJournal.availableMoods,
    ];

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: moods.length,
        itemBuilder: (context, index) {
          final mood = moods[index];
          final isSelected = _selectedMood == mood['id'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _onMoodFilterChanged(mood['id'] as String),
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (mood['color'] as Color)
                      : Colors.white,
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
                      mood['icon'] as IconData,
                      color: isSelected 
                          ? Colors.white 
                          : (mood['color'] as Color),
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mood['name'] as String,
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
              Icons.book,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? '검색 결과가 없습니다'
                  : '작성된 일지가 없습니다',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty 
                  ? '다른 검색어로 시도해보세요'
                  : '첫 번째 감정 일지를 작성해보세요',
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

  Widget _buildJournalsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _journals.length,
      itemBuilder: (context, index) {
        final journal = _journals[index];
        return _buildJournalCard(journal);
      },
    );
  }

  Widget _buildJournalCard(EmotionalJournal journal) {
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
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => JournalDetailScreen(journalId: journal.id),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 (날짜, 감정, 프라이빗)
              Row(
                children: [
                  // 감정 아이콘
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: journal.moodColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      journal.moodIcon,
                      color: journal.moodColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 날짜와 감정
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('yyyy년 MM월 dd일').format(journal.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${journal.moodDisplayName} (${journal.intensityDisplayName})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: journal.moodColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 프라이빗 표시
                  if (journal.isPrivate) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 12,
                            color: Color(0xFFEF4444),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '비공개',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              
              // 제목
              Text(
                journal.title,
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF374151),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // 내용 미리보기
              Text(
                journal.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // 태그들
              if (journal.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: journal.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B46C1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B46C1),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
