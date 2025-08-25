-- 외래 키 제약 조건을 고려한 올바른 삭제 순서

-- 1. 가장 하위 테이블부터 삭제 (다른 테이블을 참조하지 않는 테이블)
DELETE FROM journal_comments;
DELETE FROM points_history;
DELETE FROM daily_logs;
DELETE FROM emotional_journals;

-- 2. reward_purchases 테이블이 있다면 삭제
DELETE FROM reward_purchases WHERE TRUE;

-- 3. 보상/처벌 삭제
DELETE FROM rewards_punishments;

-- 4. 규칙 삭제
DELETE FROM rules;

-- 5. 초대 코드 삭제
DELETE FROM invitation_codes;

-- 6. 관계 삭제
DELETE FROM relationships;

-- 7. 사용자 프로필 삭제 (auth.users를 참조하는 테이블)
DELETE FROM users_profile;

-- 8. 마지막으로 auth.users 삭제
DELETE FROM auth.users;

-- 삭제 결과 확인
SELECT 'auth.users' as table_name, COUNT(*) as remaining_count FROM auth.users
UNION ALL
SELECT 'users_profile', COUNT(*) FROM users_profile
UNION ALL
SELECT 'relationships', COUNT(*) FROM relationships
UNION ALL
SELECT 'rules', COUNT(*) FROM rules
UNION ALL
SELECT 'daily_logs', COUNT(*) FROM daily_logs
UNION ALL
SELECT 'emotional_journals', COUNT(*) FROM emotional_journals
UNION ALL
SELECT 'points_history', COUNT(*) FROM points_history
UNION ALL
SELECT 'invitation_codes', COUNT(*) FROM invitation_codes
UNION ALL
SELECT 'rewards_punishments', COUNT(*) FROM rewards_punishments;
