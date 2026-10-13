# ADR-0008 — Persistence and Transactional World State

- **Status:** Proposed — selected for M1 proof
- **Date:** 2026-10-13

## Context

The world requires durable actors, inventories, lots/stacks, unique items, economy, relationships, settlements and scheduled events. Server restart, retries or fidelity transitions must not duplicate or silently delete canonical state.

## Decision

### Storage candidates

- M1/local/test: current **SQLite** release that contains the 2026 WAL-reset fix (minimum 3.51.3; prefer latest stable).
- Production target: **PostgreSQL 18+**.

Both are accessed through project-owned storage/repository interfaces rather than direct SQL from gameplay modules.

### Persistence model

Use:

- current snapshots/state tables for fast restore;
- versioned schemas/migrations;
- stable world IDs;
- durable scheduled events where necessary;
- bounded domain/audit journal for important history;
- explicit transactions for custody/economy mutations.

Do not event-source every movement/physics frame forever.

### Economy correctness

- currency uses integer smallest units;
- explicit sources/sinks;
- double-entry-style ledger for important currency transfers;
- idempotency keys for externally retryable commands;
- reconciliation/invariant checks.

### Item custody

- one canonical holder/container per individual item;
- revision/version for conflict detection;
- atomic source removal + destination addition;
- fungible lots conserve quantity and never become negative;
- multi-party trade uses reservation/escrow semantics.

## Consequences

Positive:

- local development stays simple;
- production has a mature transactional database and partition/replication options;
- gameplay is not coupled to one DB vendor;
- duplicate/lost item bugs become explicit invariant violations rather than silent state drift.

Risks:

- authoritative in-memory ECS state and durable state need carefully defined commit/checkpoint boundaries;
- excessive synchronous writes could become a bottleneck;
- overusing journals/events would create unnecessary storage/restore cost.

## Acceptance Gate

M1 must prove:

- save/restart/load equivalence;
- one schema migration;
- item multi-owner custody chain without duplication;
- ordinary lot/inventory state without reset;
- idempotent duplicate command handling;
- transaction failure/retry safety;
- synthesized bag/condition-layer persistence;
- observability of invalid/orphan/duplicate state.
