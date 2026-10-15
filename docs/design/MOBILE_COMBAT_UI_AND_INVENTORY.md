# Mobile Combat UI and Inventory UX

- **Version:** 0.1.0
- **Status:** Approved design direction; implementation deferred until required by its production slice
- **Updated:** 2026-10-15

## Purpose

Define the intended mobile-first interaction model for combat, quick access, hotbar and inventory without forcing premature implementation.

This document is a product/design contract, not a request to build all UI now. Systems should consume these rules when their production slice reaches the relevant interaction. Until then, existing minimal development controls may remain.

The central rule is:

> **Select is not execute.**

A skill slot chooses/arms an action. Execution is performed through the contextual combat control appropriate to that action's targeting model.

This avoids turning the mobile interface into a dense desktop MMO hotbar while preserving deep build expression and manual combat skill.

## 1. Mobile layout zones

The gameplay HUD is divided into functional zones rather than a single permanent hotbar.

### Left movement zone

The left side contains a **dynamic joystick activation area**.

- The movement joystick is not permanently anchored to one exact point.
- Touching inside the allowed movement zone spawns/centers the joystick at the initial touch position, clamped to safe bounds.
- Continuing to drag controls movement.
- Releasing removes or recenters the visual joystick according to final UX tuning.
- The activation area must not overlap buttons that need deterministic taps.
- The visual joystick should be smaller and less visually dominant than the early prototype.

This preserves thumb comfort across different hand sizes and device aspect ratios.

### Right combat zone

The right side contains the contextual combat cluster:

- jump control;
- one quick-consumable slot;
- three visible skill slots;
- skill-page rotation control;
- contextual attack/execution control;
- future target/lock assistance when that system is implemented.

The cluster must remain readable without covering the center of the world view.

### Bottom utility hotbar

A separate bottom hotbar, initially targeting **8 quick slots**, is for general item/equipment access rather than the primary skill system.

Eligible content can include:

- weapons;
- tools;
- food/consumables;
- building pieces or construction modes;
- utility items.

Resources do not need to occupy the hotbar simply because they exist in inventory.

## 2. Skill pages and build expression

Only **three active-skill slots are visible at one time** on mobile.

A page/rotation button cycles through configured groups of three:

- slots 1-3;
- slots 4-6;
- slots 7-9 if supported by the character/build;
- future larger sets may continue the same pattern.

The exact maximum number of equipped active skills is a balance/progression decision and must not be hard-coded into presentation logic.

The page system is part of build expression. Players may intentionally order skills by tactical role, for example:

- opener/control/risk skills on page 1;
- sustained DPS on page 2;
- survival/mobility/utility on page 3.

The UI must clearly communicate:

- which page is active;
- which skill is currently selected/armed;
- cooldown/unavailable state;
- resource insufficiency where relevant.

Changing page does not automatically cast anything.

## 3. Selection versus execution

Tapping a skill slot **selects** that action. It does not immediately execute it unless a future action explicitly declares a justified instant-cast interaction mode.

The selected action drives the contextual execution control.

At minimum, the architecture must support these interaction families:

### Instant/contextual button

Used when precise directional input is unnecessary.

Examples:

- self-heal;
- buff;
- target-locked action;
- basic melee action against a valid current target;
- action centered on the player's current target.

The execution control behaves as a button.

### Directional execution

Used when the player chooses direction but not an exact world point.

Examples:

- forward slash;
- dash;
- cone attack;
- directional knockback;
- line attack.

The execution control may behave as a short aim stick: drag to choose direction, release/confirm to execute according to the action contract.

### Precision/free aim

Used for actions whose gameplay value includes manual precision.

Examples:

- bow shot;
- aimed projectile spell;
- precision ranged attack;
- skill shot that should not become automatic merely because a target is locked.

Camera/look input and/or an aim stick supplies direction. Lock-on may assist acquisition or orientation but must not erase the precision requirement for actions that declare manual precision.

### Ground/area targeting

Used when the player chooses a point/area in the world.

Examples:

- thrown area effect;
- grenade-like arc;
- ground spell;
- placed trap/effect.

The game should show a telegraph/preview of the valid impact area. Actions may define:

- minimum range;
- maximum range;
- fixed range;
- variable range controlled by the player;
- valid/invalid surface rules.

The preview is presentation; the action/targeting system owns canonical validity.

## 4. Targeting and aim assistance

The game may support a target-lock / sticky-target system to improve mobile usability, especially for ranged and magic builds.

However, target lock is an **assist layer**, not universal auto-aim.

Targeting modes should remain explicit in action data/contracts, including future support for:

- self;
- current/locked entity;
- explicit entity target;
- forward/directional;
- free aim;
- world point;
- area/shape;
- last attacked target;
- assisted aim.

Rules:

- Some actions may fully use the locked target.
- Some may use it only as aim assistance.
- Precision actions may ignore hard lock for final trajectory.
- Area actions may target near or far within their authored limits.
- Presentation must never invent a valid target that simulation rejects.

## 5. Basic attack control

The right-side combat control is not permanently a single fixed-purpose button.

Its behavior is contextual and may represent:

- basic attack;
- selected ability execution;
- directional aim;
- free-aim confirmation;
- ground-target confirmation.

The exact visual should communicate the current interaction mode so the player knows whether a tap, hold, drag or release is expected.

Basic attacks themselves may use different targeting families depending on weapon/action definition:

- attack in actor facing direction;
- attack current/locked target;
- camera-relative direction;
- manual precision aim.

Do not hard-code weapon type checks into the UI. The equipped/basic-action definition should expose the required execution mode.

## 6. Quick consumable slot

One dedicated quick-consumable slot sits near the combat cluster.

It may hold compatible consumables such as:

- healing potion;
- mana/resource potion;
- food;
- other quick-use consumables.

The slot should expose:

- icon/content identity;
- stack/count where relevant;
- cooldown/unavailable overlay if relevant;
- empty state.

The slot is a convenience binding into the real inventory/item system. It must not own or duplicate item quantity.

## 7. Bottom utility hotbar

The bottom hotbar is distinct from active skills.

Initial design target: **8 slots**.

Bindings may reference inventory/equipment actions such as:

- equip/select weapon;
- select tool;
- use food/consumable;
- select building piece/mode;
- select utility item.

A hotbar entry is a binding/reference, not a duplicated item instance.

Removing or moving the underlying item must update the binding consistently.

## 8. Inventory / bag overlay behavior

The inventory opens as a central popup/overlay rather than replacing the entire world scene.

While inventory is open:

**Allowed:**

- movement;
- jump;
- inventory management;
- closing the inventory.

**Blocked/hidden:**

- combat execution;
- active-skill selection/execution;
- combat aim;
- combat quick-consumable use unless later design explicitly allows it.

The movement zone remains usable. The jump control remains available. Right-side combat controls become hidden or disabled so state is visually unambiguous.

This behavior should be implemented through input/context gating, not by teaching every ability to check whether a UI panel exists.

## 9. Inventory grid and scrolling

Mobile inventory uses a vertically scrollable grid.

- Prefer approximately **5 columns** on typical phones for touch readability.
- Up to **6 columns** may be used where device scale/slot size remains comfortable.
- Vertical rows expand according to available/logical slots.
- Horizontal scrolling is not the primary inventory navigation model.

Exact responsive sizing belongs to UI implementation and must account for safe areas/aspect ratio.

## 10. Container capacity modes

Bags/containers support at least two conceptual capacity modes.

### Fixed-slot container

- Declares a finite logical slot count.
- Empty slots exist as available capacity.
- New stacks cannot create slots beyond the limit.
- Weight limits/rules still apply independently.

### Dynamic-slot container

- Does not impose a fixed visible/logical slot ceiling for ordinary stacks.
- A UI entry/slot is materialized only when an item stack/instance requires it.
- Capacity is still bounded by weight and any category/container rules.
- "Dynamic" does not mean infinite simulation memory or unlimited carrying power.

This replaces the ambiguous term "infinite slots" in technical contracts.

## 11. Stack allocation behavior

When adding a stackable item:

1. Fill compatible existing stacks first, respecting stack limits and condition/lot rules.
2. If quantity remains, allocate another logical slot/stack.
3. Fixed-slot bags reject/partially accept when no valid slot remains.
4. Dynamic-slot bags may allocate another logical stack if weight/category rules permit.

Existing item-condition/decay rules remain authoritative; visually similar items must not be merged when their canonical stack/condition rules prohibit it.

## 12. Weight model

Every physical item definition should expose a base mass/weight in one canonical unit.

Recommended simulation representation:

- integer grams as canonical stored mass;
- UI may display grams/kilograms contextually.

Examples are balance data, not fixed targets:

- food portion: hundreds of grams;
- ore/stone: potentially much heavier;
- tools/weapons: item-specific mass.

Total raw mass is derived from quantity and item instances/stacks. The container then applies its effective-weight rules.

A bag can therefore be nearly empty in slot count but already overloaded because a few stacks contain very heavy material.

Weight and slot capacity are independent constraints.

## 13. Category-specific weight behavior

Bags may modify **effective carried weight** by item category rather than changing an item's canonical base mass.

Examples:

- food efficiency;
- ore/mineral efficiency;
- wood/material efficiency;
- weapon/tool efficiency;
- armor efficiency.

The item still knows its base mass. The bag/container computes effective carried mass through bounded category modifiers.

This enables specialized logistics builds without rewriting item definitions.

Nested containers must obey the anti-recursive-compression rules in `BAGS_AND_CONTAINERS.md`.

## 14. UI state architecture

Presentation should consume semantic/canonical state rather than become gameplay authority.

Recommended separation:

`Raw touch / key / controller`

-> `Input context + semantic intent`

-> `Selected binding/action/targeting mode`

-> `Gameplay system (Action, Inventory, Equipment, Building...)`

-> `Canonical result/state`

-> `HUD presentation`

The UI may request actions, select bindings and show previews. It must not directly mutate health, item quantities, cooldowns, combat state or authoritative inventory ownership.

## 15. Input contexts

At minimum future UI should support explicit input contexts such as:

- `GAMEPLAY_FREE`;
- `GAMEPLAY_ACTION_AIM`;
- `INVENTORY_OPEN`;
- `BUILD_MODE`;
- future dialogue/menu contexts.

Context controls which semantic intents are produced/accepted.

This is preferable to scattered checks like `if inventory.visible` across combat, movement and item code.

## 16. Desktop adaptation

Desktop may expose more conventional MMO-style slots because pointer/keyboard space is less constrained.

However, desktop and mobile must map into the same semantic systems:

- same equipped actions;
- same action IDs;
- same selection/execution contract;
- same cooldown/resource rules;
- same hotbar bindings/inventory ownership.

Desktop presentation may show more simultaneous skill bindings without changing simulation semantics.

## 17. Deferred implementation rule

Do **not** implement this entire document as one UI milestone.

Implement each part only when its owning gameplay system reaches production readiness:

- combat action/targeting work -> semantic skill selection/execution and contextual attack control;
- targeting/telegraph work -> aim/ground preview/lock assistance;
- inventory/equipment work -> bottom hotbar, quick-consumable binding and inventory overlay;
- bag/container work -> fixed/dynamic slots, stack allocation and weight display;
- building work -> construction bindings/mode in the utility hotbar;
- final HUD polish -> responsive layout, art, animation, safe-area and accessibility tuning.

Temporary development buttons may exist while a system is under construction, but they are not the final mobile UX.

## 18. Visual direction when implemented

Final controls must follow `docs/design/ART_DIRECTION.md`:

- readable at gameplay zoom;
- coherent with the game's stylized/vector identity;
- avoid giant opaque panels covering the world;
- use clear selected/cooldown/unavailable states;
- preserve center-screen visibility;
- scale for phone safe areas and aspect ratios;
- keep interaction feedback strong enough to understand without text-heavy UI.

The original hand-drawn mockup is a layout/concept reference, not final pixel-perfect sizing.

## 19. Acceptance principles for future slices

When relevant systems are implemented, device acceptance should prove:

- joystick can originate comfortably throughout its allowed left zone;
- move + camera + jump continue to work simultaneously;
- selecting a skill does not accidentally execute it;
- the contextual execution control changes correctly for action targeting mode;
- skill pages change without losing configured bindings;
- inventory opening suppresses combat but preserves movement/jump;
- hotbar/quick slots reference real item state without duplication;
- fixed-slot bags enforce slots and weight independently;
- dynamic-slot bags allocate stacks only as needed and remain weight-bounded;
- no touch region overlap causes accidental camera/action activation.
