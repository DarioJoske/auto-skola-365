CREATE TABLE instructor_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_membership_id UUID NOT NULL REFERENCES school_memberships (id),
    license_number TEXT,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ux_instructor_profiles_membership UNIQUE (school_membership_id)
);

CREATE TABLE instructors_categories (
    instructor_profile_id UUID NOT NULL REFERENCES instructor_profiles (id) ON DELETE CASCADE,
    driving_category_id UUID NOT NULL REFERENCES driving_categories (id),
    PRIMARY KEY (instructor_profile_id, driving_category_id)
);

CREATE INDEX ix_instructors_categories_category_id ON instructors_categories (driving_category_id);

CREATE TABLE instructor_availability_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instructor_profile_id UUID NOT NULL REFERENCES instructor_profiles (id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_instructor_availability_day CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT ck_instructor_availability_time CHECK (start_time < end_time)
);

CREATE INDEX ix_instructor_availability_instructor_id ON instructor_availability_rules (instructor_profile_id);
