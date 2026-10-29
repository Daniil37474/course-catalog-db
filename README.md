# course-catalog-db

Лабораторная работа 6 — схема каталога курсов в PostgreSQL.

## Журнал нарушений ограничений

Эксперименты выполнены на PostgreSQL 18.6 с `\set VERBOSITY verbose`.
Сценарий: [experiments/constraints.sql](experiments/constraints.sql).
Ожидаемые ошибки в этом сценарии являются частью проверки.

| № | Нарушение | SQLSTATE | Ограничение или столбец | Ответ API |
|---|---|---|---|---|
| 1 | NULL в courses.title | `23502` | `courses.title (NOT NULL)` | 422; если пропустила валидация API — 500 |
| 2 | Нулевые credits | `23514` | `courses_credits_check` | 422 |
| 3 | Отрицательные likes | `23514` | `courses_likes_check` | 500 — ошибка кода счётчика |
| 4 | Имя из одного символа | `23514` | `students_name_check` | 422 |
| 5 | Повтор email | `23505` | `students_email_key` | 409 Conflict |
| 6 | Повтор course id | `23505` | `courses_pkey` | 409 Conflict |
| 7 | Повтор пары курс и студент | `23505` | `enrollments_course_id_student_id_key` | 409 Conflict |
| 8 | Несуществующий курс | `23503` | `enrollments_course_id_fkey` | 404 — курс не найден |
| 9 | Несуществующий студент | `23503` | `enrollments_student_id_fkey` | 404 — студент не найден |
| 10 | Удаление курса с записями | `23001` | `enrollments_course_id_fkey` | 409 Conflict |
| 11 | Удаление студента | ошибки нет | `enrollments_student_id_fkey`, CASCADE | 204 при успешном удалении |

При удалении Daniyar внутри транзакции число записей изменилось **6 → 3**;
после `ROLLBACK` восстановилось **6**. Все десять ошибочных команд оставили
таблицы без изменений: 6 курсов, 3 студента, 6 записей.

На PostgreSQL 18 запрет RESTRICT возвращает `23001`; на 16–17 — `23503`.
Для NOT NULL сервер вернул поле `column_name = title`, без имени ограничения.
API должен различать ошибки по SQLSTATE и имени ограничения, а не тексту сообщения.

Pydantic проверяет вход API и позволяет сразу объяснить ошибку пользователю.
Ограничения БД защищают данные при прямом SQL, импорте и обращении других программ;
поэтому проверка длины имени нужна в обоих местах. UNIQUE также защищает от
одновременных запросов, которые могли бы пройти предварительную проверку API.

Счётчики ID могут иметь пропуски: выданное значение не возвращается при ошибке
или откате. Это не означает потерю строки.

## Индекс и EXPLAIN

База `idx_demo`: 500 курсов, 20 000 студентов, 50 000 записей.
Запрос: `SELECT * FROM enrollments WHERE student_id = 777;`.
Измерения получены на PostgreSQL 18.6, Windows, 29 октября 2026 года.
Сценарий повторения: [experiments/index.sql](experiments/index.sql).
Он удаляет индекс перед измерением, так как итоговая схема уже содержит его.

### План до индекса

```text
Seq Scan on enrollments  (cost=0.00..1042.00 rows=3 width=34)
  Filter: (student_id = 777)
```

### План после индекса

```text
Bitmap Heap Scan on enrollments  (cost=4.31..15.59 rows=3 width=34)
  Recheck Cond: (student_id = 777)
  ->  Bitmap Index Scan on enrollments_student_id_idx  (cost=0.00..4.31 rows=3 width=0)
        Index Cond: (student_id = 777)
```

| Показатель | До индекса | После индекса |
|---|---|---|
| Доступ | Seq Scan | Bitmap Heap Scan |
| cost | 0.0..1042.0 | 4.31..15.59 |
| Rows Removed by Filter | 49997 | 0, фильтрация всей таблицы не нужна |
| Execution Time, минимум из 3 | 8.514 ms | 0.082 ms |

Все три замера до: 9.576, 9.114, 8.514 ms; после: 0.228, 0.082, 0.083 ms. Время зависит от компьютера и кэша.

Размер таблицы — 3336 kB, дополнительного индекса — 896 kB. Индекс занимает место и требует обслуживания при INSERT, DELETE и изменении student_id.

Поиск по email:

```text
Index Scan using students_email_key on students  (cost=0.29..8.30 rows=1 width=45)
  Index Cond: (email = 'student777@example.com'::text)
```

Поиск по course_id:

```text
Bitmap Heap Scan on enrollments  (cost=5.19..241.01 rows=100 width=34)
  Recheck Cond: (course_id = 'course-7'::text)
  ->  Bitmap Index Scan on enrollments_course_id_student_id_key  (cost=0.00..5.17 rows=100 width=0)
        Index Cond: (course_id = 'course-7'::text)
```

1. PRIMARY KEY и UNIQUE автоматически создают индексы; FOREIGN KEY на ссылающейся стороне — нет. Для email индекс появился из UNIQUE, для course_id используется первый столбец UNIQUE (course_id, student_id). Для поиска только по student_id в данном эксперименте выбран Seq Scan: составной индекс не дал выгодного плана. В PostgreSQL 18 возможен skip scan по последующим столбцам, но его выбор зависит от статистики и стоимости.
2. Шесть курсов помещаются на одной странице: прочитать её дешевле, чем обращаться к индексу и затем к таблице. На 50 000 строк отдельный индекс позволяет получить только нужные записи.
3. Индекс student_id ускоряет выборку записей одного студента и поиск дочерних строк при каскадном удалении студента.
