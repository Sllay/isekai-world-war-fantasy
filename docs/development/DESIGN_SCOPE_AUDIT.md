# Design Scope Audit

- **Status:** Active planning aid
- **Updated:** 2026-10-18
- **Purpose:** identify game-design/architecture areas whose first production scope is too shallow or fragmented for reliable agent implementation.

## Why This Exists

A strong implementation agent cannot compensate for an underspecified product or authority contract without inventing behavior.

The target is **minimum ambiguity sufficient for production-quality implementation**, not maximum documentation.

## First-Scope Completeness Standard

A major player-facing domain should normally define before production implementation:

1. player-visible goal/core loop;
2. canonical entities/state;
3. major verbs/state transitions;
4. cross-system boundaries;
5. semantic interaction model;
6. data-driven extension points;
7. persistence/authority expectations;
8. important invalid/failure states;
9. presentation/feedback minimum;
10. mobile/server performance constraints;
11. small representative proof/content set;
12. explicit deferrals;
13. Player Complete acceptance principle.

Final balance numbers or launch-scale content are not required.

---

# Strong / First-Scope Ready

## Art / inventory / economy / persistence family

The following already provide sufficiently detailed first-scope direction for their current planning role:

- `ART_DIRECTION.md`;
- `BAGS_AND_CONTAINERS.md`;
- `ECONOMY_INVENTORY_AGENTS.md`;
- `ITEM_CONDITION_STACKS_AND_DECAY.md`;
- `ITEM_PERSISTENCE_AND_PROVENANCE.md`;
- `MOBILE_COMBAT_UI_AND_INVENTORY.md`;
- `POPULATION_RELATIONSHIPS.md`;
- `WAR_POPULATION_RESILIENCE.md`;
- `LIVE_BATTLE_SIMULATION.md`.

## `BUILDING.md`

**Status:** First-scope closed 2026-10-18.

Defines ARK-like structural pieces, Snap Graph placement, camera-independent placement, shared Player/NPC/Bot/world-authored construction, blueprints, semi-procedural variation, material separation, construction states, damage/repair/raid boundaries, rooms/interiors, occlusion/perception, persistence/performance and acceptance.

Technical architecture/schema should be created just-in-time for A6.

## `VIEW_INTERACTION_PERCEPTION.md`

**Status:** First-scope closed 2026-10-18.

Defines top-down and third-person as view/input adapters over shared semantic intents, Aim/Interaction boundaries, camera-independent Combat/Building, physical existence vs current perception vs knowledge, room/interior visibility, contextual cutaway, evidence/tracking and NPC/Bot perception boundaries.

## `NPC_BOT_AI.md`

**Status:** First-scope closed 2026-10-18.

Defines Resident NPC vs Important NPC vs Player-like Bot, shared gameplay capabilities, layered decision architecture, needs/professions/households, memory/relationships, inventory/property, death/corpse/scavenging, evidence/trails, economic consequences, unique-item interaction, simulation LOD and a representative AI proof.

Implementation remains deferred until A4 except for reusable contracts needed earlier.

## `RPG_IDENTITY_PROGRESSION.md`

**Status:** First-scope closed 2026-10-18.

Defines race/origin/faction separation, provisional race families, race/class data contracts, class role taxonomy, disciplines, world-distributed ability learning, progression lanes, Bot starting profiles, faction social context and a representative A5 proof.

Names/numbers remain intentionally provisional and data-driven.

## `MATERIALS_RESOURCES_CRAFTING.md`

**Status:** First-scope closed 2026-10-18.

Defines material families/variants, wood/hide/fur/ore/gem taxonomy, material-selectable recipes, tool capability gates, resource nodes, cave-depth geology, breakable barriers, Loot/Harvest Profiles, station progression, diagrams/recipe knowledge, economy/persistence and representative proof.

## `WORLD_GENERATION_ENVIRONMENT.md`

**Status:** First-scope closed 2026-10-18.

Defines deterministic world creation plus persistent deltas, continental shape, constrained natural terrain, hydrology/waterfalls, biome placement, settlement suitability/minimum-count remediation, strategic capitals, modular settlements, caves/depth/resource geology, bounded terrain modification, props, streaming boundary and representative A2 proof.

## `SERVER_AUTHORITY.md` + ADR-0016

**Status:** Immediate cross-system authority contract closed 2026-10-18.

Defines online-first authority from A1 onward:

- client sends semantic command/intent rather than final outcome;
- canonical movement/combat/inventory/world state belongs behind AuthorityHost;
- client prediction/reconciliation is non-authoritative;
- CombatService/ActionExecutor remain reusable deterministic domain logic owned by authority;
- LocalAuthorityHost provides development without a client-side offline bypass;
- official/private servers share trust boundaries;
- command sequence/replay/rate validation;
- interest management and persistence boundaries;
- adversarial authority acceptance proofs.

This closes the earlier ambiguity where server authority existed in research ADRs but current gameplay code could still look locally authoritative.

## `SERVER_CONFIGURATION.md`

**Status:** First-scope server product/customization contract closed 2026-10-18.

Defines official vs private hosting on the same server core, `private_4gb` target profile, world/rate/ecology/NPC/Bot/build/raid customization, custom data-defined NPC/Bot profiles, safe special-NPC removal/migration, versioned rule profiles, hard safety limits and configuration/save portability.

## `PERFORMANCE.md`

**Status:** Performance budgets v0 closed 2026-10-18.

Now defines measurable first targets rather than generic optimization principles:

- 4 GB mid-range mobile reference floor;
- 30 FPS/33.3 ms minimum stable target;
- provisional client memory budgets;
- `private_4gb` headless server reference;
- provisional 20 Hz private authority tick and 30 Hz stronger/official proof target;
- L0-L3 scheduling bands;
- fixed-step + deadline/frequency/dirty/event scheduler strategy;
- AI/path job budgets;
- layered navigation;
- AOI spatial hashing/replication budgets;
- server RSS targets;
- SQLite WAL local/private persistence direction;
- load-shedding order;
- repeatable client/server benchmark scenarios and regression gates.

Exact values remain subject to real profiling, but agents now have a concrete target and measurement contract.

## `NETWORKING.md`

**Status:** Authority and replication model first-scope closed; concrete transport/scale remains proof-driven.

The document now specifies semantic command ingress, movement prediction/reconciliation boundary, combat authority, durable vs replaceable delivery classes, AOI/relevance, simulation-LOD replication, reconnect/resync and security invariants.

Transport choice is still intentionally not final: ADR-0007 remains a proof candidate.

---

# Adequate Because Deeper Architecture Exists

## `WORLD.md`

Medium by itself, supported by `WORLD_SIMULATION.md`, `WORLD_REGION_FOUNDATION.md` and `WORLD_GENERATION_ENVIRONMENT.md`.

Remaining pre-A2 work is mainly technical algorithm/schema implementation and measured performance, not missing product direction.

## `PLAYER_FOUNDATION.md`

Technically solid for current local implementation and compatible with semantic intents/view adapters. The current local PlayerMotor state must be integrated behind the authority/prediction boundary defined by `SERVER_AUTHORITY.md`; it must not remain production network authority by accident.

## `COMBAT.md`

Medium product doc supported by deep `COMBAT_FOUNDATION.md`, `COMBAT_ACTIONS.md`, `ENEMY_TARGETING_TELEGRAPHS.md`, `MOBILE_COMBAT_UI_AND_INVENTORY.md`, `VIEW_INTERACTION_PERCEPTION.md` and now `SERVER_AUTHORITY.md`.

**A1 design blocker closed by the Game Director's accepted first-scope in COMBAT.md:**

- explicit combat feel/feedback contract;
- hit reaction/stagger/readability expectations;
- first-scope death/downed/respawn behavior;
- representative weapon/action set;
- audio/animation feedback minimum;
- first-scope block/dodge/parry semantics and feedback;
- exact A1 Player Complete scenario.

The mission is now ACTIVE and includes authority integration, representative feedback
and the integrated victory/death/respawn scenario. This closes design readiness;
it does not pre-approve Player Complete or Android feel/performance.

---

# Still Shallow / Future Closure Required

## `MAGIC.md`

**Status:** Critical/shallow before A5.

Needs canonical spell/action composition, source/school/element distinction, compatibility rules, cast/channel/charge lifecycle, projectile/beam/field ownership, status stacking, equipment mutation boundaries, progression relationship, representative spells, presentation minimum, persistence/network boundaries and acceptance.

## `CREATURES_TAMING.md`

**Status:** Critical/shallow before creature-heavy A4/A5 work.

Needs species vs individual state, senses/perception, needs/territory/social groups, behavior interface, reproduction, materialization/LOD, taming state machine, trust/fear/imprinting, companionship commands, injury/death/persistence and representative species scenarios.

---

# Current Closure Order

## Before releasing Codex A1 mission

1. **Closed:** Combat first-scope player experience / feel contract accepted by the Game Director; the A1 mission is ACTIVE.

Performance, authority, View/Interaction/Perception and initial Materials are now first-scope closed.

## During A1 implementation

2. Integrate the first real AuthorityGateway/LocalAuthorityHost seam around current deterministic Player/Combat systems.
3. Prove forged client outcomes cannot mutate canonical combat state.
4. Preserve external Rust/transport implementation as a proof/adapter task rather than duplicating Combat domain code.

## Before A2 implementation

5. Convert `WORLD_GENERATION_ENVIRONMENT.md` into concrete generation/streaming algorithms and schemas.
6. Create Material/SurfaceProfile schemas for representative A2 assets.

## Before A4 implementation

7. Convert `NPC_BOT_AI.md` into actor/planner/memory/knowledge architecture and scenario-test schemas.
8. Deepen `CREATURES_TAMING.md` if creatures materially participate in the representative living-world version.

## Before A5 implementation

9. Convert `RPG_IDENTITY_PROGRESSION.md` into concrete schemas/progression graphs.
10. Deepen `MAGIC.md`.

## Before A6 implementation

11. Derive Building architecture/schema from `BUILDING.md` and Materials contracts.

## Before A7 productization

12. Finish transport/network proof evidence and choose/freeze concrete production transport/session topology.
13. Package private server/config/admin workflow and official deployment/operations.

A7 is not the point where A1-A6 become authoritative.

---

# Agent Rule

A player-facing Macro Version must not begin from a one-paragraph design placeholder, and a gameplay-critical system must not be implemented as client-authoritative merely because the external server transport is not finished yet.

If a required product/authority decision remains unresolved, the Mission Contract must identify it explicitly rather than letting Codex silently choose permanent behavior.

The target is a project where an implementation agent can answer **what must exist, what owns the state, what may vary, what may be deferred, how it performs, and what Player Complete means** without inventing the game's identity.
