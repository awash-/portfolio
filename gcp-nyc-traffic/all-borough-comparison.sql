-- Normally would delete this test part of the query. This top query checks that the counts across boroughs add up; you can never be too thorough!
-- SELECT
--   (queens_accidents + brooklyn_accidents + manhattan_accidents + statenisland_accidents + bronx_accidents + locationunknown_accidents) borough_accidents,
--   total_accidents
-- FROM (
SELECT
    count(distinct unique_key) num_accidents,
    borough
FROM
    `bigquery-public-data.new_york_mv_collisions.nypd_mv_collisions`
WHERE
    borough IS NOT NULL
    AND DATE (timestamp) BETWEEN '2014-01-01' AND '2017-12-31'
GROUP BY
    2
    -- )