ALTER TABLE candidates ADD COLUMN required_driving_hours INTEGER;

UPDATE candidates
SET required_driving_hours = 35
WHERE driving_category_id IN (SELECT id FROM driving_categories WHERE code = 'B');

ALTER TABLE candidates ADD CONSTRAINT ck_candidate_required_driving_hours
    CHECK (required_driving_hours IS NULL OR required_driving_hours > 0);

CREATE INDEX ix_lessons_candidate_completed_hours
    ON lessons (school_id, candidate_id, driving_category_id)
    WHERE status = 'COMPLETED' AND lesson_type = 'DRIVING';
