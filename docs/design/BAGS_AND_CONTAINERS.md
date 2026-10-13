# Bags and Containers

- **Version:** 0.1.0
- **Status:** Design hypothesis
- **Updated:** 2026-10-13

## Core Principle

Bags are progression equipment, not passive UI decoration.

Their value comes from carrying capacity, category-specific behavior, preservation, weight manipulation, special rules and synthesis history.

The intended progression is **not** recursive physical nesting of bag inside bag inside bag. Bag-on-bag interaction primarily happens through synthesis, fusion or consumption.

## Bag State

A bag may define:

- stable item instance ID;
- archetype/type;
- rarity/tier;
- effective weight capacity;
- optional slot/volume capacity;
- category weight modifiers;
- preservation modifiers;
- durability/stability;
- allowed/restricted item categories;
- magical traits;
- inherited traits;
- synthesis history;
- owner/provenance.

## Bag Families

Bag behavior is data-driven. Names below are examples, not final content.

### Common Bag

Conventional carrying equipment.

Possible properties:

- finite slots/volume;
- finite weight support;
- no preservation magic;
- little or no weight reduction;
- can be used as synthesis material.

### Magical Bag

General magical storage focused on capacity and broad weight reduction.

Possible behavior:

- large/scrollable logical capacity;
- reduced effective weight for many item categories;
- food still degrades normally unless another trait changes this;
- can absorb compatible bags to strengthen selected properties.

### Arcane Bag

Specialized magical storage with unusual category rules.

Possible behavior:

- food degradation paused or strongly reduced;
- weapons/tools/items receive strong weight reduction;
- raw materials may remain heavy or even receive poor compression;
- rare arcane traits unavailable to ordinary bags.

The point is not that one family is strictly stronger. Different bags create different builds and logistics choices.

## Category Modifiers

Instead of one global `weight_reduction`, a bag may use per-category modifiers.

Example concept:

- food weight: 80%;
- weapons: 45%;
- armor: 55%;
- ore: 100%;
- wood: 90%;
- quest/artifact items: special rules.

Preservation can also be category-specific:

- food decay rate;
- potion stability;
- magical charge leakage;
- fragile-item protection;
- temperature/humidity effects if later supported.

## Synthesis / Fusion

Two compatible bags may be combined to create one improved bag.

The resulting bag does not necessarily inherit 100% of both parents.

A synthesis algorithm can consider:

- base bag chosen as the host;
- donor bag consumed;
- trait compatibility;
- rarity difference;
- material quality;
- crafter/enchanter skill;
- synthesis catalyst;
- random variance only within controlled bounds;
- diminishing returns;
- maximum trait budgets/caps.

Example:

`Magical Bag A + Common Reinforced Bag B -> Magical Bag A+`

Possible result:

- +12% capacity;
- +4% material weight efficiency;
- donor bag destroyed;
- one inherited reinforcement trait.

## Consumption Upgrade

Some magical/arcane bags can consume another bag as progression material without producing a traditional crafted replacement.

Example flow:

1. Host bag selects donor.
2. Donor traits are evaluated.
3. One or more compatible properties transfer partially.
4. Donor is permanently consumed.
5. Host receives synthesis XP, trait progress or direct bounded upgrades.

This lets a favorite rare bag remain relevant instead of being discarded every time a numerically larger bag appears.

## Trait Inheritance

Possible inherited traits include:

- additional capacity;
- category weight reduction;
- food preservation;
- fragile protection;
- reduced potion degradation;
- magical insulation;
- restricted specialty pockets;
- theft protection;
- faster item access if gameplay later supports it.

Inheritance needs caps and incompatibility rules so repeated consumption cannot create an unbounded all-perfect bag.

## Tradeoffs

High-tier bags should still create meaningful choices.

Examples:

- excellent food preservation but poor ore compression;
- extreme weapon compression but limited raw-resource capacity;
- huge capacity but expensive repair;
- powerful arcane preservation but vulnerable to anti-magic zones;
- very low effective weight but few specialty slots.

## No Recursive Compression Exploit

If bags can ever physically contain other containers, weight reduction does not recursively multiply without restriction.

Possible rule:

- nested container contents use the outermost applicable compression once; or
- inner bag magical compression becomes inactive while stored; or
- nested magical storage is prohibited by lore/stability rules.

The final rule should preserve usability while preventing exponential weight reduction.

## NPC and Economy Integration

NPCs can own, equip, trade, craft, inherit, steal and lose bags.

A merchant selling bags possesses actual bag instances/stock where fidelity requires it.

Rare synthesized bags may have provenance and become valuable economic objects in their own right.

## Persistence

Rare, modified or synthesized bags should normally persist as item instances with stable IDs because their history matters.

Cheap identical bags may be represented more compactly while they remain fungible stock.

## M1 Question

M1 does not need final bag crafting. It should verify that the item model can persist:

- a bag instance;
- category-specific modifiers;
- one donor consumption;
- one inherited trait;
- save/load without losing synthesis history.
