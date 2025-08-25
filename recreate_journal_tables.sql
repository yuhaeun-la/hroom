-- 기존 테이블 삭제 후 재생성
DROP TABLE IF EXISTS journal_comments CASCADE;
DROP TABLE IF EXISTS emotional_journals CASCADE;

-- 감정 일지 테이블 생성
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

-- 댓글 테이블 생성
CREATE TABLE journal_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_id UUID,
  user_id UUID,
  content TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 기본 인덱스 추가
CREATE INDEX idx_emotional_journals_relationship_id ON emotional_journals(relationship_id);
CREATE INDEX idx_emotional_journals_user_id ON emotional_journals(user_id);
CREATE INDEX idx_journal_comments_journal_id ON journal_comments(journal_id);


