DROP TABLE IF EXISTS test_acl;
CREATE TABLE test_acl (
    rowid   INTEGER NOT NULL PRIMARY KEY,
    path    TEXT NOT NULL,
    role    TEXT NOT NULL
);

DROP TABLE IF EXISTS test_user_roles;
CREATE TABLE test_user_roles (
    rowid   INTEGER NOT NULL PRIMARY KEY,
    userid    TEXT NOT NULL,
    role    TEXT NOT NULL
);
