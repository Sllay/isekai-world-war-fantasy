# Mobile + Cloud Development Workflow

- **Status:** Accepted production workflow
- **Updated:** 2026-10-18

## Development Principle

The game is mobile-first and validated on real Android hardware from the beginning, but BK is not the default runner for every micro-change.

The development host should automatically prove deterministic behavior first. Android validation is concentrated on integrated Macro Version candidates and on questions that are genuinely device-specific or subjective.

Mobile-first does not mean every compiler, database and server process must run on the phone. Workloads are split by what each environment is good at.

## Responsibilities

### Android phone

Primary responsibilities:

- Godot Android Editor;
- integrated gameplay candidate execution;
- touch/input comfort validation;
- mobile GPU/CPU/memory observations;
- UI/UX/readability checks;
- Compatibility-renderer validation;
- subjective feel and device-specific acceptance.

The phone should not be used to manually prove facts that deterministic host tests can verify, such as exact health arithmetic, cooldown state transitions or parser correctness.

### Remote development host

Primary responsibilities:

- Codex execution environment;
- Serena semantic GDScript navigation/editing;
- Git/worktrees;
- Node.js/MCP host;
- full Godot editor/runtime MCP;
- lightweight GDScript LSP/DAP diagnostics;
- Rust compilation and server tests when server work begins;
- headless Godot validation;
- deterministic gameplay/scenario tests;
- long-running simulations;
- database experiments;
- profiling/CI-like tasks that would waste mobile battery/thermal budget.

### GitHub

Canonical collaboration/source-control layer:

- source of truth for code/docs;
- branches/PRs;
- CI;
- issues/Mission handoff;
- durable handoff between remote Codex and Android device.

Git is the version/checkpoint layer; it should not force BK to manually validate every internal implementation checkpoint.

## Recommended Early Host: GitHub Codespaces

Use Codespaces as the current zero-cost-capable dev host, not as the permanent game server.

Cost-control rules:

- smallest suitable machine;
- stop immediately after use;
- short idle timeout;
- no unnecessary prebuilds;
- keep generated caches/builds disposable;
- Git remains durable source of truth.

Codespaces is a development host, not the production hosting decision.

## Repository Layout

```text
/
├── client/        # Godot project and presentation/client gameplay
├── server/        # authoritative server work when introduced
├── shared/        # protocol/schema/shared IDs and generated contracts
├── data/          # data-driven game content definitions
├── assets/        # source/shared assets + provenance
├── tests/         # cross-boundary/integration/fixtures
├── tools/         # setup, validation, generation, profiling helpers
├── docs/
├── skills/
├── .serena/
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

It does not own canonical server economy/world truth once authoritative server systems exist.

### Server rule

`server/` owns canonical multiplayer consequences when that Macro Version is active:

- world simulation authority;
- entity/state authority;
- economy authority;
- item custody;
- population/ecology;
- battle strategic state;
- persistence;
- authoritative validation.

### Shared rule

`shared/` contains contracts, not duplicate gameplay implementations.

Avoid manually duplicating the same protocol definition in GDScript and server code.

## Android File Workflow

The Android device should work from a normal clone/export of the same repository revision used by the remote host.

If Termux is used, keep secrets out of shared storage and remember that Android shared storage has different Unix filesystem semantics.

Do not put server build outputs, Rust target directories, node_modules, databases or heavy host-only caches into the phone's tracked project data.

A future authenticated direct-device sync/bridge may reduce Git round trips, but it is an optimization, not a correctness dependency.

## Development / Validation Loop

### During implementation

Codex should iterate mostly on the host:

```text
Mission Contract
 -> Serena symbol/reference navigation
 -> edit
 -> GDScript diagnostics
 -> affected deterministic tests
 -> Godot runtime MCP where required
 -> fix
 -> regression gate
```

Runtime-MCP failure after bounded recovery switches the task to DEGRADED mode instead of forcing an immediate BK test.

### Android acceptance

Sync/test on Android when one of these is true:

- an integrated Macro Version candidate is ready;
- touch/control feel changed materially;
- visual/readability/animation feedback needs human judgement;
- mobile renderer/performance/memory is the question;
- a bug appears device-specific;
- the Mission Contract explicitly names Android acceptance.

Preferred candidate loop:

1. Codex completes deterministic host validation.
2. CI passes for the candidate branch/PR.
3. Candidate revision is synchronized to Android.
4. BK validates the short acceptance checklist for feel/visual/device behavior.
5. Failures become concrete reproduction notes for the next Codex correction.

Avoid asking BK to test one field/method/change at a time.

## Performance Rule

Desktop/headless success is not proof of mobile performance.

A client performance claim is not accepted until tested on representative Android hardware in a release-like configuration. Conversely, Android manual testing is not required merely to prove deterministic domain arithmetic already covered by automated tests.

## Server/Cloud Rule

Heavy authoritative-server experiments may run in cloud/devbox environments from the start of the relevant Macro Version.

Do not choose permanent hosting solely because a provider has a free tier. Production hosting decisions follow measured CPU, RAM, bandwidth, persistence and concurrency requirements.

## No-PC Requirement

The workflow must remain usable without BK owning a conventional desktop PC.

Therefore:

- the Android phone can edit/run the Godot client;
- ChatGPT/Codex mobile experiences can steer remote work;
- cloud/devbox resources handle desktop/server toolchains;
- Serena/LSP/runtime MCP provide agent-side code/engine intelligence;
- GitHub synchronizes durable revisions and CI evidence.

A future PC can improve convenience but must not be a prerequisite for project progress.
