# ADR-0016 — Online-first authority boundary

- **Status:** Accepted
- **Date:** 2026-10-18

## Context

The production combat/player foundations were built as deterministic local domain services before an external server implementation existed. They already use stable IDs, simulation ticks, transactional combat requests and semantic player intents, but the running Godot client currently owns those service instances and can therefore mutate gameplay locally.

The product is intended to support persistent official servers and player-hosted private servers. Retrofitting authority only in a later networking milestone would force gameplay systems to be redesigned after combat, inventory, Building, NPCs and world simulation already depend on local ownership.

A development workflow also needs to run without a remote server, but a client-side `offline bypass` that directly grants health/damage/inventory authority would create the wrong architecture and an obvious cheating surface if it leaked into release builds.

## Decision

From A1 onward, Isekai World War Fantasy uses an **online-first authority boundary** independent of the final transport or server implementation technology.

Gameplay-critical state is committed only behind an `AuthorityHost`/authority boundary. Release clients submit semantic intents/commands and consume authoritative facts/snapshots.

The current deterministic services such as `CombatService` and `ActionExecutor` remain reusable domain logic, but online runtime treats the authoritative host as owner of their canonical state.

### Development without a remote server

Development/test gameplay uses a `LocalAuthorityHost` reached through a loopback authority gateway using the same command/result semantics as remote authority.

This is not a fallback that activates because a network request failed. A production client cannot promote itself to authority when disconnected.

Local-authority code should be excluded from production client packages where practical. Unit tests may invoke domain services directly inside explicit test harnesses.

### Movement and combat

- Clients send movement/input intent rather than trusted final transforms.
- The authority validates and simulates canonical movement.
- Client prediction/reconciliation may be added for responsiveness without changing ownership.
- Clients request actions/abilities; the authority validates lifecycle, timing, range, aim, cooldown/resource and relationships before committing effects.
- Client-reported damage, health, money, inventory quantities or successful Building commits are never trusted final state.

### Official vs private servers

Official and player-hosted private servers use the same authority/domain invariants. Private-server rules customize validated data/rates/content/budgets, not trust boundaries.

## Consequences

Positive:

- avoids a late multiplayer rewrite of gameplay foundations;
- anti-cheat begins at domain ownership rather than client obfuscation;
- current semantic input and tick-based combat work can be retained;
- local development remains possible without shipping an offline gameplay bypass;
- official and private hosting share one simulation model;
- deterministic command streams can be replayed against local and remote authority for testing.

Costs:

- A1 now needs an authority adapter/boundary before combat is considered production-ready;
- movement prediction/reconciliation and state replication add complexity;
- local and server implementations must preserve command/schema compatibility;
- some existing Godot state currently called `authoritative` is only locally canonical and must be reclassified during integration.

## Relationship to Previous ADRs

- ADR-0005 remains **Proposed** for the concrete Rust + ECS server implementation candidate. This ADR does not force Rust.
- ADR-0006 remains the simulation-fidelity/scheduling candidate.
- ADR-0007 remains the transport/interest-management candidate.
- ADR-0013 and ADR-0014 remain valid deterministic combat/action-domain decisions. Their commands execute behind the authority boundary in networked runtime.

## Roadmap Consequence

Macro Version A7 is no longer the first point where authority is introduced. Authority is a cross-cutting invariant from A1 onward.

A7 becomes multiplayer/server **productization and operations**: external transport hardening, session/discovery flows, reconnect, private-server packaging/admin configuration, official deployment, scale tests and production operations.

## Acceptance

This decision is considered correctly integrated when:

- gameplay-critical modules declare their authority boundary;
- release client code has no server-disconnect path that grants local persistent authority;
- forged client outcome messages cannot commit combat/inventory/world state;
- deterministic tests can exercise the same domain rules behind local and remote authority adapters;
- A1 combat implementation demonstrates the pattern before later Macro Versions copy it.
