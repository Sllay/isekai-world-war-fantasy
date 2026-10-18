# Server Configuration & Private Server Design

- **Version:** 0.1.0
- **Status:** First-scope design contract
- **Updated:** 2026-10-18

## Purpose

Define one configurable server product that can serve both:

- **official/public servers** operated by the project;
- **private/community servers** operated by players on local hardware, VPS/free cloud or similar constrained hosts.

Private servers should be expressive enough to create distinct worlds without requiring source-code forks or disabling authoritative validation.

## Core Principle

> Customize rules and content data; do not fork the simulation core for ordinary server customization.

Official and private servers use the same canonical authority/domain rules. A server owner may change configured gameplay parameters, world content and allowed actor definitions within validated bounds.

## Versioned Server Profile

Every world/server stores a versioned `ServerRuleProfile` (name is conceptual) containing:

- profile schema version;
- server identity/config ID;
- world-generation settings;
- gameplay multipliers/rules;
- NPC/Bot content overrides;
- enabled/disabled content IDs;
- persistence policy;
- resource/performance profile;
- optional content-pack references;
- canonical configuration hash.

The configuration hash/version is persisted with the world so an existing save is not silently loaded under incompatible rules.

Breaking changes require explicit migration or rejection.

## Server Classes / Presets

Initial operational presets should include:

### `official`

Project-operated server. Conservative gameplay authority, richer telemetry/backups and measured higher capacity where infrastructure allows it.

### `private_4gb`

Primary low-resource self-host target.

Target environment:

- approximately 4 GB system RAM;
- modest contemporary 64-bit ARM64/x86-64 CPU;
- headless operation;
- single machine/process group where practical;
- compatible with inexpensive/free hosting where provider restrictions allow;
- should remain viable for local Linux/Termux-class experimentation where platform/network restrictions permit.

The profile uses stricter population/active-simulation/replication budgets, not weaker correctness.

### `private_standard`

For stronger home/VPS hosts with larger simulation and player budgets.

### `sandbox_high`

Development/high-resource profile. May raise simulation limits for stress testing but does not disable authority/security invariants.

Exact player/entity capacities are benchmark-derived and must not be advertised from configuration alone.

## Server Identity and Access

Configurable fields may include:

- server name/description;
- public/private/unlisted discoverability;
- password/invite policy;
- player cap within host-tested hard limits;
- whitelist/ban/admin identities;
- region/language tags;
- world name;
- PvE/PvP tags;
- optional community rules text.

Authentication implementation remains architecture/operations work; these are product requirements.

## World Customization

A server owner may configure bounded world-generation inputs such as:

- seed;
- generator profile/version compatible with the game;
- world/continent size preset;
- biome weighting within safe ranges;
- cave density/depth profile;
- village/city/capital density constraints;
- road/landmark density;
- resource abundance profile;
- day/night length;
- season/weather intensity where supported;
- world-event intensity;
- terrain modification policy;
- persistence/reset/season policy where supported.

Changing structural world-generation parameters after a world already exists requires a defined migration/regeneration operation. It must not silently reinterpret existing chunks.

## Rates and Economy

Server rules may expose validated multipliers such as:

- gathering/farm yield;
- crop growth;
- crafting speed/cost where allowed;
- smelting/processing time;
- resource regeneration;
- XP/mastery/progression gain;
- reputation gain/loss scaling;
- item durability loss;
- food/item decay;
- merchant/economy tuning bands;
- quest reward scaling where the underlying economy can fund it.

Multipliers modify canonical formulas/data. They do not create client-authoritative rewards.

Use bounded fixed-point/integer configuration where deterministic simulation benefits from it.

## Creature / Monster Customization

Server owners may configure:

- creature/monster ecology abundance multipliers;
- threat density budgets;
- respawn/recolonization pace where the species model permits it;
- elite/rare-event frequency bands;
- allowed/disabled creature definitions;
- biome-specific overrides;
- taming enable/rules where supported;
- boss/world-event enablement.

Prefer **population/carrying-capacity/event-budget controls** over naive `spawn X every N seconds` rules. The goal is to scale a living ecology without turning server rate settings into uncontrolled entity factories.

Hard performance/safety caps remain enforced by the server profile.

## NPC Customization

Private server owners may control:

- total resident NPC budget/target bands;
- profession distribution weights;
- settlement population scaling;
- important/named NPC enable/disable rules;
- custom NPC definitions;
- custom starting relationships/faction/culture where allowed;
- custom schedules/profession presets;
- custom equipment/inventory presets within content rules;
- settlement assignments;
- dialogue/lore metadata when custom-content support is available.

### Custom NPC Definitions

First-scope custom NPCs should be **validated data compositions**, not arbitrary executable scripts supplied to the authoritative process.

A custom definition may select/reference:

- race/species/culture;
- visual profile/asset references;
- profession/role;
- personality/trait profile;
- starting equipment/resources;
- relationship/faction anchors;
- allowed goals/capabilities;
- home/settlement;
- authored identity/dialogue metadata.

Custom IDs should be namespaced, for example:

`server.<server_id>.npc.<name>`

This preserves save/reference stability and avoids collisions with official content.

### Removing Official/Special NPCs

A configuration may disable a special NPC from a **new world** when the content contract allows it.

For an existing persistent world, removal is a migration problem. The server must preserve or deliberately transfer:

- unique-item custody;
- property/storage ownership;
- contracts/quests;
- family/relationship anchors;
- faction/office roles;
- outstanding economic obligations.

Never delete a persistent actor in a way that silently deletes a unique item or corrupts references.

A safe operation may instead mark the character retired/unavailable, transfer duties/property, or schedule a world-state migration.

## Player-like Bot Customization

Server owners may:

- enable/disable Bots;
- choose a target/min/max Bot population within budget;
- add/remove custom Bot profiles;
- configure starting-level bands;
- choose race/class/discipline pools;
- choose faction/allegiance profiles;
- configure progression maturity presets;
- weight personality/goal/guild profiles;
- configure activity/aggression/risk presets;
- configure whether Bots fill low-population server activity automatically;
- protect specific authored Bots from automatic retirement where desired.

Bots remain server-controlled and must be identifiable as such. They are not presented as real human accounts.

Bot customization changes planner/profile data. Bots continue to execute through the same canonical gameplay capabilities and authority rules as supported human-player actions.

## Dynamic Population Budgeting

`bot_count` and `npc_rate` should not mean “always instantiate this many full AI actors.”

The server maintains logical populations and allocates simulation fidelity according to relevance/resource budget.

A low-resource private server can therefore preserve a large logical world while limiting:

- L0 active actors;
- simultaneous path requests;
- high-frequency decision jobs;
- replicated nearby entities;
- active physics bodies.

Increasing population settings primarily changes logical/aggregate world state until actors need materialization.

## Combat, Death and Raid Rules

Configurable rules may include:

- PvP enablement/regions;
- friendly fire;
- duel rules;
- raid/building damage windows;
- structure damage multipliers;
- death/corpse protection timers;
- loot policy;
- respawn policy/options;
- combat resource regeneration multipliers;
- world-boss difficulty scaling.

The server still validates every combat/build transaction. `PvP=true` does not mean `trust client damage=true`.

## Building Rules

Server owners may configure:

- building allowed/restricted regions;
- structure-count budgets;
- decay/maintenance rules;
- raid damage windows;
- material/build speed multipliers;
- terrain-edit limits;
- abandoned-structure cleanup policy;
- ownership/group limits.

Cleanup must respect containers/item custody and persistence references.

## Unique / Limited Content

Server rules may select content policies such as:

- true unique artifact enabled/disabled;
- limited artifact count;
- renewable rare content profile;
- custom unique items/content packs in future.

Existing unique instances must never be duplicated by toggling a setting.

Changing uniqueness policy in an existing world requires validation/migration.

## Admin and Runtime Changes

Some settings can safely change live; others require restart or world migration.

Each setting/schema field should declare a change class, conceptually:

- `LIVE_SAFE`;
- `RESTART_REQUIRED`;
- `WORLD_MIGRATION_REQUIRED`;
- `NEW_WORLD_ONLY`.

Admin tooling should expose this rather than letting operators discover it through corruption.

Runtime admin commands must be authenticated/authorized and recorded in an audit log where they mutate persistent state.

## Safety Bounds

Server customization has two layers:

1. **gameplay defaults/recommended ranges** — server owner may override within supported bounds;
2. **hard safety/resource/integrity limits** — ordinary configuration cannot disable these.

Examples of hard limits:

- max message sizes;
- command-rate protection;
- entity/component schema bounds;
- maximum custom definition sizes;
- pathfinding/job queue caps;
- max active-fidelity budget for the chosen host profile;
- persistence transaction invariants;
- authority/security checks.

A developer stress-test mode may deliberately raise safety budgets, but normal public/private hosting should reject unsafe configs at boot.

## Performance-aware Rule Validation

At startup the server validates the chosen rule profile against the selected hardware/resource preset.

Potential outcomes:

- valid;
- valid with warnings;
- invalid because hard limits conflict;
- requires stronger resource profile.

The system may estimate expected load from settings, but benchmark/runtime metrics remain the final evidence.

## Configuration and Save Portability

Backups/export should include:

- world snapshot/database;
- server rule profile;
- profile/schema versions;
- custom NPC/Bot definitions;
- custom content manifest references;
- required migration metadata.

Secrets/password hashes/admin credentials are operational secrets and must not be packaged into public content manifests.

## First Representative Private-server Proof

A first proof should start one `private_4gb` server with:

- custom seed/world profile;
- modified gathering and crop rate;
- modified creature population target;
- one disabled official special NPC in a fresh world;
- one custom resident NPC;
- two custom Player-like Bot profiles with different starting/progression presets;
- save/restart;
- deterministic verification that the configuration survives and references remain valid;
- server CPU/RSS/tick/network metrics recorded.

This proves customization through data/configuration rather than source forks.
