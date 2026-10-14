# M1.2 — Project Bootstrap & Client/World Proof

- **Status:** In progress — Android bootstrap + Codespace MCP smoke validated
- **Updated:** 2026-10-13

## Goal

Turn the M1.1 research direction into a reproducible development environment before gameplay implementation expands.

M1.2 begins with project bootstrap, not features.

## Gate A — Repository / Codex bootstrap

Required before gameplay coding:

- [x] `client/`, `server/`, and `shared/` boundaries exist;
- [x] project `AGENTS.md` uses concise/context-efficient rules;
- [x] Codex project MCP configuration exists;
- [x] Godot MCP version is pinned;
- [x] agent/subagent budget policy exists;
- [x] mobile/cloud workflow is documented;
- [x] secrets/caches are excluded from source control;
- [x] Codespaces devcontainer/bootstrap scripts exist.

## Gate B — Development host

Prove one remote/local host can:

1. [x] create/start the project Codespace;
2. [x] complete the bootstrap script successfully;
3. [x] authenticate Codex CLI with the user's ChatGPT plan;
4. [ ] load project-level Codex configuration;
5. [x] start the pinned Godot MCP server;
6. [x] install/enable the Godot MCP addon in the client project;
7. [x] run Godot 4.7.2 editor under Xvfb (normal editor, **not** Godot `--headless`);
8. [x] perform the independent MCP JSON-RPC smoke test;
9. [x] return structured Godot editor state through `godot_editor_read`;
10. [ ] run a minimal scene and return structured runtime state;
11. [ ] commit/push a change.

A GitHub Codespace is the selected development host for this proof.

### MCP research result

The selected MCP remains:

`@satelliteoflove/godot-mcp@4.1.11`

Upstream requirements fit the project:

- Node.js 20+;
- Godot 4.5+;
- stdio-capable MCP client;
- local editor addon bridge on WebSocket port 6550 by default.

Important correction discovered during verification:

**The supported workflow expects a live Godot Editor.** The agent can be headless, but Godot `--headless` is not the intended interactive bridge. Codespaces therefore use a normal Godot editor under Xvfb.

The bridge accepts one active MCP client per editor. The primary Codex agent owns the live Godot connection; subagents must not compete for it.

### Verified Codespace smoke result — 2026-10-13

The independent smoke test passed on the real project Codespace with:

- Godot editor reachable as `4.7.2-stable (official)`;
- current scene resolved as `res://scenes/bootstrap/bootstrap.tscn`;
- MCP server `godot-mcp 4.1.11`;
- successful chain `MCP stdio -> WebSocket bridge -> Godot editor`;
- one successful connection attempt.

The smoke script was corrected to account for godot-mcp connecting to Godot asynchronously after its stdio MCP server is initialized. A temporary `Not connected to Godot` immediately after MCP initialization is therefore treated as startup state and retried until the editor bridge is ready or the smoke-test timeout expires.

See `docs/development/CODESPACE_GODOT_MCP.md`.

## Gate C — Android development device

Current device runtime: **Godot Android Editor 4.7.2**.

Validated on 2026-10-13:

- [x] obtain the repository revision on Android through Termux/Git;
- [x] open `client/project.godot` in Godot Android Editor 4.7.2;
- [x] run the bootstrap project locally and display the expected bootstrap screen;
- [ ] execute and validate project touch input;
- [ ] capture basic performance/debug information;
- [ ] pull a newer repository revision and run it without manually rebuilding the project structure.

Godot/GABE setup specifics belong to the device setup checklist, not gameplay code.

## Gate D — Minimal Godot client proof

Create the smallest real client project needed to test the M1.1 assumptions:

- Compatibility renderer baseline;
- one 3D spatial test scene;
- inclined top-down camera;
- camera rotation;
- placeholder 2D-looking character in 3D space;
- real elevation/descent;
- one jump/drop test;
- simple occluder;
- basic touch + keyboard/controller abstraction;
- debug overlay with FPS/frame timing/build info.

No final art or gameplay systems are required.

## Gate E — MCP self-verification

Codex must be able to use the Godot MCP to verify at least:

- project/editor connection;
- scene tree/effective state;
- run/stop;
- injected input;
- structured runtime state;
- one deterministic/frozen-time test;
- profiler sample;
- screenshot only for a genuinely visual assertion.

This proves the agent can test rather than merely edit.

### Independent smoke test

Before trusting Codex integration, run:

```bash
bash tools/dev/start_godot_mcp_editor.sh
node tools/dev/mcp_smoke_test.mjs
```

The smoke test directly verifies:

`MCP stdio -> Node server -> localhost WebSocket -> Godot Editor addon -> editor state`

This isolates MCP/editor failures from Codex configuration.

## Token/Agent Budget

Default execution model:

- one main agent;
- zero subagents for routine bootstrap work;
- at most one specialist for an independent blocker;
- maximum two concurrent subagents without explicit user direction;
- no recursive teams;
- only the primary agent owns the live Godot MCP connection;
- structured MCP observations before screenshots/log dumps.

## Codespace Performance Caveat

Xvfb/virtual-GPU results are useful for correctness and regression comparisons, but they are **not** accepted as mobile performance evidence.

Mobile FPS, memory, thermal behavior, battery impact and touch latency must be measured on the real Android device.

## Non-goals

M1.2 bootstrap does not implement:

- production server;
- economy;
- population;
- real combat;
- final terrain pipeline;
- final character art;
- production hosting;
- direct phone MCP as a hard dependency.

## Exit Criteria

Bootstrap is complete when the same commit can be:

- edited/tested by Codex in the Codespace;
- engine-verified through MCP;
- pulled/opened/run on Android;
- measured on the real phone;
- iterated through Git without manual file shuffling.

After this gate, M1.2 proceeds into the actual 2.5D client/world benchmark prototype.
