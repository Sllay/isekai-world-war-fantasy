# M1.1 — Technical Foundation Research & Candidate Stack

- **Status:** Completed — research/candidate selection
- **Date:** 2026-10-13
- **Scope:** Technology research and architecture selection for M1 proofs
- **Important:** This document selects what M1 will prototype. Production ADRs remain `Proposed` until benchmarks/proofs pass.

## 1. Goal

M1.1 exists to avoid inventing infrastructure blindly. The project should reuse mature ideas already proven in large simulations, online games, game engines and distributed systems, while keeping the implementation small enough for an indie/mobile-first project.

The target is not to use the newest technology merely because it is new. The target is to choose the most appropriate proven technique for each workload, measure it, and preserve escape routes when an assumption fails.

## 2. Executive Decision

### Candidate client

**Godot 4.7.2 stable**, GDScript-first, with the **Compatibility renderer as the Web baseline**.

Reasons:

- free/open source and no future revenue-triggered license dependency;
- strong 2D + 3D editor/tooling;
- Web, Android, iOS and desktop targets;
- 3D spatial world with Sprite3D/2D-looking assets is directly supported;
- Jolt is integrated for 3D physics;
- NavigationServer, HLOD/visibility ranges, MultiMesh, occlusion culling and low-level RenderingServer/PhysicsServer paths already exist;
- team familiarity lowers implementation risk.

The Web target constrains rendering: Godot 4 Web exports use WebGL 2 and the Compatibility renderer. Therefore art/rendering decisions must be validated under Compatibility first, not only Forward+.

### Candidate authoritative server

**Rust + bevy_ecs + Tokio**, independent from the Godot SceneTree.

Godot may still run small headless test servers during experiments, but the production simulation candidate is a data-oriented Rust process.

Reasons:

- server simulation is mostly data, scheduling, transactions and networking rather than rendering;
- archetype ECS gives compact component-oriented processing;
- bevy_ecs can be used standalone and has safe parallel schedule execution for non-conflicting systems;
- Rust provides memory/thread safety without GC pauses;
- Tokio provides mature async I/O/timers/network runtime;
- client and server can evolve independently.

### Candidate persistence

- **M1/local/test worlds:** SQLite, using a current release with the 2026 WAL-reset corruption fix (3.51.3+; prefer latest stable available to the project).
- **Production target:** PostgreSQL 18+ behind a repository/storage interface.

Do not couple gameplay systems directly to SQL tables.

### Candidate networking

- **M1 baseline:** secure WebSocket (`wss`) because it works in Web/native Godot and is simple to prove.
- **M1 experiment / future fast path:** WebTransport over HTTP/3 for reliable streams + unreliable datagrams if Godot Web integration through browser/JavaScript is practical.
- WebRTC is not the primary authoritative-server transport; its P2P/signaling model adds complexity that does not solve our core server-authoritative problem.

### Candidate wire format

Use an explicit versioned schema. **Protocol Buffers is the first candidate**, but Godobuf currently advertises Godot 4.6 compatibility, so Godot 4.7.2 compatibility must be proven before acceptance.

Fallback for M1 is CBOR with explicit message/version schemas if Protobuf integration becomes plugin risk. JSON is acceptable only for early smoke/debug messages, not the final hot path.

## 3. Why Not One Engine for Everything?

A graphical game engine is excellent at scenes, rendering, animation, input, physics and authoring. A persistent world server has a different workload:

- huge amounts of cold data;
- scheduled future events;
- aggregate simulation;
- database transactions;
- authoritative item/economy custody;
- networking relevance;
- deterministic diagnostics;
- long-running memory behavior.

Putting every distant wolf, family, merchant and item into a Godot Node would pay object/SceneTree costs for things that do not need visuals or frame callbacks.

Therefore:

`Godot client/presentation != authoritative simulation representation`

They share contracts and IDs, not object graphs.

## 4. World Representation

### 4.1 Region/cell + local coordinates

Use a logical world partition:

`World -> Region -> Cell/Chunk -> local position`

The server stores stable region/cell identity plus local coordinates. The client materializes only an active spatial bubble.

Do **not** enable double-precision large-world coordinates by default. Godot documentation warns they increase CPU/memory cost, especially on lower-end mobile. For a top-down game, single precision has a much larger practical range than a first-person game.

If Chapter 1 grows beyond comfortable local precision, prefer region-local coordinates/origin shifting/streaming over making every client calculation double precision.

### 4.2 Logical partition is not physical server partition

A village, region or biome is not inherently “one server.” Logical simulation cells must remain movable between processes in the future.

This enables later load balancing/sharding without rewriting gameplay rules.

## 5. Rendering & Mobile/Web Optimization

The optimization rule is **remove work before optimizing work**.

Recommended hierarchy:

1. stream only relevant chunks;
2. visibility/frustum cull;
3. HLOD/visibility ranges;
4. occlusion culling where the environment benefits;
5. batch repeated visuals with MultiMesh/atlases/material reuse;
6. reduce animation/physics frequency by relevance;
7. only then use low-level RenderingServer/PhysicsServer for measured hotspots.

### 5.1 Compatibility-first art budget

Web is WebGL2/Compatibility, so avoid basing the visual identity on features unavailable there.

The project should establish budgets for:

- draw calls;
- transparent layers/overdraw;
- texture memory;
- shader variants;
- active lights/shadows;
- animation count;
- physics bodies;
- visible Sprite3D/mesh instances.

Budgets are measurements, not guesses, and must be measured on representative mobile browsers.

### 5.2 MultiMesh by spatial chunk

MultiMesh can drastically reduce draw-call overhead for repeated props. Do not place the entire world into one MultiMesh because per-instance visibility culling becomes poor. Split instances spatially (chunk/cell/biome batches) so whole groups can be culled/streamed.

Good candidates:

- grass clumps;
- repeated rocks;
- repeated decorative vegetation;
- repeated building detail where compatible.

### 5.3 HLOD

Use hierarchical representations for distant structures/settlements/forests. Distant objects do not need the same node/material/animation structure as close objects.

### 5.4 Occlusion culling

Use it selectively, especially towns/interiors with real occluders. Godot performs occlusion culling on CPU, so it is not free; open fields with little occlusion should rely more on distance/LOD/frustum/streaming.

## 6. Character Visual Pipeline

### Baseline candidate

Use the 3D spatial world for position/collision while characters remain visually 2D-stylized.

Prototype two approaches:

1. modular Sprite3D/quads attached to a Node3D transform hierarchy;
2. texture/polygon deformation only where Compatibility/Web performance remains acceptable.

Do not adopt the current community Godot Rive extension as a core dependency yet; the available integration identifies itself as alpha. Rive remains a design-tool option, not a runtime foundation until tested.

The prototype must prove:

- front/diagonal/side/back directional strategy;
- camera rotation;
- equipment attachment;
- race/body proportion changes;
- procedural/keyed rotation/scale/squash/IK-like adjustments;
- batching/material cost.

## 7. Authoritative Simulation Architecture

### 7.1 Data-oriented ECS

Use archetype/component data for hot simulation state.

Examples:

- Position / RegionRef;
- Needs;
- Health;
- InventoryOwner;
- Faction;
- HouseholdMember;
- Profession;
- CombatState;
- PersistencePriority.

Logic lives in systems, not entity classes.

This follows the same high-level pattern used by modern data-oriented frameworks such as Unreal MassEntity and Bevy ECS: compose data, process matching archetypes/chunks, avoid deep object inheritance.

### 7.2 Command/deferred mutation

Structural changes should generally be deferred/queued between schedule phases rather than mutating archetypes arbitrarily during parallel iteration.

### 7.3 Stable IDs separate from ECS entity handles

ECS handles can be transient. Persistent actors/items/settlements require stable world IDs that survive save/load and possible process migration.

## 8. Hybrid Scheduler — The Core Optimization

Do not give every system the same tick rate.

Use three timing models together.

### A. Fixed-step high-frequency simulation

For active combat/physics around players.

Exact tick rate must be benchmarked; do not hard-code a production promise during M1. Client rendering and server simulation ticks are separate concepts.

### B. Frequency buckets / staggered updates

For near but non-critical systems:

- perception;
- AI reevaluation;
- navigation refresh;
- threat evaluation;
- needs checks.

Spread agents across buckets so thousands of agents do not think on the same frame.

### C. Discrete-event / scheduled simulation

For distant or slow systems:

- hunger thresholds;
- crop completion;
- pregnancies/births;
- migrations;
- caravan checkpoints;
- trade deliveries;
- decay transformations;
- diplomatic changes;
- construction completion.

Jump directly to the next meaningful event instead of simulating empty frames.

### Timing-wheel candidate

If profiling shows very large numbers of near-future timers, use a hierarchical timing wheel or timing-wheel + overflow heap. This is a mature server scheduling pattern with near-constant timer insertion/cancellation behavior.

Do **not** implement a custom complex wheel before M1 measurements prove the simpler scheduler is a bottleneck.

## 9. Simulation LOD / Fidelity

Keep the existing four-level model:

- L0 — full active individual;
- L1 — reduced individual;
- L2 — regional/cohort aggregate;
- L3 — latent/long-horizon.

The important architectural pattern is that gameplay/scripts query a stable domain interface rather than caring which representation is currently active.

This mirrors current large-world AI practice: Warhorse’s 2026 KCD/KCD2 presentation describes nearly 2,400 NPCs using AI LOD while trying to keep scripting unaware of the representation level.

### Promotion

Aggregate -> individual materialization must preserve:

- stable identities that matter;
- inventory/custody;
- injuries;
- relationships;
- objective/progress;
- location distribution;
- leaders/notable actors.

### Demotion

Individual -> aggregate may discard presentation/transient AI state but must not discard canonical consequences.

## 10. AI Architecture

Avoid one enormous Behavior Tree running continuously for every actor.

Recommended composition:

### Hierarchical state machine / StateTree-like structure

High-level states:

`Sleep / Work / Travel / Socialize / Combat / Flee / SeekFood / Quest / Captive / Injured`

State transitions are mostly event/signal/need driven.

Modern StateTree systems combine hierarchical states with selector-style decision logic, reducing continuous tree polling while preserving expressive behavior.

### Utility scoring only when a decision is required

When several valid goals exist, score them using normalized factors:

- urgency;
- risk;
- distance;
- reward;
- personality;
- duty;
- relationships;
- resources.

Do not recalculate utility for every possible action every frame.

### Smart Objects / reservations

World interactions should be represented as queryable capabilities/resources with reservations:

- bed;
- forge;
- market stall;
- chair;
- well;
- workbench;
- training spot;
- gate;
- quest board.

Actors request/reserve a usage slot. The object exposes capability/data; the actor owns behavior execution.

This prevents 20 NPCs from trying to use the same chair/forge point simultaneously and keeps interaction data centralized.

## 11. Navigation

Use layered navigation rather than full A* over the entire map for every NPC.

### Global layer

Region/road/portal graph using A* (or Dijkstra when appropriate) for long-distance route planning.

### Local layer

Tiled navigation mesh / Godot NavigationServer for active regions.

Recast/Detour’s tiled-navmesh model is the industry pattern: tiles support streaming, rebaking and hierarchical path planning.

### Local crowd avoidance

RVO/ORCA-like local avoidance only for actors that are actually active and close enough to require it. Godot NavigationServer already uses RVO-style avoidance and threadpool work.

### Squads/large groups

Do not independently solve a global path for every soldier. Share route/corridor/formation intent; individuals solve only local slot/avoidance corrections.

### Path request budget

Queue path requests and cap expensive rebuild/query work per simulation step. Priority can favor player-relevant/combat actors.

## 12. Networking Interest Management

Never broadcast the world to every client.

Adopt a **ReplicationGraph-like relevance model**:

- spatial AOI grid/cells;
- always-relevant set (own character/party/critical global state);
- owner-only state;
- distance/relevance tiers;
- frequency buckets;
- dormancy for unchanged entities;
- event-based wake-up;
- delta snapshots.

Epic’s Replication Graph exists specifically to avoid checking every replicated actor against every client; the general concept fits our server regardless of engine.

### Channel classes

Conceptually separate:

- reliable commands/transactions: inventory, trade, quest acceptance, important state changes;
- replaceable state: movement/aim/short-lived combat snapshots;
- low-frequency world summaries: territory, economy, regional state.

This prepares the protocol for WebTransport datagrams later without making M1 depend on it.

## 13. Persistence Model

### Source of truth

Use database transactions for durable canonical state, not the event bus alone.

### Snapshot + bounded journal

- periodic/current snapshots for fast load;
- domain/audit journal for important custody/economic/history events;
- do not permanently event-source every movement tick.

### Database boundaries

A storage interface owns persistence. Gameplay systems operate on domain repositories/commands.

This makes SQLite/PostgreSQL interchangeable for test/production phases.

## 14. Economy & Item Correctness

Treat valuable state transitions like financial transactions.

### Currency

- integer smallest units, never floating-point money;
- explicit mint/source and sink accounts;
- double-entry-style ledger for important currency movements;
- idempotency key for externally retried mutations;
- reconciliation jobs/invariant tests.

### Item custody

For individual items:

- one canonical holder/container;
- version/revision number;
- atomic transfer;
- optimistic concurrency/CAS or transaction lock where necessary;
- idempotent transaction IDs.

For fungible lots:

- quantities must conserve across transfer/consume/produce operations;
- never negative;
- source reduction and destination addition happen atomically.

### Trade

Use escrow/reservation semantics for multi-party trade rather than trusting sequential client calls.

## 15. Items, Decay and Bags

Keep the already-defined design:

- definitions + instances/lots;
- representation detail independent from persistence correctness;
- stackable perishables use internal condition batches/layers;
- lazy timestamp-based decay calculation;
- buckets/tolerances to bound layer count;
- explicit transformations at decay thresholds;
- rare/synthesized bags keep stable identity and synthesis history;
- container transfer settles old decay before applying new preservation rules.

This is computationally cheap because it avoids per-item per-frame timers.

## 16. Population & Relationships

### Population

Use hybrid individual + cohort simulation.

- named/relevant people stay individual;
- distant bulk population uses households/cohorts/age bands;
- migration/birth/death use scheduled rates/events rather than per-frame polling;
- important/rare outcomes can materialize individuals.

For large homogeneous cohorts, use batched stochastic transitions (binomial/Poisson/tau-leap-like approach) rather than rolling once per person.

### Relationships

Use a sparse relationship graph, not an all-pairs matrix.

Create relationship edges only when two actors actually know/interact with each other.

Store:

- compact current dimensions (trust, affection, respect, fear, resentment, etc.);
- bounded set of important memory/event anchors;
- decay/forgetting policies for low-value memories.

## 17. Ecology

Avoid unconstrained textbook Lotka–Volterra as the production model.

At aggregate fidelity use bounded ecology with:

- carrying capacity/habitat quality;
- density-dependent/logistic growth;
- bounded predator functional response (Holling Type II/III candidate depending species behavior);
- migration/recolonization;
- refuges/reservoir populations;
- age/reproduction constraints where relevant;
- threat/event budgets to avoid accidental catastrophe stacking.

Recent ecological literature still uses carrying capacity and Holling-style functional responses because they capture saturation/handling-time effects absent from naive linear predation.

The game model is tuned for believable stability and gameplay, not scientific prediction.

## 18. Battle Simulation

### Active battle

Use:

- squad-level intent;
- shared threat/target information;
- formation slots;
- staggered individual AI;
- local detailed collision/combat;
- morale/cohesion;
- wounds/incapacitation/surrender/route.

### Distant battle

Resolve by discrete events/statistical combat phases using the same inputs:

- force strength;
- equipment;
- morale;
- terrain;
- command;
- supplies;
- objectives.

Promoting an abstract battle materializes the current state, not a fresh random battle.

## 19. Economy Simulation

Use stock-flow accounting and scheduled markets.

Do not physically simulate every loaf transfer at long distance.

Aggregate transactions can settle batches while preserving:

- stock ownership;
- money balances;
- transport losses;
- production inputs/outputs;
- prices;
- contracts.

Prices should use bounded response/smoothing rather than unconstrained instantaneous feedback to prevent oscillatory numeric explosions.

## 20. Testing & Correctness Strategy

### Deterministic test seeds

Simulation tests should be reproducible by seed and record event traces needed to replay failures.

### Property-based testing

Use `proptest` on server invariants such as:

- item cannot exist in two canonical containers;
- transfer conserves quantity/value;
- money ledger balances;
- stack layer quantities sum to total stack;
- save/load is state-equivalent;
- arbitrary transaction sequences never produce negative stock illegally.

Property-based tools automatically generate many cases and shrink failures to minimal reproductions.

### State-machine/model tests

Generate sequences such as:

`loot -> transfer -> sell -> die -> scavenge -> restart -> trade`

and compare the runtime result to a simple reference model.

### Fuzz/network tests

Malformed packets and duplicate/reordered/retried commands must not corrupt canonical state.

### Soak tests

Accelerate 30/90/365 simulated days and watch:

- population/extinction;
- wealth concentration;
- food security;
- ecological ratios;
- queue backlog;
- memory growth;
- event throughput;
- invalid-state corrections.

## 21. Observability

Optimization without measurement is forbidden.

### Godot client

Use:

- built-in profiler;
- performance monitors;
- platform GPU tools;
- Perfetto/Tracy/Instruments where appropriate;
- release-like builds for representative measurements.

Godot 4.7 documents both sampling and tracing approaches and includes tracing support for common engine events.

### Rust server

Use structured `tracing` instrumentation plus metrics. OpenTelemetry Rust currently reports metrics/logs stable and tracing beta; export metrics to Prometheus-compatible tooling where useful.

Minimum server metrics:

- time per module/system;
- event queue size;
- timers due/processed;
- ECS entity count by archetype/fidelity;
- path requests/time;
- DB latency/transaction conflicts;
- messages/sec and bytes/sec by channel;
- AOI entities per client;
- simulation lag/debt;
- promotions/demotions;
- invariant failures.

## 22. Alternative Engine Review

### Unity 6

**Strengths:** mature 3D/mobile/web ecosystem, DOTS/ECS, excellent profiling/tooling.

**Why not primary:** creates future paid-seat/license dependency above Unity’s revenue/funding threshold, and is heavier than necessary for our zero-recurring-cost constraint.

### Defold

**Strengths:** extremely lightweight, free forever/no royalties, excellent HTML5/mobile story, actively maintained Rive integration, fast startup.

**Why not primary:** our real 3D spatial world, navigation, physics, terrain/height and large authoring burden would require significantly more custom infrastructure than Godot.

### PlayCanvas

**Strengths:** browser-native, WebGL2 + WebGPU fallback, strong web performance and lightweight deployment.

**Why not primary:** Web-first editor/runtime is attractive, but native/mobile/gameplay tooling and our existing Godot expertise make Godot lower total project risk.

### Babylon.js

**Strengths:** strong WebGPU/WebGL, excellent browser engine, native host exists.

**Why not primary:** would turn more engine/editor/gameplay infrastructure into our responsibility; better as a reference/contingency if browser rendering becomes the dominant constraint.

## 23. Candidate Stack Summary

```text
CLIENT
  Godot 4.7.2 stable
  GDScript-first
  Compatibility renderer = Web baseline
  3D spatial world + stylized 2D/Sprite3D presentation
  Jolt / NavigationServer where appropriate

SERVER
  Rust
  bevy_ecs 0.20 candidate
  Tokio async runtime
  modular domain systems

NETWORK
  M1 baseline: WSS/WebSocket
  experiment: WebTransport/HTTP3
  explicit versioned protocol
  Protobuf candidate; CBOR fallback
  AOI + relevance graph + frequency tiers + delta replication

DATA
  SQLite current fixed release for M1/local
  PostgreSQL 18+ target production
  snapshots + bounded audit/domain journal
  stable IDs + versioned schemas

SIMULATION
  ECS/archetypes
  fixed-step active bubble
  staggered frequency buckets
  discrete-event distant simulation
  optional timing wheel after measurement
  L0/L1/L2/L3 fidelity

AI
  hierarchical state machine
  event-driven wakeups
  utility scoring at decision points
  smart-object reservations

NAVIGATION
  region/road graph
  tiled navmesh locally
  queued/budgeted path requests
  RVO only for relevant active actors
  shared squad routes/formations

WORLD
  region/cell + local coordinates
  chunk streaming
  HLOD
  MultiMesh by spatial batch
  selective occlusion

CORRECTNESS
  transactional item custody
  integer money + ledger
  idempotency
  property/model/fuzz/soak tests
  observability from day one
```

## 24. Explicit Rejections

M1.1 rejects these default approaches:

- one Node per persistent world entity on the server;
- every NPC/animal updating every frame;
- global all-pairs relationship matrices;
- global pathfinding per actor;
- RVO for every distant NPC;
- entire-world network broadcast;
- inventory regenerated from NPC templates;
- floating-point currency;
- unlimited event-sourcing of frame-level movement;
- one giant Behavior Tree ticking continuously for every actor;
- one giant MultiMesh for the entire world;
- double-precision large-world coordinates enabled preemptively on mobile;
- custom low-level algorithms before profiling proves a standard solution insufficient.

## 25. What M1 Must Prove Before Production Acceptance

1. Godot 4.7.2 Compatibility prototype meets visual/performance needs on target mobile Web.
2. Sprite/rig strategy survives camera rotation and equipment attachment.
3. Rust/bevy_ecs scheduler meets synthetic world throughput/memory requirements.
4. Aggregate <-> active promotion preserves state.
5. WebSocket authoritative prototype feels acceptable; WebTransport feasibility is measured separately.
6. AOI/relevance replication prevents whole-world broadcast.
7. SQLite/PostgreSQL repository boundary can restore versioned state.
8. Item/economy invariants survive retries/restarts/concurrency tests.
9. Mixed-condition stacks and synthesized bags survive persistence correctly.
10. A compressed world run does not collapse from ordinary simulation noise.
11. Mini battle demonstrates surrender/route/wounds and aggregate promotion.
12. Mini society demonstrates finite goods/money/relationships/population without arbitrary spawning.

## 26. M1.1 Closure

M1.1 is **closed** when this research document and proposed ADRs exist.

The project now has a concrete, evidence-backed technical direction for prototyping. The next work is **M1.2 — Client/World Proof**, followed by server/simulation/network/persistence proof slices.

M1.1 does **not** authorize treating any candidate technology as irreversible. Failed measurements supersede the candidate through a new ADR.

## 27. Primary/Relevant Sources

- Godot 4.7.2 stable: https://godotengine.org/article/maintenance-release-godot-4-7-2/
- Godot Web export limitations: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html
- Godot performance/profiling: https://docs.godotengine.org/en/4.7/tutorials/performance/
- Godot large-world coordinates: https://docs.godotengine.org/en/4.7/tutorials/physics/large_world_coordinates.html
- Godot NavigationServer: https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_using_navigationservers.html
- Recast/Detour: https://github.com/recastnavigation/recastnavigation
- Bevy ECS: https://docs.rs/bevy_ecs/latest/
- GDC 2026 KCD/KCD2 AI LOD: https://schedule.gdconf.com/session/supporting-thousands-of-npcs-in-kingdom-come-deliverance-kingdom-come-deliverance-ii/915120
- Unreal MassEntity: https://dev.epicgames.com/documentation/unreal-engine/overview-of-mass-entity-in-unreal-engine
- Unreal Replication Graph: https://dev.epicgames.com/documentation/unreal-engine/replication-graph-in-unreal-engine
- Unreal StateTree: https://dev.epicgames.com/documentation/unreal-engine/statetree-quick-start-guide
- WebTransport: https://developer.mozilla.org/en-US/docs/Web/API/WebTransport_API
- PostgreSQL 18: https://www.postgresql.org/docs/18/
- SQLite WAL: https://www.sqlite.org/wal.html
- Proptest: https://docs.rs/proptest/latest/
- OpenTelemetry Rust: https://opentelemetry.io/docs/languages/rust/
- Defold: https://defold.com/
- PlayCanvas browser support: https://developer.playcanvas.com/user-manual/engine/supported-browsers/
- Unity pricing: https://unity.com/products/pricing-updates
