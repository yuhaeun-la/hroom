-- H-Room 앱 Row-Level Security (RLS) 정책
-- 데이터 보안 및 접근 권한 제어

-- RLS 활성화
ALTER TABLE public.users_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emotional_journals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.points_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rewards_punishments ENABLE ROW LEVEL SECURITY;

-- 사용자 프로필 정책
-- 본인의 프로필은 읽기/쓰기 가능, 파트너의 프로필은 읽기만 가능
CREATE POLICY "Users can view own profile" ON public.users_profile
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users_profile
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users_profile
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view partner profile" ON public.users_profile
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.relationships 
            WHERE (dom_id = auth.uid() AND sub_id = users_profile.id)
               OR (sub_id = auth.uid() AND dom_id = users_profile.id)
        )
    );

-- 관계 정책
-- 관계의 당사자들만 접근 가능
CREATE POLICY "Users can view their relationships" ON public.relationships
    FOR SELECT USING (dom_id = auth.uid() OR sub_id = auth.uid());

CREATE POLICY "Dom can create relationships" ON public.relationships
    FOR INSERT WITH CHECK (dom_id = auth.uid());

CREATE POLICY "Users can update their relationships" ON public.relationships
    FOR UPDATE USING (dom_id = auth.uid() OR sub_id = auth.uid());

-- 규칙 정책
-- Dom은 생성/수정 가능, Sub는 읽기만 가능
CREATE POLICY "Relationship members can view rules" ON public.rules
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.relationships 
            WHERE id = rules.relationship_id 
            AND (dom_id = auth.uid() OR sub_id = auth.uid())
        )
    );

CREATE POLICY "Dom can create rules" ON public.rules
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.relationships 
            WHERE id = rules.relationship_id 
            AND dom_id = auth.uid()
        )
    );

CREATE POLICY "Dom can update rules" ON public.rules
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.relationships 
            WHERE id = rules.relationship_id 
            AND dom_id = auth.uid()
        )
    );

-- 일일 로그 정책
-- 관계 당사자들만 접근 가능
CREATE POLICY "Relationship members can view daily logs" ON public.daily_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.relationships 
            WHERE id = daily_logs.relationship_id 
            AND (dom_id = auth.uid() OR sub_id = auth.uid())
        )
    );

CREATE POLICY "Sub can create daily logs" ON public.daily_logs
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.relationships 
            WHERE id = daily_logs.relationship_id 
            AND sub_id = auth.uid()
        )
    );

CREATE POLICY "Sub can update own daily logs" ON public.daily_logs
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.relationships 
            WHERE id = daily_logs.relationship_id 
            AND sub_id = auth.uid()
        )
    );

-- 감정 일지 정책
-- 작성자와 파트너만 접근 가능 (비공개 일지 제외)
CREATE POLICY "Users can view accessible journals" ON public.emotional_journals
    FOR SELECT USING (
        writer_id = auth.uid() 
        OR (
            NOT is_private 
            AND EXISTS (
                SELECT 1 FROM public.relationships 
                WHERE id = emotional_journals.relationship_id 
                AND (dom_id = auth.uid() OR sub_id = auth.uid())
            )
        )
    );

CREATE POLICY "Users can create own journals" ON public.emotional_journals
    FOR INSERT WITH CHECK (
        writer_id = auth.uid() 
        AND EXISTS (
            SELECT 1 FROM public.relationships 
            WHERE id = emotional_journals.relationship_id 
            AND (dom_id = auth.uid() OR sub_id = auth.uid())
        )
    );

CREATE POLICY "Users can update own journals" ON public.emotional_journals
    FOR UPDATE USING (writer_id = auth.uid());

-- 일지 댓글 정책
-- 관계 당사자들만 댓글 작성/읽기 가능
CREATE POLICY "Relationship members can view comments" ON public.journal_comments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.emotional_journals ej
            JOIN public.relationships r ON ej.relationship_id = r.id
            WHERE ej.id = journal_comments.journal_id
            AND (r.dom_id = auth.uid() OR r.sub_id = auth.uid())
            AND NOT ej.is_private
        )
    );

CREATE POLICY "Relationship members can create comments" ON public.journal_comments
    FOR INSERT WITH CHECK (
        commenter_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.emotional_journals ej
            JOIN public.relationships r ON ej.relationship_id = r.id
            WHERE ej.id = journal_comments.journal_id
            AND (r.dom_id = auth.uid() OR r.sub_id = auth.uid())
            AND NOT ej.is_private
        )
    );

-- 포인트 이력 정책
-- 관계 당사자들만 접근 가능
CREATE POLICY "Relationship members can view points history" ON public.points_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.relationships 
            WHERE id = points_history.relationship_id 
            AND (dom_id = auth.uid() OR sub_id = auth.uid())
        )
    );

CREATE POLICY "System can insert points history" ON public.points_history
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.relationships 
            WHERE id = points_history.relationship_id 
            AND (dom_id = auth.uid() OR sub_id = auth.uid())
        )
    );

-- 보상/처벌 정책
-- Dom만 생성/수정 가능, 관계 당사자들은 읽기 가능
CREATE POLICY "Relationship members can view rewards punishments" ON public.rewards_punishments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.relationships 
            WHERE id = rewards_punishments.relationship_id 
            AND (dom_id = auth.uid() OR sub_id = auth.uid())
        )
    );

CREATE POLICY "Dom can create rewards punishments" ON public.rewards_punishments
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.relationships 
            WHERE id = rewards_punishments.relationship_id 
            AND dom_id = auth.uid()
        )
    );

CREATE POLICY "Dom can update rewards punishments" ON public.rewards_punishments
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.relationships 
            WHERE id = rewards_punishments.relationship_id 
            AND dom_id = auth.uid()
        )
    );

-- 뷰에 대한 보안 정책 (뷰는 기본 테이블의 RLS를 상속받음)
-- 추가 보안이 필요한 경우 함수로 구현
