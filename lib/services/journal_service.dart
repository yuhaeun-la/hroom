import '../config/supabase_config.dart';
import '../models/emotional_journal.dart';
import '../models/journal_comment.dart';

class JournalService {
  // 감정 일지 생성
  static Future<EmotionalJournal> createJournal({
    required String relationshipId,
    required String userId,
    required String title,
    required String content,
    required String mood,
    required int moodIntensity,
    required List<String> tags,
    required DateTime date,
    bool isPrivate = false,
  }) async {
    try {
      final now = DateTime.now();
      final response = await supabase
          .from('emotional_journals')
          .insert({
            'relationship_id': relationshipId,
            'user_id': userId,
            'title': title,
            'content': content,
            'mood': mood,
            'mood_intensity': moodIntensity,
            'tags': tags,
            'date': date.toIso8601String().split('T')[0],
            'is_private': isPrivate,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select()
          .single();

      return EmotionalJournal.fromJson(response);
    } catch (e) {
      throw Exception('일지 생성 실패: $e');
    }
  }

  // 감정 일지 목록 조회
  static Future<List<EmotionalJournal>> getJournals({
    required String relationshipId,
    String? userId, // null이면 모든 사용자의 일지
    String? mood, // 특정 감정만 필터
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = supabase
          .from('emotional_journals')
          .select()
          .eq('relationship_id', relationshipId);

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (mood != null) {
        query = query.eq('mood', mood);
      }

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      if (tags != null && tags.isNotEmpty) {
        query = query.overlaps('tags', tags);
      }

      final response = await query
          .order('date', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<EmotionalJournal>((json) => EmotionalJournal.fromJson(json)).toList();
    } catch (e) {
      throw Exception('일지 목록 조회 실패: $e');
    }
  }

  // 감정 일지 상세 조회
  static Future<EmotionalJournal?> getJournal(String journalId) async {
    try {
      final response = await supabase
          .from('emotional_journals')
          .select()
          .eq('id', journalId)
          .single();

      return EmotionalJournal.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // 감정 일지 수정
  static Future<EmotionalJournal> updateJournal({
    required String journalId,
    String? title,
    String? content,
    String? mood,
    int? moodIntensity,
    List<String>? tags,
    bool? isPrivate,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (mood != null) updateData['mood'] = mood;
      if (moodIntensity != null) updateData['mood_intensity'] = moodIntensity;
      if (tags != null) updateData['tags'] = tags;
      if (isPrivate != null) updateData['is_private'] = isPrivate;

      final response = await supabase
          .from('emotional_journals')
          .update(updateData)
          .eq('id', journalId)
          .select()
          .single();

      return EmotionalJournal.fromJson(response);
    } catch (e) {
      throw Exception('일지 수정 실패: $e');
    }
  }

  // 감정 일지 삭제
  static Future<void> deleteJournal(String journalId) async {
    try {
      // 먼저 댓글들 삭제
      await supabase
          .from('journal_comments')
          .delete()
          .eq('journal_id', journalId);

      // 일지 삭제
      await supabase
          .from('emotional_journals')
          .delete()
          .eq('id', journalId);
    } catch (e) {
      throw Exception('일지 삭제 실패: $e');
    }
  }

  // 댓글 생성
  static Future<JournalComment> createComment({
    required String journalId,
    required String userId,
    required String content,
  }) async {
    try {
      final now = DateTime.now();
      final response = await supabase
          .from('journal_comments')
          .insert({
            'journal_id': journalId,
            'user_id': userId,
            'content': content,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select()
          .single();

      return JournalComment.fromJson(response);
    } catch (e) {
      throw Exception('댓글 생성 실패: $e');
    }
  }

  // 댓글 목록 조회
  static Future<List<JournalComment>> getComments(String journalId) async {
    try {
      final response = await supabase
          .from('journal_comments')
          .select()
          .eq('journal_id', journalId)
          .order('created_at', ascending: true);

      return response.map<JournalComment>((json) => JournalComment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('댓글 조회 실패: $e');
    }
  }

  // 댓글 수정
  static Future<JournalComment> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final response = await supabase
          .from('journal_comments')
          .update({
            'content': content,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', commentId)
          .select()
          .single();

      return JournalComment.fromJson(response);
    } catch (e) {
      throw Exception('댓글 수정 실패: $e');
    }
  }

  // 댓글 삭제
  static Future<void> deleteComment(String commentId) async {
    try {
      await supabase
          .from('journal_comments')
          .delete()
          .eq('id', commentId);
    } catch (e) {
      throw Exception('댓글 삭제 실패: $e');
    }
  }

  // 감정 통계 (최근 N일간)
  static Future<Map<String, int>> getMoodStatistics({
    required String relationshipId,
    required String userId,
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      
      final response = await supabase
          .from('emotional_journals')
          .select('mood')
          .eq('relationship_id', relationshipId)
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String().split('T')[0]);

      final Map<String, int> statistics = {};
      
      for (final item in response) {
        final mood = item['mood'] as String;
        statistics[mood] = (statistics[mood] ?? 0) + 1;
      }

      return statistics;
    } catch (e) {
      throw Exception('감정 통계 조회 실패: $e');
    }
  }

  // 일지 검색
  static Future<List<EmotionalJournal>> searchJournals({
    required String relationshipId,
    required String query,
    String? userId,
    int limit = 20,
  }) async {
    try {
      var searchQuery = supabase
          .from('emotional_journals')
          .select()
          .eq('relationship_id', relationshipId);

      if (userId != null) {
        searchQuery = searchQuery.eq('user_id', userId);
      }

      // 제목이나 내용에서 검색
      searchQuery = searchQuery.or('title.ilike.%$query%,content.ilike.%$query%');

      final response = await searchQuery
          .order('date', ascending: false)
          .limit(limit);

      return response.map<EmotionalJournal>((json) => EmotionalJournal.fromJson(json)).toList();
    } catch (e) {
      throw Exception('일지 검색 실패: $e');
    }
  }

  // 태그별 일지 개수
  static Future<Map<String, int>> getTagStatistics({
    required String relationshipId,
    required String userId,
  }) async {
    try {
      final response = await supabase
          .from('emotional_journals')
          .select('tags')
          .eq('relationship_id', relationshipId)
          .eq('user_id', userId);

      final Map<String, int> tagCounts = {};
      
      for (final item in response) {
        final tags = List<String>.from(item['tags'] ?? []);
        for (final tag in tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      return tagCounts;
    } catch (e) {
      throw Exception('태그 통계 조회 실패: $e');
    }
  }
}
