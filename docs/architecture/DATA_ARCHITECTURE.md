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
