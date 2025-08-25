-- H-Room 앱 PostgreSQL 스키마
-- Supabase 백엔드용 데이터베이스 구조

-- 사용자 프로필 테이블 (auth.users 확장)
CREATE TABLE public.users_profile (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    display_name VARCHAR(50) NOT NULL,
    role VARCHAR(10) NOT NULL CHECK (role IN ('dom', 'sub')),
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 관계 테이블 (Dom-Sub 페어링)
CREATE TABLE public.relationships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    dom_id UUID REFERENCES public.users_profile(id) NOT NULL,
    sub_id UUID REFERENCES public.users_profile(id) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'inactive')),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(dom_id, sub_id)
);

-- 규칙 테이블
CREATE TABLE public.rules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    relationship_id UUID REFERENCES public.relationships(id) NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(30) NOT NULL, -- 'daily', 'health', 'study', 'behavior'
    difficulty VARCHAR(10) NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    frequency VARCHAR(10) NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly')),
    points_reward INTEGER DEFAULT 10,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 일일 로그 테이블 (규칙 달성 기록)
CREATE TABLE public.daily_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    relationship_id UUID REFERENCES public.relationships(id) NOT NULL,
    rule_id UUID REFERENCES public.rules(id),
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    completed BOOLEAN DEFAULT false,
    proof_image_url TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(rule_id, log_date)
);

-- 감정 일지 테이블
CREATE TABLE public.emotional_journals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    relationship_id UUID REFERENCES public.relationships(id) NOT NULL,
    writer_id UUID REFERENCES public.users_profile(id) NOT NULL,
    journal_date DATE NOT NULL DEFAULT CURRENT_DATE,
    mood VARCHAR(20) NOT NULL, -- 'happy', 'sad', 'angry', 'excited', 'anxious'
    mood_intensity INTEGER CHECK (mood_intensity BETWEEN 1 AND 5),
    title VARCHAR(100),
    content TEXT,
    is_private BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 일지 댓글 테이블 (Dom 피드백)
CREATE TABLE public.journal_comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    journal_id UUID REFERENCES public.emotional_journals(id) NOT NULL,
    commenter_id UUID REFERENCES public.users_profile(id) NOT NULL,
    comment TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 포인트 이력 테이블
CREATE TABLE public.points_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    relationship_id UUID REFERENCES public.relationships(id) NOT NULL,
    user_id UUID REFERENCES public.users_profile(id) NOT NULL,
    points_change INTEGER NOT NULL,
    reason VARCHAR(100) NOT NULL,
    rule_id UUID REFERENCES public.rules(id),
    log_id UUID REFERENCES public.daily_logs(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 보상/처벌 테이블
CREATE TABLE public.rewards_punishments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    relationship_id UUID REFERENCES public.relationships(id) NOT NULL,
    type VARCHAR(10) NOT NULL CHECK (type IN ('reward', 'punishment')),
    title VARCHAR(100) NOT NULL,
    description TEXT,
    points_required INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 사용자 현재 포인트 뷰 (계산된 컬럼)
CREATE VIEW public.user_current_points AS
SELECT 
    ph.user_id,
    ph.relationship_id,
    COALESCE(SUM(ph.points_change), 0) as current_points
FROM public.points_history ph
GROUP BY ph.user_id, ph.relationship_id;

-- 관계 통계 뷰 (대시보드용)
CREATE VIEW public.relationship_stats AS
SELECT 
    r.id as relationship_id,
    r.dom_id,
    r.sub_id,
    COUNT(DISTINCT dl.id) as total_logs,
    COUNT(DISTINCT CASE WHEN dl.completed = true THEN dl.id END) as completed_logs,
    ROUND(
        CASE 
            WHEN COUNT(DISTINCT dl.id) > 0 
            THEN (COUNT(DISTINCT CASE WHEN dl.completed = true THEN dl.id END)::numeric / COUNT(DISTINCT dl.id)::numeric) * 100
            ELSE 0 
        END, 2
    ) as completion_rate,
    COUNT(DISTINCT ej.id) as journal_entries,
    MAX(dl.created_at) as last_activity
FROM public.relationships r
LEFT JOIN public.daily_logs dl ON r.id = dl.relationship_id
LEFT JOIN public.emotional_journals ej ON r.id = ej.relationship_id
GROUP BY r.id, r.dom_id, r.sub_id;

-- 인덱스 생성 (성능 최적화)
CREATE INDEX idx_relationships_dom_id ON public.relationships(dom_id);
CREATE INDEX idx_relationships_sub_id ON public.relationships(sub_id);
CREATE INDEX idx_rules_relationship_id ON public.rules(relationship_id);
CREATE INDEX idx_daily_logs_relationship_id ON public.daily_logs(relationship_id);
CREATE INDEX idx_daily_logs_date ON public.daily_logs(log_date);
CREATE INDEX idx_emotional_journals_relationship_id ON public.emotional_journals(relationship_id);
CREATE INDEX idx_emotional_journals_date ON public.emotional_journals(journal_date);
CREATE INDEX idx_points_history_user_id ON public.points_history(user_id);

-- 트리거 함수 (updated_at 자동 업데이트)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 트리거 적용
CREATE TRIGGER update_users_profile_updated_at BEFORE UPDATE ON public.users_profile FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_relationships_updated_at BEFORE UPDATE ON public.relationships FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_rules_updated_at BEFORE UPDATE ON public.rules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_emotional_journals_updated_at BEFORE UPDATE ON public.emotional_journals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
