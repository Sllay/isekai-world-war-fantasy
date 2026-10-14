# ADR-0009 — Production Core runtime and local snapshots

- **Status:** Accepted
- **Date:** 2026-10-14

## Decision

Implement M1.3 Slice 1 in GDScript with explicit module composition in a production Node entry point. Dependencies flow Gameplay -> Foundation -> Core; the loader rejects upward dependencies for Core and Foundation. No directory scanning, gameplay demonstrations, or M1.2 scene dependencies are required.

Modules use stable namespaced identities, declared service contracts and dependency-ordered lifecycle hooks. Registration and initialization are separate phases. All declared contracts must be provided before initialization. Optional dependencies may be absent or feature-disabled; selected modules with startup failures abort and unwind visibly. Automatic recovery from a broken selected optional module is deferred until a concrete recovery contract exists.

Events use CoreEvent-derived scripts as exact dispatch types, typed payload subclasses, subscription tokens, synchronous subscription-ordered delivery and bounded recursion. Subscription changes during dispatch have defined semantics. Recent diagnostics are bounded in memory.

Core owns stable entity identity. Foundation owns the minimal entity capability container. Components, schema validators and persistent module state remain owned by their modules.

The world/game clock uses fixed integer ticks and retained fractional/backlogged time. The deadline scheduler uses a deterministic binary heap, token tie-breaking and bounded queue examinations per frame. Consumers choose initial deadlines to stagger work. Callback schedules are transient; persistent modules save semantic deadlines and reconstruct callbacks after load. No world simulation fidelity rules are implemented.

The local save adapter uses JSON snapshots with format and per-module section versions, plus world/game/module metadata. Loading migrates and validates every section before applying any state. Module validation must be pure, and restore must be infallible for validated state. Unknown or missing module sections fail explicitly. Files are flushed to a sibling temporary path before rename. This is a local snapshot adapter, not a transactional authoritative server storage implementation or a replacement for ADR-0008's server direction.

## Consequences

- Core can run alone, without gameplay or presentation assets.
- Modules must treat manifests as immutable after discovery, declare dependencies, release subscriptions/jobs during disposal, and retain resolved services during initialization.
- Save values must be JSON-safe. Integer values are restricted to the exact JSON number range (absolute value <= 2^53 - 1); large identifiers use strings. Concurrent writes to the same save path are unsupported. Filesystem crash durability and Web storage synchronization need platform-specific follow-up.
- Callbacks cannot be serialized. Module restore ordering follows dependencies, with Core clearing transient schedules before dependent modules rebuild them.
- Call budgets bound queue work, not callback duration. Profiling must precede scheduler optimization or budget changes.
