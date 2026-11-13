
{% macro validate_cdo_minimum_contract() %}

    {% set contract = var('cdo_minimum_position_contract') %}
    {% set requirements = contract['required_attributes'] %}
    {% set implementations = contract['implementations'] %}
    {% set checked_teams = [] %}

    {% if implementations | length == 0 %}
        {{ exceptions.raise_compiler_error(
            "CDO contract has no LOB implementations."
        ) }}
    {% endif %}

    {% for implementation in implementations %}

        {% set team = implementation['team'] %}
        {% set model_name = implementation['model'] %}
        {% set mappings = implementation['mappings'] %}

        {{ log(
            "Checking " ~ team ~ " against CDO contract...",
            info=true
        ) }}

        {# Prevent duplicate declarations for the same team #}

        {% if team in checked_teams %}
            {{ exceptions.raise_compiler_error(
                "Duplicate CDO implementation: " ~ team
            ) }}
        {% endif %}

        {% do checked_teams.append(team) %}

        {# Check contract version #}

        {% if implementation['version'] != contract['version'] %}
            {{ exceptions.raise_compiler_error(
                team ~ ": contract version mismatch."
            ) }}
        {% endif %}

        {# Find the LOB model in dbt's parsed project graph #}

        {% set found = namespace(model=none, matches=0) %}

        {% for node in graph.nodes.values() %}
            {% if node.resource_type == 'model'
                and node.name == model_name
                and node.package_name == project_name %}

                {% set found.model = node %}
                {% set found.matches = found.matches + 1 %}

            {% endif %}
        {% endfor %}

        {% if found.matches != 1 %}
            {{ exceptions.raise_compiler_error(
                team ~ ": expected exactly one dbt model named "
                ~ model_name ~ ", found " ~ found.matches
            ) }}
        {% endif %}

        {# Verify the model belongs to the declaring LOB group #}

        {% if found.model.config.get('group') != team %}
            {{ exceptions.raise_compiler_error(
                team ~ ": model ownership mismatch for "
                ~ model_name
            ) }}
        {% endif %}

        {# Validate CDO-required attributes only #}

        {% for attribute, expected_type
            in requirements.items() %}

            {% set column_name = mappings.get(attribute) %}

            {% if not column_name %}
                {{ exceptions.raise_compiler_error(
                    team ~ ": missing required CDO attribute "
                    ~ attribute
                ) }}
            {% endif %}

            {% set column = found.model.columns.get(column_name) %}

            {% if column is none %}
                {{ exceptions.raise_compiler_error(
                    team ~ ": mapped column "
                    ~ column_name ~ " is not declared in "
                    ~ model_name
                ) }}
            {% endif %}

            {% if not column.data_type %}
                {{ exceptions.raise_compiler_error(
                    team ~ ": missing data_type for "
                    ~ column_name
                ) }}
            {% endif %}

            {% set actual_type =
                column.data_type | string | lower | trim %}

            {% set expected_type =
                expected_type | string | lower | trim %}

            {% if actual_type != expected_type %}
                {{ exceptions.raise_compiler_error(
                    team ~ ": data type mismatch for "
                    ~ attribute ~ ". Expected "
                    ~ expected_type ~ ", found "
                    ~ actual_type
                ) }}
            {% endif %}

            {{ log(
                "PASS: " ~ team ~ " | " ~ attribute
                ~ " -> " ~ column_name,
                info=true
            ) }}

        {% endfor %}

        {{ log(
            "PASS: " ~ team ~ " satisfies the CDO minimum contract.",
            info=true
        ) }}

    {% endfor %}

    {{ log(
        "CDO minimum Position contract PASSED for "
        ~ (checked_teams | length) ~ " team(s).",
        info=true
    ) }}

{% endmacro %}
