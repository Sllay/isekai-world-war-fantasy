# Design Scope Audit

- **Status:** Active planning aid
- **Updated:** 2026-10-18
- **Purpose:** identify game-design areas whose first production scope is too shallow or fragmented for reliable agent implementation.

## Why This Exists

A strong architecture document cannot compensate for an underspecified product contract.

When a design file says only "support modular building", "creatures have ecology", or "magic is composable", an implementation agent must invent missing behavior, priorities, UX and edge cases. The cheapest technically valid interpretation then tends to look like a prototype even when the code is modular and tested.

This audit therefore distinguishes:

- **scope-complete enough for its current Macro Version**;
- **supported by a deeper architecture/secondary design contract**;
- **shallow and should be expanded before its owning Macro Version**;
- **missing as a dedicated cross-system contract**.

File size is only a warning signal. The real question is whether an implementation agent can determine what the first representative player experience is, what remains canonical, and what may safely be deferred.

## First-Scope Completeness Standard

A major player-facing design domain should normally define, before production implementation:

1. player-visible goal and core loop;
2. canonical entities/state owned by the system;
3. major verbs/actions and state transitions;
4. inputs/outputs and cross-system boundaries;
5. semantic interaction model for mobile/desktop where relevant;
6. data-driven extension points;
7. persistence/server authority expectations where relevant;
8. important failure/invalid states;
9. presentation/feedback requirements that make the feature understandable;
10. mobile/performance constraints;
11. one small representative content set that proves the system;
12. explicit deferrals so "not yet" cannot be confused with accidental omission;
13. acceptance principles distinguishing Engineering Complete from Player Complete.

A document does not need final balance numbers or full launch content to satisfy this standard.

---

# Current Design Document Audit

## Strong / sufficiently developed for current planning

### `ART_DIRECTION.md`

**Status:** Strong.

Already defines visual thesis, palette behavior, character view strategy, modular rigs/layers, equipment visuals, asset metadata, environment consistency, detail budgets, mobile constraints and an asset acceptance workflow.

**Remaining work:** extend the same visual language into a dedicated 3D Material/Surface contract rather than rewriting Art Direction.

### `BAGS_AND_CONTAINERS.md`

**Status:** Strong.

Contains enough behavioral detail to guide real implementation rather than only state intent.

### `ECONOMY_INVENTORY_AGENTS.md`

**Status:** Strong foundation.

Covers important ownership/economy/agent relationships. It will still need integration with NPC/Bot planning and Building production when those Macro Versions activate.

### `ITEM_CONDITION_STACKS_AND_DECAY.md`

**Status:** Strong.

Detailed enough to prevent simplistic "all same item stacks together forever" implementations.

### `ITEM_PERSISTENCE_AND_PROVENANCE.md`

**Status:** Strong.

Provides unusually detailed persistence/identity rules and should remain a source of truth for item custody/history.

### `MOBILE_COMBAT_UI_AND_INVENTORY.md`

**Status:** Strong.

Clearly defines selection versus execution, input contexts, skill pages, targeting families, inventory behavior and mobile acceptance principles.

### `POPULATION_RELATIONSHIPS.md`

**Status:** Good first-scope foundation.

Population, relationships, households, migration, reproduction and fidelity strategy are sufficiently explicit for later architecture work. NPC decision architecture itself is still missing elsewhere.

### `WAR_POPULATION_RESILIENCE.md`

**Status:** Good first-scope foundation.

Strong separation between faction defeat, military state, political state, demographic survival, occupation, surrender, refugees and extinction.

### `LIVE_BATTLE_SIMULATION.md`

**Status:** Good design foundation.

Defines strategic/command/unit/individual layers, morale, surrender and fidelity concepts. It should later connect to the dedicated NPC/Bot decision contract.

---

## Adequate only because another document currently carries the missing detail

### `WORLD.md`

**Status:** Medium by itself, acceptable because `WORLD_SIMULATION.md` and `WORLD_REGION_FOUNDATION.md` provide substantial architecture detail.

**Missing product depth:**

- representative world-generation loop;
- terrain generation model and authoring boundaries;
- biome composition;
- prop/resource placement;
- cave/interior generation direction;
- traversal affordances;
- environmental interactions;
- what makes A2 look/feel like a real world instead of a terrain test.

**Action:** create/expand a World Generation & Environment design contract before Macro Version A2.

### `COMBAT.md`

**Status:** Medium.

The product document is brief, but `COMBAT_FOUNDATION.md`, `COMBAT_ACTIONS.md`, `ENEMY_TARGETING_TELEGRAPHS.md`, and `MOBILE_COMBAT_UI_AND_INVENTORY.md` provide significant implementation contracts.

**Still missing for Player Complete A1:**

- explicit combat feel/feedback contract;
- camera-mode-independent aim/facing behavior;
- hit reaction/stagger/readability expectations;
- death/downed/respawn first-scope decision;
- first representative weapon/action set;
- audio/animation feedback minimum;
- first-scope block/dodge/parry semantics and player feedback;
- exact A1 Player Complete scenario.

**Action:** deepen Combat design before closing A1 player-facing work. Do not rewrite existing combat architecture.

### `PLAYER_FOUNDATION.md`

**Status:** Technically solid for the implemented foundation.

It already keeps camera/presentation local and gameplay state canonical, which is compatible with multiple future camera modes.

**Missing cross-system contract:** top-down and third-person view modes must map into common semantic aim/interact/build intents rather than becoming branches inside Combat/Building.

---

## Shallow — should be expanded before owning Macro Version

### `BUILDING.md`

**Previous status:** Critical/shallow (~1.2 KB).

**Action taken 2026-10-18:** expanded into a first-scope contract covering reusable structural piece families, Snap Graph placement, camera-independent placement, shared Player/NPC/Bot building, blueprints, semi-procedural variation, material separation, damage/repair/raids, rooms/interiors, occlusion/perception, persistence/performance and first-scope acceptance.

**Next technical work:** architecture/schema should be created just-in-time for Macro Version A6, not immediately implemented now.

### `MAGIC.md`

**Status:** Critical/shallow.

It currently establishes composability but does not define enough to build a production magic system safely.

**Needs first-scope closure:**

- canonical spell/action composition model;
- school/element/source distinctions;
- compatibility constraints;
- costs and resource interactions;
- cast/channel/charge lifecycle;
- projectile/beam/field ownership;
- status/effect stacking rules at design level;
- equipment modifiers and mutation boundaries;
- acquisition/progression relationship to classes/disciplines;
- representative spell set;
- visual/audio readability requirements;
- persistence/network boundary;
- explicit deferrals and acceptance.

**Target:** close before Magic becomes an A5 implementation dependency.

### `CREATURES_TAMING.md`

**Status:** Critical/shallow.

It lists useful ecology/taming concepts but does not define the actual simulation or interaction contract.

**Needs first-scope closure:**

- species vs individual state;
- needs/territory/social group state;
- senses/perception;
- behavior/decision interface;
- reproduction lifecycle;
- spawn/materialization versus persistent population;
- taming progress/state machine;
- trust/fear/imprinting ownership;
- commands/companionship after taming;
- injury/death/persistence;
- representative species examples;
- LOD behavior;
- acceptance scenario.

**Target:** close before A4/A5 creature implementation.

---

# Architecture Documents That Are Intentionally or Dangerously Thin

## `PERFORMANCE.md`

**Status:** Too shallow for a mobile-first project that is already implementing production systems.

Principles are correct, but there are no concrete first budgets or measurement contract.

**Needs near-term closure:**

- representative Android device class;
- target frame-time/FPS modes;
- CPU/GPU/memory budgets;
- draw-call/material/particle expectations;
- active actor/NPC budgets;
- physics/navigation budgets;
- streaming/chunk residency budgets;
- simulation tick/LOD frequency guidance;
- profiling capture/report format;
- regression thresholds.

Exact numbers can evolve, but agents need initial budgets to know whether an implementation is acceptable.

## `NETWORKING.md`

**Status:** Intentionally open and shallow.

This is acceptable **for A1-A6** as long as systems preserve clear authority/state boundaries. It becomes unacceptable before Macro Version A7.

**Do not prematurely choose hosting/protocol now.** Before A7, run technical evidence and then freeze an ADR plus a deeper networking contract.

## `DATA_ARCHITECTURE.md`

**Status:** Good principle, shallow operational contract.

It needs eventual concrete schema/version/reference rules, but existing production systems already demonstrate some of those practices.

**Near-term addition needed:** Material/Resource/Gem definitions will require clearer content schema and composition rules.

## `EVENT_SYSTEM.md` / `MODULE_SYSTEM.md`

**Status:** Short, but lower risk because the corresponding Core implementation and existing feature architecture already provide concrete behavior.

Expand only when measured ambiguity appears; do not create documentation volume for its own sake.

---

# Missing Dedicated Contracts

These subjects are important enough that leaving them scattered across the GDD/skills/other files creates a high risk of inconsistent agent implementation.

## 1. View / Aim / Interaction / Perception

**Priority:** Immediate cross-system contract.

Must define:

- top-down and future third-person camera modes as presentation/input adapters;
- shared semantic AimIntent/InteractionIntent/PlacementIntent concepts;
- camera-independent Combat/Building/Interaction;
- world cursor versus center-crosshair behavior;
- perception versus render visibility;
- interiors/windows/doors/line-of-sight;
- top-down contextual occlusion;
- unknown information protection;
- NPC/Bot use of the same perception truth where appropriate.

This contract should be established before camera-specific assumptions spread further through A1/A2.

## 2. NPC / Player-like Bot AI

**Priority:** High before A4.

This is a major product pillar and currently lacks one dedicated design contract.

It should define at least:

- difference between civilian/role NPCs, important authored NPCs and player-like Bots;
- shared capabilities with Players;
- needs/goals/tasks;
- knowledge/perception/memory;
- traits/personality/values;
- contextual action selection;
- planning hierarchy;
- schedule/work/social behavior;
- combat/flee/surrender behavior;
- resource/inventory/building use;
- bot progression/equipment/companionship;
- deterministic/scenario testing;
- simulation LOD;
- anti-cheat/server authority implications;
- no-deception rule: Bots may feel companion-like but are not represented as human users.

## 3. RPG Identity — Race / Class / Discipline / Progression

**Priority:** High before A5.

The GDD states the direction but no dedicated design contract currently establishes:

- what race owns versus culture/origin;
- class foundation versus discipline/school;
- progression resources/levels/mastery;
- stat growth;
- ability acquisition;
- talent structure;
- respec/change rules;
- equipment requirements;
- cross-class learning boundaries;
- representative first race/class set.

## 4. Materials / Resources / Ores / Gems / Surface Profiles

**Priority:** High before A2/A3/A6, with a small foundation useful earlier for asset tooling.

Needs to separate:

- raw resource identity;
- refined material identity;
- grade/purity/alloy;
- physical/gameplay properties;
- construction compatibility;
- crafting/tool/weapon use;
- gem/socket/modifier role;
- visual MaterialProfile used by the future Art/Asset API;
- 3D surface texture/material generation rules;
- provenance/region quality where relevant.

This is where straw, logs, worked wood, stone, blackstone-like stone, raw/refined iron, silver, mithril/fantasy alloys, ruby, emerald, diamond, amethyst, Paraiba tourmaline, imperial topaz and other content can later be added without hard-coded branches.

## 5. World Generation & Environment

**Priority:** Before A2.

Should define the first representative generated/authored hybrid world loop:

- terrain height generation;
- biome masks/rules;
- rivers/water where applicable;
- caves;
- roads/settlements/landmarks;
- resource/prop/ecology placement;
- authored points inside procedural regions;
- deterministic seeds;
- streaming/chunks;
- navigation/collision generation;
- destruction/persistence boundaries;
- representative A2 region acceptance.

---

# Recommended Closure Order

Do **not** fully spec every future system before writing more game code. Use the same just-in-time principle as engineering, but require the owning design contract to be first-scope complete before a Macro Version asks Codex to implement it.

### Cross-system contracts to close now

1. View / Aim / Interaction / Perception.
2. Combat first-scope player experience for A1.
3. Performance first budgets/measurement contract.
4. Materials/Surface Profile foundation sufficient for A1 assets and upcoming A2.

### Before A2

5. World Generation & Environment.
6. deeper Materials/Resources integration.

### Before A4

7. NPC / Player-like Bot AI.
8. Creatures/Taming if creatures participate materially in the representative living world.

### Before A5

9. RPG Identity / Race / Class / Progression.
10. Magic first-scope contract.

### Before A6

11. Building technical architecture/schema derived from the now-expanded `BUILDING.md`.

### Before A7

12. Networking evidence + final architecture ADR + deeper replication/session contract.

---

# Agent Rule Derived From This Audit

A player-facing Macro Version should not begin implementation from a one-paragraph design placeholder.

Before the implementing agent starts a major domain, Technical Design should verify that the owning design contract satisfies the First-Scope Completeness Standard above. If the contract is intentionally incomplete, the Mission Contract must explicitly identify the unknowns and prevent Codex from silently choosing permanent product behavior.

The objective is not maximum documentation. The objective is **minimum ambiguity sufficient for production-quality implementation**.
