SELECT
    "posID" AS position_id,
    "rptDate"::date AS report_date,
    pnl::numeric AS profit,
    "instrumentCode" AS instrument_code
FROM {{ ref('team_a_positions') }}