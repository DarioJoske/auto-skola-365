ALTER TABLE lessons ADD COLUMN proposed_start_at TIMESTAMP WITH TIME ZONE;
CREATE TABLE instructor_availability_blocks (
    id UUID PRIMARY KEY,
    instructor_profile_id UUID NOT NULL REFERENCES instructor_profiles(id) ON DELETE CASCADE,
    start_at TIMESTAMP WITH TIME ZONE NOT NULL,
    end_at TIMESTAMP WITH TIME ZONE NOT NULL,
    kind VARCHAR(20) NOT NULL,
    CONSTRAINT ck_availability_block_time CHECK (start_at < end_at),
    CONSTRAINT ck_availability_block_kind CHECK (kind IN ('BREAK', 'ABSENCE'))
);
CREATE INDEX ix_availability_blocks_instructor ON instructor_availability_blocks(instructor_profile_id);
