# ADR-0016 — Authoritative defense and transient surface recovery ports

- **Status:** Accepted
- **Date:** 2026-10-16

## Decision

Compose transient DefenseState/DefensePolicy with Combatant. CombatService calls
a pure stable-ID spatial DefenseResolver before committing HP/resource. Resolve
one outcome with dodge > parry > block priority and publish a typed correlated
DefenseResolved fact. Core ticks own windows. ActionRuntime owns transient
executor registration and routes interrupts through ActionExecutor; parry reactions
drain after commit using execution correlation, without coupling CombatService to
actor presentation or introducing a second execution authority.

Extend RegionRecovery through a transient RegionSurfaceQuery. The Region adapter
selects an appropriate local/contextual surface, never global maximum height.
Validate finite position, Region bounds, walkability and body clearance before
teleporting the same Player. Query clearance only for suspicious state. Preserve
last-safe/default-entry fallbacks and delay last-safe advancement until ground
confirmation after teleport. Safe snapshot substitution does not mutate gameplay;
legacy finite unsafe positions repair only in staged restore validation.

## Persistence and consequences

Persist committed HP/resource and remaining action cooldowns through existing
schemas. Defense windows/guard, executor bindings/reactions, spatial callbacks,
physics and input remain transient. No version change or new canonical service
is required. Home Valley implements only its current single-sheet terrain;
future layered adapters must supply a trustworthy context selection policy.

See [contracts and acceptance](../architecture/DEFENSIVE_VERBS_AND_RECOVERY.md).
