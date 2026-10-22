# ADR-0018 — Authoritative item custody and transactional work

- Status: Accepted for C1-R1-P2
- Date: 2026-10-22

## Context

P2 must connect combat loot, owned stock, equipment, gathering, crafting, survival
and save/resume without adding client-owned inventory, a second command validator
or a separate work-action framework. Logical goods must retain real custody and
material state across the integrated loop and future transport changes.

## Decision

Use one bounded InventoryService ledger with stable logical entries and atomic
multi-operation transactions. Distinguish immutable definitions, instance/lot
metadata, legal provenance owner and current holder. Equipment references the
same entries. Merge only compatible metadata; do not average condition/materials.
Finite money is item stock. Known learning and temporary grants have separate
sources and validate the existing persisted ActionLoadout.

One application-composed gameplay module owns persistent aggregate state; Core
remains generic. Typed AuthorityCommandPort extends LocalAuthorityHost's existing
authenticated actor binding, sequence/stale checks and bounded inbox. No client
grant/yield/output/result fields are trusted. Release remote mode still fails
closed without configured transport; there is no offline promotion to authority.

Work uses existing ActionExecutor with a typed capability-effect adapter. One SELF
transactional effect with no extra resource spend is the supported atomic form.
Validate world/tool/stock/capacity at start and commit; missing adapters reject.
Harvest commits seeded yield and reserve coherently; crafting consumes/produces
in one ledger transaction; consumption coordinates ledger removal and canonical
CombatService healing. UI, animation and world meshes never settle outcomes.

Seed actual humanoid carried stock only at world creation. Death transfers it
once; pickup transfers the same custody once. Resource nodes use authored data
and lazy simulation-tick regeneration. No global node poll or failed-request RNG
advance. Explicit 0.3 -> 0.4 migration introduces P2 state once; current missing
data rejects rather than recreating defaults or retroactive loot.

## Consequences

Run 2 can replace technical UI/content, add definitions, recipes, node profiles,
learned/loadout sources and transport adapters without replacing these contracts.
No new CombatService, save engine, client-trust fallback or work executor exists.
The first-scope world has two persistent caches and four nodes; larger populations
need a measured lifecycle/spatial policy. Perishable cohorts, final equipment/skill
UI, economy and external transport remain explicitly outside this Part.

Deterministic adversarial/atomicity tests, migration corruption checks, actual
runtime authority facts and exact fresh-process restore validate the decision.
See [implementation contracts](../architecture/ITEMS_RESOURCES_FOUNDATION.md).
