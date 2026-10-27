
{% macro validate_cdo_position_mapping() %}

    {% set contract = var('cdo_position') %}
    {% set attributes = contract['attributes'] %}

    {% for team in contract['teams'] %}

        SELECT
            '{{ team["name"] }}' AS source_team,
            CAST(
                s.{{ adapter.quote(team["source_columns"]["position_id"]) }}
                AS text
            ) AS source_position_id

        FROM {{ ref(team['source_model']) }} s

        FULL OUTER JOIN {{ ref(team['staging_model']) }} t
            ON CAST(
                s.{{ adapter.quote(team["source_columns"]["position_id"]) }}
                AS text
            ) = t.position_id

        WHERE
            s.{{ adapter.quote(team["source_columns"]["position_id"]) }} IS NULL
            OR t.position_id IS NULL

            {% for attribute, data_type in attributes.items() %}

                OR CAST(
                    s.{{ adapter.quote(team['source_columns'][attribute]) }}
                    AS {{ data_type }}
                ) IS DISTINCT FROM
                t.{{ adapter.quote(attribute) }}

                OR t.{{ adapter.quote(attribute) }} IS NULL

            {% endfor %}

        {% if not loop.last %}
            UNION ALL
        {% endif %}

    {% endfor %}

{% endmacro %}


{% macro run_cdo_position_validation() %}

    {% set validation_sql = validate_cdo_position_mapping() %}

    {% if execute %}

        {% set result = run_query(
            "SELECT COUNT(*) AS violation_count FROM ("
            ~ validation_sql
            ~ ") AS violations"
        ) %}

        {% set violation_count = result.rows[0][0] | int %}

        {% if violation_count > 0 %}

            {{ exceptions.raise_compiler_error(
                "CDO Position validation FAILED: "
                ~ violation_count
                ~ " mapping violations found."
            ) }}

        {% else %}

            {{ log(
                "CDO Position validation PASSED: "
                ~ "0 mapping violations found.",
                info=True
            ) }}

        {% endif %}

    {% endif %}

{% endmacro %}
