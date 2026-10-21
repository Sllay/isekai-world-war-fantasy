# Production combat foundation — Phase 2 historical foundation, current A1 contract

## Current authority interpretation

This document originally established deterministic combat domain logic before the external server implementation existed. Its numeric, transaction, event, persistence and capability contracts remain valid.

**ADR-0016 and `SERVER_AUTHORITY.md` now define who may own/commit those contracts in production network runtime.**

`CombatService`, `ActionExecutor` and their request/result/fact contracts are reusable domain logic. They are not permission for a release client to authoritatively mutate persistent multiplayer state.

In online runtime:

- a client requests semantic actions/intents through the AuthorityGateway boundary;
- the AuthorityHost authenticates/validates the command and owns canonical Combatant/Action state;
- authoritative domain logic derives damage/healing/resource/cooldown/defeat outcomes;
- clients consume facts/snapshots for reconciliation/presentation;
- client prediction/VFX never becomes canonical merely because it ran first;
- a disconnected release client cannot switch to trusted local combat state;
- development local play uses LocalAuthorityHost/loopback semantics, not a client-side damage bypass.

The sections below describe the underlying combat domain foundation retained by A1.

## Ownership

`foundation.combat` requires only `core.runtime` and provides `CombatService`.
`Combatant` is a RefCounted capability for any registered Core entity ID. It has
no Node, Player, physics, world or rendering dependency. Entity owners register
combatants, attach them as `foundation.combatant`, and unregister on disposal.
Owners persist their own combatants; the generic registry is transient.

`foundation.player_combat` requires Core, Player and Combat. It attaches the
capability through Player's existing component container, owns its versioned
save section and rebinds the same object after Player/Core restoration. No Player
movement/input/camera code or World/Region/Core code changes in the historical slice.
The application composes six modules and exposes a `combat` diagnostic object.

When used in network production, the owner adapter is authority-side/canonical; a client mirror is presentation/prediction state only.

## Attributes and contributions

Health/resource values are whole integer units, bounded to 1,000,000,000.
There is one generic resource channel, identified by the profile's resource ID.
Current health/resource are separate from derived maxima. Explicit typed stats
are max health, max resource, outgoing damage scale and outgoing healing scale.
Later armor/resistance/critical/haste/penetration stats extend the typed contract
and validators rather than introducing arbitrary mutable stat dictionaries.

`data/combat/definitions.tres` is a preloaded typed Godot Resource and supplies profile values and registered production
IDs: `combat.profile.standard`, `combat.damage.physical`, `combat.resource.energy`,
the four `combat.attribute.*` IDs and `combat.modifier.add`/`scale`. Definitions
have validated Core Data Registry families. Profile versions must change when
incompatible tuning changes; saves reject unsupported profile versions. Owner
selection of a profile is separate from generic combat behavior.

Each contribution has a stable namespaced **source ID**, stat enum, operator enum
and integer value. One contribution per source ID is accepted; duplicates reject.
A source contributing to several stats uses distinct stable contribution IDs.
Removal is explicit and missing sources report failure. Input objects are copied,
so later edits cannot change registered contributions. Capacity is 64 per actor.

Calculation order is fixed:

1. Base plus all signed ADD contributions.
2. Clamp to stat bounds (health maximum >=1, resource maximum >=0).
3. SCALE contributions in lexical source-ID order. A factor of 10000 means 1x;
   each stage floors integer division and clamps. Scale values are 0..1000000.

The same source set gives the same result regardless of insertion/removal order.
Clamping at each scale stage and lexical rounding are part of schema v1. Maxima
increases do not heal/refill; decreases clamp current values. Maximum-health
changes publish one HealthChanged fact, including old/new maximum. Reducing a
maximum cannot implicitly defeat or revive an actor.

Contributions in this foundation are canonical, indefinite stat state and are saved.
No temporary-effect callbacks, expiration rules, buff catalog or equipment logic
exists in the original foundation. Future source owners must reconcile their contributions by stable ID;
timed effects must own semantic expiration separately. Scheduler owners can use
explicit HealingRequest or `restore_resource` for regeneration; no per-frame
combat math or implicit class regeneration runs here. `spend_resource` rejects
underflow; restoration reports actual refill and clamps to the current maximum.

## Transactions and relationship policy

DamageRequest and HealingRequest are separate one-use **domain commands**. Both carry stable
source/target IDs, a tracing transaction ID, whole-unit amount, optional action ID
and namespaced tags. Damage also carries a registered damage type, blockable,
dodgeable, parryable and interrupt-relevance flags, friendly-fire/self/neutral
permissions, optional impact position and an informational relationship hint.
Those execution flags reserve later action/mitigation integration.

CombatService validates request numbers/metadata, Core identity, available combat
capabilities and canonical alive state. Fractional, negative, NaN, infinite or
out-of-range amounts reject without mutation. Zero is an accepted no-op. The
source's damage/healing scale applies deterministically; evaluated amount floors
and saturates at the unit limit. Intermediate products fit signed 64-bit integers.
Damage clamps at zero; healing clamps at maximum. Results report accepted/code,
source/target, requested/evaluated/actual amount, overkill/overheal, before/after
health, relationship and defeat status. Negative damage is never healing.

Queries distinguish INVALID, SELF, ALLY, ENEMY and NEUTRAL. Self identity is resolved
by the service. An injectable pure `CombatTargetPolicy` supplies other relationships
and permission rules; the default is neutral between unrelated available actors.
Default damage permits enemies, with explicit opt-ins for self/ally/neutral damage.
Default healing permits self/allies, optionally neutral, and rejects enemies.
Unavailable actors are invalid. Relationship hints never establish authority.
There is no Player-vs-everything branch or faction implementation.

### Network ingress is not DamageRequest

`DamageRequest` / `HealingRequest` are authoritative **application/domain commands**, not trusted network packets.

A normal human client should not send `DamageRequest(amount=...)` and have it accepted merely because its fields validate.

The AuthorityHost first receives a higher-level semantic command such as `activate action X toward target/direction Y`. The authority authenticates peer -> actor, checks sequence/timing/rate, validates canonical action/equipment/state/range/aim/relationship/cost/cooldown, and then derives the internal effect requests from authority-known data.

A trusted server-owned NPC/Bot/action system may produce the same internal domain commands after its own canonical validation path.

Accepted internal command objects are consumed, including zero/no-op requests; retrying
that object rejects. Their transaction IDs are correlation metadata, **not durable
network idempotency keys**. Authority adapters must authenticate commands and
deduplicate/reject network retries/replays before invoking domain commits. Do not
keep an unbounded request history; use bounded sequence/idempotency windows appropriate
to the transport/transaction type.

## Facts and lifecycle

After committing canonical health once, the service publishes exact typed facts:
DamageApplied or HealingApplied, then HealthChanged, then CombatantDefeated on the
first transition to zero. All facts are assembled before subscriber delivery and
carry only stable IDs/value metadata, a correlation ID and Core tick. Zero-effect
operations and rejected requests emit no facts. Normal command mutation during policy
resolution/event delivery rejects BUSY; owner restore/disposal operations require
a quiescent application lifecycle. Consumers queue follow-up commands rather
than recursively executing combat inside fact handlers. Providers/subscribers
must respect read-only query/fact contracts.

An event-bus delivery failure is diagnosed and returns
`APPLIED_EVENT_DELIVERY_FAILED` with `accepted=true`: health is already committed
and must not be retried. The request remains consumed. Modifier delivery failures
are diagnosed after their canonical change. The Core bus's bounded delivery
contract is reused without changes.

Lifecycle v1 is ALIVE or DEFEATED. Zero health transitions once; further damage,
ordinary healing and resource operations on a defeated actor reject. Restore
never replays defeat events. Combat does not delete actors, freeze movement,
select corpse animations or grant revival. This is the boundary for later downed/
revive policy: those require an explicit lifecycle operation, not negative damage
or ordinary healing. Future stats/mitigation/actions attach above this substrate.

## Persistence and compatibility

`foundation.player_combat` section v1 stores the Player foreign-key entity ID and
profile ID/version, current health/resource, lifecycle and sorted modifier values.
Maxima are derived from matching versioned profile plus persisted contributions;
resource channel identity comes from the profile. Its validator checks numeric
bounds, unique valid modifier IDs, derived caps and lifecycle/health consistency.
Application SaveIntegrity additionally matches its entity ID to Player/Core.

Application save game version was `0.2.0` at the historical Combat foundation point; format version remained 1. Later versions may migrate this state explicitly. Missing canonical combat data must never silently reset damaged health simply because a client mirror lacks it.

For networked worlds, authoritative/server persistence is the source of canonical persistent combat state. Client caches/snapshots are not an alternate save authority.

## Historical validation record

The original foundation validated Core, Player, World, Save/Resume and Combat suites including transaction/event/modifier/policy, persistence and process save/resume checks. Later historical combat action/enemy slices expanded that coverage to the recorded 598 automated checks before the Macro Version workflow replaced slice delivery.

Those tests remain useful regression coverage but do not by themselves prove network authority.

## A1 authority validation extension

A1 must add integration/adversarial evidence defined by `SERVER_AUTHORITY.md` and `docs/missions/COMBAT_A1_FOUNDATION_COMPLETION.md`, including:

- semantic client command -> authority validation -> canonical CombatService result;
- no client-facing arbitrary final damage/health/resource commit;
- duplicate/replay handling at authority ingress;
- local loopback authority equivalence for deterministic scenarios;
- movement/position authority seam consistent with future prediction/reconciliation;
- no `server disconnected -> trust local combat` production fallback.

## Historical progression

Slice 2 composed typed actions above these transactions. Player Combat moved to section v2 with action schema v1 cooldowns. See [Combat Actions](COMBAT_ACTIONS.md) and ADR-0014.

Slice 3 added Region-owned enemy state, Foundation targeting, fact-driven telegraphs, safe-transform recovery and save-reset behavior. See [Enemy, targeting and telegraph contracts](ENEMY_TARGETING_TELEGRAPHS.md) and ADR-0015.

A1 now treats those historical slices as one existing combat foundation and integrates the missing defensive/player-facing/authority work without creating a parallel framework.
