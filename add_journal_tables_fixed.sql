-- 감정 일지 테이블 생성 (수정된 버전)
CREATE TABLE IF NOT EXISTS emotional_journals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  relationship_id UUID NOT NULL REFERENCES relationships(id) ON DELETE CASCADE,
  user_id UUID NOT NULL, -- auth.users 참조하지 않고 단순 UUID로
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  mood TEXT NOT NULL CHECK (mood IN ('happy', 'sad', 'angry', 'anxious', 'excited', 'calm', 'confused')),
  mood_intensity INTEGER NOT NULL CHECK (mood_intensity >= 1 AND mood_intensity <= 5),
  tags TEXT[] DEFAULT '{}',
  date DATE NOT NULL,
  is_private BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 일지 댓글 테이블 생성
CREATE TABLE IF NOT EXISTS journal_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_id UUID NOT NULL REFERENCES emotional_journals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL, -- auth.users 참조하지 않고 단순 UUID로
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_emotional_journals_relationship_id ON emotional_journals(relationship_id);
CREATE INDEX IF NOT EXISTS idx_emotional_journals_user_id ON emotional_journals(user_id);
CREATE INDEX IF NOT EXISTS idx_emotional_journals_date ON emotional_journals(date);
CREATE INDEX IF NOT EXISTS idx_emotional_journals_mood ON emotional_journals(mood);
CREATE INDEX IF NOT EXISTS idx_emotional_journals_tags ON emotional_journals USING GIN(tags);

CREATE INDEX IF NOT EXISTS idx_journal_comments_journal_id ON journal_comments(journal_id);
CREATE INDEX IF NOT EXISTS idx_journal_comments_user_id ON journal_comments(user_id);

-- updated_at 트리거 함수 (이미 존재할 수 있음)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- updated_at 트리거 생성
CREATE TRIGGER update_emotional_journals_updated_at 
  BEFORE UPDATE ON emotional_journals 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_journal_comments_updated_at 
  BEFORE UPDATE ON journal_comments 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 코멘트 추가
COMMENT ON TABLE emotional_journals IS '사용자 감정 일지';
COMMENT ON TABLE journal_comments IS '일지 댓글';

COMMENT ON COLUMN emotional_journals.mood IS '감정 상태 (happy, sad, angry, anxious, excited, calm, confused)';
COMMENT ON COLUMN emotional_journals.mood_intensity IS '감정 강도 (1-5)';
COMMENT ON COLUMN emotional_journals.tags IS '태그 배열';
COMMENT ON COLUMN emotional_journals.is_private IS '비공개 여부 (Sub만 볼 수 있음)';
