/*
Project      : Double-Date Campaign Performance Analysis
Analysis     : Campaign vs Normal Days Growth Performance
Data         : Fully synthetic e-commerce data
Output grain : One row per campaign month
Author       : Bryan Christian
*/

-- Replace YOUR_PROJECT_ID with your own Google Cloud project ID.

WITH classified_orders AS (
  SELECT
    order_date,
    FORMAT_DATE('%Y-%m', order_date) AS month,
    CASE EXTRACT(MONTH FROM order_date)
      WHEN 9  THEN 9
      WHEN 10 THEN 10
      WHEN 11 THEN 11
      WHEN 12 THEN 12
    END AS campaign_end_day,

    tpv,
    gpbd,
    gpad_tp

  FROM
    `YOUR_PROJECT_ID.synthetic_ecommerce_portfolio.fact_orders`

  WHERE
    order_date BETWEEN '2024-09-01' AND '2024-12-31'
),


daily_performance AS (
  SELECT
    month,
    order_date,

    CASE
      WHEN EXTRACT(DAY FROM order_date) <= campaign_end_day
        THEN 'double_date'
      ELSE 'normal_date'
    END AS period_type,

    -- Daily financial performance
    SUM(tpv) AS daily_tpv,
    SUM(gpbd) AS daily_gpbd,
    SUM(gpad_tp) AS daily_gpad_tp

  FROM
    classified_orders

  GROUP BY
    month,
    order_date,
    period_type
),


period_performance AS (
  SELECT
    month,
    period_type,

    COUNT(DISTINCT order_date) AS observed_days,

    -- Average daily contribution
    AVG(daily_gpbd) AS avg_daily_gpbd,
    AVG(daily_gpad_tp) AS avg_daily_gpad_tp,

    -- Weighted contribution margins
    SAFE_DIVIDE(
      SUM(daily_gpbd),
      SUM(daily_tpv)
    ) AS gpbd_margin,

    SAFE_DIVIDE(
      SUM(daily_gpad_tp),
      SUM(daily_tpv)
    ) AS gpad_margin

  FROM
    daily_performance

  GROUP BY
    month,
    period_type
),


pivoted AS (
  SELECT
    month,
    MAX(IF(
      period_type = 'double_date',
      observed_days,
      NULL
    )) AS dd_days,
    -- Average daily GPBD
    MAX(IF(
      period_type = 'double_date',
      avg_daily_gpbd,
      NULL
    )) AS dd_avg_daily_gpbd,

    MAX(IF(
      period_type = 'normal_date',
      avg_daily_gpbd,
      NULL
    )) AS normal_avg_daily_gpbd,
    -- GPBD margin
    MAX(IF(
      period_type = 'double_date',
      gpbd_margin,
      NULL
    )) AS dd_gpbd_margin,

    MAX(IF(
      period_type = 'normal_date',
      gpbd_margin,
      NULL
    )) AS normal_gpbd_margin,

    -- Average daily GPAD-TP
    MAX(IF(
      period_type = 'double_date',
      avg_daily_gpad_tp,
      NULL
    )) AS dd_avg_daily_gpad_tp,

    MAX(IF(
      period_type = 'normal_date',
      avg_daily_gpad_tp,
      NULL
    )) AS normal_avg_daily_gpad_tp,


    -- GPAD-TP margin
    MAX(IF(
      period_type = 'double_date',
      gpad_margin,
      NULL
    )) AS dd_gpad_margin,

    MAX(IF(
      period_type = 'normal_date',
      gpad_margin,
      NULL
    )) AS normal_gpad_margin

  FROM
    period_performance

  GROUP BY
    month
),


economics_comparison AS (
  SELECT
    month,
    dd_days,

    normal_avg_daily_gpbd,
    dd_avg_daily_gpbd,

    -- Positive value means GPBD was higher during Double-Date
    dd_avg_daily_gpbd
      - normal_avg_daily_gpbd
      AS avg_daily_gpbd_gain,

    normal_gpbd_margin,
    dd_gpbd_margin,

    100 * (
      dd_gpbd_margin
      - normal_gpbd_margin
    ) AS gpbd_margin_change_pp,


    normal_avg_daily_gpad_tp,
    dd_avg_daily_gpad_tp,

    -- Positive value means Double-Date GPAD-TP
    -- was below the Normal Days baseline
    normal_avg_daily_gpad_tp
      - dd_avg_daily_gpad_tp
      AS avg_daily_gpad_shortfall,

    normal_gpad_margin,
    dd_gpad_margin,

    100 * (
      dd_gpad_margin
      - normal_gpad_margin
    ) AS gpad_margin_change_pp

  FROM
    pivoted
)


SELECT
  month,

  -- Before platform-funded support costs
  normal_avg_daily_gpbd,
  dd_avg_daily_gpbd,
  avg_daily_gpbd_gain,

  normal_gpbd_margin,
  dd_gpbd_margin,
  gpbd_margin_change_pp,


  -- After platform-funded support costs
  normal_avg_daily_gpad_tp,
  dd_avg_daily_gpad_tp,
  avg_daily_gpad_shortfall,

  normal_gpad_margin,
  dd_gpad_margin,
  gpad_margin_change_pp,


  -- Estimated shortfall over the Double-Date period
  avg_daily_gpad_shortfall
    * dd_days
    AS estimated_campaign_gpad_shortfall

FROM
  economics_comparison

ORDER BY
  month;