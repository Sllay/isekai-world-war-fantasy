# Version Plan

## Documents

GDD and architecture use semantic-style versions during development:

- PATCH — clarification or small non-breaking design adjustment.
- MINOR — new system/feature scope or meaningful design expansion.
- MAJOR — fundamental premise/architecture change.

During pre-production, versions remain `0.x`.

## Repository

Git history is the canonical detailed history. Do not create files such as `GDD_final_v2_REAL.md`.

Use:

- current document at stable path;
- local changelog for important document changes;
- Git tags/releases for meaningful project snapshots.

## Suggested Milestone Tags

- `gdd-v0.1`
- `architecture-v0.1`
- `prototype-v0.1`
- `vertical-slice-v0.1`
- later `v1.0.0` for the first production-level release scope.

## Compatibility

Code/module versions and save/data schema versions may evolve independently from GDD version. They should not be forced to share the same number.
