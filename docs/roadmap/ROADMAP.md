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

## Cross-cutting Online-first Authority

**Server authority is not deferred to A7.**

From A1 onward, every gameplay-critical Macro Version must establish the authority/command boundary for the state it introduces.

Release clients request gameplay through semantic commands/intents; canonical persistent/competitive outcomes live behind the AuthorityHost boundary defined by `docs/architecture/SERVER_AUTHORITY.md` and ADR-0016.

Development may use a LocalAuthorityHost/loopback adapter, but never an automatic client-authoritative fallback.

Therefore:

- A1 establishes the pattern for movement/combat/actions;
- A2 keeps canonical world/environment mutations authority-owned;
- A3 keeps inventory/item/equipment/crafting custody authority-owned;
- A4 keeps NPC/Bot simulation and shared gameplay actions authority-owned;
- A5 keeps progression/ability acquisition authoritative;
- A6 keeps Building/economy/world transformations authoritative;
- A7 productizes transport, sessions, private hosting and official operations rather than retrofitting authority into finished systems.

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

These systems are not discarded or rewritten merely because planning changed. Their deterministic logic is audited and moved behind the online-first authority boundary where required.

---

# Pass A — Playable Game

Goal: establish the representative end-to-end loop of the game with production-intent systems and limited content breadth.

## Macro Version A1 — Combat & Player Gameplay

**Status:** ACTIVE — implementation mission currently held for final design-readiness closure.

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
- **AuthorityGateway/AuthorityHost boundary for movement and combat**;
- client semantic commands rather than trusted final damage/position;
- LocalAuthorityHost/loopback development path using the same command semantics;
- adversarial tests for forged/duplicate/stale combat commands;
- movement prediction/reconciliation boundary where required for the representative network proof;
- integrated automated/runtime/device acceptance.

Existing implementations must be audited/reused before new systems are introduced. `CombatService`, `ActionExecutor`, `PlayerIntent` and the Player foundation are inputs to the authority integration, not discarded simply because they currently execute locally.

The prepared mission is `docs/missions/COMBAT_A1_FOUNDATION_COMPLETION.md`, currently held until the remaining design-readiness blocker is closed.

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
- authority-owned persistent world mutations/terrain/resource commits;
- mobile performance/culling/streaming appropriate to the representative region;
- server simulation/streaming budgets appropriate to `private_4gb` where server-side work is introduced.

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
- authority-owned custody/equipment/crafting transactions;
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
- server-owned planner/simulation authority;
- L0-L3 simulation fidelity;
- persistence;
- deterministic/scenario validation hooks;
- private-server NPC/Bot population/config hooks within validated budgets.

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
- authoritative progression/acquisition validation;
- character creation/profile presentation required by the loop.

## Macro Version A6 — Building, Economy & World Transformation

Player outcome: representative world resources can be converted into useful persistent changes.

Groups:

- building minimum;
- crafting/production flow;
- storage/stock;
- economy ownership/exchange hooks;
- contextual occlusion/presentation;
- NPC interaction with the same economy where in scope;
- authority-owned placement/damage/repair/economy transactions;
- private-server building/raid/rate settings within performance/integrity guardrails.

## Macro Version A7 — Multiplayer / Server Productization

Player/operator outcome: the already-authoritative representative game can be reliably hosted, discovered, configured and operated as official or player-run servers.

Groups:

- external transport selected from proof evidence;
- versioned wire schemas/protocol compatibility;
- authentication and connection/session lifecycle;
- server discovery/join flow;
- reconnect/resync hardening;
- private-server package/startup flow;
- versioned `ServerRuleProfile` configuration;
- custom NPC/Bot definition management;
- safe special-NPC/content enable/disable/migrations;
- admin permissions/audit tooling;
- server health/capacity reporting;
- private `private_4gb` deployment proof;
- official-server deployment/backup/observability requirements;
- abuse/security hardening;
- load/latency/loss/scale validation;
- update/save/protocol migration operations.

A7 must **not** rewrite A1-A6 to become authoritative. It productizes an authority model already used by them.

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
- Networking/Server+;
- Game Shell+.

Examples include more classes, abilities, enemies, bosses, ecosystems, structures, professions, NPC behaviors, private-server customization and larger measured multiplayer scale.

# Pass C — Polish / Release

Cross-system polish and release hardening:

- final visual/audio cohesion;
- animation/feedback polish;
- UX/accessibility/input refinement;
- balancing/content tuning;
- client/server performance and memory budgets;
- networking resilience;
- save/protocol migrations;
- onboarding;
- device/platform validation;
- production hosting/deployment decisions based on measurements.

## Expansion Rule

Do not scale content breadth aggressively until the representative loops that consume that content are Player Complete. Prefer a small number of production-quality examples exercising the whole system over large quantities of disconnected content.
