WITH
  time_of_day AS (
  SELECT
    num_accidents,
    CASE
      WHEN hour BETWEEN 6 AND 10 THEN 'Morning'
      WHEN hour BETWEEN 11
    AND 13 THEN 'Midday'
      WHEN hour BETWEEN 14 AND 17 THEN 'Afternoon'
      WHEN hour BETWEEN 18
    AND 20 THEN 'Evening'
      WHEN hour BETWEEN 21 AND 23 THEN 'Night'
      WHEN hour BETWEEN 24
    AND 2 THEN 'Late Night'
      ELSE 'Early Morning'
  END
    day_time,
    hour
  FROM (
    SELECT
      COUNT(DISTINCT unique_key) num_accidents,
      EXTRACT(HOUR
      FROM
        timestamp) hour
    FROM
      `bigquery-public-data.new_york_mv_collisions.nypd_mv_collisions`
    WHERE
      borough = 'BROOKLYN'
      AND DATE(timestamp) BETWEEN '2014-01-01'
      AND '2017-12-31'
      group by 2)
  GROUP BY
    2,1,3)
    
SELECT
  num_accidents,
  -- day_time,
  hour,
  RANK() OVER (ORDER BY num_accidents DESC) accident_rank
FROM
  time_of_day
ORDER BY
  accident_rank