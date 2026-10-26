
-- CDO Enterprise Position Mapping Validation
-- Returns rows only when a mapping is incorrect.
-- Test passes when zero rows are returned.

WITH team_a_mapping AS (

    SELECT
        'Team A' AS source_team,
        s."posID"::text AS source_position_id,

        -- Validate Position ID
        CASE
            WHEN p.position_id IS DISTINCT FROM s."posID"::text
            THEN 'position_id'
        END AS position_id_error,

        -- Validate Report Date
        CASE
            WHEN p.report_date IS DISTINCT FROM s."rptDate"::date
            THEN 'report_date'
        END AS report_date_error,

        -- Validate Profit
        CASE
            WHEN p.profit IS DISTINCT FROM s.pnl::numeric
            THEN 'profit'
        END AS profit_error,

        -- Validate Instrument Code
        CASE
            WHEN p.instrument_code IS DISTINCT FROM s."instrumentCode"::integer
            THEN 'instrument_code'
        END AS instrument_code_error

    FROM {{ ref('team_a_positions') }} s
    LEFT JOIN {{ ref('stg_team_a_positions') }} p
        ON p.position_id = s."posID"::text

),

team_c_mapping AS (

    SELECT
        'Team C' AS source_team,
        s."posIdentity"::text AS source_position_id,

        CASE
            WHEN p.position_id IS DISTINCT FROM s."posIdentity"::text
            THEN 'position_id'
        END AS position_id_error,

        CASE
            WHEN p.report_date IS DISTINCT FROM s."rptDate"::date
            THEN 'report_date'
        END AS report_date_error,

        CASE
            WHEN p.profit IS DISTINCT FROM s.profitloss::numeric
            THEN 'profit'
        END AS profit_error,

        CASE
            WHEN p.instrument_code IS DISTINCT FROM s."insCode"::integer
            THEN 'instrument_code'
        END AS instrument_code_error

    FROM {{ ref('team_c_positions') }} s
    LEFT JOIN {{ ref('stg_team_c_positions') }} p
        ON p.position_id = s."posIdentity"::text

),

all_mappings AS (

    SELECT * FROM team_a_mapping
    UNION ALL
    SELECT * FROM team_c_mapping

)

SELECT *
FROM all_mappings
WHERE
    position_id_error IS NOT NULL
    OR report_date_error IS NOT NULL
    OR profit_error IS NOT NULL
    OR instrument_code_error IS NOT NULL
