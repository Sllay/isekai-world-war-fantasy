# M1.3 — Core Production Foundation

- **Status:** Ready
- **Updated:** 2026-10-13

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
