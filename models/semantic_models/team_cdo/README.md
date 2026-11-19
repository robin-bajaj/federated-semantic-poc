# CDO semantic composition catalog

The CDO validator repository owns the authoritative Position contract and the
validated, generated composition catalog. This folder stores a **read-only
snapshot** inside the dbt project:

- `generated/cdo_enterprise_positions.catalog.txt` — YAML-formatted composition
  metadata saved as `.txt` because it is **not native dbt YAML**.
- `enterprise_metrics.yml` (parent directory) — existing native dbt derived metric.

The catalog preserves the complete Team A and Team C semantic model mappings,
CDO-inherited fields, team-specific fields (`mtm`, `cash`, `settled_cash`),
metric definitions, entity aliases, and enterprise metric metadata.

## Sync

The workflow `.github/workflows/sync-cdo-catalog.yml` can run manually using
GitHub Actions → **Sync generated CDO catalog** → Run workflow. It also checks
weekday mornings for changes. It fetches the **published and validated**
catalog from `robin-bajaj/cdo-semantic-governance`, validates expected contract
and team names, then opens a review pull request if content changed.

The file is **catalog metadata only**, not an automatically queryable combined
semantic model. Generating native dbt execution artifacts (such as a CDO
Position view and semantic model) requires a separate compiler stage. Don't
rename the catalog to `.yml` under `models/` because dbt would try to parse
its custom top-level keys.
