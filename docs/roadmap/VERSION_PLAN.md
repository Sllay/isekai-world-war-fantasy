# Version Plan

## Active Chapter / Run / Part

The current Game Director mission is **C1-R1-P2 — Items, Resources & Survival
Foundation**, Chapter 1 / Run 1 / Part 2, issue #10. It continues directly from
the completed, Android-accepted P1 remote branch. Its scoped contract/status and
evidence live in `docs/missions/C1_R1_P2_FOUNDATION.md`. Run 1 proves extensible
architecture and an integrated playable loop; Run 2 refines final Chapter 1
content/UI/balance. P1 remains recorded in its mission; it is not restarted. A1-A8
below remain domain planning/history, not an instruction to create micro releases.

## Product planning versions

Development is organized by **Macro Versions** that represent coherent playable outcomes, not isolated technical slices.

Recommended naming during the playable-foundation pass:

- `A1 Combat & Player Gameplay`
- `A2 World & Exploration`
- `A3 Inventory, Items & Survival`
- `A4 Living NPCs & Player-like Bots`
- `A5 RPG Identity`
- `A6 Building, Economy & World Transformation`
- `A7 Multiplayer / Server Foundation`
- `A8 Game Shell`

Internal implementation groups may use task IDs such as `A1/G1`, `A1/G2`, etc., but those groups are not separate product releases.

## Completion status

A Macro Version can use these status labels:

- `PLANNED`
- `ACTIVE`
- `ENGINEERING_COMPLETE`
- `PLAYER_COMPLETE`
- `ACCEPTED`

`ENGINEERING_COMPLETE` means scoped technical implementation/tests pass. `PLAYER_COMPLETE` means the player-visible Mission Contract and `SHIPPABLE_DEFINITION_OF_DONE.md` pass. `ACCEPTED` means the required BK/device acceptance for that version has also passed.

## Document versions

GDD and architecture documents may continue to use semantic-style versions during development:

- PATCH — clarification or small non-breaking design adjustment.
- MINOR — new system/feature scope or meaningful design expansion.
- MAJOR — fundamental premise/architecture change.

During pre-release development, document versions may remain `0.x`.

## Repository

Git history is the canonical detailed history. Do not create files such as `GDD_final_v2_REAL.md`.

Use:

- current document at stable path;
- local changelog for important document changes;
- branches/PRs for implementation work;
- Git tags/releases for meaningful integrated snapshots.

## Suggested integrated tags

Examples:

- `foundation-m1.3`
- `playable-a1-combat`
- `playable-a2-world`
- `playable-a4-living-world`
- later `vertical-v0.1`
- later `v1.0.0` for the first production release scope.

Do not create a tag for every internal task/checkpoint.

## Compatibility

Code/module versions and save/data schema versions may evolve independently from Macro Version names and GDD versions. They should not be forced to share the same number.
