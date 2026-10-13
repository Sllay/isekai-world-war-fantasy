# Persistent World Simulation

- **Version:** 0.1.0
- **Status:** M1 design hypothesis
- **Updated:** 2026-10-13

## Purpose

Define how the world can remain alive without requiring every creature, NPC, plant, caravan, battle, and settlement to run full-detail AI continuously.

The core rule is:

> The world continues without players, but simulation fidelity scales with relevance.

This document is intentionally an M1 hypothesis. Exact rates, budgets, entity counts, and server topology must be measured before they become production constraints.

## Design Requirements

The simulation must support:

- creatures continuing to migrate, hunt, reproduce, die, and compete without nearby players;
- settlements consuming resources, producing goods, requesting aid, defending themselves, and suffering consequences;
- caravans, hunters, patrols, and military forces affecting the world while off-screen;
- wars continuing without player participation;
- player actions influencing the same systems instead of using a separate scripted world;
- long-running worlds that do not naturally collapse into an empty map after days or weeks;
- mobile/Web clients receiving only information relevant to them;
- deterministic or reproducible diagnostics where practical.

## Region Is Not Server

A gameplay region, village, biome, or city is a **logical simulation area**, not inherently a physical server.

The world is partitioned into simulation cells/regions. Infrastructure may later assign multiple cells to one process or distribute cells across multiple processes without changing gameplay rules.

This separation prevents world design from depending on deployment topology.

## Simulation Fidelity Levels

### L0 — Active / Full Fidelity

Used around players and other situations requiring direct observation.

Examples:

- full movement;
- pathfinding;
- collision;
- combat hit resolution;
- animation-driving state;
- detailed perception;
- individual inventory where relevant;
- precise projectiles and ability timing.

This is the most expensive mode and must be spatially limited.

### L1 — Reduced Individual Simulation

Used for nearby or strategically relevant entities that do not require frame-level fidelity.

Examples:

- movement along simplified paths;
- lower-frequency decision ticks;
- simplified combat resolution;
- reduced perception checks;
- scheduled needs rather than constant polling.

An individual identity can remain preserved without running full AI every frame.

### L2 — Regional / Aggregate Simulation

Used far from active players.

Entities are represented primarily through state and cohorts rather than physical actors.

Examples:

- wolf pack: population, health, territory, hunger, prey pressure;
- village: population cohorts, food, defense, morale, production;
- patrol: strength, route, supplies, commander quality;
- caravan: cargo, guards, route, travel progress, risk;
- battle: force strength, terrain, morale, supply, modifiers.

The simulation resolves meaningful changes at scheduled intervals.

### L3 — Latent / Long-Horizon Simulation

Used for distant or low-priority systems.

Only slow variables and scheduled events advance.

Examples:

- population trends;
- resource regeneration;
- seasonal migration;
- long construction projects;
- diplomatic drift;
- economic production/consumption.

## Promotion and Demotion

Simulation representations must support moving between fidelity levels.

Example:

1. A distant caravan exists as aggregate state.
2. A player approaches its region.
3. The aggregate caravan is materialized into individual entities.
4. The player attacks or escorts it.
5. The resulting survivors, cargo, injuries, and route state are recorded.
6. When no longer relevant, the caravan returns to reduced/aggregate simulation.

The aggregate and physical representations must describe the same world state, not parallel realities.

## Scheduled Simulation Instead of Per-Entity Polling

Avoid `update every entity every frame` as the default model.

Systems should prefer:

- scheduled ticks;
- time buckets;
- batched queries;
- event queues;
- regional jobs;
- dirty-state processing;
- priority queues for future events.

Examples:

- hunger does not need to be recalculated every rendered frame;
- a distant crop does not need animation or collision updates;
- a distant wolf pack can schedule its next hunting decision;
- a trade route can resolve checkpoints instead of simulating every footstep.

## Causality Example: Food Crisis

A settlement can enter food stress because its actual systemic inputs changed.

Possible chain:

`low harvest -> food stock declines -> aid request -> caravan dispatched -> predator/bandit encounter -> shipment fails -> prices rise -> hunters take more risks -> casualties or successful hunting -> new quests/events`

The quest is therefore an output of world state, not an isolated script pretending the settlement is hungry.

## Ecological Stability

Pure unconstrained predator/prey simulation can collapse. The goal is not to prevent consequences, but to prevent normal simulation noise from accidentally destroying the playable ecosystem.

### Carrying Capacity

Habitats define approximate resource and population capacity.

Population growth slows as capacity is approached. Scarcity changes migration, reproduction, aggression, and mortality.

### Ecological Reservoirs

Not every population must be represented only by currently visible individuals.

Biomes may maintain hidden/abstract reservoir populations representing animals outside active observation, inaccessible nesting zones, migration sources, seeds, larvae, underground life, or neighboring habitat.

Reservoirs are not free infinite spawning. They obey ecological state and recovery rates.

### Migration and Recolonization

When local population falls, suitable neighboring populations may migrate into the area over time.

Local extinction can therefore differ from species extinction.

### Reproduction Feedback

Reproduction can react to:

- population density;
- food availability;
- season;
- safety;
- age structure;
- habitat quality.

### Predator Pressure

Predator reproduction and activity should depend on prey availability. Predators cannot increase indefinitely while prey disappears.

### Threat Budgets

Regions can track sustainable threat pressure. Random systems should not independently stack unlimited catastrophic events on the same weak settlement without systemic cause.

This is not immunity. Major wars, bosses, player actions, disasters, or sustained failures can still overwhelm a region.

### Extinction Policy

Species or playable peoples should not disappear because of ordinary background RNG.

Extinction should normally require sustained systemic pressure or a major world-scale event.

Possible safeguards include:

- refuges;
- migration sources;
- minimum viable abstract populations;
- protected breeding populations;
- distant populations outside the current chapter map;
- recovery events.

A true extinction, where permitted by design, should be treated as a major persistent world event rather than routine simulation noise.

## Settlement Resilience

Civilian settlements must have systemic survival mechanisms.

Possible state includes:

- civilian population;
- militia potential;
- trained guards;
- fortification;
- shelter capacity;
- food reserves;
- evacuation routes;
- allied response time;
- local threat knowledge;
- morale;
- medical capacity.

A dangerous creature entering a village should not automatically mean every villager independently fights to the death.

NPC responses may include:

- flee;
- shelter;
- alert guards;
- ring alarms;
- barricade;
- evacuate children/noncombatants;
- request nearby patrols;
- hire hunters;
- abandon the settlement temporarily.

This creates believable survival without making every civilian a soldier.

## Individual vs Cohort Population

Important NPCs may persist as individuals at all fidelity levels.

Large civilian populations can be represented as cohorts while far away, for example:

- children;
- working adults;
- elderly;
- guards;
- specialists.

When a region becomes active, the simulation materializes a suitable set of individual actors while preserving named/important characters.

This avoids requiring thousands of full AI instances merely to prove that a town population exists.

## Creatures and Hunting

A hunter does not need to be physically simulated walking every meter when far away.

An abstract hunting expedition can contain:

- hunter identities/skill;
- target species;
- equipment;
- route;
- duration;
- risk;
- expected yield;
- current injuries;
- environmental modifiers.

Possible results:

- successful hunt;
- injury;
- death;
- predator encounter;
- discovery of a rare resource;
- rescue event;
- missing person event.

If a player enters the relevant area during a significant event, it may be promoted into an observable encounter when technically and narratively appropriate.

## Persistence Strategy Hypothesis

Long-running world state should be persisted primarily as structured state plus event history where useful.

Likely building blocks:

- periodic snapshots;
- durable scheduled events;
- stable entity IDs;
- module-owned persistent state;
- versioned save schemas;
- bounded event journals for diagnostics/reconstruction.

Exact persistence technology is intentionally undecided during early M1.

## Time Advancement

The server world advances continuously while running.

If deployment later allows a world process to sleep or restart, offline catch-up must not replay every missed frame. It should advance systems analytically or in bounded time steps.

Example:

Instead of simulating 30 real days as billions of AI frames, agriculture, population, trade, and ecology resolve elapsed time through their scheduled/aggregate models.

## Safety Against Simulation Death Spirals

The simulation should detect unstable feedback loops such as:

- all prey die -> predators invade settlements -> settlements collapse -> economy collapses -> war simulation collapses;
- one faction snowballs permanently from one early random victory;
- shortages continuously create more shortages with no recovery mechanism;
- population reaches zero from ordinary background events;
- resource regeneration cannot recover from normal consumption.

Detection does not imply silently resetting the world. Recovery should preferably happen through understandable systemic mechanisms such as migration, aid, retreat, reproduction, trade rerouting, ceasefire, habitat recovery, or intervention events.

## Observability

The server simulation needs diagnostics from the beginning.

Track at minimum:

- simulation time spent by module;
- entities by fidelity level;
- active scheduled events;
- event queue backlog;
- population by species/people/region;
- births/deaths/migration;
- local extinctions;
- settlement population and food state;
- faction territorial change;
- resource stocks;
- promotion/demotion counts;
- simulation errors and invalid state corrections.

Without observability, balancing an emergent world becomes guesswork.

## M1 Proof Experiments

M1 does not need the finished ecology or war system. It needs evidence that the architecture can support them.

### Experiment A — Scheduler

Create a synthetic world with large numbers of logical agents using scheduled/aggregate updates and measure CPU/memory cost.

### Experiment B — Fidelity Transition

Demonstrate one entity/group moving between aggregate and active representations without losing persistent state.

### Experiment C — Compressed World Run

Run a simplified ecosystem/settlement model through a long accelerated period and inspect whether it converges, oscillates, or catastrophically collapses.

### Experiment D — Causal Event Chain

Demonstrate a small systemic chain such as:

`food shortage -> aid caravan -> encounter -> delivery succeeds/fails -> settlement state changes`

No production-quality quest UI is required.

### Experiment E — Recovery

Artificially stress a population or settlement and verify that designed recovery mechanisms can work without a hard reset.

## M1 Non-Goals

M1 will not attempt to implement:

- final ecology balance;
- complete NPC AI;
- production-scale wars;
- every creature;
- final networking topology;
- final database technology;
- extinction gameplay;
- full economy.

The objective is to prove the simulation model and measure its constraints before committing to production architecture.

## Core Principle

> Simulate consequences at the cheapest fidelity that preserves meaningful causality.
