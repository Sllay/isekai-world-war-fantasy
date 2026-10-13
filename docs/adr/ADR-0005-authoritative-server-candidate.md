# ADR-0005 — Authoritative Server Candidate: Rust + ECS

- **Status:** Proposed — selected for M1 proof
- **Date:** 2026-10-13

## Context

The persistent server must simulate large amounts of mostly non-visual state: actors, cohorts, regions, inventories, economy, population, ecology, war, scheduled events and network relevance. Representing all of this as graphical engine Nodes would couple server cost to presentation architecture.

## Decision

Prototype the authoritative simulation as a separate **Rust** service using **bevy_ecs 0.20** as the first ECS candidate and **Tokio** for asynchronous networking/I/O.

Godot remains the client/presentation runtime. Domain IDs/contracts are shared conceptually; SceneTree objects are not the canonical server representation.

Persistent world IDs are separate from transient ECS entity handles.

## Consequences

Positive:

- compact data-oriented simulation;
- parallel execution of non-conflicting ECS systems;
- no GC pauses;
- strong type/thread safety;
- simulation can run headless without rendering/node cost;
- client and server can scale/change independently.

Costs/risks:

- two-language stack (GDScript + Rust);
- explicit network/schema boundary required;
- more initial tooling than a single Godot project;
- bevy_ecs version changes must be isolated behind project abstractions.

## Alternatives Considered

- Godot dedicated/headless server: retained as a useful prototype/fallback, but not preferred for the large persistent simulation because SceneTree/game-object patterns encourage unnecessary object overhead.
- Custom ECS from scratch: rejected unless profiling proves a mature ECS unsuitable.
- C++/EnTT/Flecs: technically viable; Rust chosen first for safety, async ecosystem and maintainability.

## Acceptance Gate

Change to `Accepted` only after M1 proves:

- scheduler/entity throughput and memory targets;
- save/restart consistency;
- authoritative network flow;
- aggregate/active state transitions;
- modular feature boundaries;
- profiling/observability viability.
