ALTER TABLE candidates
ADD COLUMN assigned_instructor_profile_id UUID REFERENCES instructor_profiles (id);

CREATE INDEX ix_candidates_assigned_instructor_id
ON candidates (assigned_instructor_profile_id);

CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools (id),
    candidate_id UUID NOT NULL REFERENCES candidates (id),
    instructor_profile_id UUID NOT NULL REFERENCES instructor_profiles (id),
    driving_category_id UUID NOT NULL REFERENCES driving_categories (id),
    branch_id UUID REFERENCES branches (id),
    lesson_type TEXT NOT NULL DEFAULT 'DRIVING',
    status TEXT NOT NULL DEFAULT 'REQUESTED',
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    confirmed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    notes TEXT,
    created_by_role TEXT NOT NULL DEFAULT 'ADMIN',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_lessons_time CHECK (start_at < end_at),
    CONSTRAINT ck_lessons_type CHECK (lesson_type IN ('DRIVING', 'THEORY', 'EXAM')),
    CONSTRAINT ck_lessons_status CHECK (status IN ('REQUESTED', 'CONFIRMED', 'COMPLETED', 'CANCELLED', 'NO_SHOW')),
    CONSTRAINT ck_lessons_created_by_role CHECK (created_by_role IN ('ADMIN', 'INSTRUCTOR', 'CANDIDATE'))
);

CREATE INDEX ix_lessons_school_start_at ON lessons (school_id, start_at);
CREATE INDEX ix_lessons_candidate_start_at ON lessons (candidate_id, start_at);
CREATE INDEX ix_lessons_instructor_start_at ON lessons (instructor_profile_id, start_at);
