# Item Condition, Stacks and Decay

- **Version:** 0.1.0
- **Status:** Design hypothesis
- **Updated:** 2026-10-13

## Core Principle

Stackable items may share one visual inventory slot while preserving different internal condition/decay states.

A newly crafted potion must not inherit the decay state of older potions merely because it joined the same visual stack.

The system should preserve consistency without forcing every consumable into a separate visible slot or updating every unit every frame.

## Item Condition Families

Different item families use different condition models.

### Stable Stackable Goods

Examples:

- arrows;
- basic crafting materials;
- coins;
- non-perishable reagents.

They can normally stack by definition/quality without decay layers.

### Perishable Stackable Goods

Examples:

- food;
- meat;
- cooked food;
- potions with stability loss;
- unstable alchemical reagents.

They use internal decay/condition layers inside the visual stack.

### Individual Durable Items

Examples:

- weapons;
- tools;
- armor;
- accessories;
- synthesized bags;
- unique or modified equipment.

Maximum stack is normally 1 because each instance can carry its own durability, modifiers, enchantments, provenance and condition.

### Charged / Special Items

Some items may use charges, fuel, magical stability or another condition model rather than physical durability or decomposition.

The item definition chooses the model.

## Visual Stack vs Internal Layers

A visual inventory slot contains one item definition and a total quantity.

Internally, stackable perishables are divided into condition layers/cohorts.

Example:

```text
Slot: Healing Potion
Quantity: 4 / 10

Internal layers:
- 3x batch A — 52% freshness/effect condition
- 1x batch B — 100% freshness/effect condition
```

The player still sees one stack of four potions unless they inspect the slot in detail.

The newly crafted potion remains fresh even though it shares the visual stack with older potions.

## Cohort / Layer State

A decay layer can store compact state such as:

- quantity;
- base quality;
- accumulated decay progress;
- last evaluated world timestamp;
- creation/batch timestamp where useful;
- optional origin/crafting batch metadata;
- container/environment context needed for decay calculation.

A layer represents several interchangeable units with effectively equivalent condition.

## Lazy Decay Calculation

Perishable items should not tick every frame.

Instead, condition is evaluated when relevant, for example when:

- inventory UI requests it;
- item is consumed;
- stack is transferred;
- container changes;
- item is sold;
- save snapshot is written;
- decay crosses a transformation threshold through a scheduled event;
- simulation batch processes that container/region.

Conceptually:

```text
current_decay = previous_decay + elapsed_time * effective_decay_rate
```

The effective rate can depend on container traits, item type, environment and magic.

This allows thousands of stored consumables to age without per-frame work.

## Container Transfer

When an item moves between containers with different preservation rules:

1. evaluate decay under the old container up to transfer time;
2. persist the new decay progress;
3. move the layer/quantity;
4. begin future decay using the destination container modifiers.

This is required for magical/arcane bags, refrigerators/cellars, alchemy containers and similar systems.

## Stack Merge Rules

Two stackable items can share the same visual slot if their item definition and other compatibility rules allow it.

Their internal layers do **not** have to merge into one condition value.

Layers may merge only when their states are close enough to be treated as equivalent according to a configurable tolerance/bucket rule.

Example:

```text
2 potions at 91.2%
3 potions at 91.7%
```

May become:

```text
5 potions in the ~92% layer
```

But:

```text
3 potions at 50%
1 potion at 100%
```

remain separate internal layers.

## Bounded Layer Complexity

A player could otherwise create one potion every minute and produce hundreds of tiny layers.

To keep storage efficient, the system may use condition buckets/tolerances.

Example provisional buckets:

- 100–96%;
- 95–86%;
- 85–71%;
- 70–51%;
- 50–31%;
- 30–11%;
- 10–1%;
- transformed/spoiled.

Exact bucket widths are balance/technical data, not final design.

The goal is to preserve meaningful differences while compressing negligible ones.

## Maximum Stack

The stack maximum is defined by item data.

Example:

```text
Healing Potion: max_stack = 10
Cooked Meat: max_stack = 20
Arrow: max_stack = 50
Iron Sword: max_stack = 1
```

The maximum applies to total quantity in the visual slot, regardless of number of internal layers.

If total quantity exceeds the limit, additional visual stacks are created.

## Condition Terminology

For player-facing UX, prefer a positive condition value such as **Freshness**, **Potency**, **Stability** or **Condition** where appropriate.

Example:

- 100% Potency = fresh/full effect;
- 50% Potency = degraded;
- 0% Potency = transformed/spoiled/expired according to item rules.

Internally the system may store decay progress instead.

This avoids confusing statements such as “10% decomposition” meaning either 10% lost or 10% remaining.

## Effectiveness Curve

Effect strength does not have to be a direct linear copy of condition.

A data-driven curve can map condition to positive and negative effects.

Example concept for a healing potion:

```text
100% condition -> 100% healing, 0% adverse modifier
75% condition  -> 95% healing, 0% adverse modifier
50% condition  -> 80% healing, small instability risk/effect
25% condition  -> 55% healing, stronger negative modifier
5% condition   -> 20% healing or near-spoiled behavior
0% condition   -> transforms into spoiled/tainted potion
```

The exact curve must be tuned for fun. Early degradation should normally not punish the player excessively.

Negative effects can use a separate curve so they rise gently rather than exploding immediately.

## Transformation on Full Decay

An item may transform when a condition threshold is crossed.

Examples:

```text
Healing Potion -> Tainted Potion / Poisonous Brew
Raw Meat -> Rotten Meat
Cooked Meat -> Rotten Meat
Fresh Herb -> Withered Herb
Magical Reagent -> Inert Residue
```

Transformation is data-driven.

The resulting item can still have gameplay value.

Examples:

- rotten meat as taming bait;
- rotten meat as alchemy ingredient;
- spoiled potion as poison reagent;
- inert residue as crafting material.

Decay therefore changes resource value instead of always deleting the item.

## Consumption Priority

A visual stack can contain multiple internal layers, so the system needs a deterministic consumption order.

Recommended default behavior:

### Emergency / Direct Use

Consume the **highest-condition** compatible unit first.

Examples:

- healing potion from hotbar;
- antidote;
- combat food where immediate effect matters.

This matches player expectation that pressing the consumable button gives the best available result.

### Crafting / Bulk Consumption

Prefer the **lowest-condition acceptable** batch first when recipe rules allow it.

This reduces waste and feels natural for kitchens, crafting and NPC economy.

### Manual Inspection

An expanded stack view can allow selecting a specific layer when the player intentionally wants to use an older or degraded batch.

The default UI should stay simple; advanced layer control is optional/inspect-level interaction.

Consumption policy can be data-driven per item/category and overridden by an explicit player action where useful.

## Sorting Inside a Stack

Internally layers should be kept ordered by the configured priority or condition.

The UI does not need to display each layer as a separate inventory slot.

An inspected tooltip can show concise information such as:

```text
Healing Potion x4
Best: 100%
Worst: 52%

Breakdown:
1x 100%
3x ~52%
```

For normal gameplay, the slot can show one condition indicator representing the next item that will be consumed or a small range indicator.

## Weight

Weight is calculated from quantity and item/container modifiers.

For a stack:

```text
total_raw_weight = quantity * unit_weight
```

The containing bag/container then applies category-specific compression/weight rules.

Decay layers do not require separate weight calculation unless transformation changes item mass.

## NPC Integration

NPCs use the same stack/layer model.

A merchant can own:

```text
Healing Potion x8
- 5x ~90%
- 3x ~55%
```

Prices can reflect condition.

NPC consumption/crafting policies can prefer old or good stock according to role and behavior.

This allows believable markets without requiring each potion to be a fully independent persistent object.

## Economy Integration

Condition can affect:

- sale price;
- merchant willingness to buy;
- quest acceptance rules;
- recipe output quality;
- rationing decisions;
- household food safety;
- alchemy value;
- taming preference.

A village with large food stock may still face a crisis if most stock is near spoilage.

## Bags and Preservation

Container traits modify decay without changing stack identity.

Examples:

### Magical Bag

- broad weight reduction;
- normal food decay unless upgraded.

### Arcane Bag

- strong or complete food preservation;
- excellent protection for potions/reagents;
- different weight tradeoffs for raw materials.

When a stack enters or leaves such a bag, elapsed condition is settled before the new preservation rule applies.

## Persistence

Stack layers are part of canonical inventory state.

Save/load, LOD transition or server restart must preserve:

- total quantity;
- layer quantities;
- condition/decay state;
- container ownership;
- transformation schedule/state.

Reloading must never collapse a mixed-condition stack into one arbitrary condition value.

## Diagnostics / Invariants

Development checks should detect:

- layer quantities not summing to visual stack quantity;
- negative layer quantity;
- condition outside allowed range;
- merge that changes total quantity;
- fresh items inheriting old condition during stack merge;
- old items being magically refreshed by new items;
- decay reset during save/load;
- transformation losing quantity;
- container preservation applied retroactively to time spent outside the container.

## M1 Proof

M1 should prove one compact decay-stack scenario:

1. create 3 healing potions in one batch;
2. advance time until they reach degraded condition;
3. craft one fresh potion;
4. add it to the same visual stack;
5. verify the old and fresh condition layers remain distinct;
6. consume according to direct-use policy;
7. move the remaining stack into a preservation bag;
8. advance simulated time;
9. move it back out;
10. save/restart/load;
11. verify quantity, layer condition and decay history remain consistent;
12. fully decay one layer and verify data-driven transformation into the configured spoiled item.

## Design Principle

> Stack visually; preserve condition internally; calculate decay only when it matters.
