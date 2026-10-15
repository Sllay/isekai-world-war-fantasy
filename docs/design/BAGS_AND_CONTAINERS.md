# Bags and Containers

- **Version:** 0.2.0
- **Status:** Design hypothesis
- **Updated:** 2026-10-15

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
- capacity mode (`FIXED_SLOTS` or `DYNAMIC_SLOTS`);
- optional finite slot count;
- category weight modifiers;
- preservation modifiers;
- durability/stability;
- allowed/restricted item categories;
- magical traits;
- inherited traits;
- synthesis history;
- owner/provenance.

Slot capacity and weight capacity are independent constraints.

A bag can have available slots and still be unable to accept an item because of mass. Likewise, a light inventory can still be full because a fixed-slot bag has no valid slot remaining.

## Capacity Modes

### Fixed Slots

A conventional container declares a finite logical slot count.

- Empty slots exist as capacity.
- Compatible stacks are filled first.
- New stacks can occupy only available slots.
- When no valid slot remains, additional items cannot be inserted even if weight capacity remains.
- Weight limits/rules apply independently.

### Dynamic Slots

Some magical or special bags can have effectively unbounded **logical slot allocation** without having unlimited carrying capacity.

- Empty slots do not need to be pre-created.
- A logical slot/stack appears only when an item instance or stack requires one.
- Compatible stacks are still filled before creating another stack.
- New logical stacks may be allocated only while category and weight rules permit them.
- Runtime/UI implementations must not preallocate an infinite grid.

Technical contracts should use `DYNAMIC_SLOTS`, not "infinite slots", to avoid implying infinite memory or infinite carrying power.

## Stack Allocation

When adding a stackable item:

1. Fill compatible existing stacks first, respecting stack size and item condition/lot rules.
2. If quantity remains, allocate a new logical stack/slot.
3. A fixed-slot bag rejects or partially accepts when no valid slot remains.
4. A dynamic-slot bag may allocate another stack if weight/category constraints allow it.

Item condition and decay rules remain authoritative. Fresh items must not silently inherit the degradation state of an older incompatible lot merely to save a slot.

## Canonical Weight

Every physical item definition should expose one base mass in a canonical unit.

Recommended representation:

- canonical storage/calculation: **integer grams**;
- presentation: grams or kilograms depending on magnitude.

The canonical item mass never changes merely because a bag compresses weight. Containers instead calculate **effective carried mass** from item mass, quantity and category modifiers.

Examples are balancing data rather than fixed targets. A meat portion may weigh hundreds of grams, while ore, stone, armor and tools may be substantially heavier.

A few ore stacks can therefore overload a bag even while occupying very few logical slots.

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

- large or dynamic logical capacity;
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

These percentages modify effective carried mass, not the item's canonical base mass.

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

## Inventory Presentation

The final mobile inventory is a vertically scrollable grid and should materialize only the logical slots required by the underlying container mode.

A dynamic-slot bag must not render thousands of empty cells. A fixed-slot bag may show its finite empty capacity.

The inventory UI is presentation over real container state; it never owns item quantity, weight, stack identity or provenance.

Detailed mobile interaction rules are defined in `MOBILE_COMBAT_UI_AND_INVENTORY.md`.

## NPC and Economy Integration

NPCs can own, equip, trade, craft, inherit, steal and lose bags.

A merchant selling bags possesses actual bag instances/stock where fidelity requires it.

Rare synthesized bags may have provenance and become valuable economic objects in their own right.

## Persistence

Rare, modified or synthesized bags should normally persist as item instances with stable IDs because their history matters.

Cheap identical bags may be represented more compactly while they remain fungible stock.

Persistent bag state should preserve capacity mode, finite slot limit where applicable, weight/category traits and synthesis history. Empty UI cells are not canonical persistent objects unless later inventory architecture requires explicit compartment identity.

## Implementation Timing

Bag/container simulation and final inventory UI should be built in the Survival/Economy production phase, not pulled forward merely because combat already has a mobile HUD.

Earlier systems may reserve semantic hooks/bindings, but must not create a second temporary inventory model.
