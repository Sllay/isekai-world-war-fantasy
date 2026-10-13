# ADR-0006 — Hybrid Simulation Scheduling and Fidelity

- **Status:** Proposed — selected for M1 proof
- **Date:** 2026-10-13

## Context

The world must remain alive with creatures, settlements, economy, population, war and item decay even when no player is nearby. Updating every entity every render/server frame is unnecessary and will not scale.

## Decision

Prototype a **hybrid scheduler** with simulation fidelity levels:

- **L0:** fixed-step active simulation for player-relevant physics/combat;
- **L1:** reduced individual simulation with staggered/frequency-bucket updates;
- **L2:** cohort/regional aggregate simulation driven primarily by scheduled events;
- **L3:** latent long-horizon state advanced analytically/discretely.

Use event/signal wakeups and dirty-state processing instead of continuous polling when possible.

Start M1 with a simple deterministic priority/deadline scheduler. Add a hierarchical timing wheel only if measurements show timer-queue cost is material at required scale.

Aggregate/active representations must map to one canonical world state.

## AI Pattern

Use:

- hierarchical state-machine/StateTree-like high-level behavior;
- utility scoring at actual decision boundaries;
- smart-object/resource reservations for world interactions;
- shared squad intent/paths in battles;
- sparse relationship graphs;
- batched cohort transitions for distant populations/ecology.

Avoid one continuously ticking large behavior tree per persistent actor.

## Navigation Pattern

Use layered navigation:

- global region/road/portal graph;
- tiled local navmesh for active cells;
- queued/budgeted path requests;
- RVO/local avoidance only for active relevant agents;
- shared corridor/formation intent for groups.

## Consequences

Positive:

- CPU work scales with relevance rather than total world population;
- long time spans can be advanced without replaying frames;
- supports persistent worlds and server restarts/catch-up;
- same domain systems can produce detailed or aggregate outcomes.

Risks:

- promotion/demotion correctness is difficult;
- coarse simulation can diverge from active simulation if contracts are poorly defined;
- scheduling order/nondeterminism must be observable and testable.

## Acceptance Gate

M1 must prove:

- large synthetic scheduled-agent throughput;
- stable CPU/memory behavior;
- active <-> aggregate transition with custody/inventory/state intact;
- compressed 30-day+ runs;
- causal economic/ecological chains;
- no ordinary-noise extinction/death spiral;
- deterministic/reproducible diagnostics for test seeds where practical.
