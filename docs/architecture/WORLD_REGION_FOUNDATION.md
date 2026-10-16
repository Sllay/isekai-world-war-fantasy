# Production World / Region shell

M1.3 Slice 3 boots `core.runtime`, `foundation.player`, `foundation.world` and
`foundation.regions`. Core and Player state/movement/input code remain unchanged.
The runtime explicitly supplies a `WorldDefinition` and a `WorldScene`; Region
content scenes are declared by `RegionDefinition`, never discovered by node name.

## Ownership and contracts

- `WorldModule` requires only Core and provides `foundation.world` (`WorldState`)
  and `foundation.world_definition`. World owns its stable ID, seed, schema version
  and current region ID. Its clock is a borrowed reference to `core.clock`.
- `RegionModule` requires World, Player and Core. It provides `foundation.regions`
  (`RegionDirectory`) and `foundation.player_location`. The directory holds
  region records; each `RegionState` owns lifecycle and persistent state and
  explicitly references its World. IDs and duplicates are validated before boot.
- Region injects its borrowed `PlayerLocation` into the existing Player capability
  container as `foundation.location`. Player does not depend on World or Region,
  copy their IDs into its save section, or own their services.
- `WorldScene` handles one resident Region. `RegionScene` owns terrain and actor
  attachment. Region entry selection writes canonical Player position and clears
  transient motion before constructing `PlayerAvatar`. The avatar is the reusable
  Slice 2 composition extracted from the old host, with no floor/spawn ownership.
  The old floor fixture exists only under tests.

IDs come from `primary_world.tres`: the initial local world instance is
`world.primary`, seed `77231`, with `region.home_valley`. New worlds supply their
own immutable world ID via a WorldDefinition; changing node names has no identity
meaning. The seed is persisted but does not drive terrain generation in this slice.

## Residency, placement and future chunks

Region residency follows `UNLOADED -> LOADING -> LOADED -> UNLOADING -> UNLOADED`.
Failed scene-contract validation cancels loading back to UNLOADED. Duplicate
resident attachment, unknown entries and entry into an unloaded region fail.
Unload synchronously releases the physical player before another attachment.
Canonical region records survive scene unload. Residency is transient, not saved.

Entry IDs map to explicit region-local positions. Coordinates use translation-only
origins: `world_position = region.origin + local_position`. Terrain is translated
under the Region; actor parents retain identity transforms because PlayerState
uses world-space physics coordinates. Hosts must not rotate/scale those parents.

`chunk_at` uses floor division in local X/Z, including negative coordinates;
`chunk_id` combines region ID and signed cell coordinates. `chunk_bounds` defines
half-open horizontal bounds. These are addressing contracts only: no chunks are
loaded or simulated. Future streaming providers attach collision/visual content
under Region's `Terrain` boundary. Region owns the simulation LOD request hook
(`UNASSIGNED/ACTIVE/REDUCED/AGGREGATE/LATENT`); no LOD policy, scheduler, promotion
or background simulation runs yet. Definitions have namespaced metadata reference
slots for later territory, biome, faction, weather or chunk content. No such
systems are instantiated by this slice.

## Physical content

`world/regions/home_valley.tscn` is the first production Region container, using
Compatibility rendering and a neutral rough material. An authored 96m-wide
cross-section has a floor, a 12m continuous ramp (z=-4 to -16) and a ridge 3m
above the floor. A single surface supplies visual and collision geometry; it is
not a seed generator or a streaming implementation. The two entries are
`entry.arrival` at (0, 0.1, 8) and `entry.ridge` at (0, 3.1, -24), region-local.
No decorative or character art is generated. Surface edges are finite, without
respawn/void recovery; those policies need a later gameplay decision.

## Persistence integration

World and Region modules each own version-1 Core save sections. World persists
ID, seed, schema version and current region. Region persists its complete known
record set, each with region ID, world membership, schema version and last entry.
Definitions supply static geometry, origin, entries and metadata; they are content,
not inferred from saved presentation Nodes. State validators reject unknown regions,
wrong world membership, unsupported schema and unknown entries without mutation.

The application SaveCoordinator stops residency, restores Core/Player/World/Region sections, then
calls `WorldScene.open_current(true)` to attach the restored Player without applying
entry defaults or resetting velocity. Restore keeps World/Region service objects
stable. Worlds must be configured with the matching content/ID before validation.
Sections do not restore resident Nodes themselves; the coordinator owns disk I/O,
startup policy, full prevalidation and reattachment. SaveIntegrity checks top-level
World metadata and Core entity membership before mutation. See
[SAVE_SYSTEM.md](SAVE_SYSTEM.md) and ADR-0012. No second clock or
persisted clock copy exists; Region reads the borrowed Core tick.

## Diagnostics and validation

`WorldScene.development_state()` reports world ID/seed/current region, Core tick,
Region lifecycle, Player ID/position/velocity/grounded, local/chunk coordinates,
camera yaw and presentation direction. No debug HUD is added.

Run, in order:

```sh
bash tools/dev/test_core.sh
bash tools/dev/test_player.sh
bash tools/dev/test_world.sh
```

Validated suites: Core 55 checks, Player 23 checks, World/Region 50 checks, all with
zero failures. World tests cover identity, invalid/duplicate definitions, lifecycle, ownership,
clock sharing, entry placement, local/chunk addressing, real terrain collision,
keyboard ramp traversal, camera rotation, persistence validation/restore, resume,
repeated Region/runtime load/unload and dependency-cycle rejection.
Live MCP reads were blocked after the prescribed launcher and two retries on this
host; the editor log reported a listening bridge but the tool could not retain a
connection. Engine-visible coverage is headless, not a completed live MCP or
physical Android acceptance result.

## BK Android test

1. Fetch/pull `m1.3/world-region-shell`, open `client/project.godot` in Godot Android,
   and run the project main scene (not an M1.2 scene).
2. Confirm the player starts on the valley floor. Drag upward in the left 45% of
   the screen, with the camera initially unchanged, for about 5 seconds: the
   player should ascend the broad ramp and stop on the raised ridge. Release to
   stop, then drag downward to descend.
3. Hold a movement finger on the left and drag horizontally on the right to orbit
   the camera. Movement remains relative to the new camera orientation.
4. Tap the upper-right circle (80px from right, 90px from top) to jump; retain the
   movement finger to jump while moving. Confirm landing on floor/ramp/ridge.
5. Stop and rerun twice; confirm clean loading and the initial arrival entry.
   With Slice 4, a saved slot resumes its checkpoint; see SAVE_SYSTEM.md for the
   Android save/terminate/resume acceptance steps.

Desktop equivalents: WASD/arrows, Space, Q/E or right-mouse drag. Controller:
left stick, A/cross, right stick. Report real-device control/visual results;
headless/Codespace frame rate is not mobile performance evidence.

## Region actor and recovery extension

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
