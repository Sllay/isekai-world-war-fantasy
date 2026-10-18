# Server

Authoritative world-simulation/server boundary for Isekai World War Fantasy.

The project is **online-first in authority**: gameplay-critical state is owned by an AuthorityHost from A1 onward even while the concrete external server implementation remains under proof.

See:

- `docs/architecture/SERVER_AUTHORITY.md`;
- `docs/architecture/NETWORKING.md`;
- `docs/architecture/PERFORMANCE.md`;
- `docs/design/SERVER_CONFIGURATION.md`;
- ADR-0016.

## Owns

The authoritative server/host owns:

- canonical actor/world state;
- server simulation tick/time;
- movement/action/combat validation;
- canonical health/resources/cooldowns;
- inventory/item custody/equipment/money;
- crafting/Building/world mutations;
- NPC/Bot/creature canonical simulation;
- scheduler and simulation LOD;
- population/ecology/economy/war state;
- persistence adapters;
- networking authority/interest management;
- server configuration validation;
- diagnostics/invariants/health metrics.

A client sends semantic intents/commands and receives authoritative facts/snapshots. It does not become authority if the network disconnects.

## Official and Private Hosting

Official and player-hosted private servers use the same domain/authority rules.

Differences belong to validated operational/rule profiles, for example:

- `official`;
- `private_4gb`;
- `private_standard`;
- `sandbox_high`.

The `private_4gb` profile is the first low-resource target: roughly 4 GB system RAM and a modest 64-bit ARM64/x86-64 host, with simulation/replication/population budgets tuned to leave OS headroom.

Termux/local hosting is a useful target for private-server experiments where Android networking/background-process restrictions permit it. It is not assumed to behave like unrestricted Linux hosting.

## Server Customization

Private server configuration is data-driven and versioned.

Owners can eventually customize within validated bounds:

- seed/world-generation profile;
- farm/gather/crafting/progression rates;
- ecology/monster abundance;
- NPC populations/profession weights;
- custom NPC definitions;
- enabled/disabled special NPCs;
- Bot enable/count/custom profiles/starting progression;
- PvP/raid/death/building rules;
- persistence/reset policy.

Normal configuration cannot disable authority/security/integrity invariants.

## Development Local Authority

Development without a remote server uses a `LocalAuthorityHost` through the same semantic command boundary.

This is deliberately different from a client-side offline bypass:

- domain validation still runs;
- the gameplay client still requests actions;
- production client packages should exclude local-host authority code where practical;
- a modified client can simulate whatever it wants locally, but remote official/private servers continue to ignore untrusted outcome/state claims.

Unit tests can call domain services directly inside test harnesses.

## Concrete Server Candidate

ADR-0005 currently proposes for M1 proof:

- Rust;
- `bevy_ecs` standalone ECS candidate;
- Tokio for async/network I/O;
- SQLite in WAL mode for private/local same-host persistence experiments;
- PostgreSQL-compatible storage abstraction for larger official deployments.

This candidate is not promoted to Accepted until throughput, memory, persistence, authority flow and observability are measured.

## Performance Direction

The server must not materialize every logical actor as a full real-time object.

Use:

- L0-L3 simulation fidelity;
- deterministic fixed active tick;
- staggered/frequency-bucket AI;
- scheduled events/dirty queues;
- data-oriented ECS state;
- AOI/spatial-hash interest management;
- aggregate cohorts/lots;
- bounded path/AI/replication job queues;
- incremental persistence;
- graceful load shedding that reduces optional cost before gameplay correctness.

Initial measurable budgets live in `docs/architecture/PERFORMANCE.md`.
