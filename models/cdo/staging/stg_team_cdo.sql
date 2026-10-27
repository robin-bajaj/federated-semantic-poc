{{ config(materialized='view') }}

SELECT
    'team_a:' || position_id::text AS cdo_position_key,
    'team_a'::text AS source_team,
    position_id::integer AS position_id,
    report_date::date AS report_date,
    profit_loss::numeric AS profit_loss,
    cash::numeric AS settled_cash,
    CAST(NULL AS numeric) AS unsettled_cash,
    instrument_code::integer AS instrument_id

FROM {{ ref('stg_team_a_positions') }}

UNION ALL

SELECT
    'team_c:' || position_id::text AS cdo_position_key,
    'team_c'::text AS source_team,
    position_id::integer AS position_id,
    report_date::date AS report_date,
    profit_loss::numeric AS profit_loss,
    settled_cash::numeric AS settled_cash,
    CAST(NULL AS numeric) AS unsettled_cash,
    instrument_code::integer AS instrument_id

FROM {{ ref('stg_team_c_positions') }}