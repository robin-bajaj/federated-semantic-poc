# CDO-governed shared P&L metric — POC

This POC implements a **custom pre-parse metric-definition reuse extension**.
It is *not* native dbt/MetricFlow semantic-model inheritance.

## Source of truth

CDO's separate repository `robin-bajaj/cdo-semantic-contract-validator` owns:
- `metrics/profit_loss_v1.yml`: canonical `cdo.profit_loss` definition;
- `validator/meta_context_validator/metric_generator.py`: generator;
- `validator/meta_context_validator/generate_metrics.py`: command-line entry point.

The metric specification fixes `type: simple`, `agg: sum`,
`expr: profit_loss` and `fill_nulls_with: 0`.

## Team bindings

Team A's `team_a_semantics.yml` declares a `metric_bindings` reference
for `equity_profit_loss`; Team C's `team_c_semantics.yml` declares one
for `fixed_income_profit_loss`. Neither authors the aggregation or
expression in the tracked YAML. Both team staging models still publish
standardized `profit_loss` position values and must pass CDO column
contract validation. Existing position-count metrics remain team-owned.

## CI and developer workflow

GitHub Actions checks out the CDO validator at a **pinned commit**, runs
unit tests, then generates native dbt metric definitions into the
working-copy YAML **before `dbt parse`**.

Run generation locally before any dbt commands that need the metrics:

```bash
pip install /path/to/cdo-semantic-contract-validator/validator
python -m meta_context_validator.generate_metrics \
  --registry /path/to/cdo-semantic-contract-validator/metrics \
  --project .
dbt parse
```

The generator edits model property YAML in place. Run it in a disposable
checkout or inspect and revert only its generated metric changes before
committing; **do not commit generated metric blocks beside the bindings**.
Running it again with the same registry is idempotent. dbt Cloud jobs
must also execute generation before parsing or compile with generated
properties from a prepared artifact.

## Distinctions

- Team A source: `pnl` -> staging `profit_loss`; sample P&L = 2,500.
- Team C source: `profitloss` -> staging `profit_loss`; sample P&L = 4,300.
- The CDO enterprise derived metric continues to combine team metrics:
  `equity_profit_loss + fixed_income_profit_loss` (sample total = 6,800).
- The existing CDO SQL union and `cdo_total_profit_loss` metric remain
  unchanged and provide an alternative physical aggregation path.
- No generator rule certifies source position P&L business calculations.
  It centralizes only the standard *aggregation* of standardized values.

For independently deployed team repositories, repeat the CI steps in
each repo and pin the CDO metric registry revision in each workflow.
