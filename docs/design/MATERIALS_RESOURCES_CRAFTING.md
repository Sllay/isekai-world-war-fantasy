# Materials, Resources, Crafting and Resource Nodes

- **Version:** 0.1.0
- **Status:** First-scope design contract
- **Updated:** 2026-10-18

## Purpose

Define the first production scope for reusable material families, world resources, ores/gems, crafting inputs, tool requirements and crafting stations so Building, Equipment, Economy and World Generation do not each invent incompatible resource rules.

## Core Rule

**Item identity, material family, material variant and crafted object are separate concepts.**

A recipe can require a broad family such as `wood` while allowing the player to choose a compatible variant. The chosen material then modifies the resulting object's properties and presentation.

Example:

`iron_sword recipe + material.wood.oak handle`

versus

`iron_sword recipe + material.wood.enchanted handle`

use the same recipe structure while producing different final properties.

## Material Taxonomy

A material definition can expose:

- stable material ID;
- family/category tags;
- grade/refinement state;
- density/mass contribution;
- hardness;
- structural durability;
- weapon/tool durability modifier;
- flexibility/toughness;
- elemental/magical affinities;
- resistance/corrosion/flammability traits;
- crafting compatibility;
- minimum tool/process requirements;
- rarity/region/depth tags;
- visual `MaterialProfile` / `SurfaceProfile` reference;
- economy/value hints;
- special passive traits.

Exact physical formulas remain balance data. The important invariant is that systems consume declared properties rather than hard-coding every material name.

## Broad Resource Families

Initial resource families include at least:

- wood;
- stone;
- metal/ore;
- gem/crystal;
- hide/leather;
- fur/fiber;
- plant/herb;
- food;
- magical reagent;
- biological monster material;
- processed component.

New families can be registered without changing Inventory core.

## Wood Variants

The initial world direction includes at least three compatible wood variants:

- ordinary/common wood (for example oak-like wood);
- high-altitude/mountain wood with improved physical durability/resistance;
- enchanted wood with stronger magical affinity and bounded natural magical traits.

All satisfy the broad `wood` family when a recipe accepts generic wood.

A recipe may explicitly require one variant when the identity of the material is essential, such as an enchanted crafting station.

## Hide, Leather and Fur

Avoid a separate handcrafted item definition for every animal hide unless species-specific identity matters.

Initial broad hide/leather categories can include:

- light hide/leather — small creatures;
- standard hide/leather — ordinary medium creatures;
- medium/heavy hide — larger/tougher creatures;
- heavy/monster hide — very large or exceptionally resistant creatures.

**Fur is a separate resource trait/family**, not `furry leather` by default. A creature can yield both hide/leather and fur where biology supports it.

Species may also produce unique biological materials such as scales, chitin, horn, venom gland or magical tissue.

## Ores, Metals and Refinement

Ore/resource identity and processed metal identity are separate.

A progression may contain material states such as:

`ore/raw material -> smelted/refined material -> advanced alloy/high-grade material`

Examples currently in design direction include ordinary iron, rough/raw iron-like construction material, refined/polished iron, silver and later fantasy alloys such as mithril. Names and exact hierarchy remain content/balance decisions.

Building and Equipment should reference material properties/tags, not assume a fixed global tier list in code.

## Gems and Crystals

Gems/crystals are items/material components with stable definitions and can be used for:

- crafting ingredients;
- accessory creation;
- equipment sockets/upgrades;
- magic focuses/staves;
- economy/value;
- quest/artifact content;
- specialized material modifiers.

Examples can include real-world-inspired gemstones such as ruby, emerald, diamond, amethyst, aquamarine, imperial topaz, alexandrite and Paraiba tourmaline, alongside fantasy crystals.

Real-world names do not imply real-world geological accuracy; they provide recognizable material identity inside the game's fantasy system.

## Material Choice During Crafting

Recipes declare compatible material slots rather than only one exact item whenever appropriate.

Example conceptual recipe:

```text
Sword
- blade_material: family.metal, min_grade = forged
- handle_material: family.wood
- optional_gem: family.gem
```

The crafting UI resolves available compatible materials and previews relevant differences before commit.

The result records the chosen material composition so durability, value, appearance and modifiers remain stable after save/load/trade.

## Crafting Output Quality

Output may depend on bounded factors such as:

- selected material properties;
- recipe/diagram quality;
- station capability;
- crafter skill/profession;
- tool condition;
- optional modifier components;
- item condition/quality rules.

Do not make high quality purely random when the player has no meaningful influence.

## Tool Tier / Capability Gates

Resource nodes may require a tool capability rather than a single hard-coded item.

Example:

- node hardness/mining requirement;
- tool mining capability/power;
- compatible tool category;
- optional special enchantment/skill requirement.

A weak stone pick should not mine high-grade ores merely because it can call the same interaction method.

Failure should produce a semantic reason such as `TOOL_TOO_WEAK`, `WRONG_TOOL`, or `REQUIRES_SPECIAL_EXTRACTION`.

## Resource Nodes and Surface Profiles

World resources are physical world content, not inventory spawn buttons.

A resource node definition may include:

- stable node/resource profile ID;
- base mesh/shape family;
- host rock/terrain material;
- exposed resource visual profile;
- resource definition/material family;
- quantity/remaining reserves;
- tool requirement;
- extraction time/work;
- damage/depletion state;
- respawn/regeneration policy if any;
- depth/biome/geology constraints;
- rare-drop/secondary-yield profile;
- persistence policy.

### Visual Direction

Ore/gem nodes should read clearly as a stylized deposit protruding from or embedded in a host rock mass rather than only a flat recolored texture.

Examples:

- ordinary surface rock host;
- deeper `blackstone`/hard-rock host;
- visible veins/crystals/metal protrusions using the shared Art/Material profile system.

The future Art/Asset API can generate/adapt the material/surface appearance from these profiles while reusing simple 3D base meshes.

## Cave Depth Distribution

Resource generation uses **allowed depth/environment bands first**, then local distribution inside valid areas.

A resource that requires deep strata cannot appear in a shallow cave just because RNG succeeded.

Within valid strata, generation may use density/rarity rules.

For very rare gems/resources, world generation should guarantee a bounded minimum amount of discoverable supply across suitable caves/regions so the world does not accidentally generate zero viable sources.

Exact counts such as the number of caves containing a gem are world-generation tuning data, not hard-coded item rules.

## Renewable / Re-entering Rare Resources

If a resource is designed to remain renewable, new deposits can become available only through explicit world rules and valid geology/depth locations.

Do not teleport a replacement deposit arbitrarily after one is mined.

Possible mechanisms include:

- latent unexposed veins becoming discoverable;
- newly generated/changed cave sections;
- magical regeneration;
- world events;
- regional resource recovery.

Unique artifacts are governed by item provenance rules and are not regenerated as ordinary resources.

## Breakable Cave Barriers

Caves may contain visually readable breakable walls/barriers used to gate deeper sections.

A breakable barrier should expose:

- visual damage/crack language before full destruction;
- tool/power requirement;
- health/structural state;
- persistent destroyed/intact state;
- valid navigation update after destruction;
- optional resource yield.

The presentation should communicate that the wall is interactable/breakable rather than looking identical to an absolute world boundary.

## Loot / Harvest Profiles

Randomized world/creature/prop yield uses reusable profiles.

A profile can declare:

- guaranteed yields;
- weighted optional yields;
- quantity ranges;
- condition/quality rules;
- extraction method modifiers;
- tool/skill modifiers;
- unique/limited item restrictions.

Use this for monster resources, biological harvests, barrels/crates and resource props where chance is intentional.

Do **not** use it to regenerate a persistent humanoid actor's carried inventory at death.

## Crafting Stations

### Hand Crafting

Supports simple early items and creation of the initial workbench/tools where design permits.

### Workbench

The primary general crafting station has progression/upgrades with at least three capability levels in the current direction.

- **Level 1:** basic construction/components/general early recipes.
- **Level 2:** expands recipes and enables access to additional processing/utility such as cauldron/alchemy/food systems where appropriate.
- **Level 3:** advanced crafting access and prerequisite path for high-tier specialized stations such as enchanted crafting.

The exact recipe unlock list is data.

### Forge / Smelter

Processes ores/raw metal resources into usable/refined metal/material forms.

Current direction does not require the forge itself to have three linear levels; capability can instead depend on fuel, recipe, structure upgrades or later content if needed.

### Anvil / Smithing Station

Creates/works weapons, tools and armor and currently supports at least three progression/capability levels.

Higher capability unlocks more demanding recipes/material processing.

### Cauldron

Supports food/potions/alchemy-like processing in the appropriate progression band. It may be unlocked/built through the Workbench progression rather than literally being part of one monolithic scene.

### Enchanted Crafting Station

Advanced specialized station for accessories/magical components and related crafted content.

Current direction requires enchanted wood as a meaningful construction input. Additional magical requirements remain content data.

## Recipe Knowledge and Diagrams

Not every recipe is automatically known.

Recipe knowledge sources can include:

- starting/basic knowledge;
- profession/class progression;
- learned diagram/blueprint;
- NPC trainer;
- guild reward;
- chest/loot;
- quest;
- research/discovery;
- item/artifact interaction.

A diagram teaches/unlocks a stable recipe/knowledge record rather than being required to remain physically in inventory forever unless that specific item says otherwise.

NPC craftsmen can know recipes the Player does not. The Player can therefore commission an item from a blacksmith who has the required knowledge, station capability, materials and economic agreement.

## Economy Integration

Materials remain actual stock throughout:

`world node -> actor inventory -> storage -> processing -> crafting -> merchant/consumer`

NPC workshops do not receive invisible infinite materials.

Prices and availability can respond to local supply, quality, rarity, processing effort and danger.

## Persistence

Persist at least:

- resource node remaining/depleted state where relevant;
- mutable cave barriers;
- material/lot custody;
- recipe/diagram knowledge for persistent actors;
- crafted item's chosen material composition;
- station ownership/upgrade/capability state;
- ongoing jobs/reservations needed for consistent crafting.

## Representative First Proof

A3/A6 material/crafting proof should demonstrate:

1. gather ordinary wood and a stronger wood variant;
2. gather mineable ore from a valid-depth node using a compatible tool;
3. weak tool is rejected by a harder node with a semantic reason;
4. smelt/process ore;
5. craft one item with selectable compatible material;
6. resulting item retains chosen material-driven properties and appearance reference;
7. craft/build one station upgrade;
8. unlock a diagram-based recipe;
9. an NPC crafts or sells an item using real stock;
10. save/reload preserves node depletion, stocks, knowledge and crafted composition.

## Explicit Deferrals

Not frozen here:

- final full material list;
- exact numerical tiers;
- exact cave ore counts;
- final recipe catalog;
- final crafting UI;
- final blacksmith minigame, if any;
- exact gemstone modifiers;
- complete magical alloy lore.

## Acceptance Principle

The system is not complete because rocks drop ore and a crafting button creates a sword. A representative version must prove that material identity survives the full world -> inventory -> processing -> recipe -> item/economy chain and meaningfully changes the crafted result.