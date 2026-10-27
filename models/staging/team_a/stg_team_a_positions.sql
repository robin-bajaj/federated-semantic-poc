SELECT
    "posID"::text AS position_id,
    "rptDate"::date AS report_date,
    pnl::numeric AS profit_loss,
    mtm::numeric AS mtm,
    cash::numeric AS cash,
    "instrumentID"::integer AS instrument_code
FROM {{ ref('team_a_positions') }}