# ADR-0004 — Client Runtime Candidate: Godot 4.7.2

- **Status:** Proposed — selected for M1 proof
- **Date:** 2026-10-13

## Context

The client must support mobile-first Web delivery, later native mobile/desktop builds, a true 3D spatial world with stylized 2D-looking characters, camera rotation, terrain height, navigation, physics and strong authoring tools. Recurring licensing cost should be avoided.

## Decision

Use **Godot 4.7.2 stable** as the primary M1 client/runtime candidate.

Use GDScript-first client code and treat the **Compatibility renderer/WebGL2 as the visual baseline** because Godot Web exports do not support Forward+/Mobile rendering methods.

The spatial world is 3D; character presentation is prototyped as modular Sprite3D/quads/transform hierarchy rather than assuming a pure 2D scene.

Do not enable large-world double precision by default. Prefer region/cell-local coordinates and streaming unless M1 measurements prove otherwise.

## Consequences

Positive:

- no engine license/runtime fee dependency;
- strong editor and 2D/3D tooling;
- direct Web/native export path;
- integrated Jolt, NavigationServer, MultiMesh, HLOD/visibility and occlusion features;
- existing project familiarity.

Risks:

- Web is constrained to Compatibility/WebGL2;
- mobile browser memory/CPU/GPU budgets are strict;
- stylized modular rig approach needs proof under camera rotation;
- Web networking options are narrower than native.

## Alternatives Considered

- Unity 6: strong tooling/DOTS but future commercial licensing dependency and heavier project footprint.
- Defold: excellent lightweight Web/mobile and Rive integration, but more custom work for this project’s 3D spatial/navigation/terrain requirements.
- PlayCanvas/Babylon.js: stronger browser/WebGPU story, but greater custom game/editor/native infrastructure burden.

## Acceptance Gate

Change status to `Accepted` only after M1 proves:

- representative mobile Web performance;
- 2.5D camera/world model;
- character rig/equipment pipeline;
- Compatibility renderer visual quality;
- acceptable startup/memory/frame-time budget.
