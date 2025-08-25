-- 감정 일지 테이블 생성
CREATE TABLE IF NOT EXISTS emotional_journals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  relationship_id UUID NOT NULL REFERENCES relationships(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
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
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
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

-- RLS (Row Level Security) 활성화
ALTER TABLE emotional_journals ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_comments ENABLE ROW LEVEL SECURITY;

-- RLS 정책 생성 (일지)
CREATE POLICY "Users can view journals in their relationship" ON emotional_journals
  FOR SELECT USING (
    relationship_id IN (
      SELECT id FROM relationships 
      WHERE dom_id = auth.uid() OR sub_id = auth.uid()
    )
    AND (
      -- 작성자는 모든 일지를 볼 수 있음
      user_id = auth.uid()
      OR 
      -- Dom은 비공개가 아닌 일지만 볼 수 있음
      (
        relationship_id IN (
          SELECT id FROM relationships WHERE dom_id = auth.uid()
        )
        AND is_private = FALSE
      )
    )
  );

CREATE POLICY "Users can insert their own journals" ON emotional_journals
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    AND relationship_id IN (
      SELECT id FROM relationships 
      WHERE dom_id = auth.uid() OR sub_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own journals" ON emotional_journals
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own journals" ON emotional_journals
  FOR DELETE USING (user_id = auth.uid());

-- RLS 정책 생성 (댓글)
CREATE POLICY "Users can view comments on viewable journals" ON journal_comments
  FOR SELECT USING (
    journal_id IN (
      SELECT id FROM emotional_journals
      WHERE relationship_id IN (
        SELECT id FROM relationships 
        WHERE dom_id = auth.uid() OR sub_id = auth.uid()
      )
      AND (
        user_id = auth.uid()
        OR 
        (
          relationship_id IN (
            SELECT id FROM relationships WHERE dom_id = auth.uid()
          )
          AND is_private = FALSE
        )
      )
    )
  );

CREATE POLICY "Dom can insert comments on non-private journals" ON journal_comments
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    AND journal_id IN (
      SELECT id FROM emotional_journals
      WHERE relationship_id IN (
        SELECT id FROM relationships WHERE dom_id = auth.uid()
      )
      AND is_private = FALSE
    )
  );

CREATE POLICY "Users can update their own comments" ON journal_comments
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own comments" ON journal_comments
  FOR DELETE USING (user_id = auth.uid());

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
