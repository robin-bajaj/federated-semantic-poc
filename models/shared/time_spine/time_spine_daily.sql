{{ config(materialized='table') }}

SELECT
    date_day::date AS date_day
FROM generate_series(
    '2026-01-01'::date,
    '2027-12-31'::date,
    interval '1 day'
) AS dates(date_day)