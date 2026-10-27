{{ config(materialized='view') }}

SELECT
    cdo_position_key,
    source_team,
    position_id,
    report_date,
    profit_loss,
    settled_cash,
    unsettled_cash,
    instrument_id

FROM {{ ref('int_cdo_positions_union') }}