# Production enemy, targeting and telegraphs — Phase 2 Slice 3

## Ownership and composition

`gameplay.enemies` registers `enemy.archetype.melee_skirmisher` from a typed
Resource. It depends on Regions, Combat and Targeting. The application binds Player
target ports independently; enemy registration never clears another actor owner.
`EnemyActor` is a Region-owned `RegionActorState`, not a Player subclass or Node.
It composes Core identity, an `EntityComponents` capability container, Combatant,
ActionExecutor, world-space position/facing and a location capability. No AI,
rendering, loot, factions or quests live inside CombatService or the actor state.

`region.home_valley` authors `spawn.melee_skirmisher` at local (4, 0, 2).
A1 adds `spawn.melee_skirmisher_second` at (18, 0, -2) through the same actor,
controller, action and Region persistence contracts. Application save version
0.3.0 explicitly migrates old 0.2.0 slots by adding only the new authored actor
and a fresh Core identity; existing damaged/defeated actors are preserved. A
missing actor in a current-release slot is corruption, not a default respawn.
The spawn key is an authored content binding, **not** the entity ID. Core allocates
one persistent 32-hex entity ID on new game; Region restores that exact ID and
rebinds the same capabilities. Node names/paths have no identity meaning.
RegionScene owns the physical/presentation Nodes under Actors; RegionState owns
the actor record independently of loaded Nodes. Generic RegionActorState ports
capture, validate, restore and react to residency loss without World importing
combat or enemy code. Unload cancels uncommitted actions; it does not delete state.

The capsule is a neutral presentation adapter for production gameplay. It has no
canonical content/identity authority and is not final enemy art. Its flattened
form indicates defeat. No generated art, rig, navigation framework or respawn
system is introduced.

## Autonomous controller and movement

`EnemyController` runs once per distinct Core simulation tick (20 Hz default),
using the same replay of individual ticks as Player actions. Decisions and motion
displacement do not use render delta. The state flow is:

`IDLE -> ACQUIRE -> APPROACH -> ATTACK -> RECOVER -> APPROACH`

No hostile within 8m returns acquisition to IDLE. Approach stops 0.25m inside the
action's 2.5m range. CASTING/RECOVERY are observed from the actual ActionExecutor,
not independent AI timers. A target that becomes invalid, goes beyond retention
range, or takes the actor beyond its 12m home leash causes DISENGAGE -> RETURN_HOME.
The controller returns through its movement port, then reacquires from home.
DEFEATED is terminal until an explicit future world policy changes lifecycle.
Typed CombatantDefeated consumption immediately clears controller intent and
advances the executor's existing defeated-owner cancellation. No scene is freed.

`EnemyBody.approach(destination, tick_seconds)` is the movement boundary. The
current adapter uses bounded direct displacement, collision sliding and ground
settling on the authored open terrain. It has no combat decisions. Navigation can
replace this port later; there is no pathfinding or offscreen simulation claim.

## Same action pipeline for both owners

Player semantic input -> PlayerActionAdapter -> ActionExecutor -> CombatService.
Enemy controller intent -> **the same ActionExecutor class/catalog** -> **the same
CombatService instance**. Neither AI nor presentation subtracts health.

`combat.action.basic_strike` remains the Player action. The shared catalog also
contains `combat.action.enemy.basic_strike`: 24-tick windup (1.2 seconds), 14-tick
recovery, 40-tick cooldown, 2.5m entity range and one 8-unit physical damage effect.
It is interruptible/cancellable and stationary during cast. Separate data tuning
keeps the Player's accepted quick strike unchanged. All effect handling, resource
checks, range/relationship validation, exactly-once commit and typed facts reuse
the accepted action/combat implementations without parallel frameworks.

The Player can leave range during windup. Commit revalidates world-space distance,
alive state and relationship; an invalid target/range cancels without damage,
resource cost or cooldown. Remaining in range produces exactly one effect.

## Targeting boundary

`foundation.targeting` depends only on Combat. It owns TargetingService and a
minimal DispositionPolicy. Combat remains neutral by default when this optional
integration is absent. Authored traveler/hostile disposition groups express this
encounter, without a faction simulation or Player type check in combat rules.

Target registration uses stable IDs plus transient pure world-position ports.
Hostile queries require registered finite world data, alive source/target and the
existing Combat relationship boundary. Results sort by distance then stable ID.
Current selections contain IDs only. Player selection cycles these candidates;
AI independently acquires the nearest candidate. Current Player target is retained
within 20m, not the attack's 2.5m range. Every read validates defeat, unload and
range; invalid selections clear. Region position ports return unavailable
immediately on unload. Resume clears registration and selections and rebinds
residency using restored IDs.

Target/T selects without executing. Strike requests the current valid entity;
Heal remains self-targeted through action data. Direction/point target values and
explicit action TargetMode remain separate extension points. Future precision
trajectories can ignore entity lock; this boundary never guarantees a hit. Last
attacked, previous/next, assisted aim and area/point selection can extend query
policy without changing damage or executor ownership.

## Telegraph projection and rendering

`TelegraphDefinition` is typed Resource data with stable definition ID, shape,
color and band width. Shape contracts reserve circle, line, sector and world point;
only the required circle is rendered now. `combat.telegraph.melee_range` presents
an **entity strike range**, not an AoE that damages everybody inside the band.
The band communicates the upper horizontal extent of the executor's spherical
world-distance range; height/range and the selected entity are still validated
by simulation. The current home encounter is on the flat valley floor.

TelegraphTracker consumes ActionStarted and resolves metadata from ActionCatalog.
Its transient value records include execution/owner/target IDs, range, start tick
and commit tick. ActionCommitted/Cancelled/Completed and relevant defeat facts
remove records. Progress uses the same Core tick/deadline, never animation time.
Region unload cancels the action; resume clears projections. No telegraph records,
Nodes, callbacks or animation state are serialized.

TelegraphRenderer is a separate read-only adapter: a 48-segment opaque narrow band,
ground projected at creation using a surface-only physics mask (terrain also
retains ordinary collision), unshaded orange warming to gold during windup, no
particles, shadows or transparent area fill. Rendering can be removed entirely
and combat still behaves identically. The enemy remains stationary during this
telegraphed cast. Moving shapes and additional forms need their own presentation
adapters when a real action requires them.

## Persistence and compatibility

Region section v2 stores actor snapshots under the authored spawn binding:
entity ID, archetype ID, Region ID, world position/facing, authored home,
Combatant health/resource/lifecycle/modifiers, and ActionExecutor remaining
cooldowns. Region's generic ports delegate feature schema validation/rebinding to
the owner. SaveIntegrity verifies actor identity membership in Core and uniqueness
against Player/other actors before mutating any live state. Defeated actors remain
saved and resident; no automatic respawn/despawn is implemented.

Active casts, recovery, controller state, movement callbacks, selected targets and
telegraphs never resume. Committed effects/resources remain; cooldowns preserve
remaining simulation ticks without offline expiry. Enemy cooldown exceeds recovery,
so restarting cannot skip an availability restriction. Cancelling an uncommitted
cast on restart grants no effect/cost, consistent with accepted action policy.

Format/game/module versions remain compatible; Region section v2 identifies the
schema extension. The application explicitly upgrades only the exact accepted
six-module Slice 1/2 release with Region v1, introducing the two nonpersistent
module manifests and one pristine authored actor/Core identity. The existing exact
four-module M1.3 upgrade chains into it. Current saves missing actor/module state
reject instead of silently recreating content. Read/migration never rewrites disk.

## Safe transform and void recovery

RegionDefinition owns a local recovery Y threshold, optional horizontal safety
bounds, and an authored surface approval profile. Home Valley's threshold is -12m
relative to its origin; bounds/profile match its terrain. Player owns no map
coordinates or bounds. Each Region record owns the single current Player's
last-safe position/facing; Region identity is implicit in the containing record.

RegionRecovery observes the actual Player state at physics boundaries. Finite
positions above threshold/inside bounds update last-safe only when grounded or
explicitly approved against the Region's authored surface (also permits entry
and immediate post-resume contact before a physics callback). Airborne/void state
does not update recovery. Crossing a constraint restores the validated last-safe
transform, or the Region's default entry if none exists. Falling velocity and
movement intent clear; the same Player/motor/input/camera survive. Structured
`VOID_RECOVERED` and development_state expose the result.

SaveCoordinator substitutes a validated recovery transform and zero velocity for
an unsafe or unapproved airborne snapshot **without mutating live gameplay**.
Valid grounded/surface snapshots retain their transform and velocity. Last-safe is
stored in Region v2, not Player/Core. Finite legacy void/out-of-bounds positions
are repaired in staged application validation using last-safe/default entry;
nonfinite/gross malformed data still rejects. No fall damage, checkpoint, death
or revive gameplay is implied.

### Future vertical terrain recovery refinement

Android acceptance could not naturally reproduce a terrain fall-through, but BK
identified an additional resilience case that must be preserved for future world
work: collision bugs may place the Player below otherwise valid terrain while the
same X/Z location still has a usable surface above.

When terrain/world querying becomes rich enough to support this safely, Region
recovery should first attempt a **dynamic vertical surface recovery** before
falling back to last-safe/default entry. The recovery query belongs to World/Region,
not Player code: use the Player's current horizontal position, query upward/downward
against authoritative walkable terrain/surface data, choose a validated standing
transform slightly above that surface, verify collision clearance and Region
safety constraints, then restore the same Player with falling velocity cleared.
If no trustworthy surface can be resolved, use the existing last-safe/default
entry path. This is a future resilience extension, not a license to teleport from
normal airborne gameplay or bypass caves/bridges/multi-level structures without a
surface-selection policy.

## Development save deletion

Debug SaveControls sits beside Save and remains available even when corrupt saves
block startup. First Delete Save press arms Confirm Delete for three seconds;
second press in that interval invokes SaveCoordinator.delete_and_reset. UI never
performs file operations. LocalSaveSlot.delete removes only the current slot and
its temporary atomic-write sibling, never directories or unrelated project data.

The coordinator validates a clean initial snapshot before deletion, latches off
autosave, closes residency, restores pristine module state and opens a new game.
`SAVE_DELETED` reports success; failure codes preserve a visible result. Pause and
normal exit cannot recreate the deleted file. Autosave remains suppressed until
an explicit successful Save, which establishes the user's new checkpoint. This
is a development recovery control, not final slot UI.

## Diagnostics, tests and acceptance

Runtime development_state adds enemy identity/archetype/HP/lifecycle, AI state,
target, action/phase, home/leash distances, Player current target, active telegraph
values, last-safe transform, recovery count, and delete/reset/autosave state.
The small existing debug label adds enemy HP/state and selection; no final HUD.
The old Damage 10 development button is removed so it cannot conflict with the
left movement touch zone or substitute for the real encounter.
The old cylinder is instantiated only under `--combat-actions-acceptance` for the
accepted bounded fixture tests; normal Android/runtime sessions use the enemy.

Run all six existing test runners plus `tools/dev/test_enemy_telegraphs.sh`.
The latter covers production integration, isolated targeting, reaction/commit,
lifecycle, corruption and release migration, recovery, actual Delete controls,
autosave suppression and separate Godot OS-process damage/cast/defeat/recovery.
Final automated result: **598 checks, zero failures**, with no script errors or
resource leaks. Core 55; Player 23; World 50; Save/Resume 110; Combat 119;
Combat Actions 108; Enemy/Telegraphs 133 (98 integration plus 35 across four
fresh-process phases). `git diff --check` also passes. No gameplay code was added
to Core, and both generic gameplay-leakage scans pass.

Existing exact catalog/module/entity-count assertions now include the added
production content; historical migration fixtures construct the actual old schema.
No old behavior assertions were removed.

Live MCP was blocked on the implementation host: one official ensure launcher
reported healthy; both permitted read retries returned Not connected. The editor
log was inspected, recovery stopped, and the official stop script restored local
configuration.

BK Android acceptance passed for the device-observable Slice 3 behavior: the
telegraph is clearly readable, leaving its area avoids the pending hit, the enemy
acquires/follows the Player and disengages after sufficient distance, defeated
enemy state can be saved, and Delete Save/confirmation works correctly. BK noted
that the current enemy movement is visibly simple, which is expected for this
slice and is why movement remains behind a replaceable navigation port. A natural
terrain fall-through/void case could not be reproduced on device, so runtime void
recovery remains automated/headless validated rather than manually device-proven.

## BK Android acceptance steps

1. Pull `phase2/enemy-telegraphs`; open `client/project.godot` in Godot Android and
   run the normal main scene. If needed, tap Delete Save, then Confirm Delete
   within three seconds. Confirm a clean entry and a standing warm-colored capsule
   near the Player. A previous valid Slice 2 slot upgrades without losing Player
   state; a saved defeated enemy remains defeated until explicit deletion.
2. Move with the left touch zone; rotate by dragging the right side; jump with
   the upper-right circle. Combine movement with camera and jump.
3. Tap Target above Strike. Confirm the small status reads Target: Skirmisher and
   no attack happens from selection alone. Approach within melee distance and tap
   Strike; enemy HP falls by 12 once after the short Player windup. Heal restores
   up to 15 HP for 5 energy and is self-targeted; its cast stops movement.
4. Let the enemy approach and stop. Its orange ground ring appears for about
   1.2 seconds, warming toward gold. Stay inside range once: Player HP falls by
   exactly 8 at commit, then the ring disappears. Record phone readability.
5. On the next windup move outside the ring before commit. Confirm no health loss
   for that attack and the ring clears. Repeat a few times while moving/rotating.
6. Run more than 12m from its home; confirm disengage and return. Come back,
   select again if selection cleared beyond 20m, and Strike until HP reaches 0
   (nine full hits from 100). Confirm flattened defeated capsule, stopped AI,
   cleared target and no further attacks. No automatic respawn occurs.
7. For persistence, first damage a fresh enemy, tap Save, stop/terminate the game,
   rerun and confirm the same diagnostic enemy ID and reduced HP. Repeat after
   defeat and confirm it stays defeated. Active windup must not resume halfway.
8. Walk off a terrain edge if practical; authored bounds/void recovery should
   return the same Player safely with falling velocity cleared. Move, rotate,
   jump, Save, terminate and resume; confirm no infinite fall.
9. Tap Delete Save once, wait over three seconds, then press again: this only
   rearms confirmation. Press a second time promptly to delete. Confirm
   SAVE_DELETED/new-game health and standing enemy. Background/return or exit
   without pressing Save; rerun and confirm new-game startup rather than the
   deleted checkpoint. Explicit Save establishes the new slot again.

Defensive verbs can build on existing damage flags, interruption/cancellation,
shared action definitions, tick timing, targeting, telegraph facts and retained
defeat state. Dodge/block/parry require their own authoritative mitigation/action
policy; none needs to replace this controller, service, executor or Region owner.
