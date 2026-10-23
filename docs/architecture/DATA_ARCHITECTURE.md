# Data Architecture

## Principle

**Behavior reusable lives in code; content lives in data.**

The project must avoid hard-coded content branches such as `if creature == wolf` when the same behavior can be configured.

## Stable IDs

Every persistent/content definition should use a stable namespaced ID where practical:

- `creature.wolf_forest`
- `item.iron_sword`
- `skill.fireball`
- `faction.blue.kingdom`
- `profession.blacksmith`

Names shown to players are localization data, not identity.

P3 preserves Region's existing chunk address, `region_id:x:z`, rather than passing
it through the content-ID validator. `WorldGenIds` derives generated resource,
spawn and landmark IDs from world/seed/generator version/Region/coordinate/domain
inputs; generated actor IDs use deterministic Core-compatible entity identifiers.
Runtime Nodes and instance handles never replace these identities.

## Definition Families

Planned registries include:

- races;
- classes/disciplines;
- abilities;
- effects;
- creatures;
- items/equipment;
- recipes;
- professions;
- factions;
- regions;
- structures;
- quests/templates;
- economy goods;
- taming methods.

## Schemas

Every definition family should eventually have a machine-validatable schema. CI must reject malformed definitions before they reach runtime.

## Inheritance and Composition

Prefer composition/templates over deep data inheritance.

Example creature definition may reference reusable blocks for:

- attributes;
- locomotion;
- senses;
- combat profile;
- loot table;
- ecology;
- taming profile.

## Save Compatibility

Persistent saves store stable IDs and state, not copied display data. Data migrations must exist when a breaking schema change affects saves.

### C1-R1-P3 canonical world and actor records

`WorldBlueprint` schema 1 carries `world_id`, `world_seed`, `generator_id`,
`generator_version`, `content_schema_version`, logical creation tick, parameterized
chunk size and bounded Region profiles. `worldgen.chapter_one` version 1 is the
first implementation. Domain-derived streams prevent adding a spawn draw from
changing the terrain stream. Generator version is compatibility metadata: an
existing world cannot silently adopt a newer generator.

`ChunkRecord` schema 1 stores its world/Region/chunk address, generator identity,
creation tick, immutable baked `base` and `base_hash`, revision, lifecycle and
mutable `delta`. Base contains integer-millimeter terrain samples, biome/material,
resource placement, spawn/capacity descriptors, landmark and navigation/portal
metadata. Deltas currently record removed resources and claimed spawns. Reload
uses these persisted descriptors, never a regeneration of the base from seed.
This narrows older seed-reconstruction guidance: mesh reconstruction from baked
descriptors is allowed; worldgen invocation on a persisted chunk is not.

`LivingActorState` is data composed with existing movement, Combatant, Actions,
Inventory and Equipment contracts. Race, class/archetype, visual profile,
progression and faction have validated definition resources. Race/culture/origin/
historical faction/current allegiance remain separate fields. The representative
human/warrior references an LPC-compatible visual profile without storing sprites
as gameplay truth. Attributes use stable modifier sources; progression persists
XP and bounded per-source reward sequence watermarks. Clients supply no XP amount.

`ClassDefinition.starting_actions` seeds the existing `LearnedSkillSet` atomically
with the class source; later learning/equipment grants remain separate sources.
Its equipment tags match existing ItemDefinition tags/tool capabilities. The
authority composition supplies that eligibility predicate through the generic
ItemAuthorityContext hook, and the shared ItemsAuthorityPort checks it before
equipment/combat mutation. Foundation has no dependency on RPG class types.

Actor records include identity/location, faction, sparse relationship values,
durable memory, needs, activity/deadline, fidelity and materialization epoch. Memory
has at most eight ordinary records and two persistent anchors; ordinary records
expire and replacement respects importance/age. Memory subjects must exist in
the canonical entity registry. Cached plans, current visibility, SceneTree Nodes,
physics handles and local path queues are reconstructible transient data.

The same logical Core snapshot stores versioned `foundation.world_genesis` and
`gameplay.living` sections. Cross-section validation checks resource placement,
spawn claims, actor identity/custody, world/Region/location, faction and durable
memory/reward references before restoration. The physical content-addressed page
adapter changes storage layout, not those schemas. See
[ADR-0019](../adr/ADR-0019-canonical-world-chunks-and-living-actors.md) and
[SAVE_SYSTEM](SAVE_SYSTEM.md).

## Modularity

Modules register their own definition types and schemas. A module that is disabled should not require unrelated data to be loaded.

## Validation

Validators should detect at minimum:

- duplicate IDs;
- missing references;
- invalid ranges;
- missing required fields;
- cyclic references where forbidden;
- incompatible module requirements.

## Authoring Goal

Long term, common content should be creatable through internal tools/forms that output validated definitions, reducing direct manual editing and accidental schema errors.
