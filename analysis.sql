-- Pitchfork reviews: SQL analysis (SQLite)
-- Data: https://www.kaggle.com/datasets/nolanbconaway/pitchfork-data

-- 0. Data checks: does one review map to multiple genres / labels?
SELECT COUNT(*) AS rows, COUNT(DISTINCT reviewid) AS reviews FROM reviews;
SELECT COUNT(*) AS rows, COUNT(DISTINCT reviewid) AS reviews FROM genres;
SELECT COUNT(*) AS rows, COUNT(DISTINCT reviewid) AS reviews FROM labels;


-- 1. Average score and Best New Music rate by genre
SELECT g.genre,
       COUNT(*) AS n_reviews,
       ROUND(AVG(r.score), 2) AS avg_score,
       ROUND(100.0 * SUM(r.best_new_music) / COUNT(*), 1) AS bnm_pct
FROM reviews r
JOIN genres g ON r.reviewid = g.reviewid
WHERE g.genre IS NOT NULL
GROUP BY g.genre
ORDER BY avg_score DESC;

-- 2. Reviews and average score per year
SELECT pub_year,
       COUNT(*) AS n_reviews,
       ROUND(AVG(score), 2) AS avg_score
FROM reviews
WHERE pub_year BETWEEN 2000 AND 2016
GROUP BY pub_year
ORDER BY pub_year;

-- 3. Top 10 labels by average score (at least 20 reviews)
SELECT l.label,
       COUNT(DISTINCT r.reviewid) AS n_reviews,
       ROUND(AVG(r.score), 2) AS avg_score
FROM reviews r
JOIN labels l ON r.reviewid = l.reviewid
WHERE l.label IS NOT NULL AND l.label <> ''
GROUP BY l.label
HAVING COUNT(DISTINCT r.reviewid) >= 20
ORDER BY avg_score DESC
LIMIT 10;

-- 4. Author scoring tendency vs site average (CTE + window function)
WITH author_stats AS (
  SELECT author, COUNT(*) AS n, AVG(score) AS avg_score
  FROM reviews
  GROUP BY author
  HAVING COUNT(*) >= 50
)
SELECT author, n,
       ROUND(avg_score, 2) AS avg_score,
       ROUND(avg_score - (SELECT AVG(score) FROM reviews), 2) AS diff_vs_site,
       RANK() OVER (ORDER BY avg_score DESC) AS rnk
FROM author_stats
ORDER BY rnk;



-- 5. Reissue/anthology reviews vs other reviews
SELECT CASE WHEN LOWER(title) LIKE '%edition%'
              OR LOWER(title) LIKE '%anniversary%'
              OR LOWER(title) LIKE '%reissue%'
              OR LOWER(title) LIKE '%anthology%'
            THEN 'reissue/anthology' ELSE 'other' END AS type,
       COUNT(*) AS n_reviews,
       ROUND(AVG(score), 2) AS avg_score
FROM reviews
GROUP BY type;