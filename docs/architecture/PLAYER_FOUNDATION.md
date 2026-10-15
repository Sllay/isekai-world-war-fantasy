# Production player foundation

Slice 2 composes `foundation.player` with `core.runtime` in
`client/runtime/game_runtime.gd`. Core remains independently bootable with
`--core-smoke`; no player rules or input dependencies are added to Core.

The module declares its Core dependency and provides `foundation.player`
(`PlayerState`) and `foundation.player_capabilities` (`EntityComponents`).
The latter exposes `foundation.movement` and remains stable across restores so
later systems can attach capabilities without inspecting physical/visual Nodes.
The entity ID is allocated by Core. Module-owned section version 1 persists ID,
position, velocity and horizontal facing as JSON values. Ground contact and
pending input are transient and reset on restore. Save files must retain the
matching Core entity section; application `SaveIntegrity` validates that reference
before save or resume. See [save/resume contracts](SAVE_SYSTEM.md).

`PlayerIntent` carries movement, one-shot jump and incremental camera rotation.
Only `PlayerInput` reads hardware events. Left touch and right touch track
independent finger IDs. Keyboard, first connected controller and touch feed the
same intent. Release and focus loss clear touch ownership. The motor consumes
intent in fixed physics steps, uses CharacterBody3D floor/slope collision, and
writes physical results to PlayerState. Rendering never supplies canonical state.
Movement is camera-relative; modifiers can supply finite nonnegative speed
multipliers without referencing equipment, classes or combat.

`default_tuning.tres` uses exported `PlayerTuning` defaults for movement, floor
snap/angle, camera distance/inclination, smoothing and device sensitivity.
Touch defaults to 0.012 radians/pixel (about 69 degrees per 100 pixels), mouse
0.008, and controller/Q/E 3.5 radians/second. Camera inclination and distance
have bounded operating ranges for future zoom/occlusion work. Camera state is
local presentation state, excluded from persistent physical state.

`PlayerPresentation.present` passes physical state and a resolved view to
`apply_pose`. Views are front/back/side, with a horizontal-mirror flag for the
opposite side. A future rig adapter owns modular parts, bones/IK, equipment and
accessory layers, named held-item attachment Nodes and view-dependent ordering.
These are extension boundaries, not a completed animation or equipment system.
The current adapter uses engine primitives solely to observe movement; no
character asset is produced by this slice.

Slice 3 replaces `RuntimePlayerHost` with Region-owned placement and collision.
`PlayerAvatar` retains only reusable motor/input/camera/presentation composition;
the previous floor fixture now lives under tests. Physical Player positions use
world-space coordinates with identity actor parents. Region supplies the borrowed
`foundation.location` capability through the existing container, without changing
Player's module dependencies or persistent state. See
[World/Region contracts](WORLD_REGION_FOUNDATION.md) for spawning and resume.
`PlayerAvatar.development_state()` exposes the original Player diagnostics;
`WorldScene.development_state()` adds World/Region context.

Phase 2 attaches `foundation.combatant` through a separate Player Combat adapter;
movement/input/camera and Player state ownership remain unchanged. See
[Combat foundation](COMBAT_FOUNDATION.md).

Run `bash tools/dev/test_core.sh` then `bash tools/dev/test_player.sh`.
Android validation: run the project main scene, drag anywhere in the left 45%
for movement (70px full deflection), drag horizontally on the right to rotate,
and tap the upper-right circle (80px from the right edge, 90px from the top) to
jump. Keep the left finger held while rotating or jumping with another finger.
Desktop: WASD/arrows, Space, Q/E or right-mouse drag. Controller: left stick,
A/cross (Godot A), right stick. Actual Android feel/performance requires BK's
physical-device check.
