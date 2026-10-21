# Codex + Godot MCP Workflow

- **Status:** Active production workflow
- **Updated:** 2026-10-20

## Purpose

Define how Codex works on this project with low human interruption, bounded context, resilient Godot tooling and explicit fallback modes.

GitHub remains the source of truth. **Codex Cloud is the preferred everyday development host.** Codespace remains the fallback host for FULL Godot editor/runtime work when the managed Cloud environment cannot sustain the live editor bridge.

The goal is to let Codex complete coherent Mission Contracts, prove deterministic facts automatically, and ask BK primarily for design/feel/device-specific acceptance.

## Host order

Preferred order for a normal task:

1. **Codex Cloud FULL attempt** — published reusable project environment with Godot, Serena and the runtime editor bridge.
2. **Codex Cloud DEGRADED** — continue code, docs, headless Godot, deterministic tests and semantic work if the live bridge is unavailable.
3. **Codespace FULL fallback** — use only when remaining validation genuinely requires the live Godot Editor/runtime MCP and Cloud FULL is unavailable.
4. **STATIC** — repository/deterministic work only when no live LSP/editor exists.

Do not open a Codespace merely because a task touches Godot. Escalate to Codespace only for an actual editor-dependent gap.

## Core roles

1. **Repository / source of truth** — GitHub.
2. **Primary development host** — Codex Cloud reusable environment.
3. **Fallback development host** — Codespace/devbox.
4. **Godot semantic layer** — Serena connected to Godot's built-in GDScript LSP.
5. **Godot diagnostics layer** — `minimal-godot-mcp` connected to LSP/DAP.
6. **Godot runtime/editor layer** — `@satelliteoflove/godot-mcp` + editor addon.
7. **Mobile device** — authoritative acceptance for touch/UX/mobile performance.

## Tool layers

### Serena

Pinned package: `serena-agent==2.0.0`.

Project config: `.serena/project.yml`.

Use Serena for symbol discovery, references, narrow retrieval and surgical edits. Serena's GDScript backend needs the Godot LSP on port `6008` for live semantic support.

### Lightweight diagnostics MCP

Pinned package: `@ryanmazzolini/minimal-godot-mcp@0.1.6`.

Use for GDScript diagnostics and DAP console. It complements the runtime bridge.

### Full runtime/editor MCP

Pinned package: `@satelliteoflove/godot-mcp@4.1.11`.

Use for scene/editor inspection, run/stop, runtime state, deterministic playtesting, input injection, animation/effective scene state, profiling and screenshots when pixels matter.

## Operational modes

### FULL

Requires all of the following inside the **same active development task/host**:

- repository editing;
- Godot 4.7.2;
- live Godot editor/LSP on `127.0.0.1:6008`;
- runtime MCP bridge on `127.0.0.1:6550`;
- Serena/diagnostics MCP;
- headless tests.

A host is not called FULL merely because the packages are installed.

### DEGRADED

Repository and headless/deterministic work remain available but one or more live editor integrations are unavailable.

Continue with semantic work where available, diagnostics, CLI/headless tests, docs/data and deterministic integration coverage. Record only the genuinely editor-dependent validation gap.

### STATIC

No live editor/LSP. Continue only repository inspection, deterministic non-live checks and safe docs/data/schema work. Never claim live runtime behavior from STATIC mode.

## Codex Cloud setup

Codex Cloud environments are reusable prepared environments, but each new task receives its own isolated workspace. Important work still belongs in Git commits/branches, not in assumed VM persistence.

For the published Isekai environment, use this setup command from the repository root:

```bash
bash tools/dev/prepare_codex_cloud.sh
```

The script:

1. installs/validates the host-neutral project toolchain;
2. installs exact Godot 4.7.2, Serena and pinned MCP dependencies;
3. proves a headless Godot import/parse;
4. attempts to start the normal Godot editor under Xvfb/software rendering;
5. checks LSP/DAP/runtime-MCP ports;
6. runs the runtime MCP smoke test;
7. writes `.codex-local/codex-cloud-mode` as `FULL` or `DEGRADED`.

Failure to obtain the live editor bridge does **not** make the Cloud environment useless. The preparation deliberately falls back to DEGRADED after headless viability is proven.

### Runtime network access

The published Cloud environment must allow the runtime network access required by Git/GitHub, npm packages and any enabled remote MCPs. Do not expose local Godot ports publicly; `6008`, `6006` and `6550` remain loopback-only.

## Host-neutral bootstrap

Shared implementation:

```bash
bash tools/dev/bootstrap_dev_environment.sh
```

Wrappers:

```bash
# Managed Codex Cloud task environment
bash tools/dev/bootstrap_codex_cloud.sh

# GitHub Codespace/devbox
bash tools/dev/bootstrap_codespace.sh
```

Both wrappers produce the same pinned project toolchain. Codespace additionally installs/updates the local Codex CLI because Codex Cloud already supplies the managed agent runtime.

## Codespace FULL fallback

When Cloud finishes all deterministic work but the remaining acceptance genuinely requires the live editor/runtime bridge, use Codespace:

```bash
bash tools/dev/bootstrap_codespace.sh
bash tools/dev/start_godot_mcp_editor.sh
bash tools/dev/devctl.sh health
node tools/dev/mcp_smoke_test.mjs
codex mcp list
```

Codespace is not the default boot step anymore.

## Health / mode classification

Use:

```bash
bash tools/dev/devctl.sh health
bash tools/dev/devctl.sh mcp-status
```

`health` now reports the effective mode. FULL requires both the LSP and runtime bridge to be live.

## MCP recovery policy

For the full runtime/editor MCP only:

1. run `bash tools/dev/ensure_godot_mcp_editor.sh` once;
2. retry the failed MCP read;
3. wait briefly and retry at most one additional time;
4. after two failed runtime-MCP retries, stop reconnect loops;
5. inspect `.codex-local/godot-editor.log` once;
6. switch to DEGRADED and continue deterministic work;
7. if the **remaining** validation is editor-dependent and Cloud is the host, route only that validation to Codespace FULL.

Never create ad-hoc competing `nohup`, `xvfb-run` or raw Godot bridge processes when project launchers exist.

## Unified developer commands

```bash
bash tools/dev/devctl.sh health
bash tools/dev/devctl.sh godot-check
bash tools/dev/devctl.sh test affected
bash tools/dev/devctl.sh test all
bash tools/dev/devctl.sh mcp-status
bash tools/dev/devctl.sh report
```

`test affected` remains conservative until the future Project Brain provides dependency-aware impact selection.

## Mission execution loop

1. Read the active Mission Contract.
2. Inspect only relevant design/architecture/ADR material.
3. Use Serena/symbol navigation before broad code reads when live semantics are available.
4. Implement the coherent mission group.
5. Run affected deterministic tests.
6. Use diagnostics for changed GDScript.
7. Use FULL runtime MCP only for behavior that needs live engine proof.
8. If Cloud FULL fails, continue all non-editor work there rather than abandoning the task.
9. Escalate to Codespace only for the exact editor-dependent gap.
10. Run broader regressions based on impact.
11. Report Engineering Complete vs Player Complete precisely.
12. Ask BK only for subjective/device-specific acceptance.

## Single-editor rule

One live Godot editor bridge has one active MCP operator. Do not let parallel agents/tasks compete for the same live editor instance.

## Mobile development loop

```text
Codex Cloud
  edit / semantic navigation / deterministic tests
        |
        +--> FULL available: runtime MCP validation
        |
        +--> FULL unavailable: DEGRADED work continues
                              |
                              +--> only if needed: Codespace FULL validation
        |
        v
integrated candidate / branch / PR
        |
        v
mobile checkout / device build
        |
        v
BK feel / touch / visual / real-device performance acceptance
```

## Security

- Never commit keys, personal tokens or environment credentials.
- Keep Godot MCP/LSP/DAP bridges on localhost/private interfaces.
- Do not expose ports `6550`, `6008` or `6006` publicly.
- Third-party development MCPs are not runtime game dependencies.
- Published Cloud environments must not embed secrets in repository files.
