SELECT
COUNT (DISTINCT unique_key) num_accidents,
borough
-- location
FROM
`bigquery-public-data.new_york_mv_collisions.nypd_mv_collisions`
WHERE
  borough IS NOT NULL
  -- borough = 'BROOKLYN'
  -- AND location IS NOT NULL
  AND DATE(timestamp) BETWEEN '2014-01-01'
    AND '2017-12-31'
  GROUP BY 2