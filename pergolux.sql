
-- 1. Flatten anything that's a json, pull in only relevant data
WITH orders_with_line_items AS (
  SELECT 
    ID as order_id
    , CUSTOMER_ID
    , CLOSED_AT
    , CREATED_AT
    , UPDATED_AT
    , ORDER_NUMBER
    , FINANCIAL_STATUS
    , FULFILLMENT_STATUS
    , JSON_EXTRACT_SCALAR(line_item, '$.id') as line_item_id
    , JSON_EXTRACT_SCALAR(line_item, '$.name') as product_name
    , CAST(JSON_EXTRACT_SCALAR(line_item, '$.quantity') AS INT64) as quantity
    , CAST(JSON_EXTRACT_SCALAR(line_item, '$.current_quantity') AS INT64) as current_quantity
    , CAST(JSON_EXTRACT_SCALAR(line_item, '$.price') AS FLOAT64) as line_price
    , CAST(JSON_EXTRACT_SCALAR(line_item, '$.total_discount') AS FLOAT64) as total_discount


  FROM pergcase.samples.shopify,
  UNNEST(JSON_EXTRACT_ARRAY(LINE_ITEMS)) as line_item
),

-- 2. Process discount json
-- NOT USED FOR THIS PARTICULAR ANALYSIS
-- orders_with_discount_codes AS (
--   SELECT 
--     ID as order_id
--     , JSON_EXTRACT_SCALAR(discount, '$.code') as discount_code
--     , JSON_EXTRACT_SCALAR(discount, '$.type') as discount_type
--     , CAST(JSON_EXTRACT_SCALAR(discount, '$.amount') AS FLOAT64) as discount_amount
    
--   FROM pergcase.samples.shopify,
--   UNNEST(JSON_EXTRACT_ARRAY(DISCOUNT_CODES)) as discount
-- ),


-- 3. Process refund json
orders_with_refunds AS (
  SELECT 
    ID as order_id
    , JSON_EXTRACT_SCALAR(refund, '$.id') as refund_id
    -- , JSON_EXTRACT_SCALAR(refund, '$.created_at') as refund_created_at
    -- , JSON_EXTRACT_SCALAR(refund, '$.processed_at') as refund_processed_at
    , JSON_EXTRACT_SCALAR(refund_line_item, '$.id') as refund_line_item_id
    , CAST(JSON_EXTRACT_SCALAR(refund_line_item, '$.quantity') AS INT64) as refunded_quantity
    , CAST(JSON_EXTRACT_SCALAR(refund_line_item, '$.subtotal') AS FLOAT64) as refund_subtotal
    , CAST(JSON_EXTRACT_SCALAR(refund_line_item, '$.total_tax') AS FLOAT64) as refund_total_tax
    , JSON_EXTRACT_SCALAR(refund_line_item, '$.line_item.id') as original_line_item_id
    
  FROM pergcase.samples.shopify,
  UNNEST(JSON_EXTRACT_ARRAY(REFUNDS)) as refund,
  UNNEST(JSON_EXTRACT_ARRAY(JSON_EXTRACT(refund, '$.refund_line_items'))) as refund_line_item
),

-- 4. combine all for shopify analysis
shopify_all AS (
  SELECT
  date_partition
  , order_id
  , customer_id
  , order_number
  , created_at
  , closed_at
  , financial_status
  , fulfillment_status
  , line_item_id
  , product_name
  , quantity
  , current_quantity
  , total_discount
  , refund_count
  , total_refunded_quantity
  , total_refund_amount
  , AVG(TIMESTAMP_DIFF(created_at, closed_at, DAY)) avg_time_to_close
  , sum(line_price - total_discount) total_rev
FROM
    (SELECT 
      DATE(DATE_TRUNC(closed_at, MONTH)) date_partition
      , o.order_id
      , o.customer_id
      , o.order_number
      , o.created_at
      , o.closed_at
      , o.financial_status
      , o.fulfillment_status
      , o.line_item_id
      , o.product_name
      , o.quantity
      , o.current_quantity
      , o.line_price
      , o.total_discount
      , COUNT(DISTINCT r.refund_id) as refund_count
      , SUM(r.refunded_quantity) as total_refunded_quantity
      , SUM(r.refund_subtotal) as total_refund_amount

    FROM orders_with_line_items o
    LEFT JOIN orders_with_refunds r ON o.order_id = r.order_id AND o.line_item_id = r.original_line_item_id

    GROUP BY 
      o.order_id, o.customer_id, o.order_number, o.created_at, o.closed_at, o.financial_status, o.fulfillment_status,
      o.line_item_id, o.product_name, o.quantity, o.current_quantity,
      o.line_price, o.total_discount

ORDER BY o.order_id, o.line_item_id)
WHERE date_partition IS NOT NULL

group by
  date_partition
  , order_id
  , customer_id
  , order_number
  , created_at
  , closed_at
  , financial_status
  , fulfillment_status
  , line_item_id
  , product_name
  , quantity
  , current_quantity
  , total_discount
  , refund_count
  , total_refunded_quantity
  , total_refund_amount


ORDER BY
  date_partition)


-- 5. join refined shopify table w/ zendesk table
SELECT
  zen.CUSTOMER_ID
  , zen.CHANNEL
  , zen.SATISFACTION_RATING
  , shop.order_id
  , shop.product_name
  , shop.total_rev
FROM
  `pergcase.samples.zendesk` zen
INNER JOIN
  shopify_all shop 
  ON zen.CUSTOMER_ID = shop.customer_id

group by SATISFACTION_RATING, zen.CUSTOMER_ID, zen.CHANNEL, shop.order_id, shop.product_name, shop.total_rev
;
