SELECT
    "posIdentity"::text AS position_id,
    "rptDate"::date AS report_date,
    profitloss::numeric AS profit_loss,
    "settledCash"::numeric AS settled_cash,
    "insCode"::integer AS instrument_code
FROM {{ ref('team_c_positions') }}