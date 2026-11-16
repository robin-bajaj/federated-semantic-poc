# CDO governance repository layout

The central repository `robin-bajaj/cdo-semantic-contract-validator` now keeps
all CDO-specific assets in a single directory:

```text
cdo/
  contracts/position_v1.yml
  metrics/profit_loss_v1.yml
  validator/
    pyproject.toml
    meta_context_validator/
      cli.py
      contract_rules.py
      rules.py
      metric_generator.py
      generate_metrics.py
    tests/
```

GitHub Actions checks out the CDO repository beside the dbt project and pins
a specific revision of this layout:

- Install: `./contract-validator/cdo/validator`
- Unit tests: `contract-validator/cdo/validator/tests`
- Metric registry: `../contract-validator/cdo/metrics`
- Position contract: `../contract-validator/cdo/contracts/position_v1.yml`

The workflow runs the generator before `dbt parse`. The `dbt-mc` CLI entry
point and Python imports remain the same because the package name
`meta_context_validator` has not changed.

**Note:** This reorganizes files but does not add native metric inheritance.
The custom generator modifies the checked-out team semantic YAML and is
currently run by GitHub Actions. To parse locally or in dbt Studio, generated
metric declarations must be available before dbt parse.
