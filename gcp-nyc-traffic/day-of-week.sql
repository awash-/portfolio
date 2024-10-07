WITH day_of_week AS (
SELECT
  COUNT(DISTINCT unique_key) num_accidents,
  EXTRACT(DAYOFWEEK FROM timestamp) day
FROM `bigquery-public-data.new_york_mv_collisions.nypd_mv_collisions`
WHERE borough = 'BROOKLYN'
AND  DATE(timestamp) BETWEEN '2014-01-01'
    AND '2017-12-31'
GROUP BY 2)

SELECT
num_accidents,
day,
RANK() OVER (ORDER BY num_accidents DESC) accident_rank
FROM day_of_week
ORDER BY accident_rank