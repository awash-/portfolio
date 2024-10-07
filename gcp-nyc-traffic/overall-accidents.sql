  -- Guiding question: What are recommendations FOR reducing accidents IN Brooklyn? -- Slide 3a: Total accidents + accident type proportions
SELECT
  year_partition,
  -- month_partition,
  num_accidents,
  num_negative_outcome,
  num_injuries,
  num_fatalities,
  ROUND(((num_negative_outcome / num_accidents) * 100),2) pct_negative_outcomes,
  pct_injuries,
  pct_fatalities
FROM (
  SELECT
    year_partition,
    -- month_partition,
    num_accidents,
    (num_injuries + num_fatalities + num_both) num_negative_outcome,
    num_injuries,
    ROUND(((num_injuries / num_accidents) * 100),2) pct_injuries,
    num_fatalities,
    ROUND(((num_fatalities / num_accidents) * 100),2) pct_fatalities,
    num_both,
    ROUND(((num_both / num_accidents) * 100),2) pct_both,
    num_neither,
    ROUND(((num_neither / num_accidents) * 100),2) pct_neither
  FROM (
    SELECT
      year_partition,
      -- month_partition,
      COUNT(DISTINCT unique_key) num_accidents,
      SUM(injuries) num_injuries,
      SUM(fatalities) num_fatalities,
      SUM(both) num_both,
      SUM(neither) num_neither
    FROM (
      SELECT
        DATE(DATE_TRUNC(timestamp,YEAR)) year_partition,
        -- DATE(DATE_TRUNC(timestamp,MONTH)) month_partition,
        unique_key,
        accident_type,
        COUNTIF(accident_type = 'Accident resulting in injury only') injuries,
        COUNTIF(accident_type = 'Accident resulting in fatality only') fatalities,
        COUNTIF(accident_type = 'Accident resulting in injury and fatality') both,
        COUNTIF(accident_type = 'Accident resulting in no injury or fatality') neither
      FROM (
        SELECT
          unique_key,
          timestamp,
          CASE
            WHEN number_of_persons_injured > 0 AND number_of_persons_killed = 0 THEN 'Accident resulting in injury only'
            WHEN number_of_persons_killed > 0
          AND number_of_persons_injured = 0 THEN 'Accident resulting in fatality only'
            WHEN number_of_persons_injured > 0 AND number_of_persons_killed > 0 THEN 'Accident resulting in injury and fatality'
            ELSE 'Accident resulting in no injury or fatality'
        END
          accident_type
        FROM
          `bigquery-public-data.new_york_mv_collisions.nypd_mv_collisions`
        WHERE
          borough = 'BROOKLYN'
          AND DATE(timestamp) BETWEEN '2014-01-01'
          AND '2017-12-31')
      GROUP BY
        1,
        2,
        3)
    GROUP BY
      1))