# Production combat actions — Phase 2 Slice 2

## Ownership and content

`foundation.combat` composes `ActionCatalog` alongside the existing, unchanged
`CombatService`. Both depend only on Core. `foundation.actions` resolves the
catalog; `foundation.player_combat` owns one `ActionExecutor` attached under
`foundation.actions` in the Player capability container. Other actor owners can
construct the same executor with their stable ID, CombatService and catalog.
Player slot mapping lives in `PlayerActionAdapter`, outside generic execution.
No Core, World/Region or CombatService gameplay rules were added.

`data/actions/definitions.tres` is a typed `ActionContent` manifest. Its
`ActionDefinition` resources contain stable IDs, cast/recovery/cooldown ticks,
resource channel/cost, voluntary cancellation and interruption flags, movement
and turning permissions, target mode/range, typed `ActionEffect` arrays, tags,
telegraph ID and windup/commit/recovery presentation cue IDs. Durations use Core
simulation ticks (currently 0.05 seconds each), independent of render/animation
frames. Catalog registration validates bounds, references, supported modes,
effects and metadata, rejects duplicate IDs and deep-copies resources. Lookups
also return copies. Core Data Registry exposes validated action identity metadata;
the typed catalog owns the complete schema, rather than an untyped property bag.

| Definition | Windup | Recovery | Cooldown from commit | Cost | Effect |
| --- | --- | --- | --- | --- | --- |
| `combat.action.basic_strike` | 4 ticks | 6 ticks | 16 ticks | 0 | 12 physical damage, 2.5 world-unit range, blockable/dodgeable/parryable |
| `combat.action.basic_heal` | 10 ticks | 4 ticks | 60 ticks | 5 energy | 15 self-healing |

Strike allows movement/turning; heal restricts both during casting. These are real
content definitions, with conservative initial tuning. No hitbox geometry,
projectile, mitigation, animation or VFX behavior is implied by their metadata.

## Target and effect boundaries

`ActionTarget` is a value request containing a stable entity ID and reserved
world-space direction/point values. V1 executes SELF and explicit ENTITY modes
only; unsupported modes fail definition validation. SELF resolves to the owner,
regardless of caller target. ENTITY requires a pure `position_of(id)` provider
returning a finite world-space Vector3 or null. Missing positions reject rather
than falling back to scene coordinates. Range uses squared 3D distance, inclusive
at the maximum. No targeting code inspects Node ownership or selects enemies.

`ActionEffectRunner` supports typed DAMAGE and HEALING effects. It constructs
DamageRequest/HealingRequest objects, including action ID, tags, policy flags,
damage metadata and execution correlation ID, then calls CombatService exactly
once per effect at commit. Only CombatService changes health/resource. Its
relationship provider remains authoritative for both preflight and transactions.
Each effect returns a CombatResult visible in execution diagnostics. Effect lists
execute in authored order; they are not multi-target atomic transactions. Once
commit starts, subsequent effect rejection does not refund cost/cooldown or retry
previous effects. Future complex effects must define their own transaction policy.

## Execution and availability

Execution phases are `IDLE -> CASTING -> COMMIT -> RECOVERY -> IDLE`, with a
terminal `CANCELLED` observation until the next accepted request. Zero-duration
phases can transition in the same tick. COMMIT is explicit and observable during
transaction/fact delivery, without requiring a render frame. Cooldown is separate
per-action availability, so one cooling action does not prevent using another.
`remaining_cooldown(id)` returns zero for absent/expired cooldowns; finite deadlines
start at commit. This separates future charge availability from execution phases.
Charges, channels and charging execution are not implemented.

The application advances each new Core tick individually, runs due scheduler
jobs, advances the executor, then consumes semantic Player commands. This keeps
action and combat fact ticks exact even when a render frame advances several
Core ticks. Pausing or time scale zero cannot advance actions. Generic owners
must call `advance()` each simulation tick, never skip directly across a cast
boundary. Repeated calls in the same tick cannot repeat a commit. The same state,
commands and tick sequence produce the same gameplay results; generated event/
transaction trace IDs are correlation metadata, not deterministic gameplay inputs.

Activation validates owner presence/alive state, action existence, active phase,
per-action cooldown, resource channel/balance, target presence/alive state,
positions/range and relationship policy. Result codes include OWNER_UNAVAILABLE,
OWNER_DEFEATED, UNKNOWN_ACTION, ACTION_ACTIVE, COOLDOWN, INSUFFICIENT_RESOURCE,
TARGET_UNAVAILABLE, TARGET_DEFEATED, POSITION_UNAVAILABLE and
RELATIONSHIP_REJECTED/OUT_OF_RANGE. Rejections are local command results, not
broadcast global facts. The executor exposes the last result in diagnostics.

Windup reserves no resource. At the cast deadline, owner/resource/target/range/
relationship are revalidated. A failed check cancels without cost or cooldown.
After successful `spend_resource`, the executor marks the execution committed,
starts cooldown, and dispatches effects once. Reentrant activation/advance/cancel
from synchronous event delivery is blocked. Committed recovery cannot be cancelled
or refunded. `cancel()` applies only to cancellable CASTING; `interrupt()` applies
only to interruptible CASTING. Defeat/unregistration cancels active execution
regardless of those flags. Cancellation releases movement/turn gates immediately;
there are no action-owned timers, subscriptions, Nodes or callbacks to persist.

Typed ActionStarted, ActionCommitted, ActionCancelled and ActionCompleted facts
carry owner/target/action/execution IDs and Core tick; cancellation adds a reason.
Presentation resolves cue/telegraph IDs through the catalog using those facts.
The simulation emits no animation/VFX-specific facts and observes no animation
frames. Combat facts are emitted by CombatService before ActionCommitted.

## Input and movement

`PlayerInput` alone reads keyboard/controller/touch. It produces primary,
secondary and cancel one-shots on `PlayerIntent`, alongside target ID/world-space
aim values, movement, camera and jump. F/RB/right-lower Strike activates primary;
H/LB/Heal activates secondary; X/B/Cancel cancels. Touch presses are handled by
finger ID directly, without depending on single-mouse emulation. Emulated mouse
presses are ignored for actions to prevent duplicate activation. Only the three
button rectangles reserve camera space; existing movement/jump regions remain.
Focus loss clears pending actions and touch ownership.

The Player adapter maps slots to content IDs and consumes each command once;
cancel wins a simultaneous request, otherwise primary precedes secondary. Its
optional default target provider is supplied only by the development harness.
Production callers supply explicit target IDs until later targeting controllers
exist. The motor accepts generic movement/turn permission callables: it stops
horizontal self-motion and denies new jumps during a restricted cast, retaining
gravity and camera operation. No motor branch names an ability. Gates clear on
completion/cancellation/restore. Camera orbit is independent of actor turning.

## Persistence

Action schema v1 stores **only remaining cooldown ticks** inside Player Combat
section v2. Application version remains `0.2.0`, module versions remain `1.0.0`,
and save format remains 1. Explicit section v1 -> v2 migration initializes empty
cooldowns because Slice 1 had no actions. Existing strict M1.3 application upgrade
now initializes the current section shape. Missing actions in a v2 section is
corruption and rejects; unknown IDs, fractional/negative/excessive durations and
unsupported fields reject. Ordinary health/resource/modifier persistence is intact.

Active casts, recovery, target selection, result objects, input, callbacks and
presentation never serialize. Loading starts IDLE with gates released; a half
cast never commits on resume. Already committed effects/cost remain in Combatant
state. Saved remaining cooldowns become deadlines relative to restored Core time;
offline wall time does not expire them. This prevents save/reload cooldown bypass.
Recovery itself is transient by policy; current actions have longer cooldowns than
recovery. Future no-cooldown content must consider restart availability explicitly.

## Development acceptance and validation

Debug interactive sessions create one cylinder fixture at the Player's session
entry minus 1.5 world Z. It is a transient Core entity with a real Combatant and
a bounded relationship-policy adapter, not enemy AI or canonical training content.
It stays fixed, does not respawn on defeat, and resets to 100 HP on session
restart/resume. The application capture adapter excludes its ID without changing
live identities. Release sessions do not create it; headless tests opt in with
`--combat-actions-acceptance`. No fixture, policy, mesh or input object is saved.
Development diagnostics expose current action/phase/remaining ticks, cooldowns,
separate last activation/transition results, target ID, effect result codes and target HP.
The existing development combat display also shows phase/resource state; no
permanent combat HUD or final action bar was introduced.

Run `test_core.sh`, `test_player.sh`, `test_world.sh`, `test_save_resume.sh`,
`test_combat.sh` and `test_combat_actions.sh` under `tools/dev/`. The action runner
uses private temporary slots and includes independent OS-process save/resume.
Validated checks: Core 55, Player 23, World 50, Save/Resume 110, Combat Foundation
119, and Combat Actions 108 (unit 68, runtime 26, process save/resume 4/10):
**465 checks, zero failures**, retaining all previous 357. The action runner also
checks that Core contains no gameplay implementation references.
Live Godot MCP validation succeeded after one prescribed launcher recovery:
Player capability, strike CASTING/RECOVERY with target HP 100 -> 88 exactly once,
heal HP 70 -> 85/resource 50 -> 45, cooldown diagnostics, save/resume to IDLE with
59 cooldown ticks retained, injected movement/camera and airborne jump. No device
performance or Android acceptance claim follows from these host checks.

For BK on Android:

1. Pull `phase2/combat-actions`; open `client/project.godot` and run the main scene
   in a debug/editor build. Existing saves migrate without resetting health or
   resource. Observe the cylinder and `Dev target HP 100/100` near session entry.
2. Stay within 2.5 units. Tap lower-right **Strike (F)** once: after 0.2 simulation
   seconds target HP becomes 88, then remains 88. Rapidly tap again after recovery
   but before cooldown expiry: diagnostics report COOLDOWN. After about one second
   from the first activation, another strike should reduce HP to 76.
3. Hold left-touch movement and rotate with a separate right-side finger. Tap
   Strike using another finger while staying in range; movement/camera remain
   active. Move away from the cylinder and strike: OUT_OF_RANGE, no target damage.
   Return near it for further strike tests.
4. Tap development **Damage 10** twice, recording health. Tap lower-right **Heal
   (H)**: horizontal movement/new jumps stop during the 0.5-second cast, camera
   still rotates, health rises by 15 (clamped) and energy falls by 5 at commit.
   Movement resumes after cast. A second early Heal reports COOLDOWN.
5. After cooldown expiry, start Heal and immediately tap **Cancel (X)** during
   its cast. Health/energy stay unchanged and movement unlocks. Repeat later if
   needed; do not use Damage 10 near zero HP because revival is outside this slice.
6. Heal, then immediately tap **Save (K)** and confirm Saved. Terminate and rerun.
   Confirm Player identity/location/health/resource persist; no half-cast resumes.
   Any cooldown remaining at the save stays remaining on load (offline time does
   not count). The development cylinder resets to 100 HP near the resumed position.
7. Confirm left-touch move, right-drag camera, original upper-right jump, landing,
   another explicit save, background/return and normal Android back/close saving.
   Report observed action/transaction failures and device behavior.

The next enemy/telegraph slice can reuse catalog definitions/effects, stable-ID
world-space targeting, generic executor, tick progression, cancellation and
interruption API, relationship validation, movement gates and typed facts/cue IDs.
It supplies actor-owned scheduling/positions and presentation consumers; it does
not need to replace CombatService or add Player assumptions to execution.

## Production enemy integration

Slice 3 extends the runtime with Region-owned enemy state, Foundation targeting,
fact-driven telegraphs, safe-transform recovery and confirmed development save
deletion. The current contracts supersede earlier slice-specific fixture,
version/residency and void-policy descriptions where applicable. See
[Enemy, targeting and telegraph contracts](ENEMY_TARGETING_TELEGRAPHS.md) and
[ADR-0015](../adr/ADR-0015-region-actor-state-and-recovery.md).

## Slice 4 extension

[Defensive verbs and vertical recovery](DEFENSIVE_VERBS_AND_RECOVERY.md) documents
the authoritative defense flow, transient action registry, current persistence
policy, Region surface-query/fallback contracts and Android acceptance. Its Slice 4
contracts supersede earlier deferred defense/vertical-recovery descriptions.
