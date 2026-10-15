# Production combat foundation — Phase 2 Slice 1

## Ownership

`foundation.combat` requires only `core.runtime` and provides `CombatService`.
`Combatant` is a RefCounted capability for any registered Core entity ID. It has
no Node, Player, physics, world or rendering dependency. Entity owners register
combatants, attach them as `foundation.combatant`, and unregister on disposal.
Owners persist their own combatants; the generic registry is transient.

`foundation.player_combat` requires Core, Player and Combat. It attaches the
capability through Player's existing component container, owns its versioned
save section and rebinds the same object after Player/Core restoration. No Player
movement/input/camera code or World/Region/Core code changes in this slice.
The application composes six modules and exposes a `combat` diagnostic object.

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

Contributions in this slice are canonical, indefinite stat state and are saved.
No temporary-effect callbacks, expiration rules, buff catalog or equipment logic
exists. Future source owners must reconcile their contributions by stable ID;
timed effects must own semantic expiration separately. Scheduler owners can use
explicit HealingRequest or `restore_resource` for regeneration; no per-frame
combat math or implicit class regeneration runs here. `spend_resource` rejects
underflow; restoration reports actual refill and clamps to the current maximum.

## Transactions and relationship policy

DamageRequest and HealingRequest are separate one-use commands. Both carry stable
source/target IDs, a tracing transaction ID, whole-unit amount, optional action ID
and namespaced tags. Damage also carries a registered damage type, blockable,
dodgeable, parryable and interrupt-relevance flags, friendly-fire/self/neutral
permissions, optional impact position and an informational relationship hint.
Those execution flags reserve later action/mitigation integration; no dodge,
block, parry, interrupt or armor execution occurs in this slice.

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

Requests are authoritative application commands, not trusted network packets.
Accepted command objects are consumed, including zero/no-op requests; retrying
that object rejects. Their transaction IDs are correlation metadata, **not durable
network idempotency keys**. Future authority adapters must authenticate commands
and deduplicate network retries before invoking this local service. No unbounded
request history, replay system or multiplayer protocol is introduced here.

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

Application save game version is now `0.2.0`; format version remains 1. The
coordinator stamps that application version without changing generic Core.
Only the exact four-module `0.1.0` M1.3 save is upgraded: append Combat module
metadata and initialized Player combat state, then validate the entire upgraded
snapshot before mutation. Existing identity, movement, World/Region and clock
state are retained. Read/upgrade never writes the original file; explicit save
persists the upgraded representation. Missing combat data in a new-version save
is corruption and cannot silently reset health. Unknown legacy shapes reject.

## Validation and BK Android acceptance

Run Core, Player, World and Save/Resume scripts, then `bash tools/dev/test_combat.sh`.
Validated counts: Core 55, Player 23, World 50, save/resume 90 plus process
save/resume/exit 5/11/4; Combat 86, combat persistence 20, combat process save/resume
4/9. All 357 checks pass.

Combat tests run with Core alone, test transactions/events/modifiers/policies, and
exercise Player integration, corruption and explicit M1.3 upgrade. Separate OS
processes prove a disk checkpoint retains damaged health, spent resource, derived
maxima, persistent modifier IDs, lifecycle and stable Player identity; transactions
remain functional after restoration. All test files use private temporary slots.

The MCP launcher reported a listening bridge, but both permitted reads failed.
Logs were inspected and recovery stopped; live MCP assertions remain blocked.
No new assets, enemy actors or performance claims are introduced.

For BK:

1. Pull `phase2/combat-foundation`, open `client/project.godot`, and run the main
   scene. An M1.3 slot retains its location/identity and starts the new combat
   attributes at 100 health and 50 resource. An existing Phase 2 slot resumes its
   previous combat state.
2. Debug builds show HP/current max, resource/current max and lifecycle. Tap
   **Damage 10** once: health should fall by 10. These development buttons invoke
   real production transactions; no attack controls are implemented.
3. Tap **Save (K)**, confirm Saved, terminate the game, and run again. Confirm the
   reduced health and stable identity/location persist. Tap **Heal 10** to recover,
   clamped to maximum. Save and restart once more.
4. Confirm left-touch movement, right-drag camera and upper-right jump still work.
   The death boundary is covered automatically; no revive UI is part of this slice.

Next: semantic Player combat actions and modular ability/action execution, then
production enemy behavior, telegraphs and the remaining Phase 2 combat content.
