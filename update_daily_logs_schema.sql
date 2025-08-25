-- daily_logs 테이블에 누락된 컬럼 추가
ALTER TABLE public.daily_logs 
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS points_earned INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS rule_title VARCHAR(200),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 기존 컬럼명 변경 (notes -> note, proof_image_url -> photo_url)
-- 주의: 데이터가 있는 경우 백업 후 실행하세요
DO $$ 
BEGIN
    -- notes 컬럼이 존재하고 note 컬럼이 없는 경우에만 변경
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'daily_logs' AND column_name = 'notes')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'daily_logs' AND column_name = 'note') THEN
        ALTER TABLE public.daily_logs RENAME COLUMN notes TO note;
    END IF;
    
    -- proof_image_url 컬럼이 존재하고 photo_url 컬럼이 없는 경우에만 변경
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'daily_logs' AND column_name = 'proof_image_url')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'daily_logs' AND column_name = 'photo_url') THEN
        ALTER TABLE public.daily_logs RENAME COLUMN proof_image_url TO photo_url;
    END IF;
END $$;

-- updated_at 트리거 추가 (이미 있다면 무시됨)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_daily_logs_updated_at ON public.daily_logs;
CREATE TRIGGER update_daily_logs_updated_at
    BEFORE UPDATE ON public.daily_logs
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
