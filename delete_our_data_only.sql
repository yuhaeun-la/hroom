-- 우리가 만든 테이블의 데이터만 삭제
-- auth.users는 건드리지 않음

-- 관련 데이터를 순서대로 삭제
DELETE FROM public.journal_comments;
DELETE FROM public.points_history;
DELETE FROM public.daily_logs;
DELETE FROM public.emotional_journals;
DELETE FROM public.rewards_punishments;
DELETE FROM public.rules;
DELETE FROM public.relationships;
DELETE FROM public.users_profile;

SELECT 'All application data deleted successfully!' as result;
