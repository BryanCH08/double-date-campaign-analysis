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
    session_id,
    session_date,

    CASE
      WHEN session_date BETWEEN '2024-12-01' AND '2024-12-12'
        THEN 'double_date'
      ELSE 'normal_days'
    END AS period_type

  FROM
    `YOUR_PROJECT_ID.synthetic_ecommerce_portfolio.fact_sessions`

  WHERE
    session_date BETWEEN '2024-12-01' AND '2024-12-31'
),


session_stage AS (
  SELECT
    s.session_id,
    s.period_type,
    COUNTIF(e.event_name = 'product_view') > 0
      AS viewed,

    COUNTIF(e.event_name = 'add_to_cart') > 0
      AS added_to_cart,

    COUNTIF(e.event_name = 'begin_checkout') > 0
      AS checked_out,

    COUNTIF(e.event_name = 'purchase') > 0
      AS purchased

  FROM
    classified_sessions s

  LEFT JOIN
    `YOUR_PROJECT_ID.synthetic_ecommerce_portfolio.fact_funnel_events` e
    ON s.session_id = e.session_id

  GROUP BY
    s.session_id,
    s.period_type
),


period_performance AS (
  SELECT
    period_type,

    -- Session → Product View
    SAFE_DIVIDE(
      COUNTIF(viewed),
      COUNT(*)
    ) AS view_rate,

    -- Product View → Add to Cart
    SAFE_DIVIDE(
      COUNTIF(added_to_cart),
      COUNTIF(viewed)
    ) AS view_to_cart_rate,

    -- Add to Cart → Checkout
    SAFE_DIVIDE(
      COUNTIF(checked_out),
      COUNTIF(added_to_cart)
    ) AS cart_to_checkout_rate,

    -- Checkout → Purchase
    SAFE_DIVIDE(
      COUNTIF(purchased),
      COUNTIF(checked_out)
    ) AS checkout_to_purchase_rate,

    -- Overall Session → Purchase
    SAFE_DIVIDE(
      COUNTIF(purchased),
      COUNT(*)
    ) AS overall_cvr

  FROM
    session_stage

  GROUP BY
    period_type
),


pivoted AS (
  SELECT
    -- Session → Product View
    MAX(IF(
      period_type = 'normal_days',
      view_rate,
      NULL
    )) AS normal_view_rate,

    MAX(IF(
      period_type = 'double_date',
      view_rate,
      NULL
    )) AS dd_view_rate,


    -- Product View → Add to Cart
    MAX(IF(
      period_type = 'normal_days',
      view_to_cart_rate,
      NULL
    )) AS normal_view_to_cart_rate,

    MAX(IF(
      period_type = 'double_date',
      view_to_cart_rate,
      NULL
    )) AS dd_view_to_cart_rate,


    -- Add to Cart → Checkout
    MAX(IF(
      period_type = 'normal_days',
      cart_to_checkout_rate,
      NULL
    )) AS normal_cart_to_checkout_rate,

    MAX(IF(
      period_type = 'double_date',
      cart_to_checkout_rate,
      NULL
    )) AS dd_cart_to_checkout_rate,


    -- Checkout → Purchase
    MAX(IF(
      period_type = 'normal_days',
      checkout_to_purchase_rate,
      NULL
    )) AS normal_checkout_to_purchase_rate,

    MAX(IF(
      period_type = 'double_date',
      checkout_to_purchase_rate,
      NULL
    )) AS dd_checkout_to_purchase_rate,


    -- Overall Session → Purchase
    MAX(IF(
      period_type = 'normal_days',
      overall_cvr,
      NULL
    )) AS normal_overall_cvr,

    MAX(IF(
      period_type = 'double_date',
      overall_cvr,
      NULL
    )) AS dd_overall_cvr

  FROM
    period_performance
),


funnel_comparison AS (
  SELECT
    1 AS step_order,
    'Session → Product View' AS funnel_step,

    normal_view_rate AS normal_rate,
    dd_view_rate AS dd_rate,

    100 * (
      dd_view_rate
      - normal_view_rate
    ) AS change_pp

  FROM
    pivoted


  UNION ALL


  SELECT
    2,
    'Product View → Add to Cart',

    normal_view_to_cart_rate,
    dd_view_to_cart_rate,

    100 * (
      dd_view_to_cart_rate
      - normal_view_to_cart_rate
    )

  FROM
    pivoted


  UNION ALL


  SELECT
    3,
    'Add to Cart → Checkout',

    normal_cart_to_checkout_rate,
    dd_cart_to_checkout_rate,

    100 * (
      dd_cart_to_checkout_rate
      - normal_cart_to_checkout_rate
    )

  FROM
    pivoted


  UNION ALL


  SELECT
    4,
    'Checkout → Purchase',

    normal_checkout_to_purchase_rate,
    dd_checkout_to_purchase_rate,

    100 * (
      dd_checkout_to_purchase_rate
      - normal_checkout_to_purchase_rate
    )

  FROM
    pivoted


  UNION ALL


  SELECT
    5,
    'Overall Session → Purchase',

    normal_overall_cvr,
    dd_overall_cvr,

    100 * (
      dd_overall_cvr
      - normal_overall_cvr
    )

  FROM
    pivoted
)


SELECT
  step_order,
  funnel_step,
  normal_rate,
  dd_rate,
  change_pp

FROM
  funnel_comparison

ORDER BY
  step_order;