-- 개발/테스트를 위해 모든 관련 테이블의 RLS 비활성화

-- invitation_codes 테이블 RLS 비활성화
ALTER TABLE public.invitation_codes DISABLE ROW LEVEL SECURITY;

-- relationships 테이블 RLS 비활성화  
ALTER TABLE public.relationships DISABLE ROW LEVEL SECURITY;

-- users_profile 테이블 RLS 비활성화 (혹시 모를 문제 방지)
ALTER TABLE public.users_profile DISABLE ROW LEVEL SECURITY;

-- 기타 테이블들도 비활성화 (안전을 위해)
ALTER TABLE public.rules DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.emotional_journals DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_comments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.points_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.rewards_punishments DISABLE ROW LEVEL SECURITY;

-- 확인 메시지
SELECT 'All RLS policies disabled for testing - you can now test all features freely!' as result;
