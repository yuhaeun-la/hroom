-- CASCADE를 사용한 사용자 삭제 (더 간단한 방법)
-- 주의: 이 방법은 모든 관련 데이터를 자동으로 삭제합니다

-- 먼저 현재 사용자 수 확인
SELECT 'Before deletion - auth.users count:' as info, COUNT(*) as count FROM auth.users;

-- CASCADE 삭제 (관련된 모든 데이터가 자동으로 삭제됨)
-- 각 사용자를 개별적으로 삭제 (CASCADE 동작을 위해)
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN SELECT id FROM auth.users LOOP
        DELETE FROM auth.users WHERE id = user_record.id;
    END LOOP;
END $$;

-- 또는 간단하게 (PostgreSQL이 CASCADE를 지원한다면)
-- TRUNCATE auth.users CASCADE;

-- 삭제 후 확인
SELECT 'After deletion:' as info, 
       'auth.users' as table_name, 
       COUNT(*) as remaining_count 
FROM auth.users
UNION ALL
SELECT 'After deletion:', 'users_profile', COUNT(*) FROM users_profile
UNION ALL
SELECT 'After deletion:', 'relationships', COUNT(*) FROM relationships
UNION ALL
SELECT 'After deletion:', 'rules', COUNT(*) FROM rules
UNION ALL
SELECT 'After deletion:', 'daily_logs', COUNT(*) FROM daily_logs;

