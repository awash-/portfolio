-- Comprehensive NYC Traffic Collision Analysis (2014-2017)
-- PLEASE NOTE: This query was collated by Claude.ai, using pre-existing queries in this repo. Query was tested and runs as expected. Some subqueries were edited by Claude.ai for conciseness and in a real-life situation, I would spend more time reviewing the code to ensure that it's efficient (as AI can often add inefficiencies).
-- Prompt: Can you combine these queries into one query?

WITH 
-- Base data with consistent date filtering
base_data AS (
  SELECT 
    unique_key,
    timestamp,
    borough,
    contributing_factor_vehicle_1,
    number_of_persons_injured,
    number_of_persons_killed,
    number_of_cyclist_injured,
    number_of_cyclist_killed,
    number_of_motorist_injured,
    number_of_motorist_killed,
    number_of_pedestrians_injured,
    number_of_pedestrians_killed,
    EXTRACT(YEAR FROM timestamp) as year,
    EXTRACT(DAYOFWEEK FROM timestamp) as day_of_week,
    EXTRACT(HOUR FROM timestamp) as hour,
    CASE
      WHEN number_of_persons_injured > 0 AND number_of_persons_killed = 0 THEN 'Injury Only'
      WHEN number_of_persons_killed > 0 AND number_of_persons_injured = 0 THEN 'Fatality Only'
      WHEN number_of_persons_injured > 0 AND number_of_persons_killed > 0 THEN 'Injury and Fatality'
      ELSE 'No Injury or Fatality'
    END as accident_type,
    CASE
      WHEN EXTRACT(HOUR FROM timestamp) BETWEEN 6 AND 10 THEN 'Morning'
      WHEN EXTRACT(HOUR FROM timestamp) BETWEEN 11 AND 13 THEN 'Midday'
      WHEN EXTRACT(HOUR FROM timestamp) BETWEEN 14 AND 17 THEN 'Afternoon'
      WHEN EXTRACT(HOUR FROM timestamp) BETWEEN 18 AND 20 THEN 'Evening'
      WHEN EXTRACT(HOUR FROM timestamp) BETWEEN 21 AND 23 THEN 'Night'
      WHEN EXTRACT(HOUR FROM timestamp) BETWEEN 0 AND 2 THEN 'Late Night'
      ELSE 'Early Morning'
    END as time_period
  FROM `bigquery-public-data.new_york_mv_collisions.nypd_mv_collisions`
  WHERE DATE(timestamp) BETWEEN '2014-01-01' AND '2017-12-31'
    AND borough IS NOT NULL
),

-- Borough-level summary
borough_summary AS (
  SELECT
    borough,
    COUNT(DISTINCT unique_key) as total_accidents,
    ROUND(COUNT(DISTINCT unique_key) * 100.0 / SUM(COUNT(DISTINCT unique_key)) OVER(), 2) as pct_of_all_accidents
  FROM base_data
  GROUP BY borough
),

-- Brooklyn-specific yearly breakdown
brooklyn_yearly AS (
  SELECT
    year,
    COUNT(DISTINCT unique_key) as num_accidents,
    SUM(CASE WHEN accident_type IN ('Injury Only', 'Fatality Only', 'Injury and Fatality') THEN 1 ELSE 0 END) as negative_outcomes,
    SUM(CASE WHEN accident_type IN ('Injury Only', 'Injury and Fatality') THEN 1 ELSE 0 END) as injury_accidents,
    SUM(CASE WHEN accident_type IN ('Fatality Only', 'Injury and Fatality') THEN 1 ELSE 0 END) as fatality_accidents,
    ROUND(SUM(CASE WHEN accident_type IN ('Injury Only', 'Fatality Only', 'Injury and Fatality') THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT unique_key), 2) as pct_negative_outcomes,
    ROUND(SUM(CASE WHEN accident_type IN ('Injury Only', 'Injury and Fatality') THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT unique_key), 2) as pct_injuries,
    ROUND(SUM(CASE WHEN accident_type IN ('Fatality Only', 'Injury and Fatality') THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT unique_key), 2) as pct_fatalities
  FROM base_data
  WHERE borough = 'BROOKLYN'
  GROUP BY year
),

-- Contributing factors analysis for Brooklyn
brooklyn_contributing_factors AS (
  SELECT
    contributing_factor_vehicle_1,
    COUNT(DISTINCT unique_key) as accident_count,
    ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT unique_key) DESC) as rank
  FROM base_data
  WHERE borough = 'BROOKLYN'
    AND COALESCE(contributing_factor_vehicle_1, 'Unspecified') != 'Unspecified'
  GROUP BY contributing_factor_vehicle_1
),

-- Day of week analysis for Brooklyn
brooklyn_day_analysis AS (
  SELECT
    day_of_week,
    CASE day_of_week
      WHEN 1 THEN 'Sunday'
      WHEN 2 THEN 'Monday'
      WHEN 3 THEN 'Tuesday'
      WHEN 4 THEN 'Wednesday'
      WHEN 5 THEN 'Thursday'
      WHEN 6 THEN 'Friday'
      WHEN 7 THEN 'Saturday'
    END as day_name,
    COUNT(DISTINCT unique_key) as num_accidents,
    RANK() OVER (ORDER BY COUNT(DISTINCT unique_key) DESC) as day_rank
  FROM base_data
  WHERE borough = 'BROOKLYN'
  GROUP BY day_of_week
),

-- Time of day analysis for Brooklyn
brooklyn_time_analysis AS (
  SELECT
    time_period,
    COUNT(DISTINCT unique_key) as num_accidents,
    RANK() OVER (ORDER BY COUNT(DISTINCT unique_key) DESC) as time_rank
  FROM base_data
  WHERE borough = 'BROOKLYN'
  GROUP BY time_period
),

-- Hourly analysis for Brooklyn (top 10 hours)
brooklyn_hourly AS (
  SELECT
    hour,
    COUNT(DISTINCT unique_key) as num_accidents,
    RANK() OVER (ORDER BY COUNT(DISTINCT unique_key) DESC) as hour_rank
  FROM base_data
  WHERE borough = 'BROOKLYN'
  GROUP BY hour
)

-- Main results combining all analyses
SELECT 
  'BOROUGH_SUMMARY' as analysis_type,
  borough as category,
  NULL as subcategory,
  total_accidents as accident_count,
  pct_of_all_accidents as percentage,
  NULL as rank_position
FROM borough_summary

UNION ALL

SELECT 
  'BROOKLYN_YEARLY' as analysis_type,
  CAST(year AS STRING) as category,
  'Total Accidents' as subcategory,
  num_accidents as accident_count,
  pct_negative_outcomes as percentage,
  NULL as rank_position
FROM brooklyn_yearly

UNION ALL

SELECT 
  'BROOKLYN_YEARLY' as analysis_type,
  CAST(year AS STRING) as category,
  'Injury Rate' as subcategory,
  injury_accidents as accident_count,
  pct_injuries as percentage,
  NULL as rank_position
FROM brooklyn_yearly

UNION ALL

SELECT 
  'BROOKLYN_CONTRIBUTING_FACTORS' as analysis_type,
  contributing_factor_vehicle_1 as category,
  NULL as subcategory,
  accident_count,
  NULL as percentage,
  rank as rank_position
FROM brooklyn_contributing_factors
WHERE rank <= 10

UNION ALL

SELECT 
  'BROOKLYN_DAY_OF_WEEK' as analysis_type,
  day_name as category,
  NULL as subcategory,
  num_accidents as accident_count,
  NULL as percentage,
  day_rank as rank_position
FROM brooklyn_day_analysis

UNION ALL

SELECT 
  'BROOKLYN_TIME_PERIOD' as analysis_type,
  time_period as category,
  NULL as subcategory,
  num_accidents as accident_count,
  NULL as percentage,
  time_rank as rank_position
FROM brooklyn_time_analysis

UNION ALL

SELECT 
  'BROOKLYN_TOP_HOURS' as analysis_type,
  CONCAT('Hour ', CAST(hour AS STRING)) as category,
  NULL as subcategory,
  num_accidents as accident_count,
  NULL as percentage,
  hour_rank as rank_position
FROM brooklyn_hourly
WHERE hour_rank <= 10

ORDER BY analysis_type, rank_position, accident_count DESC;
