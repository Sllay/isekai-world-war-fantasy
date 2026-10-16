# Production defensive verbs and dynamic vertical recovery — Phase 2 Slice 4

## Ownership and authoritative resolution

Combatant composes a transient `DefenseState`; the Player Combat module exposes
it as `foundation.defense` and binds the authored `player_defense.tres` policy.
Other actors can compose the same capability. No Player/enemy type is imported
by the resolver. TargetingService supplies finite positions and horizontal facing
through transient stable-ID callables and removes them on residency loss.

CombatService processes a damage request in this order:

1. Validate one-use request, metadata, identities, live combatants and relationship.
2. Evaluate the existing integer damage scaling.
3. Call pure DefenseResolver once: **DODGE > PARRY > BLOCK > HIT**. Each defense
   independently respects the incoming request's dodgeable/parryable/blockable flag.
4. Commit block resource cost/guard break, resolved HP, defeat and consumed request.
5. Publish one typed `DefenseResolved`, then damage/health/defeat facts where
   applicable. Prevented hits publish no DamageApplied or HealthChanged fact.

No animation, HUD, telegraph or render delta grants immunity. Windows are
exclusive Core tick deadlines (`tick < until`); Core currently uses 0.05 seconds.
Repeated executor advancement in the same tick cannot repeat a commit. Zero
scaled damage retains the accepted no-op policy and emits no defense fact.
CombatService remains the only gameplay health/resource mutation authority;
Combatant construction/restoration initializes validated canonical values.

CombatResult adds outcome, prevented, resolved_damage and action_id while keeping
requested/evaluated/actual and existing accepted/code behavior. Fully prevented
hits are accepted NO_CHANGE transactions. DefenseResolved extends CombatEvent
with raw/evaluated/applied/prevented damage, outcome, action ID and interruption
relevance; inherited source/target/transaction/tick fields provide correlation.
There are no presentation names or scene references in facts.

## Authored verbs

| Action | Windup | Recovery | Cooldown | Energy | Behavior |
| --- | --- | --- | --- | --- | --- |
| basic_dodge | 0 | 6 | 24 | 6 | 6-tick evasion, 1.8m collision-swept displacement |
| basic_guard | 0 | 0 | 0 | 0 activation | Begin guard until semantic release |
| basic_parry | 0 | 4 | 24 | 4 | 4-tick precise window |
| basic_interrupt | 2 | 4 | 30 | 4 | Hostile current entity, 3m range, no damage |

IDs use the `combat.action.` namespace. All timing is simulation time. Activation
rejection spends nothing; commit revalidates actor/resource/range/relationship.
An accepted interrupt that finds no interruptible cast still spends its authored
cost and cooldown: it is a committed attempt with a typed failure result.

PlayerActionAdapter consumes semantic intentions. Dodge direction uses meaningful
camera-relative movement, otherwise facing; PlayerMotor executes a swept
`move_and_collide` through a transient port. Collision can shorten displacement
without extending immunity. The evasion window and movement are separate.

Guard blocks only the authored frontal 120-degree arc. The policy mitigates 7500
basis points: `floor(evaluated * 2500 / 10000)` remains. An 8-unit skirmisher hit
therefore applies 2 and prevents 6, costing 2 energy. Unblockable/rear hits spend
no block cost. Insufficient energy breaks guard and applies the full hit without
spending the remaining energy. Same-tick press/release ends guard; focus loss
releases touch ownership and sends semantic guard end.

Parry requires its own 120-degree frontal arc and a parryable hit. It prevents all
current damage. Early/expired windows offer no protection (unless another defense
independently applies). The skirmisher retains its 24-tick/1.2-second windup;
Parry's 4-tick/0.2-second window rewards reacting near commit.

## Interruption and lifecycle

ActionRuntime is a transient stable-ID executor registry, composed by CombatModule
and bound by actor/session owners. Targeted interrupt effects call the existing
ActionExecutor.interrupt contract, which only cancels interruptible CASTING.
Unavailable/idle/noninterruptible targets return typed CombatResult codes.
Out-of-range/defeated/nonhostile targets reject via normal action validation.

Parry's typed fact queues a correlated reaction. The committing executor drains
it after leaving its busy boundary. `interrupt_committed` can cancel only the
matching execution's remaining RECOVERY, if authored interruptible; it neither
retries nor refunds effects/cost/cooldown and cannot cancel a later execution.
This is a cancellation reaction, not an added stun/posture system. Telegraphs
continue consuming action facts and clear on cancellation.

Defeat, restore, unregistration and residency loss clear active defense. Runtime
clear removes registry bindings, pending reactions and interrupt diagnostics.
Player input and motor remain independent of CombatService's damage logic.

## Canonical persistence

Existing Player Combat v2/action schema v1 stores health, resource, modifiers and
remaining cooldown ticks. No new save section/version is necessary. Guard,
dodge/parry deadlines, active cast/recovery, interruption queue/results, spatial
ports, input, motor displacement and presentation are transient. Both same-session
resume and fresh-process restart begin idle with defenses cleared. Committed
resource/HP and cooldown remain; offline wall time does not expire cooldowns.
No Node, Callable, Resource policy or physics state is canonical save data.

## Region-owned vertical recovery

RegionRecovery extends the accepted last-safe system. RegionScene binds a
transient RegionSurfaceQuery and motion-clear callback; neither is captured.
RegionDefinition authors penetration depth (0.75m), standing offset (0.12m),
walkability threshold (up dot >= 0.70), safety bounds and terrain profile.

Healthy observation uses finite/bounds/threshold checks plus a short authored
profile interpolation. Only suspicious state invokes candidate discovery and
capsule clearance; there is no physics query on each healthy frame. Jumping above
the surface never triggers recovery. Minor penetration within tolerance does not
teleport; it cannot advance last-safe unless the surface is explicitly approved.

HomeValleySurfaceQuery interpolates the actual current single-sheet terrain
profile at current X/Z, including slope and raised plateau. It supplies position,
unit normal, Region ID, stable surface identity and clearance. RegionScene checks
an upright capsule (radius 0.35m, height 1.8m, matching PlayerMotor) at the standing
offset through direct-space collision, excluding the Player body. Candidate
validation rejects nonfinite/foreign/out-of-bounds/nonwalkable/obstructed values
and requires a surface above the Player. Clearance query fails closed.

The port delegates local surface/layer selection to the Region adapter. It never
scans for the globally highest surface. A future cave/bridge adapter must resolve
context and choose an appropriate local surface; no layer graph is implied here.

Fallback order is validated local vertical candidate, validated last-safe,
then authored Region default entry. Recovery preserves Player identity and valid
horizontal facing, clears velocity/movement and pending motor displacement, and
resumes ordinary physics. Last-safe does not advance from an unconfirmed teleport;
normal ground confirmation is required afterward. Diagnostics distinguish
VERTICAL_SURFACE_RECOVERED, LAST_SAFE_RECOVERED and REGION_ENTRY_RECOVERED.

Save capture uses the same validated transform selection without changing live
Player position. Suspicious underfloor state never enters canonical Player save
position. Finite legacy underfloor saves are repaired in staged validation using
validated last-safe/entry before scene attachment; disk is never rewritten by
read/repair. Nonfinite/malformed corruption still rejects. Grounded/approved safe
snapshots retain their established transform/velocity policy.

## Development controls and validation

Debug Android touch controls retain Target, Strike, Heal, Cancel, Save, confirmed
Delete Save and upper-right Jump; the adjacent right column adds Dodge, hold Block,
Parry, Interrupt and Test Underfloor. Buttons reserve only their own rectangles;
left movement and the remaining right drag region remain available. Keyboard
shortcuts are R/G hold/V/I, alongside existing controls. This is development UI;
the final contextual mobile skill/page interface remains deferred.

Test Underfloor injects the current Player below the current local surface and
sets falling velocity. It does not call recover/observe. The normal Region physics
callback must detect it. Recovery method/count and interrupt result appear beside
existing defense/HP diagnostics. Release builds omit the injection control.

Run all seven accepted runners and `bash tools/dev/test_defensive_verbs.sh`.
The new runner checks pure/tick decisions, real enemy executors/telegraphs,
frame-rate sampling, semantic controls, collision-swept dodge, candidate rejection,
actual physics recovery/movement/camera/jump, safe capture/staged repair and
independent-process defense/underfloor persistence. Older recovery assertions
retain their optional-query-absent fallback scenario; new cases exercise the
surface-present path. See TECHNICAL_HANDOFF for the live MCP validation gap.

## BK Android acceptance

1. Pull `phase2/defensive-verbs`, open `client/project.godot` in Godot Android and
   run the main scene in a debug build. Keep the Output log available. If the old
   skirmisher is defeated or energy is insufficient, explicitly use Delete Save
   and its confirmation to start a fresh test session (this discards that slot).
2. Approach the skirmisher and tap Target. Face it by briefly moving toward it,
   then release movement. With no defense, let one complete telegraph hit: HP
   must drop by **8**, with HIT/applied 8. Avoid standing through many extra hits.
3. Face it and hold Block through one windup/hit. Expect BLOCKED, prevented 6,
   applied **2**, energy minus **2**. Release: Guard becomes false. Repeat while
   briefly moving away to face backward but staying within 2.5m: the rear hit
   should apply **8** with no block energy cost. Rotate the camera independently
   to confirm camera orbit alone does not turn the combatant's facing.
4. During the last quarter of its 1.2-second windup, tap Dodge while moving
   sideways. Expect visible collision-safe displacement and 6 energy spent.
   If the attack still commits in range within the 0.3-second window, expect
   DODGED/zero damage. Moving out of range instead cancels the strike normally;
   that is valid avoidance but is not evidence of DODGED. Wait 1.2 simulation
   seconds for Dodge cooldown before repeating.
5. Face the enemy and tap Parry just before impact (within 0.2 seconds). Expect
   PARRIED, prevented 8/applied 0, energy minus 4 and the enemy telegraph ending.
   Wait 1.2 seconds, then Parry at the **start** of a fresh windup: the window
   expires before impact and the strike applies 8. For a late trial, let the hit
   land before pressing Parry; the earlier damage must remain. Keep Block off.
6. Tap Target if needed. Within 3m, tap Interrupt near the beginning of a windup,
   leaving over 0.1 seconds for its cast. Expect CANCELLED interrupt result,
   disappearing telegraph and no damage from that cast; energy minus 4. Wait
   1.5 seconds for its cooldown. An idle/recovery attempt should report
   NOT_CANCELLABLE_PHASE and still cost the committed attempt.
7. Move with left touch, orbit with another finger in the free right area, use
   upper-right Jump, land, Strike and Heal. Confirm existing movement/cast gates,
   target selection and Save still work. Use a fresh session if HP/energy runs
   too low; there is no new regeneration/revive feature.
8. Hold Block and tap Save with another finger; stop/restart. Guard must be false.
   Repeat Save immediately after Dodge or Parry; restart must show zero active
   window/idle action while retaining committed HP/energy and saved remaining
   cooldown. Offline waiting must not expire that saved cooldown.
9. Move somewhere distinctive on the flat area. Release movement and tap Test
   Underfloor. Expect the same Player to return near identical X/Z above local
   terrain, normal falling motion cleared and VERTICAL_SURFACE_RECOVERED/count
   incremented once. Repeat on the raised ridge. Output diagnostics include the
   unchanged Player ID; no second Player may appear. Confirm move/orbit/jump.
10. Save after recovery, stop/restart and confirm the same safe local position,
    identity, health and energy. Background/return and explicit Save must work.
    Finally test Delete Save: cancel the confirmation once (state retained), then
    confirm it (new default session); restart must not restore the deleted slot.

Host/headless results do not establish Android readability, timing ergonomics,
multitouch behavior or device performance. BK must record those observations.

## Next consumers

Equipment can provide defense policy/loadout data and reuse fixed-point combat
resolution, semantic guard begin/end, action cooldown/resource ownership and typed
facts. Mini-boss patterns can use the same executor registry, interruption flags,
dodgeable/blockable/parryable metadata and fact-driven telegraphs. Neither needs
a parallel damage authority. New layered terrain must preserve the surface port's
context selection and conservative clearance/fallback policy.

## Recorded verification — 2026-10-16

| Runner | Checks | Failures |
| --- | ---: | ---: |
| Core | 55 | 0 |
| Player | 23 | 0 |
| World | 50 | 0 |
| Save/Resume (including separate processes) | 110 | 0 |
| Combat | 119 | 0 |
| Combat Actions | 108 | 0 |
| Enemy/Telegraphs | 133 | 0 |
| Defensive Verbs/Recovery | 96 | 0 |
| **Total** | **694** | **0** |

The new suite comprises 49 defense checks, 35 recovery/physics checks and 12
independent-process checks. Development failures in initial tests were resolved:
a missing type annotation, fallback fixtures needing the optional surface port
absent, and grounded-only jump input issued before the new standing offset had
settled. Existing assertions remain; physical tests now wait for ground contact.
Final review also expanded real clearance to include actor collision layers and
added obstruction regression coverage. No final script/test failures or leaked
resources remain. `git diff --check` passes.

Live MCP remained unavailable after the interrupted session's launcher/first
retry and this continuation's one remaining retry. The prescribed allowance is
exhausted; logs were inspected and no additional reconnect was attempted. Android
acceptance above remains pending, including touch ergonomics and timing readability.
