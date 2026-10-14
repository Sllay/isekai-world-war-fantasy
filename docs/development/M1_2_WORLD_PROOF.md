# M1.2 Gate D — client world proof

Owner: client test world, `client/tests/world_proof/`. This isolated proof has no
server, persistence, combat, inventory, or production input/UI dependencies.
Open `client/project.godot` with Godot 4.7.2 and run the project (F6 also runs the
proof scene). Both desktop and mobile select Compatibility rendering.

## Components and contracts

- `ProofInput`: normalized movement intent, orbit intent, and a consumed jump
  request. Keyboard, controller, and provisional multitouch share this adapter.
  Future touch controls can call `set_touch_movement`, `set_touch_orbit`, and
  `request_jump`. Touch state clears on release, focus loss, or application pause.
- `ProofPlayer`: CharacterBody3D, gravity, ground movement, small jump and respawn
  after falling below the test world. Collision is independent of the billboard.
- `ProofCamera`: perspective, inclined follow camera with smooth yaw around the
  player. Movement follows camera yaw.
- Debug label: quarter-second updates of FPS, mean rendered frame delta, position,
  grounded state, engine, actual renderer, OS, and debug/release build type.
- Authored static meshes/colliders: 24 m ground, 1.5 m elevated platform, ramp,
  occluding wall, and simple ground reference lines. No dynamic mesh generation,
  expensive shadows, postprocessing, or final art. The placeholder is a Sprite3D
  billboard with normal depth testing, so geometry can hide it.

There is no persistent data or domain event bus for this standalone proof.
Scene-exported references wire the components; runtime `_mcp_state()` methods
provide observation without deriving physical state from the presentation.
Input actions are registered locally at scene entry rather than changing the
production input map. Hold Q/E or the controller right stick to orbit; movement
uses WASD/arrows or the controller left stick; Space/controller A requests jump.

## BK — exact Android test procedure

1. In the existing Termux checkout: `git fetch origin`, then
   `git switch --track origin/m1.2/client-world-proof` on first use (or
   `git switch m1.2/client-world-proof` followed by `git pull --ff-only`).
   Record `git rev-parse HEAD`. Resolve any local changes before switching.
2. Open this checkout's `client/project.godot` in Godot Android Editor 4.7.2.
   Wait for import and run the project in landscape. No MCP addon or GABE setup
   is required for running this scene.
3. Confirm the overlay reports `gl_compatibility`, the ground is genuinely 3D,
   the character looks flat, and the camera has perspective and an incline.
4. Movement: touch anywhere in the **left half**, keep the finger down, and drag
   away from that starting point. Up means camera-forward; drag distance controls
   strength (full strength at 12% of viewport height). Release to stop.
5. Orbit: use a second finger in the **right half above the bottom 30%**. Drag
   horizontally to rotate smoothly. Release, then confirm movement follows the
   new camera direction. These are invisible proof gestures, not final UI.
6. Jump: tap the **right half's bottom 30%** while grounded. Movement and jump
   can be combined using separate fingers. Confirm Y rises, grounded becomes
   false, then Y returns and grounded becomes true. Air taps do not double jump.
7. At initial camera orientation, move up from spawn `(0, 0, 1)` onto the green
   ramp at X=0, Z=-2 to -6, then the blue platform at Z=-6 to -9. Confirm the
   player's Y rises to about 1.5 and returns on descent. Walk off an edge to
   confirm gravity. The red wall is near X=4, Z=-1: move behind it and orbit to
   confirm ordinary depth occlusion and collision (no automatic wall fading).
8. Release all fingers, background the app, resume, and verify there is no stuck
   movement/orbit. Repeat movement + orbit + jump with multiple fingers.
9. Record device model, Android version, commit, renderer, FPS/frame-time range,
   visual/touch issues, and observations after several minutes (heat/throttling).
   Close/reopen and repeat. Also test portrait for overlay/control usability.

Codespace/Xvfb/llvmpipe numbers only verify correctness and profiling plumbing.
They do not establish a mobile performance budget. Gate D mobile acceptance and
Gate C touch/performance checks remain pending BK's real-device results.

## Codespace verification — 2026-10-14

Continued from the preserved files on `m1.2/client-world-proof`; the first
`godot_editor_read get_state` succeeded with Godot 4.7.2. No MCP recovery or
ad-hoc editor/display launch was needed. The existing scene ran through MCP.

Verified using frozen game-time windows and structured live state:

- Forward action traversed the ramp and settled on the platform at
  `(0, 1.5004, -6.2399)`.
- Physical Space input jumped to Y=2.4342; a second airborne jump request left
  the jump count at one; landing returned to Y=1.5003, grounded.
- Controller left-X movement crossed the platform edge and fell to ground.
- Orbit input produced yaw 0.9018 radians, converging toward goal 0.9067.
- Forward movement into the wall stopped at `(4, 0.0004, -0.475)`.
- Synthetic ScreenTouch/ScreenDrag events with three finger IDs simultaneously
  produced forward movement, orbit and a consumed jump request. Focus loss
  cleared movement, orbit, pending jump and finger ownership. This tests the
  adapter logic, not Android OS touch delivery or touch latency.
- Moving below Y=-8 respawned the body at the spawn and settled it on the ground.
- After the overlay fix, its width followed the viewport: 1256 at 1280×720 and
  696 at 720×1280, with 12-pixel horizontal margins and wrapping text.
- Two 640-pixel screenshots confirmed the inclined perspective world, flat
  billboard character, and full depth occlusion when placed behind the wall.
- Stop/run loaded the changed scene successfully; final editor state reported
  `is_playing: false`.

The host log contains X11 BadWindow diagnostics, missing optional desktop
libraries, and audio initialization failure followed by dummy-driver fallback.
No proof-script parse/runtime error was observed. Render-frame windows may span
multiple physics ticks on llvmpipe; recorded tick counts and live physical state
were used instead of assuming one rendered frame equals one physics tick.
No mobile performance claim is made. Real-device acceptance remains pending.
