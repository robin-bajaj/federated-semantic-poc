{#
{{
    config(
        materialized='view',
        group='lob_team_a'
    )
}}

SELECT *
FROM {{ ref('int_cdo_positions_union') }}
#}