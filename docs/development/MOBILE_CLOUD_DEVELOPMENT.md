# Mobile + Cloud Development Workflow

- **Status:** Accepted workflow for early development
- **Updated:** 2026-10-13

## Development Principle

The game is developed **mobile-first** and validated on real Android hardware from the beginning.

Mobile-first does not mean every compiler, database and server process must run on the phone. Workloads are split by what each environment is good at.

## Responsibilities

### Android phone

Primary responsibilities:

- Godot Android Editor;
- real-device gameplay execution;
- touch/input validation;
- mobile GPU/CPU/memory observations;
- UI/UX checks;
- Compatibility-renderer validation;
- quick GDScript/editor iteration when convenient.

Godot's Android editor is capable of 2D and 3D development. Gradle-based Android builds can be performed from the Android editor with GABE on supported versions.

### Remote development host

Primary responsibilities:

- Codex execution environment;
- Git/worktrees;
- Node.js/MCP host;
- Rust compilation and server tests;
- headless/desktop Godot validation;
- long-running simulations;
- database experiments;
- profiling/CI-like tasks that would waste mobile battery/thermal budget.

### GitHub

Canonical collaboration/source-control layer:

- source of truth for code/docs;
- branches/PRs;
- CI;
- issues;
- handoff between remote Codex and Android device.

## Recommended Early Host: GitHub Codespaces

Use Codespaces as the first zero-cost-capable dev host, not as the permanent game server.

Personal GitHub plans currently include monthly Codespaces compute/storage quotas. The exact remaining allowance must be checked in GitHub because usage is account-specific.

Cost-control rules:

- smallest suitable machine;
- stop immediately after use;
- short idle timeout;
- no unnecessary prebuilds;
- keep generated caches/builds disposable;
- Git remains the durable source of truth.

## Repository Layout

Target monorepo boundary:

```text
/
├── client/        # Godot project and presentation/client gameplay
├── server/        # Rust authoritative simulation/server
├── shared/        # protocol/schema/shared IDs and generated contracts
├── data/          # data-driven game content definitions
├── assets/        # source/shared game assets; client import policy defined later
├── tests/         # cross-boundary/integration/fixtures
├── tools/         # setup, validation, generation, profiling helpers
├── docs/
├── skills/
└── .codex/
```

### Client rule

`client/` owns things that must run in Godot/on the player device:

- rendering;
- camera;
- input;
- UI;
- local presentation;
- interpolation/prediction presentation;
- client-side effects;
- client networking adapter.

It does not own canonical economy/world truth.

### Server rule

`server/` owns canonical world consequences:

- world simulation;
- entity/state authority;
- economy;
- item custody;
- population/ecology;
- battle strategic state;
- persistence;
- authoritative validation.

### Shared rule

`shared/` contains contracts, not gameplay implementations.

Examples:

- network message schemas;
- stable ID formats;
- data schemas;
- protocol versions;
- generated bindings where needed.

Avoid manually duplicating the same protocol definition in GDScript and Rust.

## Android File Workflow

The Android device should work from a normal clone/export of the same repository revision used by the remote host.

The exact Git client is a user/device preference. If Termux is used, keep secrets out of shared storage and be aware that Android shared storage has different Unix filesystem semantics.

Do not put server build outputs, Rust target directories, node_modules, databases or other heavy host-only caches into the phone's tracked project data.

## Test Loop

For every mobile-sensitive feature:

1. Codex implements/tests on its host.
2. Commit/branch is pushed.
3. Android checkout updates to that revision.
4. Open/run in Godot Android Editor.
5. Validate touch, visuals, performance and device-specific behavior.
6. Record issue with reproduction details/metrics.
7. Codex fixes against the same revision lineage.

## Performance Rule

Desktop/headless success is not proof of mobile performance.

A performance claim affecting the client is not accepted until tested on a representative Android device using a release-like configuration.

## Server/Cloud Rule

Heavy authoritative-server experiments may run in cloud/devbox environments from the start.

Do not choose permanent hosting during M1 solely because a provider has a free tier. Production hosting decisions come after measured CPU, RAM, bandwidth, persistence and concurrency requirements exist.

## No-PC Requirement

The workflow must remain usable without the user owning a conventional desktop PC.

Therefore:

- the Android phone can edit/run the Godot client;
- the mobile ChatGPT/Codex experience can steer connected remote work;
- cloud/devbox resources handle desktop/server toolchains;
- GitHub synchronizes both sides.

A future PC can improve convenience but must not be a prerequisite for the project to progress.
