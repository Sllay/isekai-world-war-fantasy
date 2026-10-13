# Population and Relationships

- **Version:** 0.1.0
- **Status:** Design hypothesis
- **Updated:** 2026-10-13

## Core Principle

Population does not appear from arbitrary spawn bars. Intelligent peoples and creatures maintain populations through survival, relationships, reproduction, migration and settlement conditions.

The same social rules should be usable by NPCs and by player-to-NPC relationships, with player agency and consent preserved.

## Population State

Population simulation may track:

- births;
- deaths;
- age structure;
- households;
- partnerships;
- dependents;
- migration;
- fertility/reproduction conditions;
- food security;
- housing;
- safety;
- health;
- culture/species rules;
- local carrying capacity.

Exact demographic rates remain balance data, not hard-coded assumptions.

## No Spawn-Bar Population

Avoid systems equivalent to:

`population < target -> spawn random adult`

Recovery should instead happen through understandable mechanisms:

- births;
- immigration;
- refugees settling;
- returning exiles;
- family reunification;
- neighboring communities merging;
- species-specific reproduction;
- long-term recolonization.

Abstract populations may exist off-screen, but they represent real demographic state rather than infinite hidden spawning.

## Relationship Model

Relationships are multi-dimensional rather than a single heart meter.

Possible dimensions:

- familiarity;
- trust;
- affection;
- respect;
- attraction where applicable;
- fear;
- resentment;
- obligation;
- loyalty;
- rivalry;
- shared history.

Not every relationship uses every dimension.

## Relationship Events

Values change primarily because of actions and shared events.

Examples:

- keeping/breaking promises;
- helping during danger;
- saving a relative;
- fighting together;
- betrayal;
- repeated conversation;
- working together;
- defending someone's community;
- respecting cultural norms;
- gifts;
- lending/giving equipment;
- returning lost property;
- theft;
- insults;
- neglect;
- taking sides in disputes.

A gift is one signal among many; it is not the dominant relationship mechanic.

## Memory and Relationships

Important relationship changes should point back to remembered events when practical.

Example:

`Trust +25` because `BK protected family during raid` is better than an unexplained hidden number.

This allows NPC behavior and dialogue to reference causes.

## Romance and Partnership

Romantic relationships should emerge from compatibility, mutual positive relationship state, interaction history and contextual rules rather than gift grinding.

Possible lifecycle:

`acquaintance -> friendship -> courtship/romance -> partnership/marriage`

But branching must allow:

- friendship without romance;
- rejection;
- breakup;
- reconciliation;
- cultural alternatives to marriage;
- widowing;
- remarriage where appropriate.

For player-to-NPC romance, progression requires explicit game-state consent signals; the player cannot force a relationship merely by reaching a numeric threshold.

## Families and Households

A household can contain:

- partners;
- children/dependents;
- relatives;
- adopted members;
- unrelated cohabitants depending on culture.

Households matter economically and socially:

- shared food;
- housing;
- inheritance;
- caregiving;
- migration decisions;
- grief;
- risk tolerance;
- quest motivations.

## Reproduction

Reproduction is species/culture data-driven and simulated at an appropriate abstraction level.

For intelligent humanoid populations, demographic birth events can depend on factors such as:

- adult population structure;
- established relationships/households where culturally relevant;
- food security;
- housing;
- safety;
- health;
- local population pressure;
- cultural preferences;
- species-specific biology.

The simulation does not need explicit sexual-event simulation. Birth/reproduction is handled as demographic state and family events.

Creature species may use different models:

- pair bonding;
- seasonal breeding;
- eggs;
- nests;
- litters;
- colony reproduction;
- spawning grounds;
- magical reproduction;
- other species-specific rules.

## Children and Aging

Children should not instantly become adults.

The population layer can track age/cohort progression at low fidelity and materialize individuals when relevant.

Named/important children can persist individually; large populations can use cohorts while off-screen.

Aging cadence may be accelerated relative to real time if required by game design, but this must be a deliberate world-time rule.

## War Effects on Demography

War can affect population through:

- direct casualties;
- lower food security;
- refugee movement;
- separated families;
- reduced births;
- increased orphan/dependent population;
- prisoner populations;
- returning soldiers;
- post-war baby/recovery periods if conditions improve;
- occupation and mixed communities.

Military defeat does not directly delete civilian demographic groups.

## Migration Decisions

Individuals/households may move because of:

- danger;
- famine;
- jobs;
- marriage/partnership;
- family;
- persecution;
- faction loyalty;
- land availability;
- guild opportunities;
- war;
- better housing;
- player-created settlements.

Migration is a major stabilizer against local extinction.

## Fidelity Strategy

### Near Players

Important relationships can be simulated individually with memories and direct interactions.

### Far Away

Large populations use households/cohorts/statistical events while preserving named important NPCs and relationship anchors.

The goal is consistent outcomes without running every resident's social planner continuously.

## Player Integration

The player uses the same broad social world:

- friendships;
- rivalries;
- trust;
- reputation;
- romance where supported;
- marriage/partnership;
- household/property membership;
- mentorship;
- guild/social obligations.

NPC reactions to the player should use actions and remembered context, not a separate artificial dating minigame.

## Diagnostics

Track:

- births/deaths;
- age cohorts;
- household count;
- migration;
- orphan/dependent counts where relevant;
- population growth/decline;
- relationship state distribution;
- marriages/partnerships/breakups;
- local and global extinction risk;
- demographic recovery after crises.
