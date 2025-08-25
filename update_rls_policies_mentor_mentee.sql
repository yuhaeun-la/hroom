-- RLS 정책들을 mentor_id, mentee_id로 업데이트

-- 1. relationships 테이블 RLS 정책 업데이트
DROP POLICY IF EXISTS "Users can view their own relationships" ON relationships;
DROP POLICY IF EXISTS "Users can insert their own relationships" ON relationships;
DROP POLICY IF EXISTS "Users can update their own relationships" ON relationships;

-- 새로운 RLS 정책 생성 (mentor_id, mentee_id 사용)
CREATE POLICY "Users can view their own relationships" ON relationships
FOR SELECT USING (auth.uid() = mentor_id OR auth.uid() = mentee_id);

CREATE POLICY "Users can insert their own relationships" ON relationships
FOR INSERT WITH CHECK (auth.uid() = mentor_id OR auth.uid() = mentee_id);

CREATE POLICY "Users can update their own relationships" ON relationships
FOR UPDATE USING (auth.uid() = mentor_id OR auth.uid() = mentee_id);

-- 2. invitation_codes 테이블 RLS 정책 업데이트  
DROP POLICY IF EXISTS "Users can view invitation codes" ON invitation_codes;
DROP POLICY IF EXISTS "Users can insert invitation codes" ON invitation_codes;
DROP POLICY IF EXISTS "Users can update invitation codes" ON invitation_codes;

CREATE POLICY "Users can view invitation codes" ON invitation_codes
FOR SELECT USING (auth.uid() = mentor_id OR auth.uid() = used_by);

CREATE POLICY "Users can insert invitation codes" ON invitation_codes
FOR INSERT WITH CHECK (auth.uid() = mentor_id);

CREATE POLICY "Users can update invitation codes" ON invitation_codes
FOR UPDATE USING (auth.uid() = mentor_id OR auth.uid() = used_by);

-- 3. 확인
SELECT schemaname, tablename, policyname, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('relationships', 'invitation_codes')
ORDER BY tablename, policyname;
