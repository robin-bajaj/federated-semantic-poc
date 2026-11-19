-- AUTO-GENERATED from the validated CDO semantic composition catalog.
-- Logical UNION ALL view; no physical copy of source positions.
{{ config(materialized='view') }}

select
    'TEAM_A'::text as source_team,
    position_id::text as position_id,
    report_date::date as report_date,
    profit_loss::numeric as profit_loss,
    instrument_code::integer as instrument_code,
    cash::numeric as cash,
    mtm::numeric as mtm,
    null::numeric as settled_cash
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
    settled_cash::numeric as settled_cash
from {{ ref('stg_team_c_positions') }}
