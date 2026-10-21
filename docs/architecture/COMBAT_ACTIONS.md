# Production combat actions — C1-R1-P1

## Run 1 loadouts and targeting

ActionLoadout supplies primary and skill_1/2/3 from validated trusted content.
The host copies an installed loadout only when idle/cancelled; clients request a
slot, never equip an arbitrary action ID. Default slot 1 is strong, slot 2 heal,
slot 3 empty. G/Y/Strong and H/LB/Heal remain input aliases; desktop 1/2/3 and
PlayerIntent.request_skill provide the generic slot path. The technical HUD reads
equipped IDs/cooldowns, so it does not require final universal skills or equipment
UI. Loadout IDs/slots are included in detached Gateway snapshots for presentation.
Changing slots/loadouts never resets per-action cooldowns. Authored fixed
loadouts need no new save field; future player-owned equipment needs explicit
persistence. See ADR-0017 and the C1_R1_P1_FOUNDATION mission contract.

## A1 extension (current)

The historical contracts below remain domain regression documentation. Runtime
Player execution now goes through PlayerAuthorityAdapter -> AuthorityGateway ->
LocalAuthorityHost -> the same ActionExecutor/CombatService. The legacy
PlayerActionAdapter remains a domain harness/slot contract, not a production
client outcome bypass. Secondary/heal stays available; G/Y/Strong requests the
new `combat.action.strong_strike` (26 damage, 10 energy, 10 wind-up ticks,
10 recovery ticks, 40 cooldown ticks). Basic attacks retain their accepted tuning.

CombatDefense owns transient guard/dodge/stagger windows. CombatService's trusted
mitigation port returns a bounded amount/cost decision, validated before the
single transaction commits energy and health. DefenseResolved facts distinguish
GUARDED/DODGED/GUARD_FAILED, including zero-damage evasion; DamageApplied remains
the confirmed health impact. Strong tags permit a six-tick stagger with a
20-tick immunity window; lights never interrupt. Guarded strong impacts do not
stagger. Generic executor gates prevent actions/movement while staggered.

CombatFeedback consumes facts to drive a one-handed sword, wind-up/swing pose,
body reaction, impact flash, local 40 ms pose hold and synthesized swing/impact
audio. It never changes Engine time scale, health, defense or action deadlines.
Player Combat section v3 retains remaining dodge-reuse and stagger-immunity ticks,
with an explicit v2 migration. Active guard/evasion windows stay transient, so a
reload cannot restore invulnerability or bypass the reuse interval. Enemy active
stagger remains transient, matching its existing cast/recovery restore policy.
HUD includes HP/energy/lifecycle, confirmed hit and independent defense outcome
messages. Headless tests skip audio playback; the live Runtime MCP world
exercises the same presentation adapter. Final authored character art and Android
feel/performance acceptance remain separate from this representative foundation.

## Ownership and content

`foundation.combat` composes `ActionCatalog` alongside the existing, unchanged
`CombatService`. Both depend only on Core. `foundation.actions` resolves the
catalog; `foundation.player_combat` owns one `ActionExecutor` attached under
`foundation.actions` in the Player capability container. Other actor owners can
construct the same executor with their stable ID, CombatService and catalog.
Production slot mapping lives in the host's ActionLoadout; PlayerActionAdapter is
retained only for explicit domain harnesses, outside generic execution.
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
| `combat.action.strong_strike` | 10 ticks | 10 ticks | 40 ticks | 10 energy | 26 physical damage, 2.5 range, strong stagger tag |

Strike allows movement/turning; heal restricts both during casting. These are real
content definitions, with conservative initial tuning. No hitbox geometry,
projectile, mitigation, animation or VFX behavior is implied by their metadata.

## Target and effect boundaries

`ActionTarget` is a copied value request containing a stable entity ID and finite
world-space direction/point values. SELF resolves to the owner,
regardless of caller target. ENTITY requires a pure `position_of(id)` provider
returning a finite world-space Vector3 or null. Missing positions reject rather
than falling back to scene coordinates. Range uses squared 3D distance, inclusive
at the maximum. ActionTargetResolver also supports DIRECTION/POINT through an
authority-configured world_query port and authored target_query_id; no port means
TARGET_QUERY_UNAVAILABLE. Directional aim must be unit length; point range is
checked against canonical origin. The trusted query returns 1..max_targets stable
IDs (maximum eight, no duplicates), which are sorted and independently validated
for alive state, range, visibility and relationship before any spend. Resolution
runs again at commit. No targeting code inspects camera mode or trusts a cursor
intersection as a hit. Current melee content uses ENTITY; spatial query integration
is deterministic extension coverage, not a shipped ranged/projectile arsenal.
Typed facts include target_ids and aim alongside the compatible target_id field.

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
