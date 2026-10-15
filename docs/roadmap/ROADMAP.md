# Project Roadmap

## Development Principle

**Large scope, small production slices.**

The project is built in executable vertical/feature slices, but technical proofs are temporary tools, not the product. Once a major uncertainty is resolved, implementation moves to production-intent systems instead of polishing the proof indefinitely.

From M1.3 onward:

- default to production-intent code that belongs to the final architecture;
- do not create a throwaway prototype when the required behavior and contracts are already known;
- use a temporary proof only for a concrete unresolved technical risk;
- generated visual assets should target production use when art requirements are known;
- placeholders are acceptable only when final art is irrelevant to the task or would block a technical dependency;
- token/context budget is a real project resource: avoid repeatedly generating disposable implementations or assets.

## M1 Progress

- **M1.1 — Technical Foundation Research:** Completed (2026-10-13).
- **M1.2 — Project Bootstrap & Client/World Proof:** Completed (2026-10-13).
- **M1.3 — Core Production Foundation:** Completed and accepted on Android (2026-10-15). See `M1_3_CORE_PRODUCTION_FOUNDATION.md`.
- **Next production milestone:** Combat Production Slice (Phase 2).

The selected foundation is Godot 4.7.2/GDScript for the client, with the established mobile/Codespaces/Codex/MCP workflow. Candidate technologies not yet exercised by production systems remain subject to evidence when their milestone arrives.

## Phase 0 — Pre-production

Completed or established enough to proceed:

- GDD v0.x and systemic design direction;
- modular architecture and ADR foundation;
- Godot/mobile development stack;
- vector-art direction and creation rules;
- repository/module boundaries;
- Codex/MCP/real-device development loop.

## Phase 1 — Core Production Foundation

Objective: build the real reusable foundation that all later gameplay systems depend on.

- game lifecycle/bootstrap;
- Module Manager / service contracts;
- typed Event Bus;
- stable entity identity + component/capability foundation;
- data registry with stable namespaced IDs;
- clocks/tick scheduling foundation;
- logging/diagnostics and feature flags;
- save/load foundation with schema/version hooks;
- production input abstraction for mobile/desktop;
- production player entity foundation;
- production 2.5D camera/movement integration;
- first real world/region shell using the above systems.

The existing M1.2 visual proof is evidence. Individual pieces may be reused only if they satisfy the production contracts; the proof scene itself is not the architecture.

## Phase 2 — Combat Production Slice

- attributes/health/resources;
- combat foundation;
- modular abilities;
- one production enemy archetype;
- telegraphs;
- dodge/block/interruption according to the combat design;
- one modular mini-boss;
- minimum production equipment path.

Slice 1 — **Production Combat Foundation implemented**: generic stable-ID
combatants, typed attributes and source modifiers, damage/healing transactions,
relationship policy, typed facts, defeat boundary and disk-backed Player combat
persistence. See `docs/architecture/COMBAT_FOUNDATION.md` and ADR-0013.
This completes only the foundation slice; Android combat acceptance is pending.
Next slice: Player combat intent and modular action/ability execution. Enemy AI,
telegraphs, defensive verbs, mini-boss and equipment remain future Phase 2 work.

## Phase 3 — Living World Production Slice

- region/chunk state;
- faction state;
- NPC foundation;
- simulation LOD;
- small autonomous Blue/Red conflict independent of the player;
- contested territory;
- strategic/debug state inspection.

## Phase 4 — Survival / Economy Foundation Slice

- resource identity and gathering;
- persistent inventory/item custody foundation;
- item condition/decay batches and stacks;
- bags/weight;
- crafting and stations;
- modular building minimum;
- contextual occlusion;
- initial real production/stock flow needed by the slice.

## Phase 5 — Emergent RPG Slice

- reputation;
- loyalty/desertion;
- systemic quests;
- deeper economy;
- creature/ecology foundation;
- first production taming method;
- relationships/memory integration where required by the slice.

## Phase 6 — Chapter 1 Vertical Production Slice

Combine the previous production systems in one representative region of the first kingdom suitable for real gameplay testing.

## Expansion

Only after the vertical production slice is stable do we scale content: more races/classes, regions, professions, advanced economy, larger multiplayer, additional ecosystems, and new kingdoms/world areas.
