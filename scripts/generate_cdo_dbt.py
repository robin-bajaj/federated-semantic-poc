"""Generate native dbt CDO semantic model YAML and SQL from validated CDO catalog.

The governance catalog remains the input, never a dbt model schema by itself.
Outputs are valid dbt models/semantic model properties (dbt v1.12+).
"""
import argparse
from pathlib import Path
import re
import yaml

IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
MODEL_NAME = "cdo_enterprise_positions"


def _identifier(value):
    if not isinstance(value, str) or not IDENT.fullmatch(value):
        raise ValueError(f"Unsafe identifier: {value!r}")
    return value


def generate(catalog_path, output_directory):
    catalog = yaml.safe_load(Path(catalog_path).read_text(encoding="utf-8"))
    if catalog.get("catalog_format") != "cdo-federated-semantic-catalog/v1":
        raise ValueError("Unsupported composition catalog format")
    if catalog.get("contract") != {"name": "cdo.position", "version": 1}:
        raise ValueError("Unexpected CDO position contract")
    implementations = catalog.get("implementations") or []
    names = {x.get("semantic_model") for x in implementations}
    if len(implementations) != 2 or names != {"team_a_equity_positions", "team_c_fi_positions"}:
        raise ValueError("CDO requires validated Team A and Team C implementations")
    common = catalog.get("common_attributes") or []
    for name in common:
        _identifier(name)
    if len(set(common)) != len(common):
        raise ValueError("Duplicate CDO attributes")
    if set(common) != {"position_id", "report_date", "profit_loss", "instrument_code"}:
        raise ValueError("Unsupported CDO common attributes")

    extensions = []
    dtype = {}
    source_maps = []
    for implementation in implementations:
        src = _identifier(implementation["source_model"])
        team = {"team_a_equity_positions": "TEAM_A", "team_c_fi_positions": "TEAM_C"}[implementation["semantic_model"]]
        columns = implementation.get("columns") or []
        lookup = {c["name"]: c for c in columns}
        if len(lookup) != len(columns):
            raise ValueError(f"{src}: duplicate columns")
        if not set(common) <= set(lookup):
            raise ValueError(f"{src}: missing common attributes")
        for col in columns:
            name = _identifier(col["name"])
            data_type = str(col.get("data_type", "")).strip().lower()
            if not data_type:
                raise ValueError(f"{src}: missing data type for {name}")
            if name not in common:
                if name in dtype and dtype[name] != data_type:
                    raise ValueError(f"{name}: incompatible extension types across teams")
                dtype[name] = data_type
                if name not in extensions:
                    extensions.append(name)
        source_maps.append((team, src, lookup))
    # Explicitly allow SQL casts only from this restricted dbt/Postgres type set.
    accepted_types = {"numeric", "integer", "text", "date", "boolean", "bigint"}
    if set(dtype.values()) - accepted_types:
        raise ValueError(f"Unsupported extension types: {set(dtype.values()) - accepted_types}")
    extensions.sort()

    branches = []
    for team, src, cols in source_maps:
        selections = [
            f"    '{team}'::text as source_team",
            "    position_id::text as position_id",
            "    report_date::date as report_date",
            "    profit_loss::numeric as profit_loss",
            "    instrument_code::integer as instrument_code",
        ]
        for extra in extensions:
            cast = dtype[extra]
            selections.append(f"    {extra}::{cast} as {extra}" if extra in cols else f"    null::{cast} as {extra}")
        branches.append("select\n" + ",\n".join(selections) + f"\nfrom {{{{ ref('{src}') }}}}")
    sql = ("-- AUTO-GENERATED from the validated CDO semantic composition catalog.\n"
           "-- Logical UNION ALL view; no physical copy of source positions.\n"
           "{{ config(materialized='view') }}\n\n" +
           "\n\nunion all\n\n".join(branches) + "\n")

    columns = [
        {"name": "source_team", "data_type": "text", "dimension": {"type": "categorical"}},
        {"name": "position_id", "data_type": "text", "dimension": {"type": "categorical"}},
        {"name": "report_date", "data_type": "date", "granularity": "day", "dimension": {"type": "time"}},
        {"name": "profit_loss", "data_type": "numeric"},
        {"name": "instrument_code", "data_type": "integer", "dimension": {"type": "categorical"},
         "entity": {"type": "foreign", "name": "instrument"}},
    ]
    # A natural entity describes business grain without falsely claiming globally unique Position IDs.
    # Composite identity must be treated as (source_team, position_id, report_date).
    # 'primary_entity' is the semantic concept, not a physical key constraint.
    for name in extensions:
        columns.append({"name": name, "data_type": dtype[name],
                        "description": "Team-owned extension; NULL when not applicable to the source team."})

    metrics = [
        {"name": "cdo_position_profit_loss", "label": "CDO Position Profit and Loss",
         "type": "simple", "agg": "sum", "expr": "profit_loss"},
        {"name": "cdo_position_row_count", "label": "CDO Position Row Count",
         "description": "Number of position rows across team/date; not necessarily distinct enterprise positions.",
         "type": "simple", "agg": "count", "expr": "position_id"},
    ]
    schema = {"version": 2, "models": [{
        "name": MODEL_NAME,
        "description": "CDO unified Position view composed from validated Team A and Team C sources.",
        "config": {"meta": {"cdo_contract": "cdo.position", "cdo_contract_version": 1,
                            "composition_sources": [s for _, s, _ in source_maps]}},
        "semantic_model": {"enabled": True, "name": "cdo_enterprise_positions"},
        "primary_entity": "enterprise_position",
        "agg_time_dimension": "report_date",
        "columns": columns,
        "metrics": metrics
    }]}
    # Native YAML deliberately avoids copying local metric names: those still belong
    # to their original semantic models. Enterprise derived metric remains separately defined.
    out = Path(output_directory)
    out.mkdir(parents=True, exist_ok=True)
    (out / f"{MODEL_NAME}.sql").write_text(sql, encoding="utf-8")
    (out / f"{MODEL_NAME}.yml").write_text(
        "# AUTO-GENERATED; native dbt model + semantic configuration (v1.12+)\n" +
        yaml.safe_dump(schema, sort_keys=False, allow_unicode=True, width=100),
        encoding="utf-8")
    return out / f"{MODEL_NAME}.yml"


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--catalog", required=True, type=Path)
    p.add_argument("--out", required=True, type=Path)
    args = p.parse_args()
    print(f"Generated native dbt model: {generate(args.catalog, args.out)}")


if __name__ == "__main__":
    main()
