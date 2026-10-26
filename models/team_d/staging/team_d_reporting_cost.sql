{{ config(materialized='view') }}

SELECT
    '2026-10-20'::date AS report_date,
    300::numeric AS reporting_cost