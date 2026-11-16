# CDO semantic inheritance: authored source and compiled deployment

> **Custom extension / POC**, not dbt-native inheritance and not proof of Power BI connectivity.

## Ownership and branch contract

- `main` is the **only developer-authored source**. Team A and Team C YAMLs contain `config.meta.semantic_inheritance` with an exact CDO name + version, local aliases, and team-specific columns and metrics.
- `robin-bajaj/cdo-semantic-contract-validator` owns `cdo/definitions/position_v1.yml` and the Python compiler. Each team job checks out a **pinned, approved commit** of that repository read-only.
- `generated/production` is an **automatically generated dbt-compatible deployment branch**, not a second hand-maintained source. Never edit it manually or merge it into `main`.
- A team-owned GitHub Actions identity must have `contents: write` to publish this branch. CDO never needs Git write privileges to team-owned repositories.

## How the compiler behaves

The custom `python -m meta_context_validator.compile_semantics` command:

1. Resolves the declared `extends: cdo.position` and version.
2. Inherits CDO `semantic_columns`, including data types, entities, dimensions, descriptions, and `agg_time_dimension`.
3. Resolves locally chosen primary-entity and metric names through `entity_aliases` and `metric_aliases`.
4. Appends team-owned columns and metrics, rejecting attempts to redeclare inherited required columns.
5. Embeds CDO's centrally defined `SUM(profit_loss)` metric in native dbt YAML.
6. Produces the expanded files **only in the CI checkout**. The authoritative `main` files are not altered or committed.

The model still needs SQL staging transformations to map raw field names (e.g., `pnl`) to standardized columns (e.g., `profit_loss`). This semantic compiler does not generate SQL and does not verify actual P&L financial meaning.

## Existing CI vs deployment

- `cdo-semantic-ci.yml`: checks out the compiler, runs tests, compiles, calls `dbt parse` and validates CDO metadata. No Git write permission, no warehouse test.
- `publish-compiled-semantic-models.yml`: **manual opt-in release**. Reads `main`, compiles in the same runner, checks `dbt parse` + CDO contract, and publishes the expanded Team A/C YAML to `generated/production`. It pushes a release commit derived from the current `main` source using a force-with-lease guard so a concurrent publisher cannot silently overwrite it.
- The workflow does not configure dbt Cloud or publish hosted semantic metadata.

## Activating a metric for BI

To activate the generated definition in the hosted dbt Semantic Layer, a dbt Cloud production deployment environment must be configured to use **`generated/production`** as its code branch and have a properly configured warehouse connection and Semantic Layer. Run a successful deployment job with `dbt build` as needed and `dbt parse --no-partial-parse` to refresh semantic artifacts. This must be tested in the actual environment.

Before involving Power BI, query `equity_profit_loss` and `fixed_income_profit_loss` from the **production Semantic Layer**, confirming that they use `SUM(profit_loss)` and that physical warehouse models exist. BI compatibility, permissions and connector prerequisites remain separate tests.

## Production considerations

- A generated branch is a reproducible output, not a hand-edited authoritative source; it still counts as a second **physical Git representation**.
- Every release pins a specific CDO compiler revision; upgrading CDO semantic-contract versions requires explicit adoption and a rebuild.
- Current compiler supports one-level Position inheritance and simple metrics, not arbitrary recursive inheritance or data-quality checks of the underlying warehouse.
- Source YAML in `main` is **not directly parseable** by standard dbt until the custom compiler runs. Standard dbt Studio editing against `main` remains limited.
- Do not direct an existing production dbt Cloud environment to `generated/production` until the generated branch has passed the release workflow, and staging deployment has verified semantic metrics.
- This POC still contains Team A, Team C and CDO **inside one consolidated repository**. Fully independent team repositories are an architectural follow-up.
