# Economy, Inventory and Autonomous Agents

- **Version:** 0.1.0
- **Status:** Design hypothesis
- **Updated:** 2026-10-13

## Core Principle

The economy should represent real flows of goods, money, labor and risk. NPCs do not have infinite stock or infinite purchasing power merely because they are shopkeepers.

## Economic Actors

Examples:

- households;
- hunters;
- farmers;
- miners;
- bakers;
- blacksmiths;
- merchants;
- guilds;
- settlements;
- caravans;
- military organizations;
- autonomous adventurers;
- players.

Each actor may own money, inventory, property, obligations and production capacity.

## Finite Stock

A merchant sells what exists in stock or what the merchant can acquire.

Example chain:

`hunter -> raw meat -> merchant/butcher -> household`

If hunting fails:

- meat stock falls;
- price can rise;
- households seek substitutes;
- hunters may accept higher-risk expeditions;
- settlements may import food;
- quests/contracts may appear.

The shop UI may be convenient, but it represents underlying inventory/state.

## Production Chains

Production should be composable.

Example:

`farm -> grain -> mill/flour -> baker -> bread -> household/tavern`

Another:

`mine -> ore -> smelter -> metal -> blacksmith -> equipment -> soldier/adventurer`

Disrupting one stage affects downstream availability and prices.

## Money Is State

Actors have finite monetary balances unless they represent an explicit systemic institution with defined funding rules.

Money enters/leaves the simulation through controlled sources/sinks such as:

- minting/treasury;
- wages;
- taxes;
- trade;
- loot already represented by world resources;
- service fees;
- repair/crafting fees;
- fines;
- guild fees;
- destruction/loss;
- scripted world-scale grants where justified.

Avoid unexplained infinite merchant wallets.

## Inventory Model

Players and relevant NPCs share the same inventory concepts.

Potential constraints:

- physical mass/weight;
- container capacity;
- optional slot/volume limits;
- item stack rules;
- equipped items;
- currency;
- ownership/permissions;
- container nesting rules.

The final UI representation can differ from simulation representation.

## Weight

Weight affects gameplay without requiring level-up attribute-point allocation.

Possible consequences of high carried mass:

- reduced movement speed;
- higher stamina/energy cost;
- weaker dodge/jump performance;
- slower climbing;
- inability to pick up additional mass past a hard safety limit.

Exact penalties are balance decisions.

## Bags and Containers

Bags are equipment/content that modifies carrying capacity rather than permanent stat points.

Possible bag properties:

- maximum weight contribution;
- slot/volume capacity;
- weight reduction for contained items;
- allowed item categories;
- enchantments;
- durability;
- rarity.

### Magical Bags

A magical bag may offer:

- very large or scrollable logical capacity;
- partial weight reduction;
- category-specific compression;
- special protections.

It should not automatically imply infinite effective carrying power.

Restrictions may prevent exploits such as infinitely nesting weight-reducing bags.

## NPC Inventory

Relevant NPCs may possess:

- equipped gear;
- carried items;
- food;
- tools;
- profession materials;
- money;
- quest/property items.

At high fidelity, this can be individual inventory.

At low fidelity, cohorts/organizations may use aggregated stocks while named important actors preserve personal state.

## Household Economy

A household can pool or coordinate:

- food;
- housing;
- money;
- tools;
- dependents;
- work income;
- emergency savings.

A hunter does not hunt only because a quest exists; hunting may be part of the household's livelihood.

## Prices

Price can depend on:

- local stock;
- expected demand;
- transport cost;
- danger;
- taxes;
- faction/currency exchange;
- merchant margin;
- reputation;
- scarcity;
- quality.

Price systems should be bounded/stabilized to avoid numeric explosions from temporary scarcity.

## Contracts and Quests as Economic Requests

A quest reward should usually come from an actor or institution capable of offering it.

A poor village may not offer a huge gold reward.

Instead it can offer combinations such as:

- limited money;
- food;
- lodging;
- local equipment;
- crafted goods;
- rare resources;
- access rights;
- land/property privileges;
- reputation;
- information;
- future favors;
- an item inherited/stored by the community.

This makes quest rewards reflect world state.

## Guilds as Marketplaces for Problems

A guild can receive contracts from:

- village leaders;
- merchants;
- military officers;
- households;
- cities;
- travelers;
- other guilds.

A requester may:

1. seek an adventurer directly;
2. travel/send a messenger to a guild;
3. submit a contract through local administration;
4. ask another institution to subsidize the reward.

Guilds can rank, advertise, assign and archive contracts.

## NPC vs Autonomous Adventurer vs Player

The runtime should distinguish behavior roles, not create completely unrelated entity types.

### Resident NPC

Primarily lives inside a social/economic role:

- farmer;
- merchant;
- guard;
- villager;
- blacksmith;
- official.

### Autonomous Adventurer Agent

A server-controlled agent that uses player-like gameplay systems:

- accepts quests;
- explores;
- equips gear;
- earns/spends money;
- improves skills/progression;
- joins battles;
- trades;
- travels between settlements;
- forms parties/guild relationships where supported.

These agents make the world active even when few human players are present.

They should be represented honestly as world-controlled characters/NPC adventurers rather than pretending to be real human users.

### Player

Uses the same world contracts but receives human input instead of an autonomous planner.

This shared architecture prevents separate fake economies/quests for bots.

## Agent Decision Inputs

An autonomous adventurer may evaluate:

- reward;
- travel distance;
- danger;
- faction alignment;
- equipment needs;
- current money;
- relationships;
- guild obligations;
- personality;
- skill suitability;
- party availability;
- urgency;
- personal goals.

Therefore not every available quest is automatically accepted.

## Example Systemic Chain

`village food low`

-> leader checks local resources

-> local hunters cannot solve shortage

-> village allocates limited treasury + rare item reward

-> contract reaches nearby guild

-> autonomous adventurers and players can evaluate it

-> one party accepts

-> caravan/hunt/escort outcome modifies actual food stock

-> reward is transferred from actual village/guild assets

This is one connected simulation rather than separate quest, economy and population illusions.

## Simulation Fidelity

At distance, the economy resolves through batches and scheduled transactions rather than physically walking every loaf of bread across a shop counter.

When a player is present, relevant transactions can materialize into physical inventories, NPC actions and transport events.

## Diagnostics

Track at minimum:

- money supply by faction/region;
- commodity stock by region;
- production/consumption;
- trade volume;
- shortages;
- price ranges;
- household food security;
- merchant insolvency/wealth concentration;
- active contracts;
- quest reward funding source;
- autonomous adventurer income/deaths/progression;
- inventory mass distributions.
