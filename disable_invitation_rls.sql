-- 임시로 invitation_codes 테이블의 RLS를 비활성화 (테스트용)

ALTER TABLE public.invitation_codes DISABLE ROW LEVEL SECURITY;

SELECT 'RLS disabled for invitation_codes table (testing only)' as result;
