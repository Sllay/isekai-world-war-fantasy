# Item Persistence and Provenance

- **Version:** 0.1.0
- **Status:** Design hypothesis
- **Updated:** 2026-10-13

## Core Principle

Important items are part of the world state, not temporary quest props.

An item can change owner, be equipped, sold, stolen, dropped, hidden, looted, inherited, destroyed, repaired, transformed or recovered while preserving its identity and history when that history matters.

## Template vs Instance

Use two layers:

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

## Not Every Potato Needs a UUID Forever

World consistency does not require storing every fungible item as a permanent individual row.

Common identical goods can be represented as stacks/lots while they are interchangeable:

`40x common wheat, same quality/condition batch`

When individuality becomes relevant, a stack/lot can split into instances or smaller lots.

Examples that normally deserve stable identity:

- unique artifacts;
- rare rolled equipment;
- crafted named items;
- equipped gear of important actors;
- quest-linked objects;
- stolen/high-value items;
- synthesized bags;
- heirlooms;
- objects carrying meaningful history.

This keeps persistence scalable without making the economy fake.

## Ownership Chain

An important item should have exactly one canonical current state.

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

Possible classes:

### Unique World Artifact

One canonical instance in that world/server.

Changing owner changes the story.

### Limited Artifact

Small bounded number of instances can exist.

### Rare Generated Item

Can recur, but low probability/expensive source.

### Personal/Quest Instance

Instanced per eligible player/party when design requires reliable access.

### Renewable Content Item

Rare but intentionally re-enters the economy through production/events.

Using these classes prevents every interesting item from becoming permanently missable while preserving true uniqueness where it creates value.

## Death and Loot Persistence

When a persistent actor dies, relevant possessions are not silently deleted.

Possible containers:

- corpse;
- skeleton/remains;
- dropped backpack;
- loot cache;
- grave;
- killer inventory;
- scavenger inventory.

Low-value common loot may merge, decay or despawn through explicit world rules.

Important items should transition to a persistent state before visual remains are cleaned up.

Example:

`corpse visual expires -> persistent loot cache remains abstractly registered`

The visible object does not need to exist forever for the item to remain in the world.

## Scavenging and Actor Promotion

Ordinary creatures/NPCs can interact with valuable loot according to behavior.

Example:

1. a generic goblin scavenger finds a dead adventurer;
2. it takes a rare sword;
3. the rare ownership makes that goblin narratively/systemically relevant;
4. the goblin is promoted from disposable/aggregate actor to persistent actor with stable ID;
5. its future travel, death, trade and faction interactions preserve the sword's chain of custody.

Promotion can also happen because an actor:

- kills an important character;
- becomes leader;
- acquires a unique artifact;
- gains an unusual mutation/skill;
- forms a meaningful relationship with a player;
- becomes quest-relevant.

## Demotion

Persistence priority can fall when the reason for individual tracking disappears.

A formerly notable actor may eventually return to an aggregate population only if no important identity/history would be lost.

Unique-item holders cannot be demoted in a way that loses ownership state.

## Shops and Markets

Shops are part of the same item world.

If an autonomous adventurer sells a rare item to a merchant:

- merchant stock gains that exact instance;
- merchant pays from available funds/credit rules;
- price reflects rarity, knowledge, demand and risk;
- another NPC or player can potentially buy it;
- the item may move again through caravan/trade systems.

Rare items can therefore migrate through the economy instead of disappearing into bot inventories forever.

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

The information model decides what is known, delayed, uncertain or hidden.

## Theft and Stolen Goods

Ownership and possession are different concepts.

An item can track:

- legal owner;
- current holder;
- theft/crime record;
- faction jurisdiction;
- proof/witness state;
- bounty/recovery contract.

This supports stolen artifacts, fencing, confiscation and recovery quests.

## Destruction and Transformation

Unique does not necessarily mean indestructible.

If destruction is allowed, it must be explicit and historically meaningful.

Possible outcomes:

- destroyed permanently;
- broken into persistent fragments;
- transformed into another item;
- reforged;
- magical essence released;
- world event triggered.

Do not silently destroy unique items through cleanup, unload or ordinary despawn logic.

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

## Persistence Tiers

A practical implementation can assign persistence priority:

- **P0:** fungible/ephemeral, aggregate freely;
- **P1:** ordinary actor-owned item, persist while relevant;
- **P2:** modified/rare/equipped, stable instance identity;
- **P3:** quest/notable/history-bearing;
- **P4:** unique world artifact, never lose canonical custody state.

Names/numbers are provisional. The important concept is adaptive persistence cost.

## Diagnostics

Track at minimum:

- unique item current holder/location;
- lost/orphaned item references;
- duplicate unique IDs;
- items with no valid container/location;
- ownership transfer history for high tiers;
- persistent actors promoted because of notable items;
- rare item market circulation;
- item destruction/transformation events.

Invariant checks should reject or loudly report impossible states such as one unique instance existing in two inventories.

## Fun-First Rule

Simulation exists to create meaningful situations, not to punish players with invisible bookkeeping.

When persistence moves content away from its original location, the preferred response is often to **evolve the adventure around the new state** rather than reset the world or tell the player the content is gone.

The item moving is content.

## M1 Proof

M1 should prove one small custody chain:

1. create one unique item with stable ID;
2. NPC owns it;
3. NPC dies;
4. loot persists after visible corpse cleanup;
5. another autonomous actor loots it;
6. actor becomes individually persistent;
7. actor sells it to merchant;
8. server saves/restarts;
9. merchant still owns the same item instance;
10. a query/quest can resolve its current state without duplicating it.

This is a persistence/architecture proof, not the final market or quest system.
