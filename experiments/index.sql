-- Run from the repository root: psql ... -d idx_demo -f experiments/index.sql
-- NEVER run this experiment in course_catalog: it rebuilds the tables.
\set ON_ERROR_STOP on
SELECT current_database() = 'idx_demo' AS correct_database \gset
\if :correct_database
\i schema.sql
DROP INDEX IF EXISTS enrollments_student_id_idx;
\i experiments/idx_data.sql
EXPLAIN SELECT * FROM students WHERE email='student777@example.com';
EXPLAIN SELECT * FROM enrollments WHERE course_id='course-7';
EXPLAIN SELECT * FROM enrollments WHERE student_id=777;
EXPLAIN ANALYZE SELECT * FROM enrollments WHERE student_id=777;
EXPLAIN ANALYZE SELECT * FROM enrollments WHERE student_id=777;
EXPLAIN ANALYZE SELECT * FROM enrollments WHERE student_id=777;
CREATE INDEX enrollments_student_id_idx ON enrollments(student_id);
EXPLAIN SELECT * FROM enrollments WHERE student_id=777;
EXPLAIN ANALYZE SELECT * FROM enrollments WHERE student_id=777;
EXPLAIN ANALYZE SELECT * FROM enrollments WHERE student_id=777;
EXPLAIN ANALYZE SELECT * FROM enrollments WHERE student_id=777;
SELECT pg_size_pretty(pg_relation_size('enrollments')) AS table_size,
       pg_size_pretty(pg_relation_size('enrollments_student_id_idx')) AS index_size;
\else
\echo 'Use idx_demo only. No changes were made.'
\quit
\endif
