# ADR-0013 — Canonical combat capabilities and transactions

- **Status:** Accepted
- **Date:** 2026-10-15

## Decision

Generic `foundation.combat` depends only on Core and operates on stable-ID
RefCounted capabilities. A separate `foundation.player_combat` adapter attaches
and persists the Player's state without changing Player, World/Region or Core.
Other actor owners will attach and persist their own combatants using the same
contracts. Simulation and facts have no scene/presentation dependencies.

Use bounded integer resource units and basis-point scaling with explicit typed
stats. Stable source-keyed contributions reject duplicates, add before scale,
and apply scale stages in lexical source-ID order with integer flooring/clamps.
This establishes deterministic extension points without an arbitrary stat bag.

Damage and healing are separate one-use authoritative commands. Validate identities,
amounts, state and injected target policy before mutation; commit once and publish
bounded typed value facts afterward. Prevent reentrant service mutation and freeze
facts before subscriber delivery. Correlation IDs do not implement durable network
idempotency. A bus-delivery failure reports committed state explicitly.

Defeat is canonical and transitions once at zero; damage/healing cannot implicitly
revive. Combat never deletes a scene or owns corpse visuals. Downed/revive execution
and mitigation/action systems remain future layers.

## Persistence consequence

Add the Player combat owner section v1 and application game version `0.2.0`.
An explicit, strict application upgrade accepts the known four-module M1.3 `0.1.0`
snapshot and initializes only the new combat state before full validation. Missing
combat data in current-version saves is rejected. The file is not rewritten on
read. This avoids breaking accepted M1.3 saves or silently resetting damaged health
when a new save is malformed. Core's generic persistence contracts remain unchanged.

See `../architecture/COMBAT_FOUNDATION.md` for numeric bounds, policy, events,
versioned state, tests and Android controls.
