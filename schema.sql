-- =============================================================
-- BookMyShow - Theatre Show Listing
-- P1: Schema (1NF, 2NF, 3NF, BCNF compliant) + sample data
-- P2: Query to list shows on a given date at a given theatre
-- =============================================================

DROP DATABASE IF EXISTS bookmyshow;
CREATE DATABASE bookmyshow;
USE bookmyshow;

-- -------------------------------------------------------------
-- Lookup / master tables
-- -------------------------------------------------------------

-- A spoken language a movie can be screened in (Telugu, Hindi, English ...)
CREATE TABLE language (
    language_id   INT          NOT NULL AUTO_INCREMENT,
    language_name VARCHAR(50)  NOT NULL,
    PRIMARY KEY (language_id),
    UNIQUE KEY uq_language_name (language_name)
);

-- A projection format (2D, 3D, IMAX ...)
CREATE TABLE format (
    format_id   INT         NOT NULL AUTO_INCREMENT,
    format_name VARCHAR(20) NOT NULL,
    PRIMARY KEY (format_id),
    UNIQUE KEY uq_format_name (format_name)
);

-- A movie / film. Certification (UA, U, A) and runtime depend only on the movie.
CREATE TABLE movie (
    movie_id         INT          NOT NULL AUTO_INCREMENT,
    title            VARCHAR(150) NOT NULL,
    certification    VARCHAR(10)  NOT NULL,   -- U / UA / A
    duration_minutes INT          NOT NULL,
    PRIMARY KEY (movie_id)
);

-- A theatre / cinema property.
CREATE TABLE theatre (
    theatre_id   INT          NOT NULL AUTO_INCREMENT,
    theatre_name VARCHAR(150) NOT NULL,
    city         VARCHAR(80)  NOT NULL,
    address      VARCHAR(255) NOT NULL,
    PRIMARY KEY (theatre_id)
);

-- A physical screen/auditorium inside a theatre.
-- The audio/projection "experience" (4K Dolby 7.1, ATMOS, Playhouse 4K ...)
-- is a fixed property of the screen, so it lives here.
CREATE TABLE screen (
    screen_id   INT          NOT NULL AUTO_INCREMENT,
    theatre_id  INT          NOT NULL,
    screen_name VARCHAR(50)  NOT NULL,        -- e.g. "Screen 1", "Audi 2"
    experience  VARCHAR(60)  NOT NULL,        -- e.g. "4K Dolby 7.1", "ATMOS"
    PRIMARY KEY (screen_id),
    UNIQUE KEY uq_screen_per_theatre (theatre_id, screen_name),
    CONSTRAINT fk_screen_theatre
        FOREIGN KEY (theatre_id) REFERENCES theatre (theatre_id)
);

-- -------------------------------------------------------------
-- Transactional table
-- -------------------------------------------------------------

-- A scheduled screening of a movie, in a given language + format,
-- on a specific screen, at a specific date and time.
-- Candidate keys: (show_id) and (screen_id, show_date, start_time)
-- -> a screen cannot host two shows at the same moment.
CREATE TABLE shows (
    show_id     INT      NOT NULL AUTO_INCREMENT,
    screen_id   INT      NOT NULL,
    movie_id    INT      NOT NULL,
    language_id INT      NOT NULL,
    format_id   INT      NOT NULL,
    show_date   DATE     NOT NULL,
    start_time  TIME     NOT NULL,
    PRIMARY KEY (show_id),
    UNIQUE KEY uq_screen_slot (screen_id, show_date, start_time),
    CONSTRAINT fk_show_screen   FOREIGN KEY (screen_id)   REFERENCES screen (screen_id),
    CONSTRAINT fk_show_movie    FOREIGN KEY (movie_id)    REFERENCES movie (movie_id),
    CONSTRAINT fk_show_language FOREIGN KEY (language_id) REFERENCES language (language_id),
    CONSTRAINT fk_show_format   FOREIGN KEY (format_id)   REFERENCES format (format_id)
);

-- =============================================================
-- Sample data (mirrors the screenshot: PVR Nexus, 25-Apr shows)
-- =============================================================

INSERT INTO language (language_id, language_name) VALUES
    (1, 'Telugu'),
    (2, 'Hindi'),
    (3, 'English');

INSERT INTO format (format_id, format_name) VALUES
    (1, '2D'),
    (2, '3D');

INSERT INTO movie (movie_id, title, certification, duration_minutes) VALUES
    (1, 'Dasara',                       'UA', 156),
    (2, 'Kisi Ka Bhai Kisi Ki Jaan',    'UA', 145),
    (3, 'Tu Jhoothi Main Makkaar',      'UA', 151),
    (4, 'Avatar: The Way of Water',     'UA', 192);

INSERT INTO theatre (theatre_id, theatre_name, city, address) VALUES
    (1, 'PVR: Nexus (Forum Mall)', 'Bengaluru', 'Forum Mall, Koramangala, Bengaluru');

INSERT INTO screen (screen_id, theatre_id, screen_name, experience) VALUES
    (1, 1, 'Screen 1', '4K Dolby 7.1'),
    (2, 1, 'Screen 2', '4K ATMOS'),
    (3, 1, 'Screen 3', 'Dolby 7.1'),
    (4, 1, 'Screen 4', 'Playhouse 4K');

-- All shows below are on 2023-04-25 at PVR: Nexus
INSERT INTO shows (screen_id, movie_id, language_id, format_id, show_date, start_time) VALUES
    -- Dasara (Telugu, 2D) - 12:15 PM, 4K Dolby 7.1
    (1, 1, 1, 1, '2023-04-25', '12:15:00'),

    -- Kisi Ka Bhai Kisi Ki Jaan (Hindi, 2D) - multiple shows
    (2, 2, 2, 1, '2023-04-25', '13:00:00'),  -- 01:00 PM  4K ATMOS
    (2, 2, 2, 1, '2023-04-25', '16:10:00'),  -- 04:10 PM  4K ATMOS
    (1, 2, 2, 1, '2023-04-25', '18:20:00'),  -- 06:20 PM  4K Dolby 7.1
    (2, 2, 2, 1, '2023-04-25', '19:20:00'),  -- 07:20 PM  4K ATMOS
    (2, 2, 2, 1, '2023-04-25', '22:30:00'),  -- 10:30 PM  4K ATMOS

    -- Tu Jhoothi Main Makkaar (Hindi, 2D) - 01:15 PM, Dolby 7.1
    (3, 3, 2, 1, '2023-04-25', '13:15:00'),

    -- Avatar: The Way of Water (English, 3D) - 01:20 PM, Playhouse 4K
    (4, 4, 3, 2, '2023-04-25', '13:20:00');

-- =============================================================
-- P2: List all shows on a given date at a given theatre
--     along with their show timings.
-- =============================================================

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
