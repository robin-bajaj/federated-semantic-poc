# Federated dbt Semantic Layer POC

Team A (Equity) and Team C (Fixed Income) independently author position models and opt into the CDO-governed `cdo.position` v1 contract. The [CDO governance repository](https://github.com/robin-bajaj/cdo-semantic-governance) owns the contract, pre-parse inheritance compiler and validation rules. Custom `semantic_inheritance.extends` metadata is **not native dbt syntax**; it must be compiled before dbt parses or deploys the models.

## CDO Position snapshot lifecycle

1. **Team PR — contract CI:** `.github/workflows/cdo-semantic-ci.yml` compiles Team A/C's inherited semantics in a disposable checkout, validates the common CDO Position contract and parses the project. For same-repository PRs, it seeds and builds only participating Team A/C staging models in an isolated Neon CI schema.
2. **PR candidate — reusable Sync preview:** Only after CI succeeds, the `preview-cdo-snapshot` job calls the read-only reusable `.github/workflows/generate-cdo-position-snapshot.yml` with the PR's **exact head commit SHA** and repository. The generator compiles, composes, regenerates and parses the proposed CDO SQL/YAML once. It uploads both files as a 14-day GitHub Actions artifact; this path has read-only caller permissions and **cannot push a branch or deploy**.
3. **Team merge — Sync publish:** When the team's semantic YAML or generator changes on `main`, `.github/workflows/sync-cdo-position-snapshot.yml` calls the **same reusable generator** with the approved `main` commit (also available manually or through the weekday schedule). It regenerates both complete CDO artifacts rather than appending to a previous version:
   - `models/semantic_models/team_cdo/generated/cdo_enterprise_positions.sql` — unioned CDO Position SQL view
   - `models/semantic_models/team_cdo/generated/cdo_enterprise_positions.yml` — native CDO Position semantics and metrics
4. **CDO review snapshot:** If the regenerated pair differs from `main`, the Sync publishing job creates or updates branch `automation/sync-cdo-position-snapshot` and its review PR. The PR includes federated source and governance commit IDs. Team A/C authored YAML is never rewritten in Git. No changes result in no snapshot PR.
5. **Approved CDO snapshot — Release:** Once the CDO review PR is merged into `main`, `.github/workflows/cdo-semantic-release.yml` revalidates the deterministic outputs and builds the CDO view and upstream dependencies in the Neon release schema. It does not itself deploy the hosted Semantic Layer.
6. **Deployment-ready branch — Publish:** Manually run `.github/workflows/publish-compiled-semantic-models.yml`; it compiles Team A/C YAML and publishes the complete approved project, including the reviewed generated CDO files, to `generated/production`.
7. **dbt Cloud → Tableau:** Run the hosted dbt deployment job tracking `generated/production`, then refresh or reconnect Tableau's dbt Semantic Layer data source.

The **single reusable generator** owns CDO SQL/YAML generation. CI calls it for a read-only PR preview; post-merge Sync calls the same generator and alone has permission to propose a Git-reviewed snapshot. A passing CI check does **not** itself certify a deployed CDO snapshot.

**Ownership:** Team A/C own authored SQL, local semantic fields and metrics. CDO owns its common Position contract and approves generated CDO semantics. The dbt repo's generator owns the native executable CDO view and semantic model. The CDO snapshot is versioned through Git commits on `main`, not through independently maintained snapshots.

**Governance consistency:** CI, Sync, Release and Publish use reviewed CDO governance commit `d04d9f73eb3e239b1007245f840cfbdc56dadc02`. Update all four references together after a reviewed governance change.
