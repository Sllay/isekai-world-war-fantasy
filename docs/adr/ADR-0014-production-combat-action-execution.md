# ADR-0014 — Typed action execution above Combat transactions

- **Status:** Accepted
- **Date:** 2026-10-15

## Decision

Compose a generic action catalog/executor with `foundation.combat`, retaining
Slice 1 CombatService unchanged. Actor owners provide a stable entity ID and pure
world-space position lookup. Typed Resource definitions/effects own reusable
content; Core Data Registry exposes their identity metadata. A data manifest
selects content without adding behavior branches. Player slot/input integration
belongs in an adapter, with generic motor permission gates.

Execute CASTING, COMMIT and RECOVERY against individual Core ticks. Cooldowns are
per-action availability rather than an exclusive executor phase. Validate before
starting and again at commit; spend resource/start cooldown immediately before
one-time effect dispatch through CombatService. Windup cancellation/interruption
costs nothing; committed effects are never refunded or retried. Synchronous event
reentrancy is rejected. Publish typed action facts and resolve presentation hooks
from data, without animation-driven gameplay.

## Persistence consequence

Action schema v1 stores only remaining cooldown ticks in Player Combat section
v2. Explicit migration from section v1 initializes empty cooldowns. New section
v2 snapshots missing action state reject. Keep existing application/module/save
format versions; the section version identifies this backward-compatible change.
Active casts/recovery and pending input never resume; committed health/resource
remain, and saved cooldowns cannot be bypassed by reload or offline wall time.
Future no-cooldown content must revisit transient recovery if restart availability
matters. No new persistent module or Core gameplay rules are needed.

## Acceptance fixture

The cylinder target is debug-only, transient and excluded from canonical capture.
It exercises a real registered Combatant, policy and transaction pipeline without
creating an enemy architecture or committing to production training content.

See `../architecture/COMBAT_ACTIONS.md` for contracts, limits and device acceptance.
