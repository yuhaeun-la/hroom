-- 모든 사용자 데이터를 안전하게 삭제하는 스크립트
-- 외래 키 제약 조건 때문에 순서대로 삭제해야 합니다

-- 1. 일지 댓글 삭제
DELETE FROM journal_comments;

-- 2. 포인트 히스토리 삭제
DELETE FROM points_history;

-- 3. 일일 로그 삭제
DELETE FROM daily_logs;

-- 4. 감정 일지 삭제
DELETE FROM emotional_journals;

-- 5. 보상/처벌 구매 기록 삭제 (있다면)
DELETE FROM reward_purchases;

-- 6. 보상/처벌 삭제
DELETE FROM rewards_punishments;

-- 7. 규칙 삭제
DELETE FROM rules;

-- 8. 초대 코드 삭제
DELETE FROM invitation_codes;

-- 9. 관계 삭제
DELETE FROM relationships;

-- 10. 사용자 프로필 삭제
DELETE FROM users_profile;

-- 11. auth.users는 Supabase 대시보드에서 수동으로 삭제하거나
-- 다음 명령어로 시도 (권한이 있다면)
-- DELETE FROM auth.users;

-- 삭제 결과 확인
SELECT 'users_profile' as table_name, COUNT(*) as remaining_count FROM users_profile
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
SELECT 'invitation_codes', COUNT(*) FROM invitation_codes;
