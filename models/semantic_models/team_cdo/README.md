# CDO enterprise Position semantic model

CDO governs the common Position schema, and Team A/C own their full independent
semantic models. The validator publishes a validated composition catalog and
`scripts/generate_cdo_dbt.py` translates it into **native dbt** resources:

- `generated/cdo_enterprise_positions.sql`: a logical `UNION ALL` view over
  the standardized team staging models, with `source_team` and NULL for
  nonapplicable team-specific extensions.
- `generated/cdo_enterprise_positions.yml`: dbt v1.12+ model properties and
  `semantic_model`, with shared dimensions and CDO-specific P&L/count metrics.
- `enterprise_metrics.yml`: the separately authored CDO derived metric that
  references the existing Equity and FI P&L metrics.

Team A metrics (`equity_profit_loss`, `team_a_position_count`) and Team C
metrics (`fixed_income_profit_loss`, `team_c_position_count`) **remain intact**
in their team semantic models. Team-specific columns `mtm`, `cash`, and
`settled_cash` are projected into the CDO view; they are not automatically
turned into metric measures because their business aggregation semantics have
not been approved.

The new CDO view provides **position-level rows**, something a derived metric
alone cannot return. Position IDs may overlap between teams, so interpret
position identity as team + position ID (+ report date when modeling snapshots).
No join is made between independent team-specific position IDs.

## Automatic sync

`.github/workflows/sync-cdo-catalog.yml` fetches the validated catalog,
generates both native files, runs `dbt parse` after compiling Team A/C
inheritance in a disposable checkout, then opens a PR for any changes. It is
manual or scheduled on weekdays. The workflow does not change authored team
semantic YAML or enable hosted Semantic Layer on the free plan.

## Reproduce generation locally

```bash
python scripts/generate_cdo_dbt.py \
  --catalog /path/to/cdo_enterprise_positions.yml \
  --out models/semantic_models/team_cdo/generated
```

This native CDO model adds an SQL view; the original team-specific semantic
models and CDO derived metrics are preserved, not flattened into one model.
