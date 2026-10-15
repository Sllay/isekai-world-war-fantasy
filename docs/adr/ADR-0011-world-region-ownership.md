# ADR-0011 — World and Region ownership

- **Status:** Accepted
- **Date:** 2026-10-15

## Decision

Keep World identity/time and Region residency/state in separate Foundation
modules. World depends on Core; Region depends on World, Player and Core.
Region supplies Player location through its existing capability container, so
Player gains no dependency on World and cannot own Region state.

Content definitions declare stable IDs, membership, entries, origin, scene and
future metadata references. Scene/node names are never canonical identities.
Region state survives residency changes. World borrows Core's clock, and Region
borrows World time; neither creates or serializes another clock.

Replace the Slice 2 temporary host with a production WorldScene and RegionScene.
Extract its reusable Player composition as PlayerAvatar; keep the physics fixture
only in tests. Region selects entries, positions canonical state and owns physical
attachment. Resume attaches existing state without applying spawn defaults.

Use translation-only region-local coordinates with floor-divided horizontal chunk
addresses. Region owns future streaming/fidelity decisions, without implementing
streaming or simulation. The initial Region uses an authored continuous terrain
surface with neutral material and real collision/elevation.

## Consequences

World and Region have separate versioned persistent sections. Slice 4 owns the
unload/restore/reattach orchestration and cross-section validation. Content must
match the selected world before load. Only one Region is resident now; future
streaming can change residency without changing Player identity or movement.
See `../architecture/WORLD_REGION_FOUNDATION.md` for lifecycle and contracts.
