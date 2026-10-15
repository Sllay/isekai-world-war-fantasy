# ADR-0012 — Production local save/resume orchestration

- **Status:** Accepted
- **Date:** 2026-10-15

## Decision

Keep save timing, slot/startup policy, cross-section integrity and physical Region
reattachment in the application runtime. Core remains a generic snapshot adapter;
expose its existing migrate/validate stage as non-mutating `prepare_restore` so
application checks can run before any live mutation. Use full-precision JSON for
canonical clock fractions and the existing flushed temporary sibling/rename write.

Provide one injected local slot, `local.current` at `user://saves/current.json`.
Only a missing slot starts a new game. An existing invalid slot blocks startup
and writes visibly; never fall back to an automatic new game that overwrites it.
Version/content/identity checks run on every save and resume. Current game/module
versions must match exactly; later compatibility changes require explicit policy.

Validate before unloading residency. Restore sections in dependency order, then
reattach through Region's existing resume path, preserving Player ID/position/
velocity and the shared Core clock. Keep a previous canonical snapshot for
rollback if attachment fails. Saving is synchronous on the main thread, without
unloading residency, background mutation or yielding during snapshot operations.

Expose the same save API to explicit controls and lifecycle adapters. Normal
close/back saves before quitting; application pause makes a best-effort save.
Do not save blindly from teardown or assume Android guarantees notifications.

## Consequences

Core has no knowledge of World/Player integrity or application slot policy.
Player, World and Region schemas and ownership remain unchanged. Player validation
now also rejects numbers that overflow its physical Vector3 representation; Core
clock validation bounds exact JSON ticks and safely clamps large saved backlogs. The actual disk
path is proven across independent Godot processes, with corruption/write failures
covered separately. Multiple slots can use another LocalSaveSlot without changing
module persistence; cloud/server storage, multi-writer coordination, Web storage
synchronization and filesystem power-loss durability remain outside this slice.
See `../architecture/SAVE_SYSTEM.md` for contracts, failure codes and acceptance.
