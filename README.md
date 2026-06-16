# BookMyShow – Theatre Show Listing

A relational database design for the BookMyShow scenario: for a given **theatre**
and one of the next 7 **dates**, list every **show** running in that theatre along
with its **timing**, language, format and audio/projection experience.

The reference screenshot (PVR: Nexus, 25 Apr) is used as the sample data set.

## Repository contents

| File         | Description |
|--------------|-------------|
| `schema.sql` | **P1** – `CREATE TABLE` statements + sample inserts, and **P2** – the show-listing query. Directly executable on MySQL 8.x. |
| `DESIGN.md`  | Detailed write-up: entities, attributes, relationships, normalization (1NF→BCNF) reasoning and sample rows. |

## Entities

- **language** – `language_id`, `language_name` (Telugu, Hindi, English …)
- **format** – `format_id`, `format_name` (2D, 3D …)
- **movie** – `movie_id`, `title`, `certification` (U/UA/A), `duration_minutes`
- **theatre** – `theatre_id`, `theatre_name`, `city`, `address`
- **screen** – `screen_id`, `theatre_id`, `screen_name`, `experience` (e.g. "4K Dolby 7.1")
- **shows** – `show_id`, `screen_id`, `movie_id`, `language_id`, `format_id`, `show_date`, `start_time`

### Relationships
- A **theatre** has many **screens** (1 : N).
- A **screen** hosts many **shows** (1 : N).
- A **movie** appears in many **shows**; each show is one movie (1 : N).
- A **show** has exactly one **language** and one **format**.

## Normalization summary

- **1NF** – all columns atomic; each show timing is its own row in `shows`.
- **2NF** – every non-key column depends on the whole key (single-column surrogate PKs).
- **3NF** – movie-only facts live in `movie`, screen experience lives in `screen`; no transitive dependencies.
- **BCNF** – every determinant is a candidate key. In `shows` the candidate keys are `show_id` and `(screen_id, show_date, start_time)`.

## How to run

```bash
mysql -u <user> -p < schema.sql
```

This drops/creates the `bookmyshow` database, builds the tables, inserts the
sample data, and runs the P2 query.

## P2 – Shows on a given date at a given theatre

```sql
SELECT
    m.title                                AS movie,
    m.certification                        AS certification,
    l.language_name                        AS language,
    f.format_name                          AS format,
    sc.screen_name                         AS screen,
    sc.experience                          AS experience,
    DATE_FORMAT(s.start_time, '%h:%i %p')  AS show_time
FROM shows AS s
JOIN screen   AS sc ON s.screen_id   = sc.screen_id
JOIN theatre  AS t  ON sc.theatre_id = t.theatre_id
JOIN movie    AS m  ON s.movie_id    = m.movie_id
JOIN language AS l  ON s.language_id = l.language_id
JOIN format   AS f  ON s.format_id   = f.format_id
WHERE t.theatre_name = 'PVR: Nexus (Forum Mall)'
  AND s.show_date    = '2023-04-25'
ORDER BY m.title, s.start_time;
```
