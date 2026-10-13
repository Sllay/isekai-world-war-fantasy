# Item Persistence and Provenance

- **Version:** 0.2.0
- **Status:** Design hypothesis
- **Updated:** 2026-10-13

## Core Principle

Items are part of the world state, not temporary loot-table illusions.

Rarity determines how much individuality/history an item deserves, **not whether ownership is allowed to reset**.

An item can change owner, be equipped, stored, sold, stolen, dropped, hidden, looted, inherited, destroyed, repaired, transformed or recovered while preserving the custody/state required for world consistency.

## Persistence Correctness vs Persistence Detail

These are separate concerns.

### Persistence correctness

Answers:

- who currently possesses the item or lot;
- which container/property holds it;
- whether it was dropped, sold, stolen, consumed, destroyed or transferred;
- how much of a fungible good remains;
- whether the state survived save/restart/fidelity changes.

This must remain correct even for common items.

### Persistence detail

Answers how much individual metadata must be retained.

A legendary sword may need a permanent instance ID and provenance history.

A stack of ordinary wheat may only need:

- definition;
- quantity;
- quality/condition batch;
- owner/container;
- decay state.

The wheat can be compactly represented without becoming fake or resettable.

## Template vs Instance

Use two layers.

### Item Definition

Defines reusable content:

- base type;
- name/icon/visual references;
- base stats;
- material/category;
- default durability;
- stack rules;
- decay rules;
- rarity rules;
- allowed modifiers.

### Item Instance

Represents a particular physical/logical object when individuality matters:

- stable instance ID;
- definition ID;
- current owner/container/location;
- durability/condition;
- modifiers;
- enchantments;
- creator/crafter;
- synthesis history;
- provenance/history anchors;
- legal status (stolen/contraband/etc.);
- quest/artifact links;
- current persistence priority.

## Lots / Stacks for Fungible Goods

World consistency does not require every potato, wheat grain or identical arrow to have a permanent UUID.

Common interchangeable goods can be represented as lots/stacks.

Example:

`80x common wheat, quality B, stored in chest farm_chest_03`

This is still real world state.

If 30 wheat are sold:

- farm chest becomes 50;
- buyer/container receives 30;
- no invisible restock/reset occurs.

Lots can split/merge when compatible.

When individuality becomes relevant, a lot can split into individual instances or smaller lots.

## Inventory Is Canonical State

An actor inventory must not be regenerated from a character archetype whenever the actor unloads/reloads.

Bad model:

`farmer template -> always has 12 wheat + 3 coins`

Better model:

`farmer current inventory -> whatever the simulation says the farmer is carrying now`

Templates may define starting equipment, profession expectations or restocking behavior, but they do not overwrite canonical runtime inventory.

If the farmer sold the wheat, stored it in a chest, ate it, lost it, or had it stolen, the carried inventory reflects that.

## Carried Inventory vs Property Storage

Killing/looting a person does not automatically grant everything they economically own.

Separate concepts include:

- carried inventory;
- equipped gear;
- personal bag contents;
- home chest/storage;
- workshop stock;
- farm storage;
- guild/company property;
- bank/deposit storage;
- land/building ownership.

Example:

A farmer harvested 100 wheat.

1. carries 20 from field;
2. deposits 80 in barn chest;
3. sells 15 of the carried wheat;
4. returns home carrying 5 wheat and 32 coins.

If murdered at that moment, plausible loot is the current carried/equipped state, not a fabricated `farmer loot table` and not automatically the 80 wheat stored in the barn.

The murderer may later discover/steal the barn stock through separate gameplay.

## Death Loot Must Preserve Custody

When an actor dies, lootable possessions do not get rerolled from rarity tables or reset to archetype defaults.

The death transition consumes the actor's actual current carried/equipped inventory and moves eligible contents according to the game's death/loot rules.

Possible destinations:

- corpse;
- skeleton/remains;
- dropped backpack;
- loot cache;
- grave;
- killer inventory;
- scavenger inventory;
- protected/recovered inventory if specific gameplay rules require it.

The final PvP/full-loot policy is a separate design decision. Whatever the rule is, state transitions must be consistent.

## Common Items Still Matter

A common iron sword can become systemically important because of context even if its base rarity is low.

Examples:

- it was taken from a dead player;
- it belongs to a named NPC;
- it contains an enchantment/modification;
- it is evidence in a crime;
- it was inherited;
- it is currently part of a recovery quest;
- its ownership is relevant to a relationship or faction event.

Therefore persistence priority can be promoted by context, not only base rarity.

A common item must not disappear merely because it is inexpensive.

## Contextual Promotion

Items/lots may be promoted to more detailed persistence when something makes them relevant.

Promotion triggers can include:

- looted from a player;
- stolen/crime-linked;
- quest-linked;
- modified/enhanced;
- equipped by an important actor;
- transferred through a notable event;
- attached to a relationship/history event;
- used as evidence;
- acquired by a persistent notable actor.

This lets the simulation spend detail where history emerges.

## Ownership Chain

An individually tracked item should have exactly one canonical current state.

Example:

`ancient_blade_001`

1. stored in village shrine;
2. autonomous adventurer completes the local contract;
3. adventurer receives blade;
4. adventurer travels north;
5. adventurer dies to goblins;
6. corpse/loot cache contains blade;
7. goblin loots blade;
8. goblin is promoted to persistent notable actor;
9. goblin later sells blade to black-market merchant;
10. player hears rumor and tracks it.

The blade is not respawned at the shrine merely because a player arrived later.

## Quest Binding

Quests involving persistent unique items should bind to **item identity/state**, not only a fixed spawn location.

Bad model:

`Go to cave X and pick up sword.`

Better model:

`Recover artifact ancient_blade_001.`

The objective resolver can follow the item's current known/rumored state.

If the item moved, the quest can transform:

- search original site;
- investigate who took it;
- track adventurer;
- inspect corpse;
- hunt thieves;
- negotiate with merchant;
- buy it;
- steal it;
- win it in combat;
- recover it from a dungeon/cache.

This turns world persistence into content instead of making persistence punish the player.

## Unique Item Fairness

A truly unique world item may become unavailable from its original quest path. That is allowed, but the world should avoid silently deleting fun.

For important unique items, prefer systemic breadcrumbs:

- witnesses;
- guild records;
- merchant transaction records where appropriate;
- rumors;
- bounty/information brokers;
- faction intelligence;
- item-identification magic if setting permits;
- last-known-owner/location;
- theft/crime reports;
- historical provenance.

Information is not automatically omniscient. The player may need to discover the next lead.

## Item Availability Classes

Not all rare content should use the same scarcity rule.

### Unique World Artifact

One canonical instance in that world/server.

### Limited Artifact

Small bounded number of instances can exist.

### Rare Generated Item

Can recur, but low probability/expensive source.

### Personal/Quest Instance

Instanced per eligible player/party when design requires reliable access.

### Renewable Content Item

Rare but intentionally re-enters the economy through production/events.

Using these classes prevents every interesting item from becoming permanently missable while preserving true uniqueness where it creates value.

## Scavenging and Actor Promotion

Ordinary creatures/NPCs can interact with valuable or contextually important loot according to behavior.

Example:

1. generic goblin scavenger finds a dead adventurer/player;
2. it takes an iron sword and a rare artifact;
3. custody of those items moves to the goblin;
4. because the goblin now carries relevant player/notable property, it is promoted from disposable/aggregate actor to persistent actor;
5. its future travel, death, trade and faction interactions preserve custody.

Promotion can also happen because an actor:

- kills an important character;
- becomes leader;
- acquires a unique artifact;
- acquires player-owned recovery-relevant property;
- gains an unusual mutation/skill;
- forms a meaningful relationship with a player;
- becomes quest-relevant.

## Demotion

Persistence priority can fall when the reason for individual tracking disappears.

A formerly notable actor may eventually return to an aggregate population only if no important identity, custody or history would be lost.

An actor cannot be demoted in a way that loses tracked possessions.

## Shops and Markets

Shops are part of the same item world.

If an autonomous adventurer sells an item to a merchant:

- merchant stock gains that instance or lot;
- merchant pays from available funds/credit rules;
- another NPC or player can potentially buy it;
- the item/lot may move again through caravan/trade systems.

For individually tracked equipment, the exact instance transfers.

For fungible goods, quantity/lot custody transfers.

## Market Discovery

Players should have ways to investigate commerce without receiving perfect global knowledge.

Possible tools:

- local shop browsing;
- guild listings;
- auction/market boards where supported;
- trader rumors;
- merchant networks;
- black-market contacts;
- paid item-location requests;
- regional price/history records;
- faction intelligence.

## Theft and Stolen Goods

Ownership and possession are different concepts.

An item can track:

- legal owner;
- current holder;
- theft/crime record;
- faction jurisdiction;
- proof/witness state;
- bounty/recovery contract.

This supports stolen artifacts, ordinary stolen gear, fencing, confiscation and recovery quests.

## Destruction and Consumption

Items leave the world only through explicit rules.

Examples:

- consumed as food/crafting material;
- durability destruction where allowed;
- magical transformation;
- decay;
- deliberate destruction;
- synthesis donor consumption;
- world event.

Unload, despawn, LOD transition, server restart or NPC template reload are **not valid item-destruction causes**.

For fungible resources, consumption decreases quantity from the correct canonical lot/container.

## Decay

Perishable or unstable goods can decay while stored.

Decay may depend on:

- elapsed world time;
- container traits;
- temperature/environment if later modeled;
- item category;
- enchantments;
- preservation systems.

Distant/offline decay should be calculated analytically from timestamps or scheduled events, not by frame updates.

## Persistence / Representation Tiers

A practical implementation can vary representation cost:

- **R0:** fungible goods as quantities/lots;
- **R1:** ordinary individually relevant item with current custody;
- **R2:** modified/equipped/player-linked item with stable instance identity;
- **R3:** quest/notable/history-bearing item;
- **R4:** unique world artifact with permanent canonical custody/provenance.

These tiers govern **representation/history detail**, not whether state is allowed to reset.

Even R0 goods must preserve quantity and container ownership.

## Inventory Snapshot Invariant

For every persistent actor/container, the canonical state after unload/reload/save/restart must equal the state produced by legitimate world transactions, subject only to explicit decay/consumption/destruction rules.

Conceptually:

`inventory_after_reload == inventory_before_reload + valid_world_changes`

Never:

`inventory_after_reload == archetype_default_loot`

## Diagnostics and Invariants

Track/check at minimum:

- invalid inventory resets;
- duplicated unique IDs;
- orphaned item instances;
- negative lot quantities;
- items in two canonical containers;
- ownership transfers without source removal;
- player-linked items lost during actor demotion;
- container contents lost during LOD transitions;
- mismatch between actor carried inventory and death loot transition;
- rare/notable market circulation;
- item destruction/transformation events.

Invariant checks should fail loudly in development when custody becomes impossible.

## Fun-First Rule

Simulation exists to create meaningful situations, not to punish players with invisible bookkeeping.

When persistence moves content away from its original location, the preferred response is often to evolve the adventure around the new state rather than reset the world.

The item moving is content.

## M1 Proofs

M1 should prove both rare-item and ordinary-item custody.

### Proof A — Unique Artifact Chain

1. create one unique item with stable ID;
2. NPC owns it;
3. NPC dies;
4. loot persists after visible corpse cleanup;
5. another autonomous actor loots it;
6. actor becomes individually persistent;
7. actor sells it to merchant;
8. server saves/restarts;
9. merchant still owns the same item instance;
10. query/quest resolves its current state without duplication.

### Proof B — Ordinary Inventory Chain

1. farmer harvests a fungible wheat lot;
2. farmer carries part and stores part in a chest;
3. farmer sells part of carried stock;
4. current carried inventory differs from profession/template defaults;
5. farmer dies/unloads/reloads;
6. death loot contains only the legitimate carried/equipped state allowed by rules;
7. stored wheat remains in the farm chest;
8. save/restart preserves both quantities;
9. no default wheat magically reappears.

### Proof C — Player Loot Custody

1. player/NPC owns ordinary equipment;
2. ownership legitimately transfers to another actor through death/loot rules;
3. receiver unloads/enters aggregate simulation;
4. save/restart occurs;
5. same transferred equipment remains with the receiver or its subsequent legitimate destination.

This is a persistence/architecture proof, not the final PvP loot-policy decision.
