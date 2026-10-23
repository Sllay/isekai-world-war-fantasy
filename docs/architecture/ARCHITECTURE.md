# Technical Architecture

- **Version:** 0.2.0
- **Status:** Production direction / evolving by evidence
- **Updated:** 2026-10-18

## Objective

Permitir que um jogo de escopo grande seja desenvolvido em **Macro Versions coerentes**, com módulos testáveis/substituíveis, sem criar fundações descartáveis nem deixar decisões críticas de autoridade/performance para o fim.

## Product Architecture Invariants

1. `Gameplay -> Foundation -> Core` remains the preferred dependency direction.
2. Composition/contracts/data are preferred over monolithic managers and deep inheritance.
3. Gameplay-critical production state is **online-first in authority** from A1 onward.
4. Clients request gameplay; AuthorityHost owns canonical persistent/competitive outcomes.
5. Official and private servers share the same domain/authority invariants.
6. Mobile client and `private_4gb` server constraints are first-class product requirements.
7. Simulation fidelity scales with relevance; logical world size must not imply full per-frame actor cost.
8. Presentation/camera/UI are not gameplay authority.
9. Persistent identity/custody cannot be reconstructed from presentation/archetype defaults.
10. Profiling/evidence decides optimizations and capacity claims.

See `SERVER_AUTHORITY.md`, `PERFORMANCE.md`, `NETWORKING.md` and ADR-0016.

## Architectural Layers

### Core

Responsável apenas por infraestrutura indispensável:

- lifecycle;
- module registry/loader;
- event bus;
- stable entity identity;
- clocks/ticks;
- save/load foundation;
- authority/network foundation contracts;
- data registry;
- logging/diagnostics;
- feature/build flags;
- service/contracts registry.

Core não conhece regras específicas de domesticação, magia, guerra, farming, quests ou outra feature de gameplay.

### Foundation Modules

Sistemas reutilizados por grande parte do gameplay:

- entities/components/capabilities;
- attributes/status;
- movement;
- semantic intents/interactions;
- inventory/custody foundation;
- combat/action foundation;
- faction/relationship identity;
- world/region state foundation;
- authority adapters/gateways where cross-system infrastructure belongs.

A Foundation pode definir contratos genéricos; não deve virar um saco de regras específicas de conteúdo.

C1-R1-P3 adds `WorldGenerationModule` as the genesis/canonical-chunk capability
beside the existing World/Region ownership. Its pure `ChunkLedger` owns validated
baked records and revisioned mutations. `ChunkStreamer` is a scene adapter that
loads canonical data, registers existing P2 resources and materializes bounded
terrain; it does not create another world state or resource service.

### Gameplay Modules

Features independentes e expansíveis:

- war;
- quests/contracts;
- professions;
- economy;
- building;
- taming;
- crime;
- diplomacy;
- bosses;
- farming;
- magic;
- crafting;
- trading;
- infiltration;
- ecology.

P3's `LivingModule` composes persistent actor data, the existing Combat/Actions/
Items capabilities and typed RPG/faction definitions. `LivingRuntime` only adapts
relevant actors to transient bodies, targeting and authority hosts. Logical actors
remain in the domain layer when their bodies unload.

## Client / Authority Separation

The Godot client owns presentation and human input adaptation.

Conceptual boundary:

```text
hardware input / camera
        -> semantic intent
        -> AuthorityGateway
        -> AuthorityHost validation + domain simulation
        -> canonical facts / state revisions
        -> relevance-filtered replication
        -> client reconciliation / presentation
```

Client-side prediction may run compatible rules for responsiveness, but it remains a prediction mirror.

Do not expose production client paths that authoritatively commit final damage, health, money, item custody, cooldown completion, Building success or persistent world transforms.

Development without a remote server uses LocalAuthorityHost/loopback semantics rather than an automatic offline bypass.

## Server Representation

The persistent authoritative world should remain independent from Godot SceneTree presentation.

Current concrete candidate (ADR-0005): Rust + data-oriented ECS/service, subject to proof.

Important properties independent from the final stack:

- persistent stable IDs separate from transient runtime handles;
- compact component/state representation;
- fixed active simulation tick;
- scheduled/batched lower-fidelity systems;
- spatial/relevance indices;
- authority-owned persistence;
- metrics/observability from the beginning.

## Dependency Rule

Preferred flow:

`Gameplay -> Foundation -> Core`

Core never depends on Gameplay.

Authority/transport adapters depend on domain contracts rather than forcing combat/world/inventory to know socket/RPC details.

Circular dependencies are architectural errors. Systems that react to each other use typed events, contracts or shared data definitions.

## Composition over Inheritance

Entities are composed from reusable capabilities/components instead of large class trees.

Examples:

- Health/Combatant capability;
- Movement capability;
- Inventory/Custody capability;
- Faction/Relationship capability;
- Perception/Knowledge capability;
- AI/Planner state;
- Building ownership capability;
- Loot/Harvest profile.

A creature or NPC does not embed every optional system that might interact with it.

## Data-driven Content

Code implements reusable rules; data defines content/configuration.

Adding a compatible creature, item, recipe, material, NPC profile, Bot profile or spell should not require editing central managers.

Private-server customization follows the same rule: validated server data/configuration changes rates/content/presets without forking trust boundaries or arbitrary executable logic.

## Event-driven Integration

Events/facts represent committed or observed domain facts, for example:

- DamageApplied;
- EntityDefeated;
- ItemTransferred;
- TerritoryCaptured;
- ReputationChanged;
- CreatureTamed;
- BuildingDestroyed.

A producer does not know every consumer.

For networked play, **client request** and **authoritative committed fact** are distinct concepts.

## Module Isolation

Each module should declare:

- stable ID;
- version;
- required/optional dependencies;
- provided/required contracts;
- authority ownership of canonical state;
- client intents if relevant;
- events published/consumed;
- data registries;
- persistence state;
- simulation-fidelity behavior where relevant;
- tests/benchmarks.

## Feature and Build Flags

Incomplete/experimental features can be disabled in development without deleting code.

Security/authority is **not** an ordinary gameplay feature flag in release. Production builds cannot enable a `trust_local_client_state` switch.

Development-only LocalAuthorityHost/tooling should be excluded from production client packages where practical.

## Testing Strategy

- unit tests for pure/domain logic;
- integration tests for module contracts;
- authority/adversarial tests for forged/replayed/invalid client commands;
- deterministic scenario tests for systemic behavior;
- test worlds for visual/systemic behavior;
- schema/dependency checks in CI;
- headless Godot/server smoke;
- repeatable client/server performance benchmarks;
- representative mobile acceptance for device-sensitive claims.

## Simulation LOD

Canonical world state can be represented at multiple fidelities:

- **L0 Active:** relevant movement/combat/physics;
- **L1 Reduced Individual:** identity preserved, lower-frequency decisions;
- **L2 Regional/Aggregate:** cohorts/groups/economy/ecology through scheduled state;
- **L3 Latent:** slow/event/analytical long-horizon state.

Promotion/demotion changes representation cost, not reality. Inventory, unique items, relationships and other canonical state must survive fidelity transitions.

The P3 first-scope scheduler has at most 256 logical actors and eight due jobs
per advance. At the current 20 Hz Core step, L0 decisions can run each tick, L1
every five ticks (4 Hz), L2 activity work every twenty ticks and L3 at activity
deadlines. It resolves elapsed activities analytically. L2 currently proves the
regional/activity seam rather than a complete aggregate economy. Up to four
nearby living actors receive runtime bodies; 24m enter/28m leave hysteresis and
chunk relevance govern attachment. Materialization epochs reject stale active
intents after a fidelity change.

NPC decisions combine reactive safety, bounded utility selection and cached
plans. Trusted hearing events and indexed proximity/visibility queries create
knowledge; Node existence grants none. Bots produce canonical semantic intents
through the existing authority host and P1/P2 validators, with the same shared
guard authority. They do not directly settle damage, inventory or XP. Local path
requests are capped at 32 queued/two resolved per tick; current open-terrain
corridors are an adapter seam, not a global navigation mesh.

## Scheduling

Prefer:

- fixed-step L0;
- frequency buckets;
- event wakeups;
- dirty queues;
- deadline/priority scheduled work;
- bounded job budgets;
- analytical elapsed-time catch-up.

Do not continuously tick a large planner/behavior tree for every persistent entity.

A hierarchical timing wheel or other advanced scheduler is adopted only if profiling shows the simpler scheduler becoming material overhead.

## Spatial / Network Relevance

Use region/chunk/cell partitioning plus spatial hashing/AOI for common local relevance.

Combine with owner-only, group, always-relevant and event-specific sets.

Replication uses dirty revisions, frequency tiers and dormancy rather than broadcasting every entity every tick.

Perception can further restrict what information a client is allowed to receive.

P3's `StreamingRelevance` initially uses 32m Region-defined chunks, active radius
one, one prefetch ring, a 25-view cap and twelve ticks of unload hysteresis outside
that ring. Startup establishes the nine nearby collision chunks before Player
physics. Later frames perform at most one materialization/data job and one unload;
dirty canonical mutations must save before their view unloads. Prefetch produces
canonical data without requiring a visible Node for every record.

## Persistence

Canonical persistence belongs to authority.

Persist structured state and explicit transactions; do not infer it from client presentation or template defaults.

Private/local single-host server experiments may use SQLite/WAL; larger official deployments can use a client/server database behind an adapter.

Prefer incremental dirty-state writes/snapshots rather than whole-world serialization on the active simulation tick.

P3 concretely uses generate → validate → bake → atomic commit → install. Persisted
chunk requests never call the generator, even on a fresh process; generator
version incompatibility/corruption fails visibly. Immutable base data and mutable
deltas share the existing Core save/prepare/restore contract. Generic immutable
record pages prevent unchanged chunk/actor rewrites while the ordinary atomic
manifest remains the commit point. Full capture/validation still covers the
bounded first-scope snapshot; larger storage backends must preserve this logical
contract. See [ADR-0019](../adr/ADR-0019-canonical-world-chunks-and-living-actors.md).

## Failure and Load Policy

Optional module failure should not silently corrupt the game.

Loader/startup should validate manifests, references, server profiles and required contracts before accepting the world.

Under server load, reduce optional detail/frequency before correctness:

1. telemetry/detail;
2. low-priority replication;
3. distant decisions;
4. active-fidelity promotion;
5. cosmetic environment simulation;
6. preserve command validation, item custody and committed transactions as long as possible.

If gameplay-critical budgets cannot be preserved, surface an overload state rather than silently running invalid partial logic.

## Performance Principles

- mobile/Web first client;
- low-resource private-server profile first-class;
- batch/data-oriented hot paths;
- avoid universal per-entity per-frame updates;
- streaming and relevance by region/chunk/cell;
- presentation separated from simulation;
- pooling/buffer reuse where measured;
- aggregate distant state;
- profile before micro-optimization;
- do not claim player/entity capacity without benchmark evidence.

Concrete v0 budgets live in `PERFORMANCE.md`.

## Change Rule

If adding a feature requires unrelated edits across many systems, or if a local shortcut would later require an online-authority rewrite, stop and review the contract before continuing.
