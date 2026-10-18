# Project Roadmap

## Development Principle

**Large scope, coherent playable Macro Versions.**

Historical slices remain documented because they record work already completed. From this point forward, slices are no longer the product-planning unit. New work is grouped into Macro Versions that each produce a coherent player-visible capability or major game pillar.

Internal engineering may still use tasks/checkpoints/commits, but BK should normally receive an integrated candidate instead of a sequence of isolated infrastructure slices.

Use **foundation just-in-time**: build only the foundation required by the active Macro Version, then finish the corresponding gameplay loop before moving to a different major domain.

From M1.3 onward:

- default to production-intent code that belongs to the final architecture;
- do not create throwaway prototypes when required behavior/contracts are already known;
- use temporary proofs only for concrete unresolved technical risks;
- generated/integrated visual assets should target representative game use when requirements are known;
- placeholders are acceptable only when fidelity is irrelevant to the scoped mission or blocked by a real dependency;
- Engineering Complete and Player Complete are distinct states;
- player-facing Macro Versions close only when their Mission Contract and Shippable Definition of Done pass.

## Completed Foundation History

- **M1.1 — Technical Foundation Research:** Completed (2026-10-13).
- **M1.2 — Project Bootstrap & Client/World Proof:** Completed (2026-10-13).
- **M1.3 — Core Production Foundation:** Completed and accepted on Android (2026-10-15). See `M1_3_CORE_PRODUCTION_FOUNDATION.md`.
- Godot 4.7.2/GDScript remains the selected client foundation.

## Historical Combat Work

The previous Phase 2 slices are retained as engineering history and are now inputs to the first Macro Version rather than separate future delivery units.

- **Historical Slice 1 — Combat Foundation:** implemented and Android-accepted. Generic combatants, typed attributes/modifiers, damage/healing transactions, relationships, typed facts, defeat boundary and Player combat persistence.
- **Historical Slice 2 — Player Combat Actions:** implemented and Android-accepted. Semantic actions, strike/self-heal, action execution, targeting/effects, cancellation/interruption, movement gates, cues and persisted cooldowns.
- **Historical Slice 3 — Enemy/Targeting/Telegraphs:** implemented and Android-accepted. Persistent melee enemy, autonomous controller, targeting/disposition, telegraphs, save reset and Region safe-transform recovery. Automated result recorded as 598 checks / 0 failures. No final combat HUD/art was claimed.

These systems are not discarded or rewritten merely because planning changed.

---

# Pass A — Playable Game

Goal: establish the representative end-to-end loop of the game with production-intent systems and limited content breadth.

## Macro Version A1 — Combat & Player Gameplay

**Status:** ACTIVE — completion/audit mission starts now.

Player outcome: the player can enter the world, read a threat, fight it using a coherent mobile/desktop combat loop, spend/recover resources, defend, receive feedback, win/lose, and have the expected combat state persist.

This version groups related work instead of creating new isolated slices:

- health/attributes/resources;
- damage/healing/defeat;
- modular actions/abilities and cooldown/resource costs;
- targeting and disposition;
- representative enemy behavior;
- telegraphs;
- dodge/block/interruption/defensive verbs required by combat design;
- minimal equipment path needed for combat;
- combat HUD and mobile controls required for the representative loop;
- hit/damage/heal/defeat/resource/cooldown feedback;
- representative animation/audio/visual presentation where already specified;
- combat persistence/save-resume;
- integrated automated/runtime/device acceptance.

Existing implementations must be audited/reused before new systems are introduced. The active mission is `docs/missions/COMBAT_A1_FOUNDATION_COMPLETION.md`.

Content breadth intentionally remains small: this is not the stage for hundreds of weapons, enemies or skills.

## Macro Version A2 — World & Exploration

Player outcome: a representative region feels like an explorable game world rather than a test scene.

Groups:

- terrain/world generation required by current design;
- height/2.5D navigation and traversal;
- biome/environment rules;
- props/resources/spawn rules;
- representative 3D environment assets/materials/textures;
- gathering interaction hooks;
- world persistence/region state;
- mobile performance/culling/streaming appropriate to the representative region.

## Macro Version A3 — Inventory, Items & Survival

Player outcome: gather, receive loot, store, equip, consume/use and persist representative items/resources.

Groups:

- item identity/custody;
- inventory/bags/weight as required;
- equipment integration;
- item condition/stack/decay rules in scope;
- gathering/resource flow;
- consumables and survival-resource hooks;
- representative crafting/station loop where required;
- inventory/mobile UI;
- save/resume.

## Macro Version A4 — Living NPCs & Player-like Bots

Player outcome: the world contains autonomous characters that create believable company/activity even with few or no human players.

Groups:

- NPC/bot state and capabilities;
- perception/knowledge/memory boundaries;
- personality/traits/individual variation;
- contextual goals/actions;
- relationships/reputation required by representative behavior;
- player-like bots using shared public gameplay capabilities where viable;
- important authored NPCs with deeper stable identities;
- simulation LOD;
- persistence;
- deterministic/scenario validation hooks.

Bots are not intended to deceive players about being human. The design goal is believable autonomous participation and companionship.

## Macro Version A5 — RPG Identity

Player outcome: representative race/class/progression choices materially change play.

Groups:

- one or few representative races/classes first;
- attributes/progression;
- class/race traits;
- ability progression;
- equipment/stat interaction;
- representative quest/reputation hooks;
- character creation/profile presentation required by the loop.

## Macro Version A6 — Building, Economy & World Transformation

Player outcome: representative world resources can be converted into useful persistent changes.

Groups:

- building minimum;
- crafting/production flow;
- storage/stock;
- economy ownership/exchange hooks;
- contextual occlusion/presentation;
- NPC interaction with the same economy where in scope.

## Macro Version A7 — Multiplayer / Server Foundation

Player outcome: a development server can authoritatively host the representative loop and support the later official/private-server model.

Groups:

- protocol/shared schemas;
- authoritative server state;
- connection/session lifecycle;
- player identity required for the current product stage;
- persistence/server save boundaries;
- private-server direction;
- official-server hosting requirements measured rather than assumed;
- representative bot/NPC server ownership.

## Macro Version A8 — Game Shell

Player outcome: the representative game can be launched/configured/entered like a real product.

Groups:

- main menu;
- server selection/join flow as available;
- settings;
- keyboard remapping for PC scope;
- controller support where feasible;
- mobile HUD customization;
- save/account/profile shell required by the chosen network model;
- onboarding/error states;
- release-oriented diagnostics.

---

# Pass B — Feature Depth

Return through the same major domains and expand depth rather than rebuilding their foundations:

- Combat+;
- World+;
- Inventory/Economy+;
- NPC/Bot+;
- RPG/Class+;
- Building+;
- Networking+;
- Game Shell+.

Examples include more classes, abilities, enemies, bosses, ecosystems, structures, professions, NPC behaviors and larger multiplayer scale.

# Pass C — Polish / Release

Cross-system polish and release hardening:

- final visual/audio cohesion;
- animation/feedback polish;
- UX/accessibility/input refinement;
- balancing/content tuning;
- performance and memory budgets;
- networking resilience;
- save migrations;
- onboarding;
- device/platform validation;
- production hosting/deployment decisions based on measurements.

## Expansion Rule

Do not scale content breadth aggressively until the representative loops that consume that content are Player Complete. Prefer a small number of production-quality examples exercising the whole system over large quantities of disconnected content.
