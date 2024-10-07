SELECT
  round(((brooklyn_accidents / all_borough_accidents) * 100),2) brooklyn_pct
FROM (
  SELECT
    COUNTIF(borough = 'BROOKLYN') brooklyn_accidents,
    COUNTIF(borough != 'BROOKLYN') all_borough_accidents
  FROM
    `bigquery-public-data.new_york_mv_collisions.nypd_mv_collisions`
  WHERE
    DATE(timestamp) BETWEEN '2014-01-01'
    AND '2017-12-31'
  AND borough IS NOT NULL);
-- 