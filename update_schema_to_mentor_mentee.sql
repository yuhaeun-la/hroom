-- 데이터베이스 스키마를 Dom-Sub에서 Mentor-Mentee로 변경

-- 1. relationships 테이블 컬럼명 변경
ALTER TABLE relationships 
RENAME COLUMN dom_id TO mentor_id;

ALTER TABLE relationships 
RENAME COLUMN sub_id TO mentee_id;

-- 2. invitation_codes 테이블 컬럼명 변경
ALTER TABLE invitation_codes 
RENAME COLUMN dom_id TO mentor_id;

-- 3. relationship_stats 뷰가 있다면 재생성 (dom_id, sub_id 참조하는 뷰들)
DROP VIEW IF EXISTS relationship_stats;

-- 4. users_profile 테이블의 role 체크 제약 조건 수정
ALTER TABLE users_profile 
DROP CONSTRAINT IF EXISTS users_profile_role_check;

ALTER TABLE users_profile 
ADD CONSTRAINT users_profile_role_check 
CHECK (role IN ('dom', 'sub', 'mentor', 'mentee'));

-- 5. 기존 role 데이터 업데이트 (있다면)
UPDATE users_profile 
SET role = 'mentor' 
WHERE role = 'dom';

UPDATE users_profile 
SET role = 'mentee' 
WHERE role = 'sub';

-- 6. 관련 뷰 재생성 (user_current_points 등에서 dom_id, sub_id 참조하는 경우)
-- relationship_stats 뷰 재생성
CREATE OR REPLACE VIEW relationship_stats AS
SELECT 
    r.id as relationship_id,
    r.mentor_id,
    r.mentee_id,
    COUNT(dl.id) as total_logs,
    COUNT(CASE WHEN dl.completed = true THEN 1 END) as completed_logs,
    COALESCE(
        ROUND(
            COUNT(CASE WHEN dl.completed = true THEN 1 END)::numeric / 
            NULLIF(COUNT(dl.id), 0) * 100, 2
        ), 0
    ) as completion_rate,
    COUNT(ej.id) as journal_entries,
    MAX(dl.log_date) as last_activity
FROM relationships r
LEFT JOIN rules ru ON ru.relationship_id = r.id
LEFT JOIN daily_logs dl ON dl.rule_id = ru.id
LEFT JOIN emotional_journals ej ON ej.relationship_id = r.id
WHERE r.status = 'active'
GROUP BY r.id, r.mentor_id, r.mentee_id;

-- 7. 변경 사항 확인
SELECT 'relationships' as table_name, 
       column_name, 
       data_type 
FROM information_schema.columns 
WHERE table_name = 'relationships' 
  AND column_name IN ('mentor_id', 'mentee_id', 'dom_id', 'sub_id')
UNION ALL
SELECT 'invitation_codes' as table_name, 
       column_name, 
       data_type 
FROM information_schema.columns 
WHERE table_name = 'invitation_codes' 
  AND column_name IN ('mentor_id', 'dom_id')
UNION ALL
SELECT 'users_profile' as table_name,
       'role_values' as column_name,
       'check_constraint' as data_type
ORDER BY table_name, column_name;
