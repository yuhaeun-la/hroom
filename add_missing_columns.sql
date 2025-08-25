-- daily_logs 테이블에 누락된 컬럼들 추가
ALTER TABLE public.daily_logs 
ADD COLUMN IF NOT EXISTS notes TEXT;

-- 기존 데이터가 있을 수 있으므로 안전하게 컬럼 추가
-- 만약 notes 컬럼이 이미 있다면 무시됨
