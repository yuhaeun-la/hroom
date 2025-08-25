import 'dart:math';
import '../config/supabase_config.dart';
import '../models/invitation_code.dart';
import '../models/relationship.dart';

class RelationshipService {
  // 멘토가 초대 코드 생성
  static Future<InvitationCode> createInvitationCode(String mentorId) async {
    try {
      // 기존 활성 초대 코드가 있는지 확인
      final existingCodes = await supabase
          .from('invitation_codes')
          .select()
          .eq('mentor_id', mentorId)
          .eq('is_used', false)
          .gt('expires_at', DateTime.now().toIso8601String());

      // 기존 코드가 있다면 비활성화
      if (existingCodes.isNotEmpty) {
        await supabase
            .from('invitation_codes')
            .update({'expires_at': DateTime.now().toIso8601String()})
            .eq('mentor_id', mentorId)
            .eq('is_used', false);
      }

      // 새 초대 코드 생성 (간단한 방식으로 변경)
      final code = _generateRandomCode();

      final newCode = await supabase
          .from('invitation_codes')
          .insert({
            'code': code,
            'mentor_id': mentorId,
            'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          })
          .select()
          .single();

      return InvitationCode.fromJson(newCode);
    } catch (e) {
      throw Exception('초대 코드 생성 실패: $e');
    }
  }

  // 멘티가 초대 코드로 관계 요청
  static Future<Relationship> useInvitationCode(String code, String menteeId) async {
    try {
      print('코드 검색 중: $code'); // 디버그 로그
      
      // 초대 코드 유효성 검사
      final invitationList = await supabase
          .from('invitation_codes')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_used', false)
          .gt('expires_at', DateTime.now().toIso8601String());

      print('검색 결과: ${invitationList.length}개'); // 디버그 로그

      if (invitationList.isEmpty) {
        throw Exception('유효하지 않은 초대 코드입니다');
      }

      final invitationData = invitationList.first;

      final invitation = InvitationCode.fromJson(invitationData);

      // 이미 관계가 있는지 확인
      final existingRelation = await supabase
          .from('relationships')
          .select()
          .eq('mentor_id', invitation.mentorId)
          .eq('mentee_id', menteeId);

      if (existingRelation.isNotEmpty) {
        throw Exception('이미 이 멘토와 관계가 존재합니다');
      }

      // 초대 코드 사용 처리
      await supabase
          .from('invitation_codes')
          .update({
            'is_used': true,
            'used_by': menteeId,
            'used_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invitation.id);

      // 새 관계 생성
      final relationshipData = await supabase
          .from('relationships')
          .insert({
            'mentor_id': invitation.mentorId,
            'mentee_id': menteeId,
            'status': 'active', // 즉시 활성화
          })
          .select()
          .single();

      return Relationship.fromJson(relationshipData);
    } catch (e) {
      if (e.toString().contains('No rows found')) {
        throw Exception('유효하지 않은 초대 코드입니다');
      }
      throw Exception('관계 생성 실패: $e');
    }
  }

  // 사용자의 현재 관계 조회
  static Future<Relationship?> getCurrentRelationship(String userId) async {
    try {
      final response = await supabase
          .from('relationships')
          .select()
          .or('mentor_id.eq.$userId,mentee_id.eq.$userId')
          .eq('status', 'active')
          .limit(1);

      if (response.isEmpty) return null;

      return Relationship.fromJson(response.first);
    } catch (e) {
      return null;
    }
  }

  // 멘토의 활성 초대 코드 조회
  static Future<InvitationCode?> getActiveInvitationCode(String mentorId) async {
    try {
      final response = await supabase
          .from('invitation_codes')
          .select()
          .eq('mentor_id', mentorId)
          .eq('is_used', false)
          .gt('expires_at', DateTime.now().toIso8601String())
          .limit(1);

      if (response.isEmpty) return null;

      return InvitationCode.fromJson(response.first);
    } catch (e) {
      return null;
    }
  }

  // 관계 해제
  static Future<void> breakRelationship(String relationshipId) async {
    try {
      await supabase
          .from('relationships')
          .update({'status': 'inactive'})
          .eq('id', relationshipId);
    } catch (e) {
      throw Exception('관계 해제 실패: $e');
    }
  }

  // 간단한 초대 코드 생성 함수
  static String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
}
