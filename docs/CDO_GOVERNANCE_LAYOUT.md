# Unified CDO Position governance and metric-level references

All enterprise Position requirements now live in one custom CDO-owned
specification in the separate central repository:

```text
cdo/
  definitions/
    position_v1.yml                 # required_columns + metrics (one file)
  validator/
    meta_context_validator/
      contract_rules.py
      metric_generator.py
      generate_metrics.py
      cli.py
      rules.py
    tests/
```

This `position_v1.yml` file is **not** a native standalone dbt semantic
model. It is the central governance definition which our custom validator
and pre-parse generator read. The fields `position_id`, `report_date`,
`profit_loss` and `instrument_code` are required; the common
`cdo.profit_loss` metric aggregates standardized values using
`SUM(profit_loss)`.

Team A and Team C declare their **model-level** Position compliance under
`config.meta.semantic_contract`. Their **metric-level** references now
sit under the actual `metrics:` list:

```yaml
metrics:
  - name: equity_profit_loss
    label: Equity Profit and Loss
    config:
      meta:
        metric_contract:
          implements: cdo.profit_loss
          version: 1
```

The generator fills in `type: simple`, `agg: sum`, `expr: profit_loss`
and `fill_nulls_with: 0` before dbt parses the project. The central
specification is the single source of the common calculation.

The GitHub Actions workflow checks out a pinned CDO repository revision,
installs `./contract-validator/cdo/validator`, runs tests, and then:

```bash
python -m meta_context_validator.generate_metrics \
  --registry ../contract-validator/cdo/definitions/position_v1.yml \
  --project .

dbt parse --profiles-dir .ci --no-partial-parse

dbt-mc validate models/semantic_models/team_cdo/enterprise_metrics.yml \
  --contracts ../contract-validator/cdo/definitions/position_v1.yml \
  --manifest target/manifest.json
```

**dbt Studio limitation:** raw team YAML containing only metric-level
contract references cannot be parsed as complete dbt metrics until
generation runs. Our CI does generation in a temporary checkout; it does not
commit the generated YAML. A separate generated-artifact publishing mechanism
would be needed for immediate dbt Studio parsing without local generation.
