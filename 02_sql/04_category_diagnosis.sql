/*
Project      : Double-Date Campaign Performance Analysis
Analysis     : Campaign vs Normal Days Growth Performance
Data         : Fully synthetic e-commerce data
Output grain : One row per campaign month
Author       : Bryan Christian
*/

-- Replace YOUR_PROJECT_ID with your own Google Cloud project ID.

WITH classified_order_items AS (
  SELECT
    order_date,
    category_c2,
    gpad_tp,

    CASE
      WHEN order_date BETWEEN '2024-12-01' AND '2024-12-12'
        THEN 'double_date'
      ELSE 'normal_days'
    END AS period_type,
    CASE
      WHEN order_date BETWEEN '2024-12-01' AND '2024-12-12'
        THEN 12
      ELSE 19
    END AS period_days

  FROM
    `YOUR_PROJECT_ID.synthetic_ecommerce_portfolio.fact_order_items`

  WHERE
    order_date BETWEEN '2024-12-01' AND '2024-12-31'
),


period_category_performance AS (
  SELECT
    category_c2,
    period_type,
    SAFE_DIVIDE(
      SUM(gpad_tp),
      MAX(period_days)
    ) AS avg_daily_gpad_tp

  FROM
    classified_order_items

  GROUP BY
    category_c2,
    period_type
),


pivoted AS (
  SELECT
    category_c2,

    MAX(IF(
      period_type = 'normal_days',
      avg_daily_gpad_tp,
      NULL
    )) AS normal_avg_daily_gpad_tp,

    MAX(IF(
      period_type = 'double_date',
      avg_daily_gpad_tp,
      NULL
    )) AS dd_avg_daily_gpad_tp

  FROM
    period_category_performance

  GROUP BY
    category_c2
),


category_comparison AS (
  SELECT
    category_c2,

    normal_avg_daily_gpad_tp,
    dd_avg_daily_gpad_tp,

    -- Positive value means the category generated
    -- lower GPAD-TP during 12.12
    normal_avg_daily_gpad_tp
      - dd_avg_daily_gpad_tp
      AS avg_daily_gpad_shortfall

  FROM
    pivoted
),


final_output AS (
  SELECT
    category_c2,

    normal_avg_daily_gpad_tp,
    dd_avg_daily_gpad_tp,
    avg_daily_gpad_shortfall,
    SAFE_DIVIDE(
      avg_daily_gpad_shortfall,

      SUM(
        IF(
          avg_daily_gpad_shortfall > 0,
          avg_daily_gpad_shortfall,
          0
        )
      ) OVER ()
    ) AS share_of_total_shortfall,

    -- Used to identify the top three categories
    RANK() OVER (
      ORDER BY avg_daily_gpad_shortfall DESC
    ) AS shortfall_rank

  FROM
    category_comparison

  -- Category without a shortfall does not contribute
  -- to the negative GPAD-TP gap
  WHERE
    avg_daily_gpad_shortfall > 0
)


SELECT
  category_c2,
  normal_avg_daily_gpad_tp,
  dd_avg_daily_gpad_tp,
  avg_daily_gpad_shortfall,
  share_of_total_shortfall,
  shortfall_rank

FROM
  final_output

ORDER BY
  shortfall_rank;