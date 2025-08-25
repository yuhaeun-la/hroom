-- invitation_codes 테이블 RLS 정책 수정

-- 기존 정책들 모두 삭제
DROP POLICY IF EXISTS "Dom can view own invitation codes" ON public.invitation_codes;
DROP POLICY IF EXISTS "Dom can create invitation codes" ON public.invitation_codes;
DROP POLICY IF EXISTS "Anyone can view valid invitation codes" ON public.invitation_codes;
DROP POLICY IF EXISTS "Sub can update invitation code when using" ON public.invitation_codes;

-- RLS 비활성화 후 다시 활성화
ALTER TABLE public.invitation_codes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitation_codes ENABLE ROW LEVEL SECURITY;

-- 새로운 정책들 생성
CREATE POLICY "Dom can manage invitation codes" ON public.invitation_codes
    FOR ALL USING (dom_id = auth.uid())
    WITH CHECK (dom_id = auth.uid());

CREATE POLICY "Anyone can view and use valid codes" ON public.invitation_codes
    FOR ALL USING (
        NOT is_used 
        AND expires_at > NOW()
    )
    WITH CHECK (
        (dom_id = auth.uid()) OR 
        (NOT is_used AND expires_at > NOW() AND used_by = auth.uid())
    );

-- 테스트용으로 임시 정책 (더 관대한 정책)
-- CREATE POLICY "Allow all operations for testing" ON public.invitation_codes
--     FOR ALL USING (true)
--     WITH CHECK (true);

SELECT 'Invitation codes RLS policies updated successfully!' as result;
