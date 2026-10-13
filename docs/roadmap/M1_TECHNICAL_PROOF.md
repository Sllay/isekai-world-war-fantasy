# M1 — Technical Proof Plan

- **Status:** Planned
- **Updated:** 2026-10-13

## Goal

Prove the riskiest technical assumptions before building the production core.

M1 is evidence gathering, not feature production. Throwaway prototypes are acceptable when they answer a specific architectural question.

## Questions M1 Must Answer

### 1. Client Runtime / Stack

We need evidence for the runtime that best satisfies:

- mobile-first;
- Web deployment;
- desktop compatibility;
- 2.5D spatial world;
- vector/stylized asset pipeline;
- modular architecture;
- multiplayer client support;
- acceptable memory/startup/runtime cost.

The engine/framework decision must be recorded in an ADR after prototypes and measurements.

### 2. 2.5D Spatial Model

Prove:

- inclined top-down camera;
- real terrain elevation;
- character height/jump/drop behavior;
- camera rotation;
- 2D-looking characters/assets inside the spatial model;
- occlusion/fade feasibility;
- stable sorting/visibility while rotating the camera.

### 3. Character Visual Pipeline

Prove a minimal modular character with:

- separated body parts;
- rig/bones or equivalent transforms;
- procedural/keyed rotation/scale animation;
- simple IK if supported by chosen stack;
- one equipment attachment;
- one body proportion variation;
- at least the view-direction strategy required by camera rotation.

This prototype is about pipeline feasibility, not final art quality.

### 4. Web/Mobile Performance Baseline

Record measurements on a representative mobile browser/device for:

- startup time;
- memory;
- frame time;
- draw calls/batches where measurable;
- active visual entities;
- collision/physics load;
- animation load;
- network message handling in a synthetic test.

Do not set permanent entity limits from intuition. Measure first.

### 5. Persistent Simulation Scheduler

Prove that the world can advance without frame-level AI for every entity.

Required experiments are defined in `docs/architecture/WORLD_SIMULATION.md`:

- large synthetic scheduled-agent test;
- active <-> aggregate fidelity transition;
- compressed long-horizon world run;
- causal food/aid/encounter chain;
- recovery after simulated stress.

### 6. Modular Boundary Prototype

M2 builds the real module system, but M1 should validate that the selected stack does not fight the architecture.

A minimal prototype should demonstrate:

- one core service;
- two isolated feature modules;
- a typed or schema-validated event between them;
- feature enable/disable;
- no direct circular dependency.

This code may be discarded before M2.

### 7. Networking Feasibility

M1 does not implement the final multiplayer architecture.

It should prove a minimal authoritative flow suitable for later development:

- client connects;
- server owns canonical state;
- client sends an intent/input;
- server validates/applies it;
- state change reaches client;
- irrelevant world state is not blindly broadcast.

Exact transport, hosting, database, sharding, and scale strategy remain open until measured and documented.

### 8. Persistence Feasibility

Prove that stable IDs and versioned state can survive:

- save;
- server/process restart;
- load;
- module state restoration;
- at least one schema migration experiment;
- transfer of one persistent item between multiple owners/containers without duplication;
- one persistent modified bag retaining inherited traits/synthesis history.

Production storage technology does not need to be chosen solely from this prototype.

## World Health Tests

Because the game is intended to run persistently, M1 should include accelerated simulations that look for accidental death spirals.

Track at minimum:

- total population by test species;
- predator/prey ratio;
- local extinction count;
- settlement food stock;
- settlement survival;
- migration;
- resource recovery;
- event queue size;
- simulation CPU time.

A 30-day equivalent accelerated run should be one of the test scenarios, but the exact acceleration and model complexity are experimental rather than production guarantees.

## Social/Economic Proof Scenario

M1 should include one deliberately small connected society rather than separate isolated mock systems.

Suggested test world:

- one village;
- several households;
- one farmer;
- one hunter;
- one merchant;
- one baker/crafter;
- one local leader;
- a few guards;
- two or more autonomous adventurer agents;
- finite food, money and inventories;
- one nearby creature threat;
- one external settlement or trade source represented abstractly.

The test should prove a causal chain such as:

`food shortage -> household pressure -> production/hunting/import attempt -> contract created -> adventurer evaluates/accepts -> encounter succeeds/fails -> goods/money move -> village state changes`

The important proof is not final balance. It is that the same inventory, money, relationship and quest state can flow through multiple modules without fake infinite resources.

## Live Battle Proof Scenario

M1 should also run a small live battle that demonstrates behavior beyond HP depletion.

Minimum proof:

- two squads with commanders;
- morale/cohesion;
- wounds/incapacitation distinct from death;
- retreat or surrender possible;
- command succession if an officer falls;
- battle state can be reduced to aggregate form and later materialized again;
- statistics record dead, wounded, surrendered, captured and routed separately.

A commander should not have a hard-coded `fight to death` rule. Rank is one decision input among personality, morale, tactical state, culture, loyalty and perceived prisoner treatment.

## Population/Relationship Proof Scenario

M1 does not need a finished life simulator, but should prove that population can change without random adult spawning.

Minimum experiment:

- several households/relationships;
- births represented as demographic/family events;
- aging or cohort progression in accelerated time;
- migration into/out of the test settlement;
- relationship changes caused by actions/events rather than gift spam;
- named important NPCs preserved while distant population can be aggregated.

This experiment should validate data flow and performance, not define final demographic rates.

## Persistent Item Custody Proof Scenario

M1 must prove that a notable item can move through the world without being duplicated, silently deleted or tied to one fixed quest spawn.

Minimum chain:

1. create one unique item with stable ID;
2. assign it to an autonomous adventurer;
3. kill/remove the actor from active simulation;
4. preserve the item in corpse/loot state after visual cleanup;
5. let another autonomous actor loot it;
6. promote that holder to persistent individual state because the item matters;
7. let that actor sell the exact item instance to a merchant;
8. save/restart/load the server;
9. verify the merchant still owns the same item instance;
10. resolve a quest/query to the item's current state without respawning a duplicate.

This proof should also test an invariant that one unique item ID cannot legally exist in two inventories at once.

## Bag Persistence Proof Scenario

A minimal container test should prove:

- one base bag;
- category-specific weight/preservation traits;
- one donor bag consumed through synthesis;
- bounded inheritance of at least one trait;
- donor permanently removed;
- host bag keeps stable identity;
- save/load preserves the resulting traits and synthesis history.

Final crafting balance is not required in M1.

## Evidence Package

Each technical experiment should leave:

- objective;
- prototype code/location;
- device/browser/runtime version;
- test scenario;
- measurements;
- screenshots/logs where useful;
- result: pass / fail / inconclusive;
- architectural consequence.

## ADRs Expected From M1

Likely decisions include:

- runtime/engine choice;
- 2.5D world representation;
- character rendering/rig strategy;
- initial networking model;
- initial simulation scheduling model;
- persistence direction;
- persistent item identity/aggregation strategy if the proof exposes a major architectural choice.

Do not write an ADR as `Accepted` before the relevant proof exists.

## Exit Criteria

M1 is complete when:

- runtime/engine is selected from evidence;
- Web/mobile prototype runs on the target class of device/browser;
- camera and 2.5D spatial representation are validated;
- modular character pipeline is validated;
- performance baseline is recorded;
- persistent simulation scheduling is shown feasible;
- aggregate/active simulation transition is demonstrated;
- minimal authoritative network flow is demonstrated;
- persistence basics are demonstrated;
- one connected social/economic causal chain is demonstrated;
- one live battle demonstrates non-lethal defeat states;
- one population test demonstrates recovery/migration without arbitrary adult spawning;
- one unique item survives a multi-owner custody chain and restart without duplication;
- one synthesized bag survives save/load with inherited traits;
- unresolved risks are explicitly documented rather than hidden.

## Principle

> Prototype the unknowns; do not productionize guesses.
