# ADR-0010 — Production player boundaries

- **Status:** Accepted
- **Date:** 2026-10-15

## Decision

Compose the production player outside Core with a `foundation.player` module,
Core entity identity, a stable capability container and a versioned persistent
physical state section. Semantic intent is the only input to movement. A
CharacterBody3D adapter performs collision physics and synchronizes explicit
state; character visuals and camera never provide saved physical defaults.

Camera and visual adapters consume state separately. Directional presentation
resolves front/back/side plus mirroring, with rig parts, attachments, animation
and layer ordering owned by future adapters. Movement modifiers use callable
providers without feature dependencies.

Until Region exists, a runtime-only host supplies placement, collision and
composition. It owns no world schema. Region will replace this host rather than
extend M1.2 proof scenes or rewrite Player internals.

## Consequences

Core remains unchanged. Tests can boot Player with only declared Core services.
The initial primitives are observation aids, not production character content.
Networking authority, rig implementation, zoom/occlusion and the end-to-end
save/resume UX remain future slices. See `../architecture/PLAYER_FOUNDATION.md`
for concrete contracts, coordinate assumptions and controls.
