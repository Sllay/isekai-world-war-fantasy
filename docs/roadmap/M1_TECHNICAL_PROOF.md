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
- at least one schema migration experiment.

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
- persistence direction.

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
- unresolved risks are explicitly documented rather than hidden.

## Principle

> Prototype the unknowns; do not productionize guesses.
