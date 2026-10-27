SELECT
    code::integer AS instrument_code,
    cusip::text AS cusip,
    isin::text AS isin,
    "securityType"::text AS security_type
FROM {{ ref('team_b_instruments') }}