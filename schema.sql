-- Lab 6: course catalog schema. Re-running this file deletes existing data.
-- For this teaching database only; production changes use migrations.
BEGIN;
DROP TABLE IF EXISTS enrollments, students, courses;

CREATE TABLE courses (
    id text PRIMARY KEY,
    title text NOT NULL,
    description text NOT NULL,
    credits integer NOT NULL CHECK (credits > 0),
    is_elective boolean NOT NULL DEFAULT false,
    likes integer NOT NULL DEFAULT 0 CHECK (likes >= 0)
);

CREATE TABLE students (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL CHECK (char_length(name) >= 2),
    email text NOT NULL UNIQUE
);

CREATE TABLE enrollments (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_id text NOT NULL REFERENCES courses (id) ON DELETE RESTRICT,
    student_id bigint NOT NULL REFERENCES students (id) ON DELETE CASCADE,
    enrolled_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (course_id, student_id)
);
-- Supports student lookups and cascading deletion.
CREATE INDEX enrollments_student_id_idx ON enrollments (student_id);
COMMIT;
