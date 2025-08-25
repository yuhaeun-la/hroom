-- users_profile 테이블의 role 체크 제약 조건 완전 제거

-- 체크 제약 조건 제거
ALTER TABLE users_profile 
DROP CONSTRAINT IF EXISTS users_profile_role_check;

-- 확인: 제약 조건이 제거되었는지 확인
SELECT conname, contype 
FROM pg_constraint 
WHERE conrelid = 'users_profile'::regclass 
AND contype = 'c';

