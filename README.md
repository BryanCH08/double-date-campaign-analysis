# Double-Date Campaign Performance Analysis

An end-to-end data analytics portfolio project evaluating whether an
e-commerce Double-Date campaign should be expanded, redesigned, or limited.

This project uses fully synthetic data inspired by common e-commerce business
processes. It does not contain confidential Blibli data.

## Business Background

Double-Date campaigns aim to generate more visits and purchases through greater
campaign exposure, platform discounts, vouchers, cashback, and shipping
subsidies.

However, higher sales do not automatically create sustainable business value.
Campaign growth must also generate sufficient contribution to cover the
additional campaign costs.

## Business Question

**Should the Double-Date campaign be expanded, redesigned, or limited?**

The decision framework is:

- **Expand:** sales and after-cost contribution both improve.
- **Redesign:** sales improve, but after-cost contribution declines.
- **Limit:** sales remain weak and after-cost contribution declines.

## Analysis Scope

The analysis covers September–December 2024 and compares four campaigns:

| Campaign | Campaign period | Normal Days baseline |
|---|---|---|
| 9.9 | September 1–9 | September 10–30 |
| 10.10 | October 1–10 | October 11–31 |
| 11.11 | November 1–11 | November 12–30 |
| 12.12 | December 1–12 | December 13–31 |

Because the periods contain different numbers of days, volume metrics are
compared using average daily performance instead of raw totals.

## Analysis Framework

### 1. Demand Growth

Evaluates whether the campaigns increased:

- Visits
- Purchase conversion
- Completed orders
- Average order value
- Customer-paid transaction value

### 2. Financial Sustainability

Compares:

- Contribution before campaign costs (GPBD)
- Contribution after campaign costs (GPAD-TP)
- Contribution margins
- Daily and total contribution gaps

### 3. Performance Diagnosis

Investigates:

- Customer journey conversion
- Product-category contribution
- Platform discount, voucher, cashback, and shipping subsidy costs

## Key Findings

- All four campaigns increased average daily orders and transaction value.
- The strongest demand result occurred during 12.12:
  - Average daily orders increased by **132.7%**.
  - Average daily transaction value increased by **110.4%**.
- Growth was driven by more visits and stronger purchase conversion.
- Average order value declined during every campaign.
- Contribution before campaign costs improved, but contribution after campaign
  costs became negative.
- During 12.12, after-cost contribution reached approximately **-Rp3.6 million
  per day**.
- The total 12.12 contribution gap versus its Normal Days baseline was
  approximately **Rp55.7 million**.
- Platform discounts and shipping subsidies represented the largest additional
  campaign-cost components.

## Recommendation

### Redesign before expanding

The Double-Date campaign successfully created customer demand, so it should not
be stopped entirely. However, the existing campaign-cost structure should not
be expanded across all categories.

Recommended actions:

1. Maintain the campaign elements that increased visits and purchase conversion.
2. Target platform discounts more selectively.
3. Review shipping-subsidy eligibility and spending limits.
4. Apply campaign-cost limits by product category.
5. Expand only when after-cost contribution remains positive or meets an agreed
   minimum threshold.

## Tools Used

- **Google Colab:** synthetic-data generation
- **Google BigQuery:** SQL querying and analytical data processing
- **Microsoft Excel:** result validation and visualization
- **Canva:** business presentation design
- **GitHub:** project documentation and version control

## Repository Structure

```text
00_data_generation/
├── 01_generate_synthetic_data.ipynb
└── 02_load_or_restore_snapshot_to_bigquery.ipynb

01_data/
└── 13 synthetic e-commerce tables in Parquet format

02_sql/
├── 01_demand_growth.sql
├── 02_financial_sustainability.sql
├── 03_customer_journey.sql
├── 04_category_diagnosis.sql
└── 05_promotion_cost_breakdown.sql

03_analysis_outputs/
└── Excel query outputs and visualizations
