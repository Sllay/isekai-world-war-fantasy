# M1.3 — Core Production Foundation

- **Status:** Implementation complete — Android acceptance pending
- **Updated:** 2026-10-15

## Purpose

Start building the actual game foundation after M1.1/M1.2 resolved the major stack, mobile, 2.5D and tooling uncertainties.

This milestone is **not** a better prototype. Work produced here is expected to survive into later gameplay phases unless explicitly replaced by an accepted architectural decision.

## Production rules

- production-intent code by default;
- no throwaway scene/system without a named unresolved technical risk;
- smallest useful production slice rather than broad half-built frameworks;
- reuse M1.2 code only when it fits production contracts cleanly;
- keep `Gameplay -> Foundation -> Core` dependency direction;
- data and simulation state must remain separate from presentation;
- mobile/Web constraints are first-class;
- generated art targets real game use when requirements are known;
- avoid token-expensive duplicate asset/code generation;
- one feature branch per coherent production slice, tested before merge.

## Slice 1 — Core runtime

Deliver the minimum real runtime infrastructure:

- game lifecycle entry point;
- module/service registry;
- typed event bus;
- stable entity IDs;
- component/capability foundation;
- namespaced data registry;
- clocks/tick scheduler foundation;
- feature flags;
- logging/diagnostics;
- schema/version-ready save foundation.

Acceptance:

- modules declare identity/dependencies;
- invalid dependencies fail visibly;
- core can start with only declared dependencies;
- entity IDs survive save/load round-trip proof;
- data IDs reject duplicates;
- event subscriptions can be added/removed safely;
- no gameplay-specific rules live in Core.

Slice 1 implementation: production runtime and focused validation are in `client/core/`, `client/foundation/entity_components.gd`, and `client/tests/core_tests.gd`. Run `bash tools/dev/test_core.sh`. See ADR-0009 for lifecycle, scheduling and snapshot contracts. The remaining slices are implemented below; physical-device acceptance is tracked separately.

## Slice 2 — Production player foundation

Create the real player entity on top of the Core/Foundation contracts:

- player stable entity identity;
- movement component/service;
- production mobile + desktop input abstraction;
- gravity/jump/elevation movement;
- player-facing state exposed for later attributes/combat/equipment;
- production camera controller with tunable sensitivity;
- presentation interface separated from physical player state.

The M1.2 billboard placeholder is not the final presentation contract.

Character presentation must support the future modular vector rig and directional visual states without coupling movement logic to a specific sprite implementation.

Slice 2 implementation: `client/foundation/player/` and `client/runtime/`. Contracts and Android controls: `docs/architecture/PLAYER_FOUNDATION.md`; decision: ADR-0010. Run Core and Player test scripts. Live MCP acceptance remains blocked by the host bridge connection; Android acceptance awaits BK.

## Slice 3 — Production world/region shell

Create the first real world shell rather than another test map:

- stable world/region identity;
- region loading contract;
- basic 3D terrain/ground container;
- spawn/entry contract;
- world clock connection;
- region-owned persistent state container;
- hooks for future chunking/streaming without implementing full world simulation yet.

This becomes the home for later combat, living-world and survival slices.

Slice 3 implementation: `client/foundation/world/` owns World/Region contracts and save sections; `client/world/` supplies production residency, Region-owned player spawning and the first terrain scene. See `docs/architecture/WORLD_REGION_FOUNDATION.md` and ADR-0011. Run Core, Player and World test scripts. Live MCP acceptance is blocked by the bridge connection; Android validation awaits BK.

## Slice 4 — Save / resume loop

Prove the real game state can survive restart:

- world ID;
- player entity ID;
- player transform/state required by the slice;
- current region ID;
- schema version;
- module-owned state sections;
- migration hook structure;
- safe load failure diagnostics.

No full event sourcing. Snapshot/versioned state is the baseline unless later evidence requires more.

Slice 4 implementation: `client/runtime/persistence/` owns local slot policy,
full-snapshot integrity validation and application save/resume orchestration.
The real `user://saves/current.json` path uses validated full-precision JSON and
flushed temporary-file/rename replacement. Startup resumes only valid existing
saves; corrupt slots block visibly and remain protected. See
`docs/architecture/SAVE_SYSTEM.md` and ADR-0012 for contracts, failures and BK steps.

Automated validation: Core 55 checks, Player 23, World/Region 50, persistence 90,
independent-process save 5, resume 11 and lifecycle/exit 4; zero failures.
The process proof walks onto the real ridge, saves to disk, exits Godot, starts
another process, restores all canonical sections and continues jump/move/camera.
MCP remains blocked after bounded recovery. BK's Android save/terminate/resume
acceptance is pending; no mobile performance claim is made.

## Visual asset rule

When a slice requires a visual asset and its requirements are already known, create it with production intent:

- follow `docs/design/ART_DIRECTION.md`;
- follow `skills/vector-art/SKILL.md`;
- use the project palette/shape language;
- define pivots/layers/views before drawing modular character pieces;
- avoid generating a low-quality temporary asset and then paying the token cost again for the same role.

Placeholder art is acceptable only when visual fidelity is irrelevant to the slice or final art would block an unresolved technical dependency.

## Branch / validation flow

For each slice:

`feature branch -> implement -> automated/MCP checks -> Android test when relevant -> review -> merge main`

Do not push half-verified gameplay directly into `main`.

## Definition of done

M1.3 is complete when the repository has a production-intent Core/Foundation runtime, a real player foundation, a real world/region shell, and a versioned save/resume path that later gameplay modules can build on without depending on the M1.2 proof scene.

Implementation evidence for each Definition of Done item:

- [x] Production Core/Foundation runtime with declared module contracts and tests.
- [x] Production Player identity, physical movement, input, camera and visual boundary.
- [x] Production World/Region shell owning terrain, membership and Player attachment.
- [x] Versioned, validated disk save/resume across separate OS processes, independent
  of the M1.2 proof scene, with explicit failure/lifecycle behavior.

The implementation Definition of Done is satisfied. Full device acceptance is
still pending BK's Android check; the status above does not claim that result.
Next production milestone: **Combat Production Slice** (Phase 2 in ROADMAP.md),
starting with attributes/health/resources and combat contracts on these foundations.

## Explicit non-goals

M1.3 does not implement full:

- combat;
- inventory/economy;
- war simulation;
- NPC AI;
- building;
- taming;
- professions;
- final character equipment catalog;
- final world content scale.

Those systems come next on top of this foundation rather than being mocked inside it.
