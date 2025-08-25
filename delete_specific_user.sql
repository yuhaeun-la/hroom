-- 특정 이메일 사용자만 삭제하는 스크립트
-- 'your_email@example.com'을 실제 삭제하고 싶은 이메일로 변경하세요

-- 1단계: 삭제할 사용자 확인
SELECT id, email, raw_user_meta_data->>'display_name' as display_name 
FROM auth.users 
WHERE email = 'your_email@example.com';

-- 2단계: 해당 사용자의 관련 데이터 삭제
WITH user_to_delete AS (
    SELECT id FROM auth.users WHERE email = 'your_email@example.com'
)
DELETE FROM public.journal_comments 
WHERE commenter_id IN (SELECT id FROM user_to_delete);

WITH user_to_delete AS (
    SELECT id FROM auth.users WHERE email = 'your_email@example.com'
)
DELETE FROM public.points_history 
WHERE user_id IN (SELECT id FROM user_to_delete);

WITH user_to_delete AS (
    SELECT id FROM auth.users WHERE email = 'your_email@example.com'
)
DELETE FROM public.emotional_journals 
WHERE writer_id IN (SELECT id FROM user_to_delete);

WITH user_to_delete AS (
    SELECT id FROM auth.users WHERE email = 'your_email@example.com'
)
DELETE FROM public.relationships 
WHERE dom_id IN (SELECT id FROM user_to_delete) 
   OR sub_id IN (SELECT id FROM user_to_delete);

WITH user_to_delete AS (
    SELECT id FROM auth.users WHERE email = 'your_email@example.com'
)
DELETE FROM public.users_profile 
WHERE id IN (SELECT id FROM user_to_delete);

-- 3단계: auth.users에서 삭제
DELETE FROM auth.users WHERE email = 'your_email@example.com';

SELECT 'User deleted successfully!' as result;
