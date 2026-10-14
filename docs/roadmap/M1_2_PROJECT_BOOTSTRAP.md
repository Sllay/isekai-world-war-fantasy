# M1.2 — Project Bootstrap & Client/World Proof

- **Status:** Completed
- **Updated:** 2026-10-13

## Goal

Turn the M1.1 research direction into a reproducible development environment and prove the 2.5D/mobile client assumptions before production gameplay expands.

M1.2 is a technical proof milestone, not a production-content phase.

## Gate A — Repository / Codex bootstrap

- [x] `client/`, `server/`, and `shared/` boundaries exist;
- [x] project `AGENTS.md` uses concise/context-efficient rules;
- [x] Codex project MCP configuration exists;
- [x] Godot MCP version is pinned;
- [x] agent/subagent budget policy exists;
- [x] mobile/cloud workflow is documented;
- [x] secrets/caches are excluded from source control;
- [x] Codespaces devcontainer/bootstrap scripts exist.

## Gate B — Development host

The project Codespace has proven it can:

1. [x] start the project Codespace;
2. [x] complete bootstrap successfully;
3. [x] authenticate Codex CLI with the user's ChatGPT plan;
4. [x] load project-level Codex configuration;
5. [x] start the pinned Godot MCP server;
6. [x] install/enable the Godot MCP addon in the client project;
7. [x] run Godot 4.7.2 editor under Xvfb using the normal editor, not Godot `--headless`;
8. [x] perform the independent MCP JSON-RPC smoke test;
9. [x] return structured Godot editor state through `godot_editor_read`;
10. [x] run a scene and return structured runtime state;
11. [x] commit/push from the Codex development host.

Selected MCP:

`@satelliteoflove/godot-mcp@4.1.11`

Verified requirements and behavior:

- Node.js 20+;
- Godot 4.5+;
- stdio MCP client;
- local editor addon bridge on WebSocket port 6550;
- one active MCP client per editor;
- normal Godot Editor under Xvfb for the Codespace interactive bridge;
- bounded recovery through the project launcher scripts rather than ad-hoc restart loops.

The smoke/runtime path was verified end to end:

`Codex/MCP stdio -> Node MCP server -> localhost WebSocket -> Godot Editor addon -> runtime/editor state`

Codex successfully exercised:

- project start/stop;
- structured runtime/editor reads;
- injected input;
- deterministic freeze/step/thaw;
- profiler capture;
- Git commit/push.

Codespace/Xvfb profiler numbers are diagnostic only and are not accepted as mobile performance evidence.

## Gate C — Android development device

Runtime: **Godot Android Editor 4.7.2**.

Validated on the real Android device:

- [x] repository updates through Termux/Git;
- [x] `client/project.godot` opens in Godot Android Editor 4.7.2;
- [x] project runs locally;
- [x] touch/mobile controls are usable for movement/camera interaction in the 2.5D proof;
- [x] a newer branch/revision can be fetched and run without manual file copying;
- [x] basic real-device performance was observed at a mostly locked 60 FPS in the minimal proof scene, with occasional 59 FPS dips.

That FPS observation applies only to the minimal proof scene and is not a production benchmark.

## Gate D — 2.5D client assumption proof

The Android-tested proof established that the selected presentation is viable:

- [x] Compatibility renderer baseline;
- [x] true 3D world space;
- [x] inclined top-down camera;
- [x] rotatable camera;
- [x] visually 2D player presentation inside 3D world space;
- [x] real elevation/descent;
- [x] jump/gravity;
- [x] movement around 3D obstacles/terrain;
- [x] touch/mobile input path;
- [x] runtime/debug instrumentation.

The proof used simplified visual behavior such as billboard-style facing. That behavior is evidence only and is not automatically promoted into the production character presentation.

## Gate E — MCP self-verification

Validated:

- [x] project/editor connection;
- [x] scene/effective-state reads;
- [x] run/stop;
- [x] injected input;
- [x] structured runtime state;
- [x] deterministic/frozen-time stepping;
- [x] profiler sample.

Screenshot verification remains optional and should be used only for a genuinely visual assertion; it is not required to close this milestone.

## Lessons carried into production

M1.2 proved the unknowns. It must not become an endless prototype branch.

From M1.3 onward:

- new gameplay/core work is production-intent code;
- proof code is reused only when it meets production contracts and quality;
- throwaway prototypes require a specific unresolved technical question;
- generated art should target production use when requirements are already known;
- placeholders are reserved for cases where final art would block a technical task or where visual fidelity is irrelevant;
- token budget is treated as a development resource and must not be spent repeatedly generating disposable content.

## Exit Result

The project now has a working mobile/cloud development loop:

`Codex -> Godot MCP -> Git -> GitHub -> Termux -> Godot Android -> real-device validation`

The next milestone is **M1.3 — Core Production Foundation**.
