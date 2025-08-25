-- 보상 구매 내역 테이블 생성
CREATE TABLE IF NOT EXISTS public.reward_purchases (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    relationship_id UUID REFERENCES public.relationships(id) NOT NULL,
    reward_id UUID REFERENCES public.rewards_punishments(id) NOT NULL,
    user_id UUID REFERENCES public.users_profile(id) NOT NULL,
    reward_title VARCHAR(200) NOT NULL,
    points_spent INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'used', 'expired'
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used_at TIMESTAMP WITH TIME ZONE,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS 활성화 (현재 모든 테이블의 RLS가 비활성화되어 있으므로 일단 생략)
-- ALTER TABLE public.reward_purchases ENABLE ROW LEVEL SECURITY;

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_reward_purchases_relationship_id ON public.reward_purchases(relationship_id);
CREATE INDEX IF NOT EXISTS idx_reward_purchases_user_id ON public.reward_purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_reward_purchases_reward_id ON public.reward_purchases(reward_id);
CREATE INDEX IF NOT EXISTS idx_reward_purchases_status ON public.reward_purchases(status);

-- 기존 rewards_punishments 테이블이 있는지 확인하고 없으면 주석 해제
-- CREATE TABLE IF NOT EXISTS public.rewards_punishments (
--     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
--     relationship_id UUID REFERENCES public.relationships(id) NOT NULL,
--     title VARCHAR(200) NOT NULL,
--     description TEXT,
--     type VARCHAR(20) NOT NULL, -- 'reward' 또는 'punishment'
--     category VARCHAR(50) NOT NULL,
--     points_cost INTEGER NOT NULL,
--     is_active BOOLEAN DEFAULT true,
--     is_limited BOOLEAN DEFAULT false,
--     limit_count INTEGER,
--     purchase_count INTEGER DEFAULT 0,
--     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
--     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
-- );
