# Codex + Godot MCP Workflow

- **Status:** Active production workflow
- **Updated:** 2026-10-18

## Purpose

Define how Codex works on this project with low human interruption, bounded context, resilient Godot tooling and explicit fallback modes.

The goal is not merely to make Codex capable of editing Godot files. The goal is to let Codex complete a coherent Mission Contract, prove deterministic facts automatically, and ask BK primarily for design/feel/device-specific acceptance.

## Core roles

1. **Repository / source of truth** — GitHub.
2. **Development host** — Codespace/devbox where Codex, Serena, Node.js, Git and Godot tooling run.
3. **Godot semantic layer** — Serena connected to Godot's built-in GDScript LSP.
4. **Godot diagnostics layer** — `minimal-godot-mcp` connected to LSP/DAP.
5. **Godot runtime/editor layer** — `@satelliteoflove/godot-mcp` + editor addon.
6. **Mobile Godot device** — authoritative acceptance for touch/UX/mobile performance.

## Tool layers

### Serena

Pinned bootstrap package: `serena-agent==2.0.0`.

Project config: `.serena/project.yml`.

Use Serena for:

- symbol discovery;
- definitions/references;
- narrow code retrieval;
- semantic/surgical edits;
- avoiding repeated broad reads of large GDScript files.

Serena's GDScript backend connects to Godot's built-in LSP. The editor must be running with LSP enabled; the project uses port `6008`.

Serena is not a replacement for runtime validation, architecture docs or tests.

### Lightweight diagnostics MCP

Pinned package:

`@ryanmazzolini/minimal-godot-mcp@0.1.6`

Use it for:

- fast per-file GDScript diagnostics;
- workspace diagnostic scans;
- debug-session console output through DAP.

It complements the full runtime MCP and does not install a Godot addon.

### Full runtime/editor MCP

Pinned package:

`@satelliteoflove/godot-mcp@4.1.11`

Use it for engine-aware work that files/LSP cannot prove cheaply:

- scene/editor inspection;
- run/stop/restart;
- runtime state;
- deterministic playtesting;
- input injection;
- animation/effective scene state;
- profiling;
- screenshots when pixels matter.

Do not use runtime MCP merely to edit a normal text file.

## Operational modes

The project must continue useful work when one integration is unavailable.

### FULL

Available:

- repository editing;
- Serena semantic tools;
- GDScript diagnostics/DAP;
- full Godot runtime/editor MCP;
- headless tests.

Use this for normal gameplay implementation and runtime verification.

### DEGRADED

Typical case: full runtime MCP is not connected, but repository/Godot LSP/headless execution remain available.

Continue with:

- Serena symbol/reference work where LSP is healthy;
- lightweight diagnostics;
- headless/runtime CLI tests;
- deterministic unit/integration suites;
- documentation/data work.

Do not stop the entire mission because the live editor bridge is down. Record only the remaining live/visual validation gap.

### STATIC

Use when no live editor/LSP is available.

Continue only work safely supported by:

- repository inspection/search;
- deterministic non-live checks;
- docs/data/schema work;
- already-established architecture.

Do not claim live runtime behavior from STATIC mode.

## Observation priority

Prefer:

1. Serena/symbol state for code navigation;
2. GDScript diagnostics and narrow logs;
3. structured runtime/editor state;
4. screenshots only when pixels/readability matter.

This reduces token/context consumption.

## MCP recovery policy

For the full runtime/editor MCP only:

1. Run `bash tools/dev/ensure_godot_mcp_editor.sh` once.
2. Retry the failed MCP read.
3. Wait briefly and retry at most one additional time.
4. After two failed runtime-MCP retries, stop reconnect loops.
5. Inspect `.codex-local/godot-editor.log` once.
6. Switch to DEGRADED mode and continue all deterministic work.
7. Record the precise unverified behavior in the task report/handoff.

Never create ad-hoc `nohup`, `xvfb-run` or competing Godot bridge processes when project launchers exist.

## Standard host bootstrap

The Codespace/devbox uses Node.js 22+ and Godot 4.7.2.

Run:

```bash
bash tools/dev/bootstrap_codespace.sh
```

The bootstrap installs/validates:

- Godot 4.7.2;
- Codex CLI;
- uv;
- Serena;
- full runtime MCP package/addon;
- lightweight diagnostics MCP availability.

Then:

```bash
bash tools/dev/start_godot_mcp_editor.sh
bash tools/dev/devctl.sh health
node tools/dev/mcp_smoke_test.mjs
codex mcp list
```

The runtime smoke test should execute before a Codex session occupies the single full-MCP editor connection.

## Unified developer command

Use:

```bash
bash tools/dev/devctl.sh health
bash tools/dev/devctl.sh godot-check
bash tools/dev/devctl.sh test affected
bash tools/dev/devctl.sh test all
bash tools/dev/devctl.sh mcp-status
bash tools/dev/devctl.sh report
```

`test affected` is intentionally conservative in Block 1. Unknown impact runs broader tests. A symbol/dependency impact resolver belongs to Block 2.

## Agent policy

Default: one primary Codex agent.

Subagents are reserved for genuinely independent workstreams. A single live Godot editor must have one active full-MCP operator at a time.

Normal limits:

- routine coding: zero subagents;
- complex investigation: one subagent if clearly useful;
- genuinely parallel independent task: maximum two concurrent subagents;
- larger fan-out requires explicit direction.

Parallel code work should prefer worktrees/branches. Do not let multiple agents control the same editor bridge.

## Mission execution loop

For non-trivial work:

1. Read the active Mission Contract.
2. Use Serena to find owning symbols/contracts and references before broad file reads.
3. Inspect only relevant design/architecture/ADR material.
4. Implement a coherent group of the active Macro Version.
5. Run affected deterministic tests.
6. Use lightweight diagnostics for changed GDScript.
7. Use full runtime MCP for the behavior that actually requires live engine proof.
8. Fix failures without asking BK to perform deterministic micro-QA.
9. Run broader regression tests based on risk/impact.
10. Report `Engineering Complete` vs `Player Complete` precisely.
11. Ask BK only for remaining subjective/device-specific acceptance.

## Mobile development loop

The phone remains the authoritative device target, but BK should validate integrated candidates rather than every tiny patch.

```text
Codex host
  semantic navigation / edit
        |
        v
LSP + deterministic tests
        |
        v
Godot runtime MCP verification
        |
        v
integrated Macro Version candidate
        |
        v
Git branch / commit
        |
        v
Android checkout / Godot Editor
        |
        v
BK feel / touch / visual / device acceptance
```

The current Git sync path remains accepted until a safer direct-device bridge is proven. A future direct phone bridge may shorten the hot loop but is not required for correctness.

## Security

- Never commit keys, personal tokens or tunnel credentials.
- Keep MCP/LSP/editor bridges on localhost/private networks.
- Do not expose ports `6550`, `6008` or DAP publicly.
- High-impact actions remain reviewable.
- Third-party agent tools are development dependencies, not runtime game dependencies.
