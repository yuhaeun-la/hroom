import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/emotional_journal.dart';
import '../../models/journal_comment.dart';
import '../../models/user_profile.dart';
import '../../services/journal_service.dart';
import '../../providers/auth_provider.dart';
import 'create_journal_screen.dart';

class JournalDetailScreen extends ConsumerStatefulWidget {
  final String journalId;

  const JournalDetailScreen({
    super.key,
    required this.journalId,
  });

  @override
  ConsumerState<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends ConsumerState<JournalDetailScreen> {
  EmotionalJournal? _journal;
  List<JournalComment> _comments = [];
  bool _isLoading = true;
  bool _isCommentLoading = false;
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 일지 상세 정보 조회
      final journal = await JournalService.getJournal(widget.journalId);
      
      if (journal != null) {
        // 댓글 목록 조회
        final comments = await JournalService.getComments(widget.journalId);
        
        setState(() {
          _journal = journal;
          _comments = comments;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackBar('일지를 찾을 수 없습니다');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('데이터 로드 실패: $e');
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _isCommentLoading = true);

    try {
      await JournalService.createComment(
        journalId: widget.journalId,
        userId: user.id,
        content: content,
      );

      _commentController.clear();
      await _loadData(); // 댓글 목록 새로고침
      
      // 맨 아래로 스크롤
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      _showErrorSnackBar('댓글 작성 실패: $e');
    } finally {
      setState(() => _isCommentLoading = false);
    }
  }

  Future<void> _deleteJournal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일지 삭제'),
        content: const Text('정말로 이 일지를 삭제하시겠습니까?\n삭제된 일지는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await JournalService.deleteJournal(widget.journalId);
        if (mounted) {
          Navigator.of(context).pop(); // 상세 화면 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('일지가 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        _showErrorSnackBar('삭제 실패: $e');
      }
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

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(authProvider).profile;
    final currentUser = ref.watch(authProvider).user;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_journal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('오류')),
        body: const Center(
          child: Text('일지를 찾을 수 없습니다'),
        ),
      );
    }

    final journal = _journal!;
    final isAuthor = currentUser?.id == journal.userId;
    final canViewPrivate = isAuthor || (userProfile?.isMentor == true && !journal.isPrivate);
    
    // 비공개 일지이고 작성자가 아닌 경우 접근 제한
    if (journal.isPrivate && !isAuthor) {
      return Scaffold(
        appBar: AppBar(title: const Text('접근 제한')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Color(0xFF9CA3AF)),
              SizedBox(height: 16),
              Text(
                '비공개 일지입니다',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '작성자만 볼 수 있습니다',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
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
          '감정 일지',
          style: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
        actions: [
          if (isAuthor) ...[
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateJournalScreen(existingJournal: journal),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.edit, color: Color(0xFF6B7280)),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteJournal();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // 일지 내용
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 일지 헤더
                  _buildJournalHeader(journal),
                  const SizedBox(height: 24),
                  
                  // 일지 내용
                  _buildJournalContent(journal),
                  const SizedBox(height: 24),
                  
                  // 댓글 섹션
                  _buildCommentsSection(),
                ],
              ),
            ),
          ),
          
          // 댓글 입력 (멘토만 가능)
          if (userProfile?.isMentor == true && !journal.isPrivate)
            _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildJournalHeader(EmotionalJournal journal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜와 프라이빗 표시
          Row(
            children: [
              Text(
                DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR').format(journal.date),
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const Spacer(),
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
                      Icon(Icons.lock, size: 12, color: Color(0xFFEF4444)),
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
          const SizedBox(height: 16),
          
          // 제목
          Text(
            journal.title,
            style: GoogleFonts.notoSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          // 감정 정보
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: journal.moodColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  journal.moodIcon,
                  color: journal.moodColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journal.moodDisplayName,
                      style: GoogleFonts.notoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: journal.moodColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '강도: ${journal.intensityDisplayName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              // 강도 표시
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < journal.moodIntensity 
                        ? Icons.star 
                        : Icons.star_border,
                    color: journal.moodColor,
                    size: 20,
                  );
                }),
              ),
            ],
          ),
          
          // 태그들
          if (journal.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: journal.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  Widget _buildJournalContent(EmotionalJournal journal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, color: Color(0xFF6B46C1), size: 20),
              const SizedBox(width: 8),
              Text(
                '일지 내용',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            journal.content,
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: const Color(0xFF374151),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.comment, color: Color(0xFF6B46C1), size: 20),
              const SizedBox(width: 8),
              Text(
                '댓글 (${_comments.length})',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_comments.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '아직 댓글이 없습니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return _buildCommentItem(comment);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentItem(JournalComment comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF10B981),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '멘토',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('MM/dd HH:mm').format(comment.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          comment.content,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF374151),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: '멘티에게 따뜻한 댓글을 남겨주세요...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              onSubmitted: (_) => _addComment(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isCommentLoading ? null : _addComment,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isCommentLoading 
                    ? const Color(0xFF9CA3AF) 
                    : const Color(0xFF6B46C1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: _isCommentLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
