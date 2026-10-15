# Production local save / resume

- **Status:** Implemented — M1.3 accepted; Phase 2 combat integration added
- **Updated:** 2026-10-15

## Ownership

Each module owns its persistent schema and pure validator. `CoreSaveStore` is
only generic infrastructure: JSON-safe capture, format/section migrations,
validation/preparation, dependency-ordered restore, disk read, and temporary-file
write/flush/rename. `prepare_restore` returns a detached, migrated snapshot without
mutating live state or its input. Full-precision JSON preserves clock fractions.
Module restore must remain infallible after successful validation (ADR-0009).

Application orchestration lives in `client/runtime/persistence/`:

- `LocalSaveSlot`: slot identity/path and storage access;
- `SaveIntegrity`: current game/content compatibility and cross-section checks;
- `SaveCoordinator`: startup choice, coherent save, resume and residency ordering.

`client/runtime/game_runtime.gd` wires those contracts to the declared modules
and exposes `save_game()`, `resume_game()`, `request_exit()` and structured
`development_state()`. Player/World/Region ownership and schemas are preserved; Player numeric validation
also rejects values that overflow the physical Vector3 representation.
The coordinator is application-owned, not another gameplay module or a second
clock. It holds transient scene references, never serializes them.

## Current slot

The default slot is `local.current`, at `user://saves/current.json`. Godot resolves
`user://` to the current application's platform storage. The temporary sibling is
`current.json.tmp`; it is never treated as a completed save. Inject a different
`LocalSaveSlot` before runtime startup to select another storage location without
changing gameplay. Tests always inject private temporary directories; they never
write the player's current slot.

One writer per slot is supported. Writes validate a complete snapshot, create the
storage directory, write/flush the temporary sibling, check errors, then rename
it over the slot. A failed write returns `SAVE_WRITE_FAILED`; existing bytes stay
untouched until successful replacement. A leftover temporary file from process
termination is ignored. There is no cloud sync, backup rotation or multi-writer
protocol. Filesystem power-loss durability and Web storage synchronization remain
platform work beyond the current local adapter.

## Canonical contents

Format version 1 stores game version, world ID/seed, exact enabled module version
metadata, and these versioned module sections:

| Section | State |
| --- | --- |
| `core.runtime` v1 | Stable entity ID set; Core tick, fractional remainder, step seconds, time scale and pause flag |
| `foundation.player` v1 | Stable entity ID, world-space position, velocity and horizontal facing |
| `foundation.world` v1 | World ID, seed, schema version and current Region ID |
| `foundation.regions` v1 | Region records: Region ID, World membership, schema version and last entry ID |
| `foundation.player_combat` v1 | Player foreign key, combat profile/version, current health/resource, lifecycle and stable-source modifiers |

Ground contact, pending input, Nodes, cameras, fallback visuals, Region residency,
callbacks and presentation defaults are transient. Region collision and entries
come from matching content definitions, not persisted visual objects. Saved
position/velocity/facing remain canonical even when reattaching the physical body.

Top-level World metadata must match the World section and configured World ID/seed.
Saved ticks must fit the exact JSON integer range; restored large clock backlogs
are clamped before conversion to frame-step counts. Current Region must exist in that content and the Region section. Every Region's
membership/identity must match its definition and dictionary key. Player identity
must exist in Core's validated, duplicate-free identity set. Required persistent
sections must be present; unknown module sets, future format/section/schema
versions and incompatible game/module versions fail. Current application policy
requires exact game/module versions; future compatible releases must explicitly
adjust that policy alongside schema migrations. Generic one-step section and
format migration hooks remain in Core and are exercised by Core tests.

Phase 2 application game version is `0.2.0`. SaveCoordinator stamps the application
version on generic Core captures. The exact four-module M1.3 `0.1.0` snapshot can
upgrade in memory by initializing only the new combat section; all state is then
fully validated. Read never rewrites the slot. Current-version missing combat data
rejects, and Player combat's entity ID must match Player/Core. See
[Combat persistence contracts](COMBAT_FOUNDATION.md). Generic format version is
still 1; Core has no combat or application upgrade policy.

## Startup and resume

1. Boot configured Core, Player, World, Region, Combat and Player Combat modules; create the World scene
   without loading Region residency.
2. Read the selected slot. `NO_SAVE` alone starts a new game using its entry.
3. Existing saves must pass all generic and application integrity checks before
   *any* live state or Region residency changes.
4. For a valid resume, close existing residency if present; restore sections in
   dependency order; call `WorldScene.open_current(true)` to reattach the saved
   Player. That path never applies entry defaults or resets saved velocity.
5. Continue the borrowed Core clock. Initial newly allocated entity IDs are
   replaced by the saved Core set, so no extra Player identity remains.

No `await` or background state mutation occurs within capture/validation/write or
restore/reattach. Calls run on the Godot main thread between callbacks. Saving
keeps the Region resident and does not require exit. Resume validation failure
leaves canonical state, clock and physical residency untouched. If attachment
fails after valid restore, the coordinator restores the previous canonical
snapshot and attempts to reopen its previous residency, reporting rollback status.
A content/engine failure that also prevents reopening remains a visible blocked
error; it never causes an automatic new game or replacement of the save.

## Failure and lifecycle policy

Machine-readable diagnostics include startup mode (`new_game`/`resume`), slot ID
and path, format version, World/Region/Player IDs, saved position/tick and operation
codes. Codes include `NO_SAVE`, `NEW_GAME_READY`, `SAVE_OK`, `RESUME_OK`,
`SAVE_INVALID`, `SAVE_BLOCKED`, `SAVE_WRITE_FAILED`, `RESUME_ATTACH_FAILED` and
`NEW_GAME_FAILED`, with error/reason details. No whole save payload is logged.

Malformed/truncated JSON, incompatible versions, missing sections, unknown Regions,
World mismatches and orphaned/duplicate Player identities produce `SAVE_INVALID`.
An existing invalid slot blocks startup with a visible message, pauses the runtime
clock, and latches writes blocked. It is not deleted or overwritten automatically.
Restore/repair the slot externally and restart, or explicitly retry `resume_game()`
after repair. The latter clears the error state and resumes processing. A missing
slot during active play returns `NO_SAVE` without resetting the game.

Godot window-close and Android back requests call `request_exit()`, which saves
first and refuses graceful exit on save failure. Application pause attempts the
same production save operation and reports failures. `_exit_tree` only releases
residency/modules; it does not overwrite the explicit checkpoint. Android may
kill a process without any lifecycle notification, so explicit saving remains
available and necessary. There is no claim of guaranteed save-on-kill.

Debug builds expose a minimal **Save (K)** button and K shortcut; both call the
production API and show success/failure feedback. Release builds expose the API
for later UI, without final slot/settings UI in this slice.

## Validation

Run Core, Player and World suites, then `bash tools/dev/test_save_resume.sh`.
The persistence runner uses isolated disk files and cleans its temporary directory.
It covers valid/invalid startup, active saves, repeated restore, cross-section
corruption, no partial mutation, protected corrupt bytes, deterministic write
failure, recovery, and test cleanup. Independent Godot OS processes exercise:
new game -> keyboard movement up the ridge -> save -> complete runtime shutdown
and process exit -> fresh process -> exact canonical restore -> jump/move/camera
and clock continuation -> save again. An additional process tests pause and
normal-exit saving, including refusal to quit after a failed write.

MCP: the prescribed launcher reported a listening bridge, but the two permitted
read retries failed (`Connection closed` / `Not connected to Godot`). The editor
log was inspected and recovery stopped. Live MCP acceptance is blocked; headless
Godot tests cover the actual runtime and disk path. Android remains BK's device
acceptance; no Codespace frame-rate/mobile performance claim is made.

## BK Android acceptance

1. Fetch/pull `m1.3/save-resume-loop`; open `client/project.godot` in Godot Android
   and run the project main scene. With no current slot it reports `NEW_GAME_READY`
   and `NO_SAVE`; otherwise it resumes the existing slot.
2. Initially keep camera yaw unchanged and drag upward in the left 45% for about
   five seconds to reach the raised ridge (or move to another distinctive place
   if resuming). Release movement and tap **Save (K)**, left of the upper-right
   jump circle. Confirm **Saved** and the `SAVE_OK` output record. Record its
   Player ID, position, World/Region IDs and tick.
3. Immediately stop/terminate the running game. Start it again. Confirm the
   `RESUME_OK` record has the same Player/World/Region IDs and saved position/tick,
   and the Player remains at that position instead of the arrival entry. The
   clock naturally advances after that startup record. Camera yaw resets because
   camera state is intentionally transient.
4. Move with left touch, orbit with right horizontal drag, and jump using the
   upper-right circle (80px from right, 90px from top). Confirm landing and save
   again. Repeat stop/start once more.
5. Background the game and return, then perform a normal Android back/close if
   supported by the editor's player window. Confirm lifecycle `SAVE_OK` records
   and resume. Explicit saving must still work independently of these hooks.
6. Report device results and any failure codes. Corruption testing is automated;
   do not delete the current save merely to test restart. If corrupted, preserve
   it for diagnosis and restore a known-valid copy before restarting.

Desktop controls remain WASD/arrows, Space, Q/E/right-mouse drag; K saves.
