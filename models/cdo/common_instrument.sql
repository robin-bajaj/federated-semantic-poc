{{ config(materialized='view') }}

SELECT
    instrument_code::integer AS instrument_code,
    isin::text AS isin,
    cusip::text AS cusip,
    security_type::text AS instrument_type

FROM {{ ref('stg_team_b_instruments') }}