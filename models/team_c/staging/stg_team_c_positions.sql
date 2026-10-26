SELECT
    "posIdentity" AS position_id,
    "rptDate"::date AS report_date,
    profitloss::numeric AS profit,
    "insCode" AS instrument_code
FROM {{ ref('team_c_positions') }}