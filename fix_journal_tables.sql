-- 잘못된 테이블들 삭제
DROP TABLE IF EXISTS emotional_journals CASCADE;
DROP TABLE IF EXISTS journal_comments CASCADE;

-- 올바른 감정 일지 테이블 생성
CREATE TABLE emotional_journals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  relationship_id UUID NOT NULL,
  user_id UUID NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  mood TEXT NOT NULL,
  mood_intensity INTEGER NOT NULL,
  tags TEXT[] DEFAULT '{}',
  date DATE NOT NULL,
  is_private BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 올바른 댓글 테이블 생성
CREATE TABLE journal_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_id UUID NOT NULL,
  user_id UUID NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX idx_emotional_journals_relationship_id ON emotional_journals(relationship_id);
CREATE INDEX idx_emotional_journals_user_id ON emotional_journals(user_id);
CREATE INDEX idx_emotional_journals_date ON emotional_journals(date);
CREATE INDEX idx_journal_comments_journal_id ON journal_comments(journal_id);
CREATE INDEX idx_journal_comments_user_id ON journal_comments(user_id);

-- 테이블 생성 확인
SELECT 'emotional_journals table created' as status;
SELECT 'journal_comments table created' as status;
