-- TODO: Add a query that accounts for ALL contributing factors

WITH num_accidents AS (
  SELECT
    contributing_factor_vehicle_1 confac1,
    COUNT(DISTINCT unique_key) accident_count
  FROM
  `bigquery-public-data.new_york_mv_collisions.nypd_mv_collisions`
  WHERE
    borough = 'BROOKLYN'
  AND DATE(timestamp) BETWEEN '2014-01-01'
      AND '2017-12-31'
  AND COALESCE(contributing_factor_vehicle_1) != 'Unspecified'
  GROUP BY 1
),

ranked_accidents AS (
  SELECT
    confac1,
    accident_count,
    ROW_NUMBER() OVER (ORDER BY accident_count DESC) AS rank
  FROM
    num_accidents
)

SELECT
  confac1 mode_value,
  accident_count mode_count
FROM
  ranked_accidents
WHERE
  rank = 1