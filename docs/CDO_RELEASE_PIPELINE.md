# CDO CI → Sync → Release

This project has three primary GitHub Actions workflows, plus one optional
manual publishing workflow for a separate dbt Cloud integration approach.

## Primary path

1. **CI — `cdo-semantic-ci.yml`:** Every pull request targeting `main`
   compiles the short Team A/C authored inheritance YAML in an ephemeral
   checkout, runs validator tests, parses native dbt semantics, and builds the
   CDO view plus reconciliation test in an isolated Neon CI schema for
   same-repository PRs. CI never publishes to the release schema.
2. **Sync — `sync-cdo-catalog.yml`:** After a successful Team A/C change
   is *merged to main*, a path-filtered push starts the generator.
   It compiles current Team A/C YAML, composes the validated CDO catalog,
   regenerates `cdo_enterprise_positions.sql` and
   `cdo_enterprise_positions.yml`, parses them, and opens a **review PR**
   only if the generated files differ. Team-owned authored YAML is not
   committed back. The weekday schedule and manual dispatch also cover
   changes in the separately governed CDO repository.
3. **Release — `cdo-semantic-release.yml`:** Review/merge the Sync PR.
   A generated-CDO-files push to `main` starts release validation.
   The pipeline regenerates from the same reviewed team sources and fails
   if committed output differs. After validation, the protected
   `cdo-release` environment authorizes the Neon deployment.
   The job builds `+cdo_enterprise_positions` and tests
   `assert_cdo_position_composition`. A manual dispatch may be used
   for an approved redeployment.

**Important:** CI, Sync, and Release are independent GitHub Actions triggered
by Git events/schedule/manual runs. They do not directly call each other.
Team changes lead to a Sync review PR, not an immediate database release.
A failed or unmerged Sync PR blocks the normal deployment sequence.

## Optional manual branch publisher

`.github/workflows/publish-compiled-semantic-models.yml` remains
**manual-only**, and produces a `generated/production` Git branch containing
compiled Team A/C semantic YAML. Use it only if a separately configured dbt
Cloud environment needs that branch; **it is not part of the Neon release
path**, and does not enable the hosted dbt Semantic Layer.

## One-time protected Neon environment setup

Create a GitHub Environment named **cdo-release** with required reviewers and
restrict deployment to `main`. Configure environment secrets:

- `DBT_PG_HOST`, `DBT_PG_USER`, `DBT_PG_PASSWORD`, `DBT_PG_DBNAME`
- `DBT_PG_PORT` (optional; default 5432)

Set `DBT_CDO_RELEASE_SCHEMA` as an environment variable for a dedicated,
isolated POC schema, e.g. `ci_cdo_poc`; the Neon user needs access to create
objects in this schema. The current POC builds upstream dbt seeds in addition
to views, so **do not use a shared production schema**.

Outputs are Neon database objects and GitHub Actions manifest artifacts;
this is **not** a hosted dbt Semantic Layer deployment or direct Power BI
publication. Business certification of currency and as-of-date aggregation
semantics remains separate from structural/data reconciliation.

## Existing limitation

The original CI/optional Publish workflows pin a reviewed CDO governance
commit, whereas Sync/Release check out CDO governance `main`.
For future enterprise use, pin all jobs to one reviewed, versioned governance
artifact to avoid differences between validation and generated releases.
