-- Run in course_catalog after schema.sql and seed.sql.
-- This file intentionally raises 23503 then 25P02.
\set ON_ERROR_STOP off
\set VERBOSITY verbose
BEGIN;
INSERT INTO students (name,email) VALUES ('Madina Ospanova','madina@example.com');
INSERT INTO enrollments (course_id,student_id)
SELECT 'no-such-course',id FROM students WHERE email='madina@example.com';
SELECT count(*) FROM students;
ROLLBACK;
SELECT count(*) AS after_rollback FROM students WHERE email='madina@example.com';
\set VERBOSITY default

-- Successful case: execute the following block manually in connection A.
-- BEGIN;
-- INSERT INTO students (name,email) VALUES ('Madina Ospanova','madina@example.com');
-- INSERT INTO enrollments (course_id,student_id)
-- SELECT 'web-security',id FROM students WHERE email='madina@example.com';
-- In connection B (autocommit), run:
-- SELECT count(*) FROM students WHERE email='madina@example.com'; -- 0
-- In A: COMMIT;
-- Repeat the SELECT in B: 1. Both inserts are now visible.
-- Re-run schema.sql and seed.sql afterwards to restore the original data.
