# Performance Architecture

- **Version:** 0.2.0
- **Status:** First measurable budget contract
- **Updated:** 2026-10-18

## Purpose

Performance is a product constraint for both the mobile client and the authoritative server.

The first budgets below are **engineering targets for profiling and regression detection**, not promises about final player capacity. Measurements may tighten/adjust the values, but agents must have a target before they can claim an implementation is performant.

## Primary Constraints

### Client reference floor

Design and validate toward a modest contemporary 64-bit mobile device class with approximately:

- **4 GB system RAM**;
- mid-range ARM CPU/GPU;
- Godot Compatibility renderer;
- dynamic/resolution scaling available when necessary.

A stronger desktop/phone may receive higher quality/FPS, but core gameplay must not require that hardware.

### Private server reference floor

The first lightweight server target is a `private_4gb` profile:

- approximately **4 GB system RAM**;
- modest modern 64-bit ARM64/x86-64 CPU;
- target roughly **4 logical cores** when available, but avoid architecture that requires all of them;
- headless, no rendering/audio stack;
- viable on inexpensive/free cloud instances where provider/network limits allow;
- viable for local Linux/Termux-class experimentation where Android/process/network restrictions permit.

Official servers can use stronger hardware and larger capacity while keeping the same simulation/authority rules.

## Client Frame Budget v0

### Reference target

- **30 FPS minimum stable gameplay target** on the reference device class;
- 33.3 ms frame budget;
- avoid sustained p95 frame time above the budget in representative gameplay;
- 60 FPS / 16.7 ms is a quality target for stronger devices, not the minimum reference requirement.

A short isolated hitch may happen during explicit loading/stream transitions, but routine combat/navigation should not continually stall.

### Client memory target

Because mobile integrated graphics share constrained system memory, treat process/assets/renderer memory as one scarce product budget.

Initial profiling targets for the 4 GB class:

- steady representative app memory: aim **<= 900 MiB**;
- warning zone: **> 1.1 GiB** sustained;
- normal representative peak target: **<= 1.3 GiB**;
- do not intentionally consume the remaining system RAM merely because the OS has not killed the process yet.

These thresholds are provisional and must be measured on real target devices. A device-specific OS memory limit overrides them.

## Client Rendering Strategy

Prefer:

- Compatibility renderer as baseline;
- texture/material atlasing or shared material profiles where it reduces state changes;
- simple environment meshes with strong art direction rather than geometry density;
- mesh LOD / visibility ranges for 3D world assets where useful;
- occlusion/culling appropriate to the camera modes;
- pooled transient VFX/projectiles where churn is measurable;
- GPU-friendly particles with strict count/lifetime bounds;
- baked/precomputed data when dynamic work adds no gameplay value;
- streaming by region/chunk rather than retaining the whole world scene.

Do not assign universal final draw-call/triangle limits before representative art exists. Record them per benchmark scene and establish regressions from measured baselines.

## Server Budget Philosophy

The server simulates **meaningful causality**, not every visual detail.

A 4 GB private server remains viable by combining:

- data-oriented state;
- simulation fidelity L0-L3;
- fixed active tick plus lower-frequency decision systems;
- scheduled events instead of per-entity polling;
- interest management;
- aggregate populations/lots;
- bounded job queues;
- incremental persistence;
- load shedding that preserves gameplay correctness.

The low-resource profile changes *how much work is simultaneously active*, not whether transactions are valid.

## Authoritative Tick Budgets v0

### `private_4gb`

Initial proof target:

- L0 authoritative simulation: **20 Hz** / 50 ms tick interval;
- aim for ordinary p95 simulation work **<= 25 ms** per L0 tick in the representative benchmark;
- warning when sustained simulation work approaches **40 ms**;
- preserve headroom for networking, serialization, OS scheduling and spikes.

### Official/stronger profile

Prove **30 Hz** / 33.3 ms L0 as an early official-server target when measurements support it.

Do not duplicate gameplay formulas between 20 Hz and 30 Hz profiles. Durations/rates are tick/time aware and the chosen server tick becomes part of session configuration.

Render FPS remains independent from server tick.

## Multi-rate Simulation

Not every system belongs on the L0 tick.

Initial frequency direction:

- **L0 Active:** 20-30 Hz canonical movement/combat/nearby physics as required;
- **L1 Reduced Individual:** roughly 2-5 Hz expensive goal/perception/decision evaluation, with immediate event wakeups and promotion to L0 where necessary;
- **L2 Regional/Aggregate:** roughly 0.2-1 Hz or scheduled deadlines for economy/ecology/population/route progress;
- **L3 Latent:** long-horizon events/analytical elapsed-time advancement rather than periodic polling.

These are scheduling bands, not promises that every L1 system ticks at exactly one frequency. Prefer event-driven wakeups over waiting for the next bucket when a material event occurs.

## Scheduler Algorithms

Start with deterministic, observable structures before exotic optimization.

### Active work

- fixed-step L0 loop;
- stable ordering where gameplay determinism requires it;
- batched ECS/system iteration;
- no unbounded work spawned from one actor/event.

### Deferred/scheduled work

Use:

- deadline/priority queue for sparse future events;
- frequency buckets for common repeated lower-rate jobs;
- dirty queues for state that only needs work after mutation;
- event wakeups for threats, contracts, arrivals, relationship/economy changes.

A **hierarchical timing wheel** is a future optimization only if profiling proves heap/deadline queue overhead material at scale.

## AI Performance

Do not run a full planner or behavior tree for every persistent NPC each frame.

Use:

- reactive rules only while immediate context requires them;
- utility scoring at decision boundaries;
- bounded HTN/GOAP planning only when a goal actually needs decomposition;
- cached plans until invalidated;
- staggered decision buckets;
- event-driven replanning;
- smart-object/resource reservations;
- sparse relationship/memory graphs;
- aggregate household/cohort decisions at L2/L3;
- promotion of an actor to higher fidelity only when relevance demands it.

### AI job budget

Each server tick has a bounded AI/path/work budget.

When the budget is exhausted:

- non-critical low-priority decisions defer;
- distant/aggregate work can slip within bounded tolerances;
- active combat correctness and already-started authoritative transactions are not silently dropped.

This produces graceful degradation instead of a simulation spiral.

## Navigation Performance

Use layered navigation rather than global full-detail pathfinding:

1. region/road/portal graph for long travel;
2. active tiled/local navmesh for detailed movement;
3. cached corridors/route segments;
4. queued path requests with per-tick budget;
5. shared group/corridor paths for patrols, caravans and formations;
6. local avoidance/RVO only for relevant active agents.

Consider flow-field/group navigation for large groups when profiling demonstrates repeated near-identical path queries.

Do not keep full navigation agents active for cohorts represented only at L2/L3.

## Spatial Queries and Interest Management

Use region partition + uniform spatial hashing/AOI cells for common local relevance queries.

A connection normally subscribes to its current cell and bounded neighboring/relevant cells rather than testing every world entity against every player.

Maintain specialized sets for:

- owner-only state;
- party/group relevance;
- always-relevant rare state;
- event-specific relevance.

Spatial indices are updated when an entity changes cell, not rebuilt globally every tick.

## Replication Budgeting

Replication is relevance and change driven.

Use:

- dirty component/state revisions;
- delta/state-change messages;
- dormancy for unchanged entities;
- frequency tiers;
- quantized transform/aim values where measured accuracy allows it;
- higher snapshot frequency for owner/active combat;
- lower frequency for distant/reduced actors;
- no replication for unperceived/unsubscribed world state.

Initial snapshot direction is **5-20 Hz depending on relevance**, while clients render/interpolate independently.

Reliable durable transactions (inventory, quests, trades, Building commits) must not be treated as replaceable transform snapshots.

## Server Memory Budget v0

For a machine with ~4 GB total RAM, leave material headroom for OS, filesystem cache, Termux/host services and spikes.

Initial `private_4gb` server-process targets:

- steady representative RSS: aim **<= 1.0 GiB**;
- warning zone: **> 1.25 GiB** sustained;
- normal hard target: **<= 1.5 GiB** during representative load;
- a configuration predicted/measured to exceed the profile should lower budgets or require a stronger server preset instead of relying on swap thrash/OOM.

Targets are provisional until the Rust/server proof exists.

## Server Memory Techniques

Prefer:

- compact ECS/component data rather than SceneTree Nodes;
- stable numeric/interned references inside hot data where safe while preserving stable external IDs;
- structure-of-arrays/archetype iteration through the selected ECS;
- aggregate fungible inventories/lots rather than UUID per wheat grain;
- aggregate cohorts for distant populations;
- bounded event/memory/provenance histories with promotion for important state;
- pooled/reused serialization/network buffers;
- capped transform rewind ring buffers only for relevant active actors;
- no per-tick allocation churn in hot loops where profiling identifies it;
- unload/cold-store content definition blobs not needed by active systems where practical.

## Persistence Performance

Private/local server proof may use **SQLite in WAL mode on the same host**.

Rules:

- database engine and WAL files stay local to the server host filesystem;
- do not place SQLite WAL state on an arbitrary network filesystem;
- simulation does not rewrite the whole world every tick;
- track dirty persistent state;
- group/batch safe writes;
- keep durable ordering/idempotency for important transactions;
- use periodic snapshots/checkpoints plus bounded journals where appropriate;
- move expensive serialization/I/O off the critical simulation path when it can be done without reordering canonical commits.

Official multi-process/multi-machine deployment can place a client/server database such as PostgreSQL behind the persistence abstraction after measurements justify it.

## Load Shedding Order

When server load rises, degrade **cost before correctness**.

Preferred order:

1. reduce optional telemetry/detail frequency;
2. lower low-priority replication frequency;
3. postpone non-urgent distant AI decisions;
4. aggregate/promote fewer distant actors;
5. reduce optional environmental cosmetic simulation;
6. preserve active authority tick, command validation, item custody and durable commits as long as possible.

If the server cannot preserve gameplay-critical budgets, report overload/health state rather than silently processing invalid partial simulation.

## Server Configuration Guardrails

Private server owners may raise farm/creature/NPC/Bot/world settings only within hard resource/integrity guardrails for the selected host profile.

Logical population can exceed active-actor budget because L2/L3 representations are cheap. Configuration does not force all configured NPCs/Bots into L0 simultaneously.

See `docs/design/SERVER_CONFIGURATION.md`.

## Benchmark Scenarios v0

Performance work should include repeatable scenarios rather than anecdotal editor FPS.

### Client A — Representative combat

- one Player;
- representative HUD;
- several nearby enemies;
- telegraphs/projectiles/VFX;
- representative environment/materials;
- camera movement and active combat.

Record frame-time distribution, memory, draw calls/objects/particles where available.

### Server A — Active combat cell

- several connected synthetic clients;
- L0 movement/action command streams;
- representative enemy/NPC actors;
- authority validation;
- snapshots/interest filtering;
- persistence events.

### Server B — Living world

- large logical population mostly L2/L3;
- farms/economy/ecology/contracts;
- scheduled migrations/production;
- bounded number of L0/L1 materialized actors.

### Server C — Promotion burst

Move players into a populated region and measure L2 -> L1/L0 materialization, pathing and network subscription without losing canonical state.

### Server D — Long compressed run

Advance long world time with players absent and verify CPU/memory/event queues remain bounded and causal state stays valid.

## Regression Gates

For each benchmark/profile, retain baseline metrics in machine-readable output.

Flag a regression when a change materially worsens a measured metric beyond the accepted tolerance for that benchmark. Initial CI may use generous thresholds until runner variance is understood.

Never optimize one synthetic metric by violating gameplay correctness or persistence invariants.

## Capacity Claims

Do **not** hard-code or advertise a max player/NPC/Bot count before benchmarks.

Capacity is a measured tuple of:

`hardware profile + world rules + active density + player density + network conditions + version`

The server should expose health metrics so an operator can understand why a configuration is approaching its limit.
