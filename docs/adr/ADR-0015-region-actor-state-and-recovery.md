# ADR-0015 — Region actor state and safe resume transforms

- **Status:** Accepted
- **Date:** 2026-10-15

## Decision

Region records own persistent world actors through a generic RegionActorState
capture/validate/restore/residency-loss port. Gameplay modules compose capabilities
and implement their actor schema; World/Region do not import combat or AI.
The application validates Core identity membership across sections. Node paths,
residency, controllers and presentation are never canonical identity/state.

Region also owns recovery constraints and last-safe Player transforms. Grounded
or explicitly surface-approved state can advance the recovery point. Runtime
constraint violations recover the same Player; snapshots substitute safe recovery
state for unapproved airborne/void state. Staged legacy finite void transforms
use last-safe/default-entry recovery. Invalid nonfinite schemas still reject.

Region section v2 persists these additions. Only explicit known-release upgrades
may introduce a new world actor and its Core identity; missing current actor
state rejects. Active actions never resume and committed cooldowns remain.

## Consequences

Combat/Player/Core remain reusable without enemy-specific rules. Future actor
owners and navigation adapters can extend the Region port without changing its
persistence ownership. Current single-Player recovery state is Region-local;
multiple Players will require stable-ID keyed recovery records and a migration.
No respawn, checkpoints, fall damage, faction simulation or final visual content
is implied. See `../architecture/ENEMY_TARGETING_TELEGRAPHS.md` for contracts,
development save deletion, tests and device acceptance.
