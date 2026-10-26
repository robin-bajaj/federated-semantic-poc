WITH enterprise_positions AS (

    SELECT
        'Team A' AS source_team,
        position_id,
        report_date,
        profit,
        instrument_code
    FROM {{ ref('stg_team_a_positions') }}

    UNION ALL

    SELECT
        'Team C' AS source_team,
        position_id,
        report_date,
        profit,
        instrument_code
    FROM {{ ref('stg_team_c_positions') }}

)

SELECT
    source_team,
    position_id
FROM enterprise_positions
WHERE
    position_id IS NULL
    OR report_date IS NULL
    OR profit IS NULL
    OR instrument_code IS NULL