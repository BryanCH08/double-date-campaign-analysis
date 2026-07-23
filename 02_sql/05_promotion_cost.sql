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
    CASE
      WHEN order_date BETWEEN '2024-12-01' AND '2024-12-12'
        THEN 'double_date'
      ELSE 'normal_days'
    END AS period_type,
    CASE
      WHEN order_date BETWEEN '2024-12-01' AND '2024-12-12'
        THEN 12
      ELSE 19
    END AS period_days,
    gpbd,
    platform_discount,
    voucher_cost,
    cashback_cost,
    shipping_subsidy,
    gpad_tp

  FROM
    `YOUR_PROJECT_ID.synthetic_ecommerce_portfolio.fact_order_items`

  WHERE
    order_date BETWEEN '2024-12-01' AND '2024-12-31'
),


period_performance AS (
  SELECT
    period_type,

    -- Total period value / calendar days
    SAFE_DIVIDE(
      SUM(gpbd),
      MAX(period_days)
    ) AS avg_daily_gpbd,

    SAFE_DIVIDE(
      SUM(platform_discount),
      MAX(period_days)
    ) AS avg_daily_platform_discount,

    SAFE_DIVIDE(
      SUM(voucher_cost),
      MAX(period_days)
    ) AS avg_daily_voucher,

    SAFE_DIVIDE(
      SUM(cashback_cost),
      MAX(period_days)
    ) AS avg_daily_cashback,

    SAFE_DIVIDE(
      SUM(shipping_subsidy),
      MAX(period_days)
    ) AS avg_daily_shipping,

    SAFE_DIVIDE(
      SUM(gpad_tp),
      MAX(period_days)
    ) AS avg_daily_gpad_tp

  FROM
    classified_order_items

  GROUP BY
    period_type
),


pivoted AS (
  SELECT
    -- GPBD
    MAX(IF(
      period_type = 'double_date',
      avg_daily_gpbd,
      NULL
    )) AS dd_gpbd,

    MAX(IF(
      period_type = 'normal_days',
      avg_daily_gpbd,
      NULL
    )) AS normal_gpbd,


    -- Platform discount
    MAX(IF(
      period_type = 'double_date',
      avg_daily_platform_discount,
      NULL
    )) AS dd_platform_discount,

    MAX(IF(
      period_type = 'normal_days',
      avg_daily_platform_discount,
      NULL
    )) AS normal_platform_discount,


    -- Voucher
    MAX(IF(
      period_type = 'double_date',
      avg_daily_voucher,
      NULL
    )) AS dd_voucher,

    MAX(IF(
      period_type = 'normal_days',
      avg_daily_voucher,
      NULL
    )) AS normal_voucher,


    -- Cashback
    MAX(IF(
      period_type = 'double_date',
      avg_daily_cashback,
      NULL
    )) AS dd_cashback,

    MAX(IF(
      period_type = 'normal_days',
      avg_daily_cashback,
      NULL
    )) AS normal_cashback,


    -- Shipping support
    MAX(IF(
      period_type = 'double_date',
      avg_daily_shipping,
      NULL
    )) AS dd_shipping,

    MAX(IF(
      period_type = 'normal_days',
      avg_daily_shipping,
      NULL
    )) AS normal_shipping,


    -- GPAD-TP
    MAX(IF(
      period_type = 'double_date',
      avg_daily_gpad_tp,
      NULL
    )) AS dd_gpad_tp,

    MAX(IF(
      period_type = 'normal_days',
      avg_daily_gpad_tp,
      NULL
    )) AS normal_gpad_tp

  FROM
    period_performance
),


cost_comparison AS (
  SELECT
    -- Additional contribution generated during 12.12
    dd_gpbd
      - normal_gpbd
      AS extra_gpbd_per_day,

    -- Additional campaign support costs
    dd_platform_discount
      - normal_platform_discount
      AS additional_platform_discount,

    dd_voucher
      - normal_voucher
      AS additional_voucher,

    dd_cashback
      - normal_cashback
      AS additional_cashback,

    dd_shipping
      - normal_shipping
      AS additional_shipping,

    -- Final after-cost difference versus Normal Days
    dd_gpad_tp
      - normal_gpad_tp
      AS final_contribution_gap

  FROM
    pivoted
),


cost_summary AS (
  SELECT
    *,

    additional_platform_discount
      + additional_voucher
      + additional_cashback
      + additional_shipping
      AS total_additional_support_cost,

    SAFE_DIVIDE(
      additional_platform_discount
        + additional_voucher
        + additional_cashback
        + additional_shipping,

      extra_gpbd_per_day
    ) AS support_cost_to_extra_contribution_ratio

  FROM
    cost_comparison
),


waterfall_output AS (
  SELECT
    1 AS component_order,
    'Extra contribution before support costs' AS component,

    extra_gpbd_per_day AS incremental_value_per_day,

    CAST(NULL AS FLOAT64) AS share_of_support_cost,

    support_cost_to_extra_contribution_ratio
      AS support_cost_ratio

  FROM
    cost_summary


  UNION ALL


  SELECT
    2,
    'Platform Discount',

    -- Negative because it reduces contribution
    -additional_platform_discount,

    SAFE_DIVIDE(
      additional_platform_discount,
      total_additional_support_cost
    ),

    NULL

  FROM
    cost_summary


  UNION ALL


  SELECT
    3,
    'Voucher',

    -additional_voucher,

    SAFE_DIVIDE(
      additional_voucher,
      total_additional_support_cost
    ),

    NULL

  FROM
    cost_summary


  UNION ALL


  SELECT
    4,
    'Cashback',

    -additional_cashback,

    SAFE_DIVIDE(
      additional_cashback,
      total_additional_support_cost
    ),

    NULL

  FROM
    cost_summary


  UNION ALL


  SELECT
    5,
    'Shipping Support',

    -additional_shipping,

    SAFE_DIVIDE(
      additional_shipping,
      total_additional_support_cost
    ),

    NULL

  FROM
    cost_summary


  UNION ALL


  SELECT
    6,
    'Final Contribution Gap',

    final_contribution_gap,

    NULL,
    NULL

  FROM
    cost_summary
)


SELECT
  component_order,
  component,
  incremental_value_per_day,
  share_of_support_cost,
  support_cost_ratio

FROM
  waterfall_output

ORDER BY
  component_order;