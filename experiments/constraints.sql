-- Intentional errors: run WITHOUT -v ON_ERROR_STOP=1.
\set ON_ERROR_STOP off
\set VERBOSITY verbose
-- 1. Required title.
INSERT INTO courses (id,title,description,credits) VALUES ('x-test',NULL,'Test',3);
-- 2. Positive credits.
INSERT INTO courses (id,title,description,credits) VALUES ('x-test','Test','Test',0);
-- 3. Nonnegative likes.
UPDATE courses SET likes=-1 WHERE id='api-design';
-- 4. Name length.
INSERT INTO students (name,email) VALUES ('A','a@example.com');
-- 5. Unique email.
INSERT INTO students (name,email) VALUES ('Dup Student','aigerim@example.com');
-- 6. Unique course identifier.
INSERT INTO courses (id,title,description,credits) VALUES ('api-design','x','y',1);
-- 7. Unique enrollment pair.
INSERT INTO enrollments (course_id,student_id) VALUES ('modern-frontend',1);
-- 8. Existing course.
INSERT INTO enrollments (course_id,student_id) VALUES ('no-such-course',1);
-- 9. Existing student.
INSERT INTO enrollments (course_id,student_id) VALUES ('web-security',999);
-- 10. Restrict course deletion.
DELETE FROM courses WHERE id='modern-frontend';
-- 11. Cascading student deletion; restore data afterwards.
BEGIN;
SELECT count(*) AS before_delete FROM enrollments;
DELETE FROM students WHERE email='daniyar@example.com';
SELECT count(*) AS after_delete FROM enrollments;
ROLLBACK;
SELECT count(*) AS after_rollback FROM enrollments;
\set VERBOSITY default
