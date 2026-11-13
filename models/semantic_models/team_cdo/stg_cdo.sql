SELECT
    'EQ' AS source_team,
    position_id,
    customer_id,
    report_date,
    profit_loss
FROM {{ ref('stg_eq_position') }}

UNION ALL

SELECT
    'FI' AS source_team,
    position_id,
    customer_id,
    report_date,
    profit_loss
FROM {{ ref('stg_fi_position') }}