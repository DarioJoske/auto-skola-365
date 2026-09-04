CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    oib TEXT,
    email TEXT,
    phone TEXT,
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX ux_schools_oib ON schools (oib) WHERE oib IS NOT NULL;

CREATE TABLE branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools (id),
    name TEXT NOT NULL,
    address TEXT,
    city TEXT,
    phone TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ix_branches_school_id ON branches (school_id);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX ux_users_email ON users (lower(email));

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    scope TEXT NOT NULL
);

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL
);

CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles (id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions (id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE school_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools (id),
    user_id UUID NOT NULL REFERENCES users (id),
    role_id UUID NOT NULL REFERENCES roles (id),
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ux_school_memberships_school_user UNIQUE (school_id, user_id)
);

CREATE INDEX ix_school_memberships_user_id ON school_memberships (user_id);
CREATE INDEX ix_school_memberships_role_id ON school_memberships (role_id);

CREATE TABLE driving_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT true
);

INSERT INTO roles (key, name, scope) VALUES
    ('platform_super_admin', 'Platform Super Admin', 'PLATFORM'),
    ('school_owner', 'School Owner', 'SCHOOL'),
    ('school_admin', 'School Admin', 'SCHOOL'),
    ('instructor', 'Instructor', 'SCHOOL');

INSERT INTO permissions (key, description) VALUES
    ('platform.tenants.manage', 'Manage schools and tenant provisioning.'),
    ('school.settings.manage', 'Manage school settings and branch records.'),
    ('users.manage', 'Manage school users and memberships.'),
    ('candidates.manage', 'Manage candidates.'),
    ('instructors.manage', 'Manage instructors.'),
    ('lessons.manage', 'Manage lesson scheduling.'),
    ('lessons.view_assigned', 'View assigned instructor lessons.'),
    ('progress.manage_assigned', 'Manage progress for assigned candidates.');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.key IN (
    'platform.tenants.manage'
)
WHERE r.key = 'platform_super_admin';

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.key IN (
    'school.settings.manage',
    'users.manage',
    'candidates.manage',
    'instructors.manage',
    'lessons.manage'
)
WHERE r.key IN ('school_owner', 'school_admin');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.key IN (
    'lessons.view_assigned',
    'progress.manage_assigned'
)
WHERE r.key = 'instructor';

INSERT INTO driving_categories (code, name) VALUES
    ('A', 'Motorcycle'),
    ('B', 'Passenger car'),
    ('C', 'Truck'),
    ('D', 'Bus'),
    ('CE', 'Truck with trailer');
