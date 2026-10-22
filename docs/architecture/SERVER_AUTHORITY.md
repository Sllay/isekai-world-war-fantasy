# Server Authority Architecture

- **Version:** 0.1.0
- **Status:** First-scope architecture contract
- **Updated:** 2026-10-18

## Purpose

Isekai World War Fantasy is **online-first in authority**, even while the final external server transport and hosting stack are still being proven.

The project must not build gameplay-critical features as client-owned systems and later attempt to bolt authority on top. From A1 onward, every gameplay-critical mutation must have an explicit authority boundary.

Official servers and player-hosted private servers use the same authority model. Hosting profile and server rules may differ; trust boundaries do not.

## Core Invariant

> Clients request gameplay. The authority decides gameplay.

### A1 implemented development boundary

`PlayerAuthorityAdapter` converts hardware-neutral PlayerIntent to movement,
guard/dodge/cancel and action-slot commands. `LoopbackAuthorityGateway` numbers
versioned envelopes; `LocalAuthorityHost` binds one trusted session to the Player,
rejects unknown fields/outcomes, forged sessions, nonfinite/out-of-range axes,
duplicates/replays, old/future tick windows and full inboxes. The inbox is capped
at eight commands and consumes at most four per simulation tick. Sequence high
water marks are session-scoped; correlation IDs are not deduplication keys.

The application explicitly selects this host in debug development. Release or
`--authority-remote` uses a disconnected AuthorityGateway until a transport is
configured; it freezes gameplay instead of promoting client state. There is no
network-error path that constructs a local host. Remote transport/authentication
handshake, reconnect and A7 services remain outside this mission.

The host reuses the canonical CombatService/ActionExecutor/module state, runs
enemy decisions and controls PlayerMotor collision through a physics port. Raw
input no longer writes the motor's canonical intent: the host uses its own
validated PlayerIntent. Physics cadence drives collision; Core's fixed 20 Hz
ticks drive actions, defense, regeneration and respawn. Region safe-transform
observation is also invoked through the host's physics port. Camera and visual
pose remain local. A detached snapshot contains tick/ack/state; PlayerReconciler
corrects a separate mirror and rejects obsolete corrections. Full prediction,
pending-input replay and remote interpolation are not claimed.

Host loadout slots reference trusted action definitions. Combat modifiers remain
the equipment/stat extension point; P2's equipment references canonical inventory
instances and supplies contributions through that same modifier contract.
Host-owned SaveCoordinator capture/resume retains canonical domain state; client
snapshots are value copies and cannot mutate the host. Tests exercise adversarial
ingress, direct-domain equivalence, defense, stagger, death and an entire playable
scenario; see `client/tests/authority_tests.gd` and `a1_scenario_tests.gd`.

C1-R1-P1 uses an authority-installed ActionLoadout (primary, skill_1/2/3; optional
empty skills). Legacy strong/heal commands alias slots 1/2. Action ingress accepts
either the original slot/target pair or the pair plus finite world direction/point
hints; arbitrary extra fields remain rejected. P2 extends this with validated
`skill.equip` requests against authority-owned learning/equipment sources.
World queries are authority-only ports and return bounded candidate IDs; the
existing executor revalidates them at commit and spends cost/cooldown once. Target
selection and commit share physics visibility, independent of camera rendering.
See ADR-0017 and `client/tests/c1_foundation_tests.gd`.
The remote-without-transport runtime disables both motor and autonomous Region
recovery; raw input cannot advance actions/combat, recover a transform or save
untrusted state. `remote_authority_tests.gd` boots that actual application mode.

### C1-R1-P2 item and resource boundary

AuthorityCommandPort extends the same host envelope/actor/inbox validation.
ItemsAuthorityPort accepts semantic pickup/equip/transfer/split/merge/harvest/
craft/consume and eligible skill-slot requests, never final grants, yields or
outputs. ItemsModule owns canonical stock/custody, equipment, learning and world
resource/drop state. Work commits through existing ActionExecutor capability
effects and revalidates canonical context at commit. The remote-disconnected
regression now also proves rejected item requests leave all P2 state unchanged.
See [Items and resources](ITEMS_RESOURCES_FOUNDATION.md) and ADR-0018.

A production client may submit semantic input/intent, but it does not authoritatively submit final gameplay outcomes.

The authority owns at minimum:

- actor identity and peer -> actor binding;
- simulation tick/time used by gameplay;
- canonical gameplay position, velocity, grounded state and gameplay facing;
- action/cast/commit/recovery state;
- cooldowns, charges and gameplay resources;
- hit validation and combat outcomes;
- health, healing, defeat, respawn and authoritative status effects;
- inventory, item custody, equipment and money;
- crafting/harvest/gather commits;
- Building placement/ownership/damage commits;
- NPC/Bot/creature canonical decisions and world consequences;
- quest/contract state and unique-item custody;
- canonical world/economy/ecology/war state;
- persistence and durable transaction ordering.

The client may own locally:

- raw hardware input;
- camera/view mode;
- HUD/UI state that is not gameplay authority;
- interpolation and presentation smoothing;
- animation blend state derived from canonical facts;
- VFX/SFX;
- non-authoritative aim/build previews;
- bounded prediction for responsiveness.

Camera pitch/yaw and top-down/third-person presentation are not authoritative world state unless a gameplay mechanic explicitly derives a validated aim/facing intent from them.

## Existing Foundation Compatibility

The current `CombatService` and `ActionExecutor` are useful domain foundations rather than throwaway offline prototypes:

- they operate on stable IDs;
- combat mutation is transactional;
- action execution uses simulation ticks rather than animation time;
- action commit revalidates range/resource/cooldown;
- requests/results/events are already separate objects;
- presentation is not the source of combat truth.

The missing boundary is **who is allowed to invoke authoritative commits in a networked game**.

These services may remain reusable as deterministic domain logic, but in online runtime the authoritative host owns their canonical instance/state. A network client must not gain equivalent authority merely by instantiating a local service.

## Semantic Command Pipeline

The preferred network boundary is intent/command oriented:

```text
Raw input
  -> View/Input adapter
  -> Semantic Intent
  -> Client command envelope
  -> AuthorityGateway
  -> authenticated server command inbox
  -> fixed authority tick
  -> validation
  -> canonical domain commit
  -> typed authoritative facts/state revisions
  -> relevance-filtered replication
  -> client reconciliation/presentation
```

A command envelope should be able to carry, as appropriate:

- protocol/schema version;
- command sequence number;
- client-observed tick/time reference;
- semantic action ID or input buttons;
- movement axes;
- aim direction/world hint;
- requested target stable ID;
- correlation/request ID.

The command does **not** carry trusted final outcomes such as:

- `damage = 9999`;
- `health = 100`;
- final inventory quantity;
- final cooldown;
- final position that the server simply accepts;
- arbitrary money/XP gain;
- successful Building placement without validation.

## Combat Authority

For an attack/ability, the client requests the action. The authority derives the result from canonical state.

At action start/commit the authority can validate:

- authenticated actor ownership;
- action known/equipped/allowed;
- alive/action lifecycle state;
- resource/cost;
- cooldown/charges;
- canonical source/target position;
- range;
- line of sight/perception requirements;
- relationship/friendly-fire rules;
- aim/direction constraints;
- block/dodge/parry/interrupt state;
- server tick/window validity;
- rate/sequence/replay rules.

Damage/healing values are then produced from server-known action/equipment/status data and passed to the combat domain service.

Client hit effects may be predicted visually, but health/damage confirmation comes from authority facts.

## Movement Authority

A release client should normally send movement/input intent rather than an unconstrained final transform.

### Local player

Use **client-side prediction + server reconciliation** when required for responsiveness:

1. client numbers input commands;
2. client predicts its own movement using compatible movement rules;
3. server processes commands in canonical tick order;
4. server sends authoritative state plus last acknowledged input sequence;
5. client corrects to the authority state and replays still-unacknowledged local inputs;
6. presentation smooths small corrections without altering canonical truth.

Server-side movement validation may check acceleration/speed, movement mode, collision, action movement gates and impossible displacement.

### Remote actors

Use **snapshot interpolation** between buffered authoritative states. Short bounded extrapolation may hide packet gaps, but clients do not invent durable remote state.

## Lag Compensation

Fast combat may later use bounded **server-side rewind** for spatial validation.

The server can retain a short transform/history ring for relevant actors and reconstruct a past spatial query corresponding to a validated command timestamp.

Rules:

- rewind is bounded by a configured maximum window;
- only the spatial validation context is rewound;
- inventory, health, item custody and durable world state are not rolled back merely to validate one hit;
- the server clamps/validates claimed timing;
- history memory is limited to relevant active actors;
- exact window is a measured balance/network parameter, not hard-coded by this document.

## Fixed Tick and Multi-rate Simulation

One global frame rate is not required for every subsystem.

Initial proof direction:

- active authority gameplay (L0): fixed tick;
- nearby/relevant AI (L1): staggered lower-frequency decisions while movement/combat can promote to L0;
- distant regions (L2): scheduled/aggregate transitions;
- latent world (L3): analytical/event-driven advancement.

Render FPS is independent from authority tick rate.

The performance contract defines provisional tick budgets and may change them after profiling without changing this authority model.

## AuthorityGateway

Client-facing gameplay code should depend on an authority interface rather than directly deciding whether it is offline or online.

Conceptual implementations:

### `RemoteAuthorityGateway`

Production/default path. Serializes semantic commands to the remote authoritative server and applies replicated facts/snapshots.

### `LoopbackAuthorityGateway`

Development/test path. Talks to a `LocalAuthorityHost` through the same command/result semantics without requiring Internet connectivity.

The loopback path is **not** a gameplay bypass. The local host must run canonical validation/commit rules as an authority.

### Direct domain harness

Unit tests may instantiate domain services directly when testing the service itself. This is test code, not a production client fallback.

## No Runtime Offline Bypass

Release builds must not contain a switch equivalent to:

```text
if server_unavailable:
    trust_client_damage()
```

A production client losing its server connection cannot become authority over persistent/competitive state.

The development local-host capability should be excluded from production exports/packages where practical through build/export features and packaging boundaries. Even if a modified client recreates a local host, official/private remote servers still authenticate and validate their own canonical commands, so the modified client cannot grant itself remote authority.

Single-player/offline product support, if ever desired, is a separate explicitly hosted local world mode using the server-authority rules, not a bypass inside gameplay systems.

## Command Security and Abuse Resistance

At the authority ingress layer:

- authenticate session/peer before gameplay commands;
- map network peer/session to allowed actor IDs server-side;
- never trust a client-provided source actor merely because the ID exists;
- validate message/schema size and ranges;
- use monotonic command sequence numbers where appropriate;
- reject/ignore duplicate or stale commands safely;
- bound accepted future/old tick windows;
- rate-limit spam-sensitive commands;
- use bounded queues/backpressure;
- make durable transactions idempotent where retries are possible;
- keep gameplay RNG seeds/outcomes authoritative when they affect persistent results;
- do not ship server secrets/private admin credentials in the client.

Anti-cheat begins with not trusting the client. Client-side anti-tamper may exist later but is not a substitute for authority validation.

## Replication and Interest Management

Network cost must scale primarily with **relevance**, not total world population.

Use a transport-independent relevance layer combining:

- region subscription;
- spatial AOI cells / uniform spatial hashing;
- owner-only sets;
- always-relevant sets for rare critical state;
- distance/relevance tiers;
- frequency buckets;
- dirty-state tracking;
- dormancy for unchanged entities;
- event-driven wakeup;
- state revisions/deltas;
- bounded replication budgets per connection.

Do not perform all-pairs distance tests across the full world for every client.

High-frequency replaceable state such as transforms may use a different delivery policy from reliable economic/inventory/quest transactions.

## Data-oriented Server Representation

Canonical server simulation should not require a rendered Godot Node per persistent entity.

The current server candidate is a Rust data-oriented ECS/service. The authority contract is independent from that implementation choice, but server data should remain compact and suitable for:

- archetype/component iteration;
- batched scheduled work;
- stable world IDs separate from transient ECS handles;
- aggregate cohorts/lots when individual detail is unnecessary;
- event/dirty processing rather than universal frame polling.

## Persistence Boundary

The authority owns persistence.

Private/local server candidates may use SQLite WAL on the same host. Larger official deployments may use a client/server database behind a persistence adapter.

Gameplay ticks should not synchronously serialize the entire world. Prefer:

- dirty entity/component tracking;
- transactional command results;
- incremental snapshots;
- bounded journals/WAL;
- scheduled checkpoints;
- asynchronous persistence work where ordering safety permits.

A save failure must not cause a second gameplay commit.

## Official and Private Servers

Both server types use the same core domain/authority contracts.

Differences belong to validated configuration and operational profiles:

- server rules;
- world-generation profile;
- population/Bot budgets;
- rates;
- authentication/listing policy;
- resource budgets;
- database/deployment adapter;
- observability/backup level.

A private server configuration cannot opt out of core command validation and still be considered a normal network server.

See `docs/design/SERVER_CONFIGURATION.md`.

## Acceptance Proofs

Before authority work is considered production-ready, automated/integration proofs should cover at least:

1. a forged direct damage/health command cannot mutate authority state;
2. a forged teleport/final-position command is rejected or never part of the accepted protocol;
3. duplicate/replayed action commands do not duplicate a durable effect;
4. insufficient-resource/cooldown/range checks are decided by authority state;
5. client prediction can be corrected by an authoritative movement snapshot;
6. a LocalAuthorityHost scenario and a remote-authority scenario produce equivalent canonical results for the same deterministic command stream;
7. reconnect/resync restores canonical state without trusting stale client state;
8. relevance filtering does not leak intentionally unknown gameplay state;
9. server overload/load-shedding never drops already-committed durable transactions;
10. private low-memory profile remains within measured process budgets during the representative benchmark scenario.
