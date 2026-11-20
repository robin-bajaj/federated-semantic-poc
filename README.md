# Federated dbt Semantic Layer POC

Team A (Equity) and Team C (Fixed Income) independently author position models and opt into the CDO-governed `cdo.position` v1 contract. The [CDO governance repository](https://github.com/robin-bajaj/cdo-semantic-governance) owns the contract, pre-parse inheritance compiler and validation rules. Custom `semantic_inheritance.extends` metadata is **not native dbt syntax**; it must be compiled before dbt parses or deploys the models.

## CDO Position snapshot lifecycle

1. **Team PR — Validate:** `.github/workflows/cdo-semantic-ci.yml` compiles inherited team YAML in a disposable checkout, validates the CDO contract, parses the project and builds selected models in an isolated Neon CI schema for same-repository PRs. CI does **not** publish a snapshot.
2. **Team merge — Sync:** `.github/workflows/sync-cdo-position-snapshot.yml` runs when Team A/C semantic YAML or the CDO generator changes on `main`; it can also run manually or on its weekday schedule. It compiles both teams, validates the composed catalog, and deterministically generates **both** native CDO files:
   - `models/semantic_models/team_cdo/generated/cdo_enterprise_positions.sql` (unified Position view)
   - `models/semantic_models/team_cdo/generated/cdo_enterprise_positions.yml` (CDO Position dimensions and metrics)
3. **Initial snapshot or changed snapshot:** The same Sync workflow handles first creation and all subsequent revisions. It regenerates complete files from the latest approved sources, **never appends to an old snapshot**. If they differ from `main`, it creates or updates the `automation/sync-cdo-position-snapshot` branch and opens/updates a CDO review PR. The PR records the federated source and governance commit IDs. If nothing changes, no PR is created.
4. **CDO snapshot merge — Release:** After approval and merge to `main`, `.github/workflows/cdo-semantic-release.yml` checks that the committed generated files match reproducible output and builds the governed CDO view with its upstream models in Neon. Release does not directly deploy the hosted Semantic Layer.
5. **Deployment branch — Publish:** Manually run `.github/workflows/publish-compiled-semantic-models.yml`. It compiles Team A/C's reference-only YAML and publishes a deployable project to `generated/production`, including the approved generated CDO files already in `main`. This branch is not the snapshot's source of truth.
6. **Hosted Semantic Layer:** Run the dbt Cloud deployment job configured to use `generated/production` and the Neon connection; then refresh/reconnect Tableau to see the updated semantic manifest.

**Ownership:** Team A/C own authored SQL, local semantic fields and metrics. CDO owns its common Position contract and approves generated CDO semantics. The dbt repo's generator owns the native executable CDO view and semantic model. The CDO snapshot is versioned through Git commits on `main`, not through independently maintained snapshots.

**Important:** The CDO governance checkout used for Team PR CI and Publish is pinned to a reviewed commit, while Sync and Release currently read governance `main`. Aligning those revisions is a separate release-consistency improvement.
