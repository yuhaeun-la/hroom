-- 테스트 사용자 데이터 삭제 스크립트
-- ⚠️ 주의: 이 스크립트는 모든 사용자 데이터를 삭제합니다!

-- 1. 관련 테이블 데이터 삭제 (외래키 제약조건으로 인해 순서 중요)
DELETE FROM public.journal_comments;
DELETE FROM public.points_history;
DELETE FROM public.daily_logs;
DELETE FROM public.emotional_journals;
DELETE FROM public.rewards_punishments;
DELETE FROM public.rules;
DELETE FROM public.relationships;
DELETE FROM public.users_profile;

-- 2. 인증 사용자 삭제 (auth 스키마)
-- 주의: 이는 관리자 권한이 필요할 수 있습니다
-- DELETE FROM auth.users;

-- 또는 특정 이메일만 삭제하려면:
-- DELETE FROM public.users_profile WHERE id IN (
--     SELECT id FROM auth.users WHERE email = 'test@example.com'
-- );

SELECT 'All test data deleted successfully!' as message;
