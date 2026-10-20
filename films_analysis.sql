-- Films Box Office Analysis
-- Data: films_clean.csv (4,846 films, duplicates already removed).
-- Written for SQLite; also runs on PostgreSQL apart from the .import setup step.
-- Run: sqlite3 films.db < films_analysis.sql

-- ---------------------------------------------------------------
-- 1. Load data
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS films;
CREATE TABLE films (
    film_id       INTEGER PRIMARY KEY,
    title         TEXT,
    release_year  INTEGER,
    country       TEXT,
    duration_min  INTEGER,
    language      TEXT,
    rating        TEXT,
    gross_usd     REAL,
    budget        REAL      -- local currency for non-US films
);
.mode csv
.import --skip 1 films_clean.csv films
.mode column
.headers on

-- Empty CSV fields import as '' in SQLite; turn them into real NULLs.
UPDATE films SET language  = NULL WHERE language  = '';
UPDATE films SET rating    = NULL WHERE rating    = '';
UPDATE films SET country   = NULL WHERE country   = '';
UPDATE films SET gross_usd = NULL WHERE gross_usd = '';

-- ---------------------------------------------------------------
-- 2. Data quality checks
-- ---------------------------------------------------------------
SELECT
    COUNT(*)                                                  AS total_films,
    SUM(CASE WHEN gross_usd = 25529689.5 THEN 1 ELSE 0 END)   AS gross_filled_with_median,
    SUM(CASE WHEN gross_usd IS NULL THEN 1 ELSE 0 END)        AS gross_missing,
    SUM(CASE WHEN budget > 1000000000 THEN 1 ELSE 0 END)      AS budgets_over_1bn_local_currency,
    SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END)           AS rating_missing
FROM films;

-- ---------------------------------------------------------------
-- 3. Analysis set: US films from 1980 with a real gross value
-- ---------------------------------------------------------------
DROP VIEW IF EXISTS analysis_set;
CREATE VIEW analysis_set AS
SELECT
    f.*,
    gross_usd - budget                               AS profit,
    gross_usd / budget                               AS return_x,
    CASE WHEN gross_usd >= budget THEN 1 ELSE 0 END  AS is_hit,
    CASE
        WHEN budget <=   5000000 THEN '1. Under $5M'
        WHEN budget <=  20000000 THEN '2. $5M-20M'
        WHEN budget <=  50000000 THEN '3. $20M-50M'
        WHEN budget <= 100000000 THEN '4. $50M-100M'
        ELSE '5. $100M+'
    END                                              AS budget_tier,
    (release_year / 10) * 10                         AS decade
FROM films AS f
WHERE country = 'USA'
  AND release_year >= 1980
  AND gross_usd IS NOT NULL
  AND gross_usd <> 25529689.5;

-- Headline numbers
SELECT
    COUNT(*)                        AS films,
    ROUND(AVG(is_hit) * 100, 1)     AS hit_rate_pct,
    ROUND(SUM(profit) / 1e9, 1)     AS total_profit_bn
FROM analysis_set;

-- ---------------------------------------------------------------
-- 4. Hit rate and profit by budget tier
-- ---------------------------------------------------------------
SELECT
    budget_tier,
    COUNT(*)                                   AS films,
    ROUND(AVG(is_hit) * 100, 1)                AS hit_rate_pct,
    ROUND(SUM(gross_usd) / SUM(budget), 2)     AS pooled_return_x,
    ROUND(SUM(profit) / 1e6, 0)                AS total_profit_m
FROM analysis_set
GROUP BY budget_tier
ORDER BY budget_tier;

-- ---------------------------------------------------------------
-- 5. Hit rate by rating (main MPAA ratings only)
-- ---------------------------------------------------------------
SELECT
    rating,
    COUNT(*)                          AS films,
    ROUND(AVG(is_hit) * 100, 1)       AS hit_rate_pct,
    ROUND(AVG(gross_usd) / 1e6, 1)    AS avg_gross_m
FROM analysis_set
WHERE rating IN ('G', 'PG', 'PG-13', 'R')
GROUP BY rating
ORDER BY hit_rate_pct DESC;

-- ---------------------------------------------------------------
-- 6. Trend by decade
-- ---------------------------------------------------------------
SELECT
    decade,
    COUNT(*)                        AS films,
    ROUND(AVG(is_hit) * 100, 1)     AS hit_rate_pct
FROM analysis_set
GROUP BY decade
ORDER BY decade;

-- ---------------------------------------------------------------
-- 7. Concentration: share of total gross taken by the top 10% of films
-- ---------------------------------------------------------------
WITH ranked AS (
    SELECT gross_usd, NTILE(10) OVER (ORDER BY gross_usd DESC) AS decile
    FROM analysis_set
)
SELECT
    ROUND(100.0 * SUM(CASE WHEN decile = 1 THEN gross_usd END) / SUM(gross_usd), 1)
        AS top_10pct_share_of_gross
FROM ranked;

-- ---------------------------------------------------------------
-- 8. Biggest losses and best returns
-- ---------------------------------------------------------------
SELECT title, release_year, budget, gross_usd, profit
FROM analysis_set
ORDER BY profit ASC
LIMIT 5;

SELECT title, release_year, budget, gross_usd, ROUND(return_x, 0) AS return_x
FROM analysis_set
ORDER BY return_x DESC
LIMIT 5;
