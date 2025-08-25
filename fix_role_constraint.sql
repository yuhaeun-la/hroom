-- users_profile 테이블의 role 체크 제약 조건 수정

-- 1. 기존 체크 제약 조건 제거
ALTER TABLE users_profile 
DROP CONSTRAINT IF EXISTS users_profile_role_check;

-- 2. 새로운 체크 제약 조건 추가 (mentor, mentee 허용)
ALTER TABLE users_profile 
ADD CONSTRAINT users_profile_role_check 
CHECK (role IN ('dom', 'sub', 'mentor', 'mentee'));

-- 3. 기존 데이터 업데이트 (있다면)
UPDATE users_profile 
SET role = 'mentor' 
WHERE role = 'dom';

UPDATE users_profile 
SET role = 'mentee' 
WHERE role = 'sub';

-- 4. 확인
SELECT role, COUNT(*) as count 
FROM users_profile 
GROUP BY role;
