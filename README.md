# Federated dbt Semantic Layer POC

Team A (Equity) and Team C (Fixed Income) independently author their Position models in the federated dbt repository. The [CDO governance repository](https://github.com/robin-bajaj/cdo-semantic-governance) owns the enterprise `cdo.position` v1 contract, semantic inheritance compiler, validation, composer, and generator for native dbt CDO SQL/YAML.

The teams' `config.meta.semantic_inheritance.extends: cdo.position` declaration is **custom** metadata, not native dbt syntax. It must be compiled before a dbt build or hosted deployment.

## Two workflows, one manual promotion point

1. **Team A/C PR to `main` — validation only.** `.github/workflows/cdo-semantic-ci.yml` checks out the proposed team model changes, compiles inheritance in an ephemeral workspace, runs governance tests and validates dbt parsing/semantic contracts. Same-repository PRs also seed and build Team A/C staging SQL against an isolated Neon CI schema to enforce native physical model contracts. CI **does not** generate or commit composite CDO snapshots, push deployment branches, or release.
2. **Human approves and merges team PR into `main`.** No automatic Sync, CDO snapshot PR, release, or production publishing is triggered by this merge.
3. **Production promotion trigger:** If `generated/production` exists, manually merge approved `main` into it using a reviewed GitHub PR (or controlled Git merge/push). The resulting push automatically triggers `.github/workflows/publish-compiled-semantic-models.yml` (**Promote CDO Semantic Models to Production**). If the branch does **not** exist yet, manually run this same workflow from `main` using **Actions → Run workflow** to create it on first successful promotion. Existing branches must contain the latest approved `main` before promotion. The pipeline uses the protected `cdo-release` environment.
4. **Combined promotion pipeline (the former Sync + Release + Publish):** From a **fresh checkout of `main`** (not previously compiled deployment YAML), compile Team A/C inheritance using the pinned CDO governance package; dbt parse; run `semantic.composition` to create `/tmp/current_cdo_catalog.yml`; run `semantic.dbt_generator` to produce the native CDO `cdo_enterprise_positions.sql` and `.yml`; parse and check the semantic manifest; build `+cdo_enterprise_positions` in the protected Neon release schema; then copy and commit the compiled Team A/C YAML and generated CDO SQL/YAML back to **`generated/production` only**, without force-pushing or changing authored `main`.
5. **dbt Cloud → Tableau.** After the promotion completes, run the hosted dbt Cloud deployment job tracking `generated/production` to update its Semantic Layer manifest and then refresh the Tableau connection. This GitHub workflow does **not** directly trigger the hosted job.

### Output ownership

- **`main`:** Independently authored Team A/C SQL and short inheritance YAML. The complete `models/semantic_models/team_cdo/` directory is intentionally absent from authored `main`. CDO definition and generator are in the governance repository.
- **`generated/production`:** Full native dbt project following manual promotion, with compiled Team A/C semantic YAML and current composite CDO SQL/YAML. Only this branch is the deployment source for the hosted dbt job.
- **CDO governance:** `contracts/position_v1.yml` is the source of truth. `cdo_governance.semantic.inheritance`, `compose_cdo`, and `generate_cdo_dbt` are implementation code owned by CDO. The combined promotion workflow writes the validated composition catalog to `artifacts/cdo/position_v1_composition.yml` in `generated/production`, outside dbt's `models/` directory; it is not stored in the governance repo or authored `main`.

**Governance revision:** `ebbfec8868c088750e43089977b7862580be3d40` is pinned in CI and promotion. Update both together after reviewing governance updates.

**Promotion caveat:** An existing branch's manual merge into `generated/production` precedes compilation and validation, so the branch temporarily contains the freshly merged authored YAML until GitHub Actions finishes. Do not configure a hosted dbt Cloud deployment to run automatically on *every* branch push: manually invoke it **after** the promotion succeeds to avoid parsing transient custom inheritance metadata. If the promotion fails, the deployment branch is not ready and should not be deployed.

**First-time creation:** GitHub cannot trigger a branch-specific `push` workflow on a branch that does not exist. The additional `workflow_dispatch` trigger on `main` generates and validates the native output, builds Neon and then creates `generated/production` if absent. For later updates, merge approved `main` into that branch; pushes trigger regeneration. Bot-generated commits do not recursively trigger this workflow.

**Inspectable CDO composition:** Each successful promotion copies the validated Team A/C catalog to `artifacts/cdo/position_v1_composition.yml` in `generated/production`. It includes participants, standardized CDO attributes, aliases, team-specific extensions, and inherited/team metrics. This custom metadata is **not a native dbt semantic model** and must remain outside `models/`. The native dbt artifacts remain `models/semantic_models/team_cdo/generated/cdo_enterprise_positions.sql` and `.yml`.

## Governance package upgrade

The [CDO governance toolkit](https://github.com/robin-bajaj/cdo-semantic-governance) is now a root-level Python project with `contracts/position_v1.yml`, `src/cdo_governance/semantic/`, `src/cdo_governance/validation/`, `tests/`, and `pyproject.toml`. Federated pipelines install the pinned checkout using `pip install ./contract-validator` and run `python -m cdo_governance.semantic.inheritance`, `...composition`, and `...dbt_generator` as appropriate.
