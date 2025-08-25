-- 가장 기본적인 감정 일지 테이블
CREATE TABLE emotional_journals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  relationship_id UUID,
  user_id UUID,
  title TEXT,
  content TEXT,
  mood TEXT,
  mood_intensity INTEGER,
  tags TEXT[],
  date DATE,
  is_private BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 가장 기본적인 댓글 테이블
CREATE TABLE journal_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_id UUID,
  user_id UUID,
  content TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
