# Milestones

This file preserves high-level milestone gates. Product development after the completed technical foundation is organized by Macro Versions, not isolated slices.

## M0 — Repository Foundation

Exit criteria:
- repository structure exists;
- GDD v0.1 exists;
- architecture documents exist;
- ADR process exists;
- agent rules exist;
- roadmap exists.

## M1 — Technical Foundation

Exit criteria:
- stack/engine chosen from evidence;
- mobile Godot proof runs on target device;
- camera/2.5D spatial model validated;
- base asset/character rig direction validated enough to proceed;
- production modular Core/Player/World/Save foundations established;
- development/Codex/MCP workflow established;
- unresolved technical risks documented.

Status: completed through M1.3. Historical M1 proof/foundation documents remain authoritative records for their decisions.

## Pass A — Playable Game

### A1 — Combat & Player Gameplay

Exit criteria:
- representative player + enemy combat loop is Player Complete for the A1 scope;
- health/resources/damage/healing/defeat are integrated;
- modular abilities/cooldowns/resource costs work;
- targeting/telegraphs/defensive verbs work;
- minimum equipment hook/path required by combat works;
- required mobile controls/HUD/feedback exist;
- expected combat state persists;
- automated/runtime/device acceptance gates pass.

### A2 — World & Exploration

Exit criteria:
- representative region is explorable as a real game environment;
- world/terrain/height/2.5D traversal behavior works;
- representative props/resources/biome rules exist;
- world state/persistence works;
- environment presentation is representative rather than debug-only;
- mobile performance is measured for the scope.

### A3 — Inventory, Items & Survival

Exit criteria:
- gather/loot -> custody/inventory -> equip/use/consume loop works;
- representative item condition/stack/survival rules required by scope work;
- mobile inventory interaction is usable;
- expected item state persists.

### A4 — Living NPCs & Player-like Bots

Exit criteria:
- autonomous NPCs/bots perform contextual actions without player scripting;
- perception/knowledge/memory/personality boundaries exist for the representative scope;
- player-like bots reuse public gameplay capabilities where viable;
- important characters can persist divergent server histories;
- simulation LOD/persistence supports the representative population;
- deterministic/scenario validation exists for core behavior.

### A5 — RPG Identity

Exit criteria:
- representative race/class/progression choices materially affect gameplay;
- class/race traits, abilities and equipment integration work;
- representative character identity/profile flow is usable.

### A6 — Building, Economy & World Transformation

Exit criteria:
- representative gather/produce/build/store/exchange loop works;
- world changes persist;
- NPC/system interaction with the representative economy works where in scope.

### A7 — Multiplayer / Server Foundation

Exit criteria:
- authoritative development server hosts the representative gameplay loop;
- session/protocol/persistence boundaries work;
- private/official server direction is supported by measured architecture rather than placeholders;
- bots/NPCs have correct authoritative ownership.

### A8 — Game Shell

Exit criteria:
- main menu/settings/join flow required by the current network model work;
- PC input remapping/mobile HUD customization/controller support are implemented to accepted scope;
- product-level onboarding/error states exist;
- an integrated playable build can be entered and configured without development-only steps.

## Pass B — Feature Depth

Return through the same domains and expand content/depth without rebuilding their foundations.

Exit criteria are defined per Macro Version+ mission: more classes, abilities, enemies, bosses, ecosystems, professions, structures, NPC behaviors, economy depth and multiplayer scale.

## Pass C — Polish / Release

Exit criteria:
- visual/audio/animation/UX cohesion;
- performance and memory budgets met on target devices;
- balancing/content tuning;
- save migration and networking resilience;
- accessibility/input refinement;
- production hosting/deployment choices backed by measurements;
- release candidate passes cross-system regression and device acceptance.
