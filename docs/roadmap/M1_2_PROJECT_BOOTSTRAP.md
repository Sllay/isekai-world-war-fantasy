# M1.2 — Project Bootstrap & Client/World Proof

- **Status:** Planned
- **Updated:** 2026-10-13

## Goal

Turn the M1.1 research direction into a reproducible development environment before gameplay implementation expands.

M1.2 begins with project bootstrap, not features.

## Gate A — Repository / Codex bootstrap

Required before gameplay coding:

- `client/`, `server/`, and `shared/` boundaries exist;
- project `AGENTS.md` uses concise/context-efficient rules;
- Codex project MCP configuration exists;
- Godot MCP version is pinned;
- agent/subagent budget policy exists;
- mobile/cloud workflow is documented;
- secrets/caches are excluded from source control.

## Gate B — Development host

Prove one remote/local host can:

1. clone the repository;
2. load project-level Codex configuration;
3. start the pinned Godot MCP server;
4. install/enable the Godot MCP addon in the client project;
5. run Godot 4.7.x against the client project;
6. perform an MCP status/read operation;
7. run a minimal scene and return structured runtime state;
8. commit/push a change.

A GitHub Codespace is the first dev-host candidate for this proof.

## Gate C — Android development device

Prove the Android device can:

1. obtain the same repository revision;
2. open `client/project.godot` in the Godot Android Editor;
3. run the project locally;
4. execute touch input;
5. capture basic performance/debug information;
6. update to a newer repository revision without rebuilding the project structure manually.

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

## Token/Agent Budget

Default execution model:

- one main agent;
- zero subagents for routine bootstrap work;
- at most one specialist for an independent blocker;
- maximum two concurrent subagents without explicit user direction;
- no recursive teams;
- structured MCP observations before screenshots/log dumps.

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

- edited/tested by Codex on the development host;
- engine-verified through MCP;
- pulled/opened/run on Android;
- measured on the real phone;
- iterated through Git without manual file shuffling.

After this gate, M1.2 proceeds into the actual 2.5D client/world benchmark prototype.
