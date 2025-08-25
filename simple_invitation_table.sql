-- 간단한 초대 코드 테이블 생성

CREATE TABLE public.invitation_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code VARCHAR(8) NOT NULL UNIQUE,
    dom_id UUID REFERENCES public.users_profile(id) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    is_used BOOLEAN DEFAULT false,
    used_by UUID REFERENCES public.users_profile(id),
    used_at TIMESTAMP WITH TIME ZONE
);

-- 인덱스 생성
CREATE INDEX idx_invitation_codes_code ON public.invitation_codes(code);
CREATE INDEX idx_invitation_codes_dom_id ON public.invitation_codes(dom_id);

-- RLS 정책 활성화
ALTER TABLE public.invitation_codes ENABLE ROW LEVEL SECURITY;

-- RLS 정책 생성
CREATE POLICY "Dom can view own invitation codes" ON public.invitation_codes
    FOR SELECT USING (dom_id = auth.uid());

CREATE POLICY "Dom can create invitation codes" ON public.invitation_codes
    FOR INSERT WITH CHECK (dom_id = auth.uid());

CREATE POLICY "Anyone can view valid invitation codes" ON public.invitation_codes
    FOR SELECT USING (NOT is_used AND expires_at > NOW());

CREATE POLICY "Sub can update invitation code when using" ON public.invitation_codes
    FOR UPDATE USING (NOT is_used AND expires_at > NOW())
    WITH CHECK (is_used = true AND used_by = auth.uid());

SELECT 'Simple invitation codes table created successfully!' as result;
