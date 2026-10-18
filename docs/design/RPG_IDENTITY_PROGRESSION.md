# RPG Identity, Classes, Disciplines and Progression

- **Version:** 0.1.0
- **Status:** First-scope design contract
- **Updated:** 2026-10-18

## Purpose

Define the first production scope for playable identity and progression without hard-locking players into one optimal race/class pairing or one linear quest path.

The system separates race/species, origin, faction history, current loyalty, class foundation, disciplines, learned abilities, equipment and personal progression.

## Core Rule

**Race influences the start and flavor of a build; it does not decide the final ceiling of the character.**

A Human can become an excellent mage. An Elf can build defensively. A Dragonkin can learn magic. Differences should matter without turning character creation into a solved spreadsheet where one race is mandatory for one class.

## Identity Layers

A playable character can carry separate persistent identity fields:

- race/species;
- culture/origin;
- world of origin;
- historical faction association;
- current allegiance/loyalty;
- class;
- disciplines/specializations;
- learned skills/abilities;
- professions;
- reputation/crime/title state.

Race must not permanently lock current faction. Players/Bots of a race associated with one side may join the other side and receive contextual social/lore consequences rather than being technically prohibited.

## Initial Race Families

The exact final names are content decisions. The first identity taxonomy currently targets four broad playable peoples associated with each original world/faction history.

### World A / historical side A

- **Human** — generalist baseline; flexible across physical and magical builds.
- **Elf** — faster/more magically capable baseline, with lower physical robustness and selected elemental vulnerabilities/resistances as balance data.
- **Dwarf** — stronger defensive/physical baseline, good durability and heavy-combat affinity, with lower speed and weaker initial magical/resource efficiency.
- **Beastkin / Semi-human** *(provisional name)* — animal-feature humanoids; speed/agility/DPS leaning with species/subtype variation. Cat, canine, rabbit and other visual/body families may exist under this broad taxonomy.

### World B / historical side B

- **Vampire** — distinct survival/resource behavior around blood and related racial abilities/risks.
- **Druidic/Sylvan people** *(provisional race name; avoid confusing race with the future druid class/tradition)* — resilient nature-associated people with support/control/healing affinity.
- **Fae/Fairy people** — high mobility and magic affinity, lower physical robustness; may support limited flight/glide behavior. The wider world can also contain non-playable fae spirits and fae monsters without making them the same playable subtype.
- **Dragonkin / Semi-dragon** — strong melee/physical durability, broad elemental resistance and dragon visual traits; mobility/magic balance remains tunable.

The final names, exact stat coefficients and elemental matrices remain data-driven balance/content work.

## Race Definition Contract

A race definition should be able to declare:

- stable race ID;
- body/visual family and compatible modular rig tags;
- baseline attribute modifiers;
- resource modifiers;
- movement traits;
- resistance/vulnerability profile;
- innate passive/active abilities;
- survival needs or special meters;
- equipment/body compatibility tags;
- cultural/origin defaults;
- historical faction association;
- reputation modifiers/initial social reactions;
- progression modifiers/learning affinities;
- optional locomotion traits such as glide/flight/swim.

Do not implement race logic as long chains of `if race == ...` in Player/Combat.

## Class Philosophy

A class is the **starting combat/gameplay chassis and progression identity**, not the entire final build.

Current first taxonomy is role-oriented and names remain provisional where the design is not final.

### Melee / frontline families

- **Warrior** — broad melee baseline/flexible physical class.
- **Paladin** — mobile/fast defensive frontline hybrid; tankier than ordinary DPS while maintaining speed and pressure.
- **Heavy Knight / Heavy Warrior** *(name provisional)* — slower high-durability frontline/tank archetype.
- **Fast melee/DPS controller** *(name TBD)* — high attack speed/mobility/pressure with lower durability; control and sustained DPS through execution rather than tanking.

### Ranged / projectile families

- **Archer** — bow/projectile precision and ranged physical combat.
- **Shooter / Projectile Specialist** *(name provisional)* — broader projectile-focused class not limited to firearms; exact fantasy weapon identity remains open.

### Magical/support families

- **Mage** — structured magic/high ranged magical capability.
- **Warlock** — alternative supernatural paradigm with distinct sources/contracts/style rather than being a renamed Mage.
- **Healer / Curative class** *(final name TBD)* — healing/support-oriented class foundation.

Additional classes may be added later through the same contract.

## Class Definition Contract

A class should be data-driven and able to declare:

- stable class ID;
- baseline stat/resource tendencies;
- starting weapon/equipment proficiencies;
- starting actions/abilities;
- class quest line references;
- allowed/recommended discipline families;
- progression unlock graph;
- combat role tags;
- animation/visual equipment requirements;
- AI suitability tags for Bots/NPCs;
- content requirements for advancement.

Classes can have recommended race synergies but must not hard-lock ordinary playable combinations unless a specific lore/biology requirement explicitly justifies it.

## Discipline Model

A **Discipline** is a specialization/advancement path layered on the class rather than a replacement for it.

A discipline can:

- unlock/modify abilities;
- deepen one combat identity;
- add utility/control/support;
- change resource interactions;
- improve equipment synergy;
- introduce new quests/teachers/training;
- expose new passive/talent choices.

The player may also learn abilities outside the default class/discipline path through world content when compatibility rules allow it.

## Build Formula

Conceptually:

`Build = Race + Class + Disciplines + Learned Abilities + Equipment + Accessories + Professions + Player Choices`

No one layer should own the complete build.

## Main Progression Lanes

The first progression model recognizes three major authored lanes around a class identity:

1. **Class progression** — core class story/training and reliable foundational abilities.
2. **Discipline/world-learning progression** — specialization plus abilities learned from NPCs, hidden quests, guilds, exploration, events and other world sources.
3. **Enhancement/build completion** — equipment, class-themed armor, accessories, modifiers, diagrams and difficult/optional progression that shapes the final build.

These lanes can intersect; they do not need to be three completely separate quest logs.

## World-distributed Ability Learning

Not every strong ability comes from the main class quest.

Abilities may come from:

- class trainers;
- discipline mentors;
- rare NPCs;
- guild quests;
- region events;
- hidden locations;
- bosses;
- books/scrolls/diagrams;
- artifacts/equipment;
- faction/cultural progression;
- emergent world conditions.

The world should naturally provide breadcrumbs toward important optional progression so a first-time player is not expected to read an external wiki merely to discover that a core-enabling skill exists in an unrelated remote corner.

Optional power can remain obscure; foundational usability should not.

## Level and Skill Progression

Exact XP curves and max level remain balance decisions.

The architecture should support:

- actor level/profile progression;
- class progression;
- individual skill/ability unlocks;
- profession progression;
- equipment requirements;
- Bot starting progression profiles;
- NPC authored/organic skill profiles.

Bots may join a server with a persistent/generated history profile that justifies starting progression, completed content and possessions. This is not a reason to fabricate unique world items that already belong elsewhere.

## Race and Faction Social Context

Historical race/faction association influences initial social state/lore but does not define permanent allegiance.

A Dragonkin aligned with the historically opposing side may be treated as a traitor, exile, outsider, valuable defector or suspicious ally depending on local faction/culture/history.

Dialogue/reputation should consume identity facts rather than hard-code all members of a race as one permanent faction.

## Representative First Content Set

A5 should prove the system with limited breadth, for example:

- at least 2 playable races with visibly different innate traits;
- at least 2 classes with different combat loops;
- at least 1 discipline/specialization per demonstrated class;
- several world-learned abilities beyond class starters;
- equipment/accessories that materially alter builds;
- one cross-race/class combination proving affinities are not hard locks;
- one character with faction allegiance different from historical racial association.

The final game can expand toward the wider race/class list after the system is Player Complete.

## Explicit Deferrals

Not frozen in this document:

- final race/class names;
- exact numerical balance;
- final max level;
- full talent trees;
- complete class roster;
- every discipline;
- every elemental resistance coefficient;
- every lore quest;
- final PvP meta.

## Acceptance Principle

The system is not complete because character creation can select a race and class. The first representative version must show that those choices alter gameplay/progression, remain compatible with world/faction identity, and combine with learned abilities/equipment without forcing a single predetermined build.