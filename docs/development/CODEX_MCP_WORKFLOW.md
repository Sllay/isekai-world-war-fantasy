# Codex + Godot MCP Workflow

- **Status:** Initial development policy
- **Updated:** 2026-10-13

## Purpose

Define how Codex works on this project without wasting context, spawning unnecessary agents, or coupling the project to one workstation.

## Core Model

The project uses three distinct roles:

1. **Repository / source of truth** — GitHub.
2. **Development host** — a machine/devbox where Codex, Node.js, Git and engine tooling can run.
3. **Mobile Godot device** — primary visual/runtime test device during early development.

The ChatGPT/Codex mobile app is treated primarily as the control plane for Codex work running on a connected host. Project files, tools and permissions remain on that host. Mobile Godot uses the same Git repository and validates real device behavior.

## Why This Split

Trying to make the phone simultaneously be:

- the Godot editor,
- the Codex execution host,
- the MCP stdio host,
- Rust server compiler,
- database host,
- benchmark machine,

would add fragile Android/Termux assumptions before the game exists.

The phone remains extremely important: it is the real mobile target and should be tested from the beginning. Heavy compilation and server experiments can run elsewhere.

## Primary Godot MCP Candidate

Use:

`@satelliteoflove/godot-mcp@4.1.11`

Reasons for the initial choice:

- Godot 4.5+ support, compatible with the 4.7 line;
- 21 top-level tools rather than hundreds of exposed schemas;
- structured runtime state reduces screenshot/vision usage;
- deterministic freeze/step/step-until playtesting;
- real input injection;
- profiler access;
- editor/runtime inspection and screenshots when needed;
- MIT licensed;
- file edits are intentionally left to normal repository tools rather than duplicated in MCP.

This is a candidate dependency. Pin the tested version and upgrade deliberately.

## Host Requirements

The development host needs, at minimum:

- Git;
- Node.js 20+;
- Codex local/remote execution environment;
- Godot 4.7.x editor binary when using live Godot MCP features;
- repository checkout.

Later server work adds Rust/Cargo, SQLite/PostgreSQL tooling and related profilers.

## MCP Installation Pattern

Preferred command on a development host:

```bash
npx -y @satelliteoflove/godot-mcp@4.1.11 --install-addon /workspace/isekai-world-war-fantasy/client
```

The exact checkout path is host-specific.

Then enable **Godot MCP** in Godot Project Settings > Plugins.

The MCP process itself can be started by Codex through project/user configuration when Node.js is available.

## MCP Usage Rules

Use MCP for engine-aware work that normal file editing cannot prove cheaply:

- scene/editor inspection;
- run/stop/restart;
- runtime state;
- deterministic playtesting;
- input injection;
- animation/scene effective state;
- profiling;
- screenshots for visual validation;
- version-matched Godot documentation.

Do not use MCP merely to edit a text file that Codex can edit directly.

### Observation priority

Prefer:

1. structured runtime/editor state;
2. narrow logs/metrics;
3. screenshot only when pixels matter.

This policy reduces token/context consumption.

## Agent Policy

Default: **one main Codex agent**.

Subagents are reserved for independent workstreams.

Normal limits:

- routine coding: zero subagents;
- complex investigation: one subagent if clearly useful;
- genuinely parallel technical task: maximum two concurrent subagents;
- larger fan-out requires explicit user direction.

Subagents must not recursively create teams for routine work.

A single live Godot editor should have one active MCP operator at a time. Other agents can work on isolated files/tests/worktrees without controlling that same editor session.

## Worktree Strategy

Parallel Codex work should prefer Git worktrees/branches rather than multiple agents editing the same checkout.

Suggested pattern:

- main task: current feature branch/worktree;
- independent research/test: separate temporary worktree;
- merge only after tests/review.

Do not use parallelism merely because it exists.

## Mobile Development Loop

```text
Codex host
  edit / validate / headless test
        |
        v
Git branch / commit
        |
        v
GitHub
        |
        v
Android phone checkout
        |
        v
Godot Android Editor
        |
        v
real-device run + profiler/debug observations
        |
        v
issue/log/result returned to repo/Codex
```

The mobile result is authoritative for mobile-specific performance/UX questions.

## Direct Phone MCP

Running a Godot MCP bridge directly against the Android editor may be investigated later, but it is **not a bootstrap dependency**.

Reasons:

- the selected MCP server expects a Node.js stdio host;
- Codex Remote is designed around work running on a connected development host;
- Android app sandbox/storage and localhost bridging add platform-specific failure modes;
- direct phone MCP does not remove the need for a server/compiler host later.

If direct-phone MCP is tested, it must be treated as an optional convenience path. Failure of that path must never block development.

## Cloud Development Host

For zero-cost early work, GitHub Codespaces is the preferred first devbox candidate because personal GitHub accounts include a monthly free quota.

Rules:

- use the smallest machine that satisfies the task;
- stop the codespace immediately when work ends;
- lower idle timeout;
- avoid prebuilds unless measurements justify them;
- do not treat Codespaces as the permanent game server.

Codespaces is a development host, not the production hosting decision.

## Security

- Never commit API keys, personal tokens or tunnel credentials.
- Keep MCP/editor bridges on localhost/private networks unless a deliberate authenticated tunnel is configured.
- Do not expose the Godot editor bridge directly to the public internet.
- Write actions remain reviewable; high-impact repository/engine operations should not be globally auto-approved.

## Acceptance Criteria for Bootstrap

Before M1.2 gameplay work begins:

- repository layout separates client/server/shared concerns;
- Codex project instructions are concise;
- agent/subagent limits are documented;
- Godot MCP candidate/version is pinned;
- a development host can clone the repo and start the MCP server;
- the Godot client can be opened on Android;
- the same Git commit can be tested on host and phone;
- no workflow depends on a paid always-on service.
