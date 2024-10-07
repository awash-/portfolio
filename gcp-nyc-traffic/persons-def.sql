  -- number_of_persons IS TOTAL OF other number_ COLUMNS (dbl-check TO ensure that persons isn't catchall OF roadway users that fall outside OF the other definitions)
SELECT
  DATE(DATE_TRUNC(timestamp, MONTH)) date_partition,
  number_of_cyclist_injured,
  number_of_cyclist_killed,
  number_of_motorist_injured,
  number_of_motorist_killed,
  number_of_pedestrians_injured,
  number_of_pedestrians_killed,
  number_of_persons_injured,
  number_of_persons_killed
FROM
  `bigquery-public-data.new_york_mv_collisions.nypd_mv_collisions`
ORDER BY
  date_partition
LIMIT
  100