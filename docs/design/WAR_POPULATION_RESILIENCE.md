# War Population Resilience

- **Version:** 0.1.0
- **Status:** Design foundation
- **Updated:** 2026-10-13

## Purpose

Prevent the war simulation from treating military defeat, territorial loss, or faction collapse as automatic biological or cultural extinction.

The simulation must represent enough intermediate outcomes that populations can survive defeat in believable ways.

## Core Principle

> A faction can lose a war without its peoples disappearing.

Faction state, military state, political control, culture, and biological population are separate variables.

A faction may collapse while its populations survive as minorities, refugees, occupied communities, diasporas, autonomous enclaves, prisoners, deserters, assimilated groups, rebels, or members of successor states.

## Separate State Domains

Avoid a single `FactionPopulation` value controlling everything.

Relevant state may include:

- race/species population;
- civilian population;
- military population;
- political allegiance;
- cultural identity;
- territorial control;
- settlement ownership;
- refugee population;
- prisoner population;
- displaced population;
- diaspora population;
- resistance population;
- neutral population;
- deserters;
- surrendered units;
- missing/disconnected groups.

This separation allows political defeat without accidental extermination.

## Combatant Survival States

A soldier who loses a fight does not only have `alive` or `dead` outcomes.

Possible outcomes include:

- unharmed retreat;
- wounded retreat;
- incapacitated;
- rescued;
- surrender;
- captured;
- prisoner exchange;
- desertion;
- hiding/dispersal;
- defection;
- discharge after defeat;
- death.

The probability of each outcome can depend on:

- morale;
- wounds;
- leadership;
- escape routes;
- encirclement;
- enemy policy;
- culture/doctrine;
- terrain;
- supply;
- nearby allies;
- perceived chance of survival;
- prior treatment of prisoners.

## Morale Before Annihilation

Military units should often break before every member dies.

A simplified sequence may be:

`organized -> pressured -> shaken -> routing -> dispersed/surrendered`

This means a decisive battlefield victory can destroy a unit as an effective fighting force while leaving many individuals alive.

## Civilian Survival Responses

Civilians should respond to approaching danger before direct combat reaches them.

Responses may include:

- evacuation;
- hiding;
- sheltering in fortified areas;
- migration to allied settlements;
- crossing borders;
- seeking neutral territory;
- surrendering settlement control;
- paying tribute;
- temporary abandonment;
- accepting occupation;
- joining refugee caravans.

Civilian AI should not default to fighting professional armies or monsters to the death.

## Occupation

Territorial conquest creates an occupation state rather than deleting the conquered population.

Possible occupation variables:

- occupier tolerance;
- local compliance;
- resistance;
- taxation;
- food security;
- military presence;
- cultural repression/tolerance;
- autonomy;
- collaboration;
- migration pressure;
- prisoner policy;
- reconstruction level.

Different occupying governments can therefore produce radically different outcomes from the same military victory.

## Refugees and Diaspora

War can move populations instead of merely reducing them.

Refugees may:

- settle in allied cities;
- create camps;
- migrate to neutral lands;
- form new settlements;
- return after a ceasefire;
- become permanent minorities;
- carry culture and political grievances elsewhere.

This provides an organic mechanism for preserving races/cultures after territorial defeat.

## Prisoners of War

Captured combatants remain part of the world state.

Possible outcomes include:

- imprisonment;
- labor;
- ransom;
- prisoner exchange;
- release after treaty;
- recruitment/defection;
- escape;
- rescue mission;
- execution only under specific policies/events.

Prisoner treatment can influence morale, diplomacy, surrender probability, reputation, and future retaliation.

## Desertion

Desertion is a valid pressure-release mechanism.

Soldiers may desert because of:

- low morale;
- starvation;
- fear;
- abusive leadership;
- hopeless battlefield conditions;
- family danger;
- ideological disagreement;
- unpaid service;
- enemy amnesty offers.

Deserters can become civilians, bandits, mercenaries, refugees, rebels, or defectors instead of disappearing from simulation.

## Defeat Ladder

War outcomes should normally descend through multiple layers before extinction becomes possible.

Example:

1. battlefield defeat;
2. retreat;
3. territorial loss;
4. settlement evacuation or occupation;
5. military collapse;
6. political surrender;
7. faction dissolution or transformation;
8. minority/diaspora/refugee survival;
9. long-term cultural decline or assimilation;
10. only under extreme sustained conditions: cultural or biological extinction.

Skipping directly from step 2 to step 10 under ordinary simulation should be treated as a balance or logic warning.

## Anti-Massacre Design Principle

The world should contain both destructive and protective feedback loops.

Destructive pressures include:

- combat deaths;
- famine;
- disease;
- predation;
- sieges;
- resource loss;
- forced displacement.

Protective pressures include:

- retreat;
- surrender;
- evacuation;
- diplomacy;
- alliances;
- ceasefire;
- prisoner systems;
- humanitarian aid;
- migration;
- reconstruction;
- reproduction;
- recolonization;
- sanctuary regions;
- external populations.

A stable emergent simulation requires both classes of variables.

## Extinction Policy

Extinction is not forbidden, because the game is intended to preserve meaningful sandbox consequences.

However, full extinction should require extraordinary and sustained causes rather than normal war attrition.

Examples may include:

- deliberate world-scale extermination campaign;
- destruction of all refuges and external populations;
- catastrophic ecological failure;
- supernatural catastrophe;
- very long demographic collapse;
- coordinated player/world actions sufficient to overcome recovery systems.

A race losing the Chapter 1 kingdom does not imply that every member of that race in the world has died.

## Simulation Diagnostics

The simulation should expose enough metrics to distinguish meaningful tragedy from broken balancing.

Track examples:

- battle deaths versus captures;
- surrender rate;
- desertion rate;
- civilian casualties;
- refugee flows;
- occupied population;
- faction military strength;
- total race/species population;
- demographic recovery;
- cultural/political control;
- prisoner counts;
- settlement abandonment and resettlement;
- cause-of-death distribution.

## Test Cases

### Defeated Army

Force one army into overwhelming defeat and verify that some combination of death, retreat, capture, surrender, and desertion occurs instead of universal death.

### Fallen Faction

Collapse a faction politically and verify that its races/cultures remain represented through surviving populations.

### Occupied City

Transfer control of a city without automatically replacing or deleting its civilian population.

### Refugee Recovery

Destroy or occupy a settlement and verify that displaced civilians can migrate, survive, and later integrate or resettle.

### Long War Stress Test

Accelerate a prolonged war and verify that ordinary attrition does not accidentally erase entire peoples solely because recovery/surrender variables were missing.

## Design Rule

> When simulation produces catastrophic population loss, first ask whether the world actually caused it or whether the model simply lacked plausible ways to survive.
