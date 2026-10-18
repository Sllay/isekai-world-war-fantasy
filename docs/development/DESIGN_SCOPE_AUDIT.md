# Design Scope Audit

- **Status:** Active planning aid
- **Updated:** 2026-10-18
- **Purpose:** identify game-design areas whose first production scope is too shallow or fragmented for reliable agent implementation.

## Why This Exists

A strong architecture document cannot compensate for an underspecified product contract.

When a design file says only "support modular building", "creatures have ecology", or "magic is composable", an implementation agent must invent missing behavior, priorities, UX and edge cases. The cheapest technically valid interpretation then tends to look like a prototype even when the code is modular and tested.

The goal is **minimum ambiguity sufficient for production-quality implementation**, not maximum documentation.

## First-Scope Completeness Standard

A major player-facing design domain should normally define, before production implementation:

1. player-visible goal/core loop;
2. canonical entities/state;
3. major verbs/state transitions;
4. cross-system boundaries;
5. semantic interaction model where relevant;
6. data-driven extension points;
7. persistence/authority expectations;
8. important invalid/failure states;
9. presentation/feedback minimum;
10. mobile/performance constraints;
11. small representative proof/content set;
12. explicit deferrals;
13. Player Complete acceptance principle.

Final balance numbers or launch-scale content are not required.

---

# Strong / First-Scope Ready

## `ART_DIRECTION.md`

Strong visual thesis, palette, modular character presentation, asset metadata, environment consistency, mobile detail budgets and acceptance workflow.

## `BAGS_AND_CONTAINERS.md`

Strong behavioral contract for capacity, weight and container behavior.

## `ECONOMY_INVENTORY_AGENTS.md`

Strong foundation for finite inventory/money, actual production flows, guild contracts, NPC inventory and player-like autonomous adventurers.

## `ITEM_CONDITION_STACKS_AND_DECAY.md`

Strong condition/decay/stack model, including compact internal cohorts and lazy evaluation.

## `ITEM_PERSISTENCE_AND_PROVENANCE.md`

Strong custody/provenance contract, unique-item movement, corpse loot correctness, item promotion/demotion and persistent world economy.

## `MOBILE_COMBAT_UI_AND_INVENTORY.md`

Strong semantic mobile interaction contract for selection/execution, targeting, inventory and input contexts.

## `POPULATION_RELATIONSHIPS.md`

Good first-scope population/relationship/household/migration foundation.

## `WAR_POPULATION_RESILIENCE.md`

Good separation of faction defeat, military outcome and demographic/cultural survival.

## `LIVE_BATTLE_SIMULATION.md`

Good strategic/command/unit/individual battle model and fidelity direction.

## `BUILDING.md`

**Status:** First-scope closed 2026-10-18.

Now defines ARK-like structural pieces, Snap Graph placement, camera-independent placement, shared Player/NPC/Bot/world-authored construction, blueprints, semi-procedural variation, material separation, construction states, damage/repair/raid boundaries, rooms/interiors, occlusion/perception, persistence/performance and acceptance.

Technical architecture/schema should be created just-in-time for A6.

## `VIEW_INTERACTION_PERCEPTION.md`

**Status:** First-scope closed 2026-10-18.

Defines top-down and third-person as view/input adapters over shared semantic intents, Aim/Interaction boundaries, camera-independent Combat/Building, physical existence vs current perception vs knowledge, room/interior visibility, top-down cutaway, third-person behavior, evidence/tracking and NPC/Bot perception boundaries.

This closes the major camera-mode ambiguity before it spreads through A1/A2.

## `NPC_BOT_AI.md`

**Status:** First-scope closed 2026-10-18.

Defines Resident NPC vs Important NPC vs Player-like Bot, shared gameplay capabilities, layered decision architecture, needs/professions/households, memory/relationships, inventory/property, death/corpse/scavenging, evidence/trails, bank insolvency consequences, unique-item interaction, simulation LOD and a representative AI proof.

Implementation remains deferred until A4 except for reusable contracts needed earlier.

## `RPG_IDENTITY_PROGRESSION.md`

**Status:** First-scope closed 2026-10-18.

Defines race/origin/faction separation, provisional race families, race/class data contracts, class role taxonomy, disciplines, world-distributed ability learning, progression lanes, Bot starting profiles, faction social context and a representative A5 proof.

Names/numbers remain intentionally provisional and data-driven.

## `MATERIALS_RESOURCES_CRAFTING.md`

**Status:** First-scope closed 2026-10-18.

Defines material families/variants, wood/hide/fur/ore/gem taxonomy, material-selectable recipes, tool capability gates, resource nodes, cave-depth geology, breakable barriers, Loot/Harvest Profiles, station progression, diagrams/recipe knowledge, economy/persistence and representative proof.

This supplies the missing material/surface foundation for Building, A2 world work, crafting and the future Art/Asset API.

## `WORLD_GENERATION_ENVIRONMENT.md`

**Status:** First-scope closed 2026-10-18.

Defines deterministic world creation plus persistent deltas, continental shape, constrained natural terrain, hydrology/waterfalls, biome placement, settlement suitability and minimum-count remediation, strategic capitals, modular settlements, caves/depth/resource geology, bounded terrain modification, props, streaming boundary and a representative A2 world proof.

---

# Adequate Because Deeper Architecture Exists

## `WORLD.md`

Medium by itself, but now supported by `WORLD_SIMULATION.md`, `WORLD_REGION_FOUNDATION.md` and `WORLD_GENERATION_ENVIRONMENT.md`.

Remaining work before A2 is mainly technical architecture/algorithm selection and measured performance, not missing product direction.

## `PLAYER_FOUNDATION.md`

Technically solid for current implementation. Camera remains local presentation state and gameplay state remains canonical, which aligns with `VIEW_INTERACTION_PERCEPTION.md`.

## `COMBAT.md`

Medium product doc supported by deep `COMBAT_FOUNDATION.md`, `COMBAT_ACTIONS.md`, `ENEMY_TARGETING_TELEGRAPHS.md`, `MOBILE_COMBAT_UI_AND_INVENTORY.md` and now `VIEW_INTERACTION_PERCEPTION.md`.

Still missing before Player Complete A1:

- explicit combat feel/feedback contract;
- hit reaction/stagger/readability expectations;
- first-scope death/downed/respawn behavior;
- representative weapon/action set;
- audio/animation feedback minimum;
- first-scope block/dodge/parry semantics and feedback;
- exact A1 Player Complete scenario.

**Action:** deepen Combat design before releasing issue #8.

---

# Still Shallow / Future Closure Required

## `MAGIC.md`

**Status:** Critical/shallow before A5.

Needs canonical spell/action composition, source/school/element distinction, compatibility rules, cast/channel/charge lifecycle, projectile/beam/field ownership, status stacking design, equipment mutation boundaries, progression relationship, representative spells, presentation minimum, persistence/network boundaries and acceptance.

`RPG_IDENTITY_PROGRESSION.md` now provides the surrounding progression contract but does not replace this work.

## `CREATURES_TAMING.md`

**Status:** Critical/shallow before creature-heavy A4/A5 work.

Needs species vs individual state, senses/perception, needs/territory/social groups, behavior interface, reproduction, materialization/LOD, taming state machine, trust/fear/imprinting, companionship commands, injury/death/persistence and representative species scenarios.

`NPC_BOT_AI.md` and `VIEW_INTERACTION_PERCEPTION.md` provide reusable decision/perception boundaries but do not define creature ecology/taming itself.

---

# Architecture Docs Requiring More Depth

## `PERFORMANCE.md`

**Status:** Immediate remaining blocker for design-readiness pass.

Needs first measurable budgets/contract for:

- representative Android hardware class;
- target FPS/frame time;
- CPU/GPU/memory;
- draw calls/materials/particles;
- active actor/NPC counts;
- physics/navigation;
- streaming/chunk residency;
- simulation tick/LOD frequency;
- profiling report format;
- regression thresholds.

Numbers may evolve after profiling, but agents need a target to optimize against.

## `NETWORKING.md`

Intentionally open. Acceptable for A1-A6 if systems preserve authority boundaries. Must be deepened before A7 after technical evidence.

## `DATA_ARCHITECTURE.md`

Good principles but still operationally thin. The new Materials/RPG/NPC contracts will eventually need machine-validatable schemas/registries. Build those just-in-time with their Macro Versions.

## `EVENT_SYSTEM.md` / `MODULE_SYSTEM.md`

Short but currently lower risk because production code already demonstrates concrete contracts. Expand only when measured ambiguity appears.

---

# Current Closure Order

## Before releasing Codex A1 mission

1. **Combat first-scope player experience / feel contract.**
2. **Performance budgets v0 / measurement contract.**

View/Interaction/Perception and initial Materials/Surface direction are now first-scope closed.

## Before A2 implementation

3. Convert `WORLD_GENERATION_ENVIRONMENT.md` into technical generation/streaming architecture and algorithms.
4. Create concrete Material/SurfaceProfile schemas needed by representative A2 assets.

## Before A4 implementation

5. Convert `NPC_BOT_AI.md` into actor/planner/memory/knowledge architecture and scenario-test schemas.
6. Deepen `CREATURES_TAMING.md` if creatures materially participate in the representative living-world version.

## Before A5 implementation

7. Convert `RPG_IDENTITY_PROGRESSION.md` into concrete data schemas/progression graphs.
8. Deepen `MAGIC.md`.

## Before A6 implementation

9. Derive Building architecture/schema from `BUILDING.md` and Materials contracts.

## Before A7 implementation

10. Run networking evidence/proofs, freeze ADR and expand session/replication/server contract.

---

# Agent Rule

A player-facing Macro Version must not begin from a one-paragraph design placeholder.

If a required product decision remains unresolved, the Mission Contract must identify it explicitly and prevent Codex from silently choosing permanent behavior.

The target is not an encyclopedia before code. It is a project where an implementation agent can answer **what must exist, what owns the state, what may vary, what may be deferred, and what Player Complete means** without inventing the game's identity.