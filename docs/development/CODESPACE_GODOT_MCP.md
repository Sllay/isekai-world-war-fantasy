# Codespace + Codex + Godot MCP

- **Status:** M1.2 development-host candidate
- **Godot:** 4.7.2 stable
- **Godot MCP:** `@satelliteoflove/godot-mcp@4.1.11`
- **Codex:** current CLI installed in the Codespace

## Verdict

`@satelliteoflove/godot-mcp` is suitable for this project, with one important constraint:

**The MCP expects a live Godot Editor addon. Do not use Godot `--headless` as the main MCP editor process.**

In a GitHub Codespace we therefore run a normal Godot editor inside **Xvfb**, a virtual X11 display. The agent remains terminal/headless, while Godot still has the editor/runtime environment the bridge expects.

## Why this MCP

It provides the capabilities M1.2 actually needs:

- editor/scene state;
- engine-aware node/property inspection;
- run/stop/restart;
- structured runtime state;
- deterministic freeze/step testing;
- keyboard/action/controller/relative-look input injection;
- profiler snapshots/time series;
- screenshots only when visual proof is needed;
- 3D spatial inspection;
- mesh validation.

The tool surface is intentionally compact compared with exposing one MCP tool for every tiny operation.

## Requirements verified upstream

- Godot 4.5+;
- Node.js 20+;
- MCP client with stdio support;
- addon installed and enabled in the Godot project;
- local WebSocket bridge on port `6550` by default.

Our selected Godot 4.7.2 satisfies the engine requirement.

## Important limitation: one MCP client per editor

One Godot editor bridge accepts one active godot-mcp client at a time. Extra clients wait/retry instead of stealing the session.

Project rule:

- the **primary Codex agent owns the live Godot MCP connection**;
- subagents should not call the Godot MCP concurrently;
- subagents can still research, inspect files, write isolated code, or run non-MCP tests;
- hand control back to the primary agent for engine verification.

This also matches the project's token/agent budget policy.

## Codespace architecture

```text
Codex CLI
   |
   | MCP stdio
   v
@satelliteoflove/godot-mcp (Node)
   |
   | ws://127.0.0.1:6550
   v
Godot MCP EditorPlugin
   |
   | Godot debugger protocol
   v
Running test game

Godot Editor itself runs under Xvfb in the Codespace.
```

Port `6550` stays **localhost-only**. Do not make it a public Codespaces forwarded port.

## Automated bootstrap

The repository contains:

- `.devcontainer/devcontainer.json`
- `tools/dev/bootstrap_codespace.sh`
- `tools/dev/start_godot_mcp_editor.sh`
- `tools/dev/stop_godot_mcp_editor.sh`
- `tools/dev/mcp_smoke_test.mjs`

The Codespace post-create step installs:

- Node 22 via the devcontainer feature;
- Linux/X11/Xvfb dependencies;
- exact Godot 4.7.2 stable;
- Codex CLI;
- pinned Godot MCP addon/server version.

The Godot download checksum is verified before installation.

## First Codespace run

Use the smallest practical Codespace machine first (2 cores).

After creation finishes:

```bash
codex
```

Complete ChatGPT/Codex sign-in once, then exit or keep the CLI open.

Start the virtual Godot editor:

```bash
bash tools/dev/start_godot_mcp_editor.sh
```

Expected result:

```text
Godot MCP bridge is listening on 127.0.0.1:6550
```

Then run the independent end-to-end smoke test:

```bash
node tools/dev/mcp_smoke_test.mjs
```

Expected result includes:

```text
MCP server initialized: godot-mcp 4.1.11
Godot editor reachable: 4.7.2...
PASS: MCP stdio -> WebSocket bridge -> Godot editor is healthy.
```

Finally confirm Codex sees the configured servers:

```bash
codex mcp list
```

The project `.codex/config.toml` already defines the pinned Godot MCP and OpenAI Docs MCP.

## Why the addon is not committed into the mobile project

The MCP addon is a **development-host tool**, not a gameplay dependency.

It is installed locally into `client/addons/godot_mcp/`, which is ignored by Git. The launcher temporarily enables it for the virtual editor process and restores the original `client/project.godot` once the MCP bridge is ready.

This keeps the Android checkout clean and avoids forcing an editor-only MCP plugin onto the real mobile test device.

## What Codespace profiling means

Codespace/Xvfb profiling is useful for:

- finding CPU spikes;
- detecting runaway processing;
- comparing regressions in the same environment;
- validating that systems start/stop correctly;
- checking entity/process counts.

It is **not** authoritative for mobile FPS, GPU cost, memory pressure, thermals, touch latency, or battery.

Real performance acceptance happens on the Android phone using Godot 4.7.2 and later exported builds.

## Headless clarification

The MCP project's own evaluation harness can run the *agent* headlessly, but its documentation explicitly says the Godot editor must already be open. There is also upstream evidence that the editor plugin may start a WebSocket server during `godot --headless` import/export processes; that behavior is not the intended interactive MCP workflow and can create port conflicts.

Therefore:

- `godot --headless` remains useful for CI/import/static validation;
- **Xvfb + normal `godot --editor`** is the M1.2 MCP workflow.

## Troubleshooting order

If MCP fails:

1. `godot --version` must report 4.7.2.
2. `node --version` must be 20+.
3. `npx -y @satelliteoflove/godot-mcp@4.1.11 --version` must work.
4. `nc -z 127.0.0.1 6550` must succeed after the editor launcher.
5. inspect `.codex-local/godot-editor.log`.
6. run `node tools/dev/mcp_smoke_test.mjs`.
7. only after the independent smoke test passes should Codex/MCP configuration be debugged.

This isolates failures by hop instead of guessing.

## Stop the virtual editor

```bash
bash tools/dev/stop_godot_mcp_editor.sh
```

Also stop the Codespace itself when the work session is finished to conserve included compute quota.
