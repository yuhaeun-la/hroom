-- 안전한 사용자 삭제 스크립트
-- 외래키 제약조건을 고려한 순서로 삭제

-- 1단계: 먼저 특정 사용자의 ID를 확인 (선택사항)
-- SELECT id, email, raw_user_meta_data->>'display_name' as display_name 
-- FROM auth.users 
-- ORDER BY created_at DESC;

-- 2단계: 관련 데이터를 순서대로 삭제
-- 가장 의존성이 높은 테이블부터 삭제

-- 일지 댓글 삭제
DELETE FROM public.journal_comments;

-- 포인트 이력 삭제  
DELETE FROM public.points_history;

-- 일일 로그 삭제
DELETE FROM public.daily_logs;

-- 감정 일지 삭제
DELETE FROM public.emotional_journals;

-- 보상/처벌 삭제
DELETE FROM public.rewards_punishments;

-- 규칙 삭제
DELETE FROM public.rules;

-- 관계 삭제
DELETE FROM public.relationships;

-- 사용자 프로필 삭제
DELETE FROM public.users_profile;

-- 3단계: RLS 임시 비활성화 후 auth.users 삭제
ALTER TABLE auth.users DISABLE ROW LEVEL SECURITY;

-- auth.users에서 삭제 (모든 사용자)
DELETE FROM auth.users;

-- RLS 다시 활성화
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

SELECT 'All users and related data deleted successfully!' as result;
