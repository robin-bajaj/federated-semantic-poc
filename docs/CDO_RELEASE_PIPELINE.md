# CDO Semantic Release Pipeline

The automated release workflow is `.github/workflows/cdo-semantic-release.yml`.

## Workflow and ownership

- **PR:** compile CDO v1 inheritance into Team A/Team C, run validator tests, dbt parse and metadata validation, compose the CDO catalog, regenerate native CDO `*.sql` and `*.yml` and verify they exactly match the committed reviewed artifacts. No database write.
- **If generated files are stale:** run the existing `Sync native CDO semantic model` workflow, review and merge the generated-file PR, then re-run validation.
- **On main:** repeat the same validation, then deploy only after the protected GitHub Environment `cdo-release` authorizes the job.
- **Build:** `dbt build --select +cdo_enterprise_positions` builds its selected dependencies and CDO logical PostgreSQL view.
- **Reconciliation:** `dbt test --select assert_cdo_position_composition` compares row counts and approved financial column totals against team-owned staging sources.
- **Artifacts:** manifest, semantic_manifest and run_results retained in GitHub Actions.

## One-time GitHub setup

Create a GitHub Environment **cdo-release** with required reviewers and restrict it to `main`. Set the following environment secrets:

`DBT_PG_HOST`, `DBT_PG_USER`, `DBT_PG_PASSWORD`, `DBT_PG_DBNAME`; optionally `DBT_PG_PORT` (default 5432).

Set environment variable `DBT_CDO_RELEASE_SCHEMA` to a **dedicated, isolated POC schema**, for example `ci_cdo_poc`. Ensure the Neon PostgreSQL login has permission to create and replace objects there. Never point this deployment at production or a schema used by other dbt jobs without review.

**Important:** This POC includes source `team_a_positions` and `team_c_positions` as dbt seeds. The `+cdo_enterprise_positions` build includes upstream seeds/models and can write seed tables. Use the dedicated POC schema only. Replace seeds with governed live sources before a production release.

This workflow does not set up hosted dbt Semantic Layer access or publish directly to a BI connector. The result is a built CDO view in Neon and a validated semantic manifest. Hosted Semantic Layer connectivity requires separate dbt account/service configuration.

The comparison is structural/value reconciliation; it does not certify business-level FX conversion or correct aggregation of snapshots across dates. That requires future finance-approved test cases.
