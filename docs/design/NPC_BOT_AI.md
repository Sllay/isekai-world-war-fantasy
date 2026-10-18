# NPC and Player-like Bot AI

- **Version:** 0.1.0
- **Status:** First-scope design contract
- **Updated:** 2026-10-18

## Purpose

Define how resident NPCs, important named NPCs, creatures and server-controlled player-like Bots participate in one persistent world without requiring an LLM or a separate fake economy/gameplay layer.

The goal is believable contextual behavior produced by reusable state, memory, goals, world facts and shared gameplay capabilities.

## Core Rule

**NPC, Bot and Player are different decision sources acting through shared world contracts.**

Where practical, movement, combat, inventory, equipment, crafting, building, quests, trading, death/loot and interaction use the same canonical systems. The difference is primarily who produces semantic intent and which goals/permissions are available.

## Actor Families

### Resident NPC

A resident NPC primarily belongs to the social/economic simulation. Examples include:

- farmer;
- miner;
- blacksmith;
- baker/cook;
- merchant;
- hunter;
- guard;
- guardian/patrol defender;
- knight/escort;
- official/leader;
- other professions added through data.

A resident normally has a home/household, work role, relationships, possessions, obligations and local knowledge. A profession influences likely goals and skills but does not overwrite current state.

### Important Named NPC

Uses the same base actor model but receives higher persistence and simulation priority, richer memory/relationships and authored identity/goals where appropriate.

Commanders, dukes, major guild leaders, lore characters and other important people may survive, change allegiance, gain scars/history, acquire items, lose battles or die differently in different servers.

### Player-like Bot

A server-controlled autonomous participant intended to make a server feel active even with few or no human players.

A Bot should be able to use player-facing systems when those systems exist:

- explore;
- fight;
- gather;
- mine;
- craft;
- build;
- trade;
- equip gear;
- use items;
- accept/complete quests;
- join guild/party relationships;
- progress class/skills;
- own/store/lose items;
- form relationships and households where allowed;
- die, leave a corpse/loot state and respawn under Bot rules.

Bots are not presented as human users. The goal is believable autonomous participation, not deception.

Bots may enter a server through authored progression profiles, for example a low-level newcomer or a more established level/profile with historically plausible completed content and equipment. Exact levels are balance/content data.

### Creature / Monster

Creatures use the same world causality where relevant but do not need the full humanoid economic/social planner.

Species data can provide ecology, hunger, territory, fear, social group, hunting, reproduction and loot/harvest behavior. Intelligent monsters may opt into more actor capabilities.

## Shared Canonical Actor State

A persistent intelligent actor may expose or reference modules/capabilities such as:

- stable identity;
- race/species;
- class/progression where applicable;
- traits/personality;
- needs;
- health/resources;
- skills/proficiencies;
- profession/role;
- household/home;
- faction/organization membership;
- relationships;
- memories;
- knowledge/perception;
- current goals/obligations;
- inventory/equipment;
- property/storage;
- money and financial claims;
- location/travel state;
- legal/crime status;
- current job/task;
- persistence/fidelity priority.

Not every actor needs every capability.

## Decision Architecture

Do not encode NPC life as one giant state machine or one script per profession.

Use a layered planner where different mechanisms solve different problems:

1. **Reactive safety layer** — immediate threats such as lethal attack, fire, drowning or imminent collision.
2. **Context/state layer** — current combat, work, travel, sleep, conversation, escort or emergency context.
3. **Utility goal selection** — ranks possible goals from needs, profession, household, obligations, personality, world facts and opportunities.
4. **Task/plan decomposition** — converts the chosen goal into reusable actions or a bounded plan.
5. **Shared action execution** — requests the same movement/combat/inventory/trade/build capabilities used elsewhere.

Utility/priority selection is preferred for broad goal choice; hierarchical tasks/GOAP-like planning may be used for bounded multi-step problems. Do not run an expensive global search every frame.

## Scheduled Decisions and Simulation LOD

Actor thinking is event/schedule driven, not a full planner every rendered frame.

Examples:

- combat/reactive decisions: high frequency only while active;
- nearby daily behavior: staggered short decision ticks;
- profession/economy goals: scheduled or triggered by state changes;
- distant actor: reduced decisions or aggregate expedition/job state;
- latent population: household/cohort/organization simulation.

Promotion/demotion must preserve identity, relationships, item custody and important memory anchors as required by `WORLD_SIMULATION.md` and `ITEM_PERSISTENCE_AND_PROVENANCE.md`.

## Needs, Obligations and Context

Goals may be generated from:

- hunger/thirst/rest/safety;
- family/household needs;
- profession;
- paid contract;
- guild/settlement obligation;
- military order;
- relationships;
- debt/payment;
- personal ambition;
- fear/trauma;
- curiosity/exploration;
- equipment/resource need;
- current world crisis.

Example:

`household food low -> hunter evaluates hunt/buy/request work -> chooses viable path -> obtains food -> stores/shares/sells according to obligations`

A village food crisis can create leader/guild contracts only when actual settlement resources, treasury and institutions support those rewards.

## Profession and Settlement Roles

Initial role semantics include:

- **Farmer:** crop/animal production, storage, sale, household supply.
- **Miner:** extraction, cave travel, ore transport, tool requirements.
- **Blacksmith:** processing/crafting/service, recipe/diagram knowledge, market stock.
- **Hunter:** food/hide/resource hunting, risk assessment and household/contract supply.
- **Guard:** protects internal streets/gates/public areas and responds to local crime/threat.
- **Guardian/Patrol:** operates around settlement perimeter/nearby territory to reduce external threats.
- **Knight/Escort:** accompanies vulnerable/important workers, caravans or officials and can reinforce expeditions.
- **Autonomous Adventurer/Bot:** accepts higher-risk open problems, quests and exploration opportunities.

Roles are goal/skill profiles, not hard-coded entity subclasses.

## Contextual Survival Behavior

Actors should use world context instead of defaulting to fight-to-the-death.

Examples:

- hunter attacked by food-motivated predators may drop compatible meat as a diversion and flee;
- a parent may prioritize family safety over work;
- civilians alert guards/shelter/evacuate during attacks;
- a knight may hold a threat while an escorted miner retreats;
- an actor with low morale may flee or surrender;
- a scavenger personality may investigate unattended corpses.

Species/creature motive matters. Food diversion should not automatically pacify an animal defending offspring or territory.

## Inventory, Property and Loot

Humanoid NPCs/Bots do **not** respawn profession loot tables on death.

Their carried/equipped inventory is canonical world state. A farmer who sold wheat and carries coins can be looted for the eligible current possessions, not fabricated wheat.

Property remains separate from carried inventory:

- home storage;
- workshop stock;
- farm/barn storage;
- guild property;
- bank deposits/claims;
- other containers.

Canonical custody rules are defined in `ITEM_PERSISTENCE_AND_PROVENANCE.md`.

### Creature/Object Loot Sources

Creature species, monsters and breakable props may define reusable `Loot/Harvest Profiles` when randomized yield is appropriate.

Examples:

- creature meat/hide/fur/material yields;
- monster-specific rare drops;
- barrel/crate contents;
- destructible resource props.

This system must not be used to replace persistent intelligent-actor inventory.

## Death, Corpses and Scavenging

Death can create a persistent corpse/remains/loot-container state according to world rules.

Eligible actors may:

- ignore it;
- protect it;
- report it;
- loot it;
- recover items for household/faction;
- steal from it;
- consume biological remains where species behavior allows.

A theft from a player/Bot/NPC corpse is an explicit custody/crime event, not a silent item teleport.

### Forensic / Trail State

The game may create bounded evidence around recent corpse theft or other crimes:

- theft event records;
- item provenance/legal status;
- local scent/blood/footprint/trail representation where supported;
- last-known witness/holder information;
- temporary world-space trace with a defined lifetime.

Evidence is not omniscient global tracking. Tracking tools, creatures or skills may consume the available evidence to infer a direction/target.

## Player/Bot Respawn

Human Players and player-like Bots can use a respawn/checkpoint system rather than permanent death by default.

First-scope direction:

- eligible known beds/checkpoints/settlements are candidates;
- discovered villages/cities/capitals can act as recovery locations under their rules;
- a capital/faction-safe recovery point can be a fallback;
- corpse/world possessions remain governed by the death/loot policy rather than teleporting automatically with the respawned actor.

Exact PvP/full-loot and distance-priority rules remain a separate balance/design decision.

Resident NPC permanent-death/replacement rules are separate from Player/Bot respawn.

## Relationships, Memory and Personality

Relationships use the existing multi-dimensional model in `POPULATION_RELATIONSHIPS.md`.

An actor may remember causal anchors such as:

- attempted murder;
- rescue;
- betrayal;
- shared battle;
- repeated work/travel;
- theft;
- gift;
- promise kept/broken;
- family harm/help;
- guild history.

Memory does not require storing every event forever. Important events create compressed anchors/tags with cause, target, intensity, decay/persistence policy and references to durable world facts when needed.

Personality/traits influence priorities, risk tolerance and interpretation; they must not directly force arbitrary actions that ignore available knowledge.

## Gifts and Preference Generation

NPC/Bot preferences are generated once as persistent identity data, not re-rolled on each gift.

Candidate preference weights may derive from:

- personality/temperament;
- profession/class;
- race/culture;
- personal history;
- item category/visual/theme/value;
- bounded random seed for individuality.

A generated favorite remains stable unless an explicit life event changes it.

Players can discover preferences through conversation, observation, trade, previous gifts and relationships rather than receiving complete hidden data automatically.

Gift value is one relationship signal. Shared action/history normally matters more than repetitive gift grinding.

## Bank and Settlement Finance

Bank deposits represent real assets and depositor claims.

A settlement institution may spend or borrow against reserves only through explicit policy/state. If leadership consumes deposited reserves, the bank does not magically remain solvent: depositor claims remain liabilities and the institution can enter shortage/default/debt/crisis states.

This can create trust loss, protest, political conflict, emergency measures or later repayment/recovery.

## Unique Items and Autonomous Actors

Bots may legitimately complete quests and acquire unique world artifacts.

A unique item can then be equipped, stored, sold, stolen, lost, looted or tracked through its canonical provenance. It does not respawn for a later human Player merely because the Bot acquired it first.

However, unique-item fun should be protected through systemic breadcrumbs as defined in `ITEM_PERSISTENCE_AND_PROVENANCE.md`.

### Dormant Unique Item Pressure

A unique artifact stored indefinitely in an unattended/insecure container may create world interest/rumor/theft opportunities. This must resolve through plausible actors, access and world events — never by silently teleporting the item to a new owner.

## First Representative AI Scenario

The first Player-complete NPC/Bot proof should contain a small connected settlement loop:

1. one farmer produces/stores/sells food;
2. one merchant buys/sells finite stock;
3. one hunter responds to household or settlement food need;
4. one guard/patrol reacts to a local threat;
5. one player-like Bot evaluates and accepts a funded guild contract;
6. all use persistent inventory/money/property rather than regenerated archetype loot;
7. at least one relationship/memory event changes later behavior;
8. at least one actor transitions between active and reduced simulation without losing important state;
9. save/restart preserves identity, inventory, relationship anchors and contract/item custody.

## Explicit Deferrals

Not required for the first proof:

- LLM dialogue;
- thousands of unique personalities;
- unrestricted procedural long-horizon planning;
- final romance dialogue content;
- every profession;
- final crime/legal system;
- final respawn/full-loot balance;
- city-scale population at full fidelity.

## Acceptance Principle

The AI system is not Player Complete because an NPC can wander, chase or execute a finite-state routine.

The representative proof must show that actors make materially different contextual choices from persistent needs/goals/knowledge, act through shared game systems and preserve the consequences of those actions.