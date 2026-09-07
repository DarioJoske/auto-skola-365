ALTER TABLE candidates
ADD COLUMN user_id UUID REFERENCES users (id);

CREATE INDEX ix_candidates_user_id
ON candidates (user_id);

CREATE UNIQUE INDEX ux_candidates_school_user
ON candidates (school_id, user_id)
WHERE user_id IS NOT NULL;

INSERT INTO roles (key, name, scope)
VALUES ('candidate', 'Candidate', 'SCHOOL')
ON CONFLICT (key) DO NOTHING;

INSERT INTO permissions (key, description)
VALUES ('lessons.reserve_own', 'Reserve own candidate lessons.')
ON CONFLICT (key) DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT role.id, permission.id
FROM roles role
JOIN permissions permission ON permission.key = 'lessons.reserve_own'
WHERE role.key = 'candidate'
ON CONFLICT DO NOTHING;
