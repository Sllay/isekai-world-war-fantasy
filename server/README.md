# Server

Authoritative Rust world-simulation/server boundary.

This directory will later become the Rust workspace selected for M1 server proofs.

## Owns

- canonical world state;
- simulation scheduler and simulation LOD;
- population/ecology/economy/war state;
- authoritative inventory/item custody;
- persistence adapters;
- networking authority and interest management;
- server diagnostics and invariants.

## Baseline candidate

- Rust;
- `bevy_ecs` as standalone ECS candidate;
- Tokio for async/network I/O;
- SQLite for M1/local persistence experiments;
- PostgreSQL target behind a storage abstraction.

No production technology is irreversible until its M1 proof passes.
