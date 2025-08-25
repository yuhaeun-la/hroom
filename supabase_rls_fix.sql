-- RLS 정책 수정 - 사용자 프로필 생성 권한 문제 해결

-- 기존 정책 삭제
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users_profile;

-- 새로운 프로필 생성 정책 (더 관대한 정책)
CREATE POLICY "Anyone can insert profile after signup" ON public.users_profile
    FOR INSERT WITH CHECK (true);

-- 또는 더 안전한 정책을 원한다면 아래 주석을 해제하고 위 정책을 삭제하세요
-- CREATE POLICY "Users can insert own profile" ON public.users_profile
--     FOR INSERT WITH CHECK (auth.uid() = id);
