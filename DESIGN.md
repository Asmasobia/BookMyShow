# BookMyShow – Theatre Show Listing (Database Design)

This document describes the data model behind the screen shown in the assignment:
for a chosen **theatre** and one of the next 7 **dates**, list every **show**
running in that theatre along with its **show timing**, language, format and
audio/projection experience.

The reference screenshot (PVR: Nexus, 25 Apr) is used as the sample data set.

---

## 1. Entities and Attributes

| Entity      | Attributes                                                                 | Notes |
|-------------|-----------------------------------------------------------------------------|-------|
| **language**| `language_id` (PK), `language_name`                                         | Telugu, Hindi, English … |
| **format**  | `format_id` (PK), `format_name`                                            | 2D, 3D, IMAX … |
| **movie**   | `movie_id` (PK), `title`, `certification`, `duration_minutes`              | Certification = U / UA / A |
| **theatre** | `theatre_id` (PK), `theatre_name`, `city`, `address`                       | The cinema property |
| **screen**  | `screen_id` (PK), `theatre_id` (FK), `screen_name`, `experience`           | A physical auditorium; `experience` = "4K Dolby 7.1", "4K ATMOS" … |
| **shows**   | `show_id` (PK), `screen_id` (FK), `movie_id` (FK), `language_id` (FK), `format_id` (FK), `show_date`, `start_time` | One scheduled screening |

### Relationships
- A **theatre** has many **screens** (1 : N).
- A **screen** hosts many **shows** (1 : N).
- A **movie** can appear in many **shows**; each show is exactly one movie (1 : N).
- A **show** has exactly one **language** and one **format**.

---

## 2. Why this design satisfies the normal forms

**1NF – atomic values, no repeating groups.**
Every column holds a single value. The screenshot shows a movie with several
timings ("01:00 PM, 04:10 PM, 06:20 PM …"); instead of stuffing them into one
column, each timing is its own row in `shows`.

**2NF – no partial dependency on part of a composite key.**
Every table uses a single-column surrogate primary key, and all non-key columns
depend on that whole key. The natural composite key of a show
`(screen_id, show_date, start_time)` is kept as a `UNIQUE` constraint, and the
remaining attributes (movie, language, format) depend on the full show, not a part of it.

**3NF – no transitive dependency.**
Attributes that belong to a movie (`certification`, `duration_minutes`) live in
`movie`, not in `shows`. The `experience` ("4K Dolby 7.1") is a property of the
physical screen, so it lives in `screen`, not repeated on every show. Language
and format names are factored into their own tables so a show only stores their ids.

**BCNF – every determinant is a candidate key.**
In `shows` the only determinants are `show_id` and the composite
`(screen_id, show_date, start_time)`; both are candidate keys. In the lookup
tables (`language`, `format`) the name is unique, so `name → id` and `id → name`
are both candidate keys. No non-trivial functional dependency has a determinant
that is not a key, so the schema is in BCNF.

---

## 3. Sample rows (from the screenshot)

**theatre**

| theatre_id | theatre_name              | city      |
|------------|---------------------------|-----------|
| 1          | PVR: Nexus (Forum Mall)   | Bengaluru |

**screen**

| screen_id | theatre_id | screen_name | experience    |
|-----------|------------|-------------|---------------|
| 1         | 1          | Screen 1    | 4K Dolby 7.1  |
| 2         | 1          | Screen 2    | 4K ATMOS      |
| 3         | 1          | Screen 3    | Dolby 7.1     |
| 4         | 1          | Screen 4    | Playhouse 4K  |

**movie**

| movie_id | title                          | certification | duration_minutes |
|----------|--------------------------------|---------------|------------------|
| 1        | Dasara                         | UA            | 156              |
| 2        | Kisi Ka Bhai Kisi Ki Jaan      | UA            | 145              |
| 3        | Tu Jhoothi Main Makkaar        | UA            | 151              |
| 4        | Avatar: The Way of Water       | UA            | 192              |

**shows** (all on 2023-04-25)

| show_id | screen_id | movie_id | language | format | start_time |
|---------|-----------|----------|----------|--------|------------|
| 1       | 1         | 1        | Telugu   | 2D     | 12:15 PM   |
| 2       | 2         | 2        | Hindi    | 2D     | 01:00 PM   |
| 3       | 2         | 2        | Hindi    | 2D     | 04:10 PM   |
| 4       | 1         | 2        | Hindi    | 2D     | 06:20 PM   |
| 5       | 2         | 2        | Hindi    | 2D     | 07:20 PM   |
| 6       | 2         | 2        | Hindi    | 2D     | 10:30 PM   |
| 7       | 3         | 3        | Hindi    | 2D     | 01:15 PM   |
| 8       | 4         | 4        | English  | 3D     | 01:20 PM   |

---

## 4. Deliverables

- **`schema.sql`** – P1 (CREATE TABLE statements + sample inserts) and P2 (the
  listing query), directly executable on MySQL 8.x.

### P2 query

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
