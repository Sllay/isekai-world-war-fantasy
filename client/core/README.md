# Production Core — M1.3 Slice 1

`GameRuntime` is the production entry point. It composes `core.runtime`, boots the module registry, advances the clock/scheduler and shuts modules down on exit. The M1.2 bootstrap scene remains untouched and is not a dependency.

Responsibilities are split between lifecycle/graph validation, services, events, identities, data, clock, scheduler, flags, diagnostics and snapshots. `CoreRuntimeServicesModule` only wires the services and owns the identity/clock save section. The capability container lives in `foundation/entity_components.gd` and depends only on Core identity/namespace contracts.

## Module integration

1. Subclass `CoreModule`, declare stable ID/version, required/optional module IDs, provided services, event/data declarations, feature flag and persistent section version. Manifests are immutable once discovered.
2. Add modules to the registry before `boot()`. Configure feature flags before validation. Missing required dependencies, cycles, duplicate contracts and layer violations fail visibly; status dictionaries expose results.
3. Provide services in `register()`. Resolve declared dependencies during `initialize()` and retain the references needed at runtime. Service resolution outside a lifecycle owner scope is deliberately unavailable.
4. Define event scripts derived from `CoreEvent` with typed payload fields. Register their exact script types, subscribe with valid Callables, retain tokens and unsubscribe in `dispose()`. Emit stable source IDs and simulation ticks. Delivery is synchronous; new subscriptions start with the next publication, removed subscriptions are skipped immediately.
5. Register data families with pure validators, then definitions. The registry rejects duplicate IDs and returns deep copies. Cross-definition reference validation belongs to the owning family.
6. Use explicit scheduler deadlines/intervals in clock ticks. Equal deadlines use registration order. Overdue recurring jobs keep their original cadence and catch up over bounded frames. Cancel jobs at module disposal. Callback duration must remain small; the queue budget cannot preempt a callback.
7. Persistent modules implement capture, pure validation, infallible restore and one-version migration steps. Save semantic state/IDs, never Nodes or presentation defaults. Sections are restored in dependency order. Reconstruct persistent schedules during restore after Core clears transient jobs.

## Validation

Run `bash tools/dev/test_core.sh` from the repository. It imports scripts, runs focused tests, verifies the actual main scene with `--core-smoke`, and runs ten runtime frames. The runner checks both process status and engine error output because GDScript errors may otherwise return exit code zero.

## Slice 2 integration points

Add a `foundation.player` module requiring `core.runtime`. Allocate/reuse its stable entity ID through `core.entities`; compose movement/input/presentation capabilities using the Foundation container. Register movement tuning as validated namespaced data. Persist canonical player state in its own versioned section, publish typed player facts with IDs/ticks, and release subscriptions/schedules on shutdown. Resolve services during initialization. Presentation must not define authoritative transform/state defaults on load.

The local save foundation and production disk-backed player/world resume are implemented. `prepare_restore` exposes non-mutating migration/validation to the application coordinator; cross-section game policy remains outside Core. See `docs/architecture/SAVE_SYSTEM.md` from the repository root. No Android/Web performance claim is made by the headless checks. Durable server storage, platform crash recovery, persistent gameplay schedules, schema reference tooling and runtime inspector UI remain future integration work.
