CREATE TABLE candidates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools (id),
    driving_category_id UUID NOT NULL REFERENCES driving_categories (id),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    oib TEXT,
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ix_candidates_school_id ON candidates (school_id);
CREATE INDEX ix_candidates_driving_category_id ON candidates (driving_category_id);
CREATE UNIQUE INDEX ux_candidates_school_oib ON candidates (school_id, oib) WHERE oib IS NOT NULL;
