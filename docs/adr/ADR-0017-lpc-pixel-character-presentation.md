# ADR-0017 — LPC Pixel Character Presentation in the 3D World

- **Status:** Accepted
- **Date:** 2026-10-22

## Context

The previous character-art direction assumed custom modular vector characters using three authored views, multiple runtime body/equipment layers, bones/IK and procedural deformation.

That approach creates a large bespoke art/animation burden, increases runtime layering complexity and duplicates a body/equipment ecosystem that already exists in the Liberated Pixel Cup (LPC/ULPC) community.

The game already requires a true 3D world for terrain height, structures, jumping, camera rotation, physics and systemic simulation. Character gameplay logic does not depend on the vector implementation.

## Decision

Adopt a production presentation architecture based on:

- true 3D world and gameplay geometry;
- pixel-art humanoid characters based primarily on a pinned Universal LPC asset catalog;
- upright `Sprite3D`-style character presentation;
- four-direction LPC facing resolved relative to the rotating camera while canonical facing remains world-space;
- data-driven race visual profiles and curated palette choices;
- offline layer composition/caching rather than one independently animated runtime draw object for every LPC body/equipment layer;
- `AnimationPlayer` plus `AnimationTree`/state-machine presentation driven by semantic gameplay animation states;
- project-owned frame-aware pixel-normal-map tooling for optional 3D lighting integration;
- deterministic asset provenance, licensing and generated credits.

The game must not require an online LPC service at runtime.

## Superseded assumptions

This ADR supersedes the following production assumptions from the previous art direction:

- custom vector art as the default humanoid source format;
- three-view front/back/side character production with mirrored side art;
- full humanoid modular rig rendered from many independent vector pieces;
- bones/IK/procedural deformation as the default character animation pipeline;
- vector-only visual identity for the world.

Prototype billboard/vector work remains valid as technical evidence only.

## Preserved invariants

This decision does not change:

- server authority;
- player movement/combat contracts;
- item/equipment authority;
- race gameplay rules;
- persistence ownership;
- true 3D terrain/elevation/camera requirements;
- mobile-first performance goals.

Appearance remains presentation derived from canonical data.

## Camera-relative direction rule

Actor facing is canonical world state.

A presentation-only resolver computes which LPC cardinal view should be visible from the current camera orientation. Camera rotation therefore changes the visible sprite face without mutating gameplay-facing direction.

Directional selection must use hysteresis/dead bands to avoid flicker at quadrant boundaries.

## Composition rule

LPC modularity is retained at the data/import layer.

Default runtime output is a composed/cached animation sheet or equivalent minimal-draw representation. Separate runtime layers are reserved for cases that materially require independent motion, effects or occlusion.

Composition occurs on appearance/equipment change, not every frame.

## Race customization rule

Playable races define curated `RaceVisualProfile` data including body family, required species layers, skin/eye/hair palette sets, compatible equipment and visual scale.

Players customize within the profile. They do not receive arbitrary access to every LPC component.

## Licensing rule

No LPC-derived production asset is accepted without machine-readable author/source/license provenance.

The project keeps:

- a full pinned-upstream legal/catalog archive;
- an exact used-asset manifest;
- generated in-game attribution/legal resources.

Target-specific license compatibility must be validated before release.

## Consequences

Positive:

- much larger reusable character/equipment/tool asset base;
- faster race/equipment prototyping;
- predictable four-direction animation vocabulary;
- reduced custom character-art workload;
- easier data-driven recoloring/material variants;
- strong fit with 2.5D/HD-2D-like presentation;
- simpler mobile runtime when sheets are precomposed/cached.

Risks:

- heterogeneous upstream license obligations;
- not every LPC layer supports every expanded animation/body;
- composition/palette tooling must be built and maintained;
- four-direction art can visibly snap during camera rotation without a good resolver;
- normal maps for pixel sprites require custom frame-aware tooling;
- visual consistency requires curation instead of blindly using the entire upstream catalog.

## Follow-up contracts

- `docs/design/ART_DIRECTION.md`
- `docs/design/LPC_CHARACTER_PIPELINE_AND_LICENSING.md`
- race visual-profile schema when playable-race implementation begins;
- pixel normal-map tool specification before normal-map production work;
- runtime character presentation implementation in the appropriate Chapter/Run delivery.

## Acceptance gate

This ADR is successfully implemented when a representative race can be composed from pinned LPC sources, rendered in the true 3D world, preserve world-space facing under camera rotation, animate through semantic state transitions, change equipment/material palette without layer drift, run within mobile budgets, and provide complete source/license attribution.