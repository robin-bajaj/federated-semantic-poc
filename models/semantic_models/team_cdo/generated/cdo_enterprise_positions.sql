-- AUTO-GENERATED from approved CDO Position composition selection.
{{ config(materialized='view') }}

select
    'TEAM_A'::text as source_team,
    position_id::text as position_id,
    report_date::date as report_date,
    profit_loss::numeric as profit_loss,
    instrument_code::integer as instrument_code,
    cash::numeric as cash,
    mtm::numeric as mtm,
    null::numeric as settled_cash,
    mtm::numeric as cdo_value_team_a_equity_total_mtm,
    cash::numeric as cdo_value_team_a_equity_total_cash,
    null::numeric as cdo_value_team_c_fi_total_settled_cash
from {{ ref('stg_team_a_positions') }}

union all

select
    'TEAM_C'::text as source_team,
    position_id::text as position_id,
    report_date::date as report_date,
    profit_loss::numeric as profit_loss,
    instrument_code::integer as instrument_code,
    null::numeric as cash,
    null::numeric as mtm,
    settled_cash::numeric as settled_cash,
    null::numeric as cdo_value_team_a_equity_total_mtm,
    null::numeric as cdo_value_team_a_equity_total_cash,
    settled_cash::numeric as cdo_value_team_c_fi_total_settled_cash
from {{ ref('stg_team_c_positions') }}
