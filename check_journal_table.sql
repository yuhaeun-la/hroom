-- 기존 테이블 구조 확인
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'emotional_journals' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 댓글 테이블 구조도 확인
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'journal_comments' 
AND table_schema = 'public'
ORDER BY ordinal_position;
