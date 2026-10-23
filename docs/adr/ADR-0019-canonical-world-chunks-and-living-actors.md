# ADR-0019 — Canonical generated chunks and logical living actors

- Status: Accepted for C1-R1-P3 implementation; delivery validation tracked by the mission
- Date: 2026-10-22

## Context

P3 must extend the accepted Player/Combat and Items/Resources foundations into a
persistent living world. A seed alone cannot preserve a harvested node, a moved
actor or compatibility with an older generator. Keeping every persistent actor
in the SceneTree would also tie logical population to physics and presentation
cost. Neither concern justifies another WorldState, SaveManager or authority path.

## Decision

Use `WorldGenerationModule` beside the existing `WorldModule` and `RegionModule`.
`WorldBlueprint` records world identity/seed, generator ID/version, content schema,
logical creation metadata and the bounded first-region profiles. Domain-derived
streams isolate terrain, resources and spawns. Generated feature IDs derive from
the same stable inputs; generated actor IDs remain compatible with Core entity IDs.
Region-owned chunk addresses retain the existing `region_id:x:z` contract.

`ChunkLedger` first checks its restored canonical records. A missing address is
reserved, generated, validated, baked and durably committed through the existing
`SaveCoordinator.commit_section` before installation. Failed generation or commit
installs nothing. Duplicate in-flight requests reject. A persisted request loads
the record without invoking the generator, including after a fresh process. A
different generator version fails compatibility checks; it never reinterprets an
existing world. Baked base descriptors have a canonical hash; mutable monotonic
deltas track removed resources and claimed spawns with revision validation.

`ChunkStreamer` converts descriptors into transient terrain/resource presentation.
The first attachment establishes nearby collision before Player physics; later
frames bound materialization/data jobs and unload work. Active radius, prefetch
ring, resident cap and spatial/tick hysteresis belong to `StreamingRelevance`.
P2 `ResourceService` still owns yields, tools, inventory and depletion. Placement
registration is idempotent and cannot reset existing reserves. Typed committed
harvest facts update the corresponding permanent-depletion chunk delta. Persisted
spawn claims bind logical actors and prevent reload from creating replacements.

Persist these contracts as two additional versioned sections of the same Core
format-1 logical snapshot: `foundation.world_genesis` and `gameplay.living`.
Application version 0.5.0 explicitly migrates an exact supported 0.4.0 P2 snapshot
by introducing an empty generated ledger and initial RPG identity, preserving the
six existing sections. Current missing sections and corrupt cross-references fail
before any live state or residency changes.

`CoreSavePages` is a generic physical adapter under `CoreSaveStore`. Selected chunk
and actor dictionaries use immutable content-addressed record pages; the ordinary
atomic slot-manifest replacement is the commit point. The complete logical
snapshot still passes the existing validators. Unchanged records reuse pages;
fractional values have a lossless codec so reload cannot create false dirty
records. Missing/corrupt pages reject. Unreachable pages retire after a successful
commit. Capture and validation still inspect the bounded first-scope snapshot;
this decision does not claim incremental capture or database-scale storage.

`LivingActorState` and `LivingCapabilities` own persistent actor data independently
of Nodes: identity/location, canonical movement, existing combat/actions/items,
RPG identity, faction, sparse relationships, capped durable memory and activity
deadlines. `LivingRuntime` materializes relevant actors with transient bodies and
hosts. Promotion/demotion preserves their data and increments an epoch so stale
active intents cannot apply after a representation change.

`LivingScheduler` uses deterministic bounded due jobs: L0 active, L1 reduced
individual decisions, L2 scheduled aggregate/activity work and L3 deadline-only
resolution. Elapsed travel/activity resolves analytically rather than replaying
historical frames. The first-scope L2 seam does not implement a village economy.
Reactive safety and bounded utility selection use cached plans; hearing facts and
spatial observations supply knowledge rather than Node existence. Durable memories
have ordinary/anchor caps and reference validation; transient plans/LOS caches
are excluded from saves. Local paths use a bounded queue over materialized chunks;
the initial open-terrain corridor is replaceable by an obstacle-aware adapter.

Player-like Bots produce authority-owned semantic intents through
`LocalAuthorityHost.submit_authority_intent`. This uses the existing payload,
action, item and lifecycle validators with actor/epoch checks, without simulating
a network client or granting trusted result fields. Hosts share the existing
defense authority, so attaching a Bot cannot replace the Player guard resolver.
XP consumes trusted canonical gameplay facts with definition-owned amounts and
persisted source/sequence replay protection. Clients have no XP/world grant API.
Class starting actions seed the existing learned-skill source ledger; class
equipment tags supply a generic authority-context eligibility predicate consumed
by the existing item port before mutation. Learned skills keep their independent
sources, and Foundation does not depend on Gameplay class definitions.

## Consequences

World genesis, persistent truth, streaming, actor existence and presentation have
separate ownership. Run 2/3 can add content, visual fidelity, obstacle navigation,
broader ecology and regional activity adapters without replacing P1/P2 contracts.
The initial limits are explicit budgets, not claims of final server capacity.
Generation/load/materialization, page reuse, scheduler, perception and path metrics
remain available to tests and runtime inspection.

Tests must prove deterministic hashes/IDs across processes, zero-generator fresh
reload, persistent mutations, bounded streaming, actor identity preservation,
adversarial rejection and P1/P2 regression. Runtime MCP and final release checks
remain separate mission gates; this ADR records the implementation decision rather
than declaring those gates passed. See [P3 mission](../missions/C1_R1_P3_FOUNDATION.md)
and [save contracts](../architecture/SAVE_SYSTEM.md).
