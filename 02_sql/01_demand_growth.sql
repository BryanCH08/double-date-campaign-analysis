/*
Project      : Double-Date Campaign Performance Analysis
Analysis     : Campaign vs Normal Days Growth Performance
Data         : Fully synthetic e-commerce data
Output grain : One row per campaign month
Author       : Bryan Christian
*/

-- Replace YOUR_PROJECT_ID with your own Google Cloud project ID.

WITH classified_sessions AS (
  SELECT
    session_date AS activity_date,
    FORMAT_DATE('%Y-%m', session_date) AS month,
    CASE EXTRACT(MONTH FROM session_date)
      WHEN 9  THEN 9
      WHEN 10 THEN 10
      WHEN 11 THEN 11
      WHEN 12 THEN 12
    END AS campaign_end_day,

    session_id

  FROM
    `YOUR_PROJECT_ID.synthetic_ecommerce_portfolio.fact_sessions`

  WHERE
    session_date BETWEEN '2024-09-01' AND '2024-12-31'
),


classified_orders AS (
  SELECT
    order_date AS activity_date,
    FORMAT_DATE('%Y-%m', order_date) AS month,

    CASE EXTRACT(MONTH FROM order_date)
      WHEN 9  THEN 9
      WHEN 10 THEN 10
      WHEN 11 THEN 11
      WHEN 12 THEN 12
    END AS campaign_end_day,

    order_id,
    session_id,
    tpv

  FROM
    `YOUR_PROJECT_ID.synthetic_ecommerce_portfolio.fact_orders`

  WHERE
    order_date BETWEEN '2024-09-01' AND '2024-12-31'
),


daily_traffic AS (
  SELECT
    month,
    activity_date,

    CASE
      WHEN EXTRACT(DAY FROM activity_date) <= campaign_end_day
        THEN 'double_date'
      ELSE 'normal_date'
    END AS period_type,

    -- Satu session merepresentasikan satu website/app visit
    COUNT(DISTINCT session_id) AS daily_sessions

  FROM
    classified_sessions

  GROUP BY
    month,
    activity_date,
    period_type
),


daily_orders AS (
  SELECT
    month,
    activity_date,

    CASE
      WHEN EXTRACT(DAY FROM activity_date) <= campaign_end_day
        THEN 'double_date'
      ELSE 'normal_date'
    END AS period_type,

    COUNT(DISTINCT order_id) AS daily_orders,

    -- Session yang menghasilkan setidaknya satu purchase
    -- Digunakan sebagai numerator CVR
    COUNT(DISTINCT session_id) AS daily_purchasing_sessions,

    SUM(tpv) AS daily_tpv

  FROM
    classified_orders

  GROUP BY
    month,
    activity_date,
    period_type
),


daily_performance AS (
  SELECT
    t.month,
    t.activity_date,
    t.period_type,
    t.daily_sessions,
    COALESCE(o.daily_orders, 0) AS daily_orders,
    COALESCE(
      o.daily_purchasing_sessions,
      0
    ) AS daily_purchasing_sessions,

    COALESCE(o.daily_tpv, 0) AS daily_tpv

  FROM
    daily_traffic t

  LEFT JOIN
    daily_orders o
    ON t.activity_date = o.activity_date
    AND t.month = o.month
    AND t.period_type = o.period_type
),


period_performance AS (
  SELECT
    month,
    period_type,

    COUNT(DISTINCT activity_date) AS observed_days,

    -- Average daily volume
    AVG(daily_sessions) AS avg_daily_sessions,
    AVG(daily_orders) AS avg_daily_orders,
    AVG(daily_tpv) AS avg_daily_tpv,

    -- Weighted purchase conversion:
    -- total purchasing sessions / total sessions
    SAFE_DIVIDE(
      SUM(daily_purchasing_sessions),
      SUM(daily_sessions)
    ) AS cvr,

    -- Weighted AOV:
    -- total TPV / total orders
    SAFE_DIVIDE(
      SUM(daily_tpv),
      SUM(daily_orders)
    ) AS aov

  FROM
    daily_performance

  GROUP BY
    month,
    period_type
),


pivoted AS (
  SELECT
    month,

    -- Sessions
    MAX(IF(
      period_type = 'double_date',
      avg_daily_sessions,
      NULL
    )) AS dd_avg_daily_sessions,

    MAX(IF(
      period_type = 'normal_date',
      avg_daily_sessions,
      NULL
    )) AS normal_avg_daily_sessions,


    -- Purchase conversion
    MAX(IF(
      period_type = 'double_date',
      cvr,
      NULL
    )) AS dd_cvr,

    MAX(IF(
      period_type = 'normal_date',
      cvr,
      NULL
    )) AS normal_cvr,


    -- Orders
    MAX(IF(
      period_type = 'double_date',
      avg_daily_orders,
      NULL
    )) AS dd_avg_daily_orders,

    MAX(IF(
      period_type = 'normal_date',
      avg_daily_orders,
      NULL
    )) AS normal_avg_daily_orders,


    -- Average order value
    MAX(IF(
      period_type = 'double_date',
      aov,
      NULL
    )) AS dd_aov,

    MAX(IF(
      period_type = 'normal_date',
      aov,
      NULL
    )) AS normal_aov,


    -- Transaction value
    MAX(IF(
      period_type = 'double_date',
      avg_daily_tpv,
      NULL
    )) AS dd_avg_daily_tpv,

    MAX(IF(
      period_type = 'normal_date',
      avg_daily_tpv,
      NULL
    )) AS normal_avg_daily_tpv

  FROM
    period_performance

  GROUP BY
    month
)


SELECT
  month,

  -- Driver 1: Sessions / Visits
  dd_avg_daily_sessions,
  normal_avg_daily_sessions,

  SAFE_DIVIDE(
    dd_avg_daily_sessions - normal_avg_daily_sessions,
    normal_avg_daily_sessions
  ) AS sessions_uplift_pct,


  -- Driver 2: Purchase conversion
  dd_cvr,
  normal_cvr,

  100 * (
    dd_cvr - normal_cvr
  ) AS cvr_change_pp,


  -- Outcome 1: Orders
  dd_avg_daily_orders,
  normal_avg_daily_orders,

  SAFE_DIVIDE(
    dd_avg_daily_orders - normal_avg_daily_orders,
    normal_avg_daily_orders
  ) AS orders_uplift_pct,


  -- Driver 3: Average order value
  dd_aov,
  normal_aov,

  SAFE_DIVIDE(
    dd_aov - normal_aov,
    normal_aov
  ) AS aov_uplift_pct,


  -- Outcome 2: Transaction value
  dd_avg_daily_tpv,
  normal_avg_daily_tpv,

  SAFE_DIVIDE(
    dd_avg_daily_tpv - normal_avg_daily_tpv,
    normal_avg_daily_tpv
  ) AS tpv_uplift_pct

FROM
  pivoted

ORDER BY
  month;