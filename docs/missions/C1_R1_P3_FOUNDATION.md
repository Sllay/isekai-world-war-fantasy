# C1-R1-P3 — World, RPG & Living Entities Foundation

Status: FOUNDATION COMPLETE / ENGINEERING COMPLETE; Android acceptance pending.
Issue #11, Chapter1 / Run1 / Part3, one integrated macro. Deterministic gates,
real stdio Runtime MCP and fresh-process resume passed. This is the scoped Run1
foundation, not final Chapter1 content or device performance certification.
P2 base `c06d513e1df6705016c4f70f78b0e1232bb9b958`; approved GDD/LPC/offline
direction `7d3f394208c3973ea0752b2084da1b1f19288afd` merged only into
`impl/c1-r1-p3-world-rpg-living`. Both ancestry gates passed. Preserve main/P1/P2,
PR#9 and the existing FULL Environment. No final art, lobby or offline-sleep system.

## Invariants and ownership

Generate once; persist canonical state; materialize by relevance; simulate
causality at the cheapest correct fidelity. Clients request, authority decides.
WorldModule retains identity/time; RegionModule retains spatial/residency ownership.
WorldGenerationModule supplies a separate genesis/canonical-chunk capability,
not another WorldState or save engine. CoreSaveStore/SaveCoordinator retain the
single versioned snapshot/prepare/restore/atomic-storage contract.

WorldBlueprint stores generator ID/version, seed, content schema, logical creation
metadata and a bounded first-region profile. ChunkLedger separates immutable baked
terrain/resource/spawn/navigation base from mutable revisioned deltas. Requesting
persisted data never calls the generator. Generation stages validated records,
commits through the existing save boundary, then installs/materializes. Duplicate
requests/reservations, incompatible versions and corrupt references reject visibly.

The older World Generation doc allows reconstructing unchanged geometry from
seed. This mission takes precedence: persisted baked descriptors are canonical;
runtime reconstructs meshes from those descriptors, never by invoking worldgen.
Authored Home Valley starting constraints preserve P1/P2 terrain/resources; seeded
outer chunks prove variation and extensibility. Chunk size remains Region-defined
(32m first-scope), active radius1, prefetch ring1, twelve-tick unload hysteresis
outside that ring and a 25-view cap. First attachment establishes nine collision
chunks before Player physics. Subsequent frames bound work to one materialization/
data job and one unload. Cold work yields to active actions/P1 threats, and idle
prefetch is spaced by four Core ticks. Prefetch persists spawn candidates; first
active relevance commits their logical actor birth. Existing actors keep living
after dematerialization. The blueprint bounds the first Region to coordinates
[-4,4] on both axes; this is a first-scope capacity, not a final world-size decision.
No final continent, hydrology/caves/settlements or complex ecology is claimed.

Persistent logical actors compose PlayerState, existing Combatant/ActionExecutor,
InventoryService/EquipmentState, typed RPG identity, faction, memory and activities.
Nodes are transient. NPC reactive/utility decisions consume bounded spatial/event
perception; durable memory has caps/expiry/anchors. L0 active, L1 reduced,
L2 aggregate and L3 deadline work preserve identity/custody/health/activity.
Bot producers use an authority-only semantic ingress into the same host/action/
item validators, without pretending to be clients or directly applying outcomes.
`LocalAuthorityHost.submit_authority_intent` validates actor and materialization
epoch before those shared validators. Its defense authority is the same instance
used by Player/P1 enemy hosts; Bot attachment cannot replace the guard resolver.

Living runtime has four-body maximum and 24m enter/28m leave hysteresis, gated by
active chunks. The deterministic scheduler accepts up to 256 logical actors,
consumes at most eight due jobs per advance, runs L0 each tick, L1 every five ticks
(4Hz at the existing 20Hz Core step), L2 every twenty ticks and L3 at deadlines.
Fidelity transitions retain capabilities and increment an epoch. L2 proves the
regional/activity seam without claiming a village economy. Path work uses a
32-request queue/two resolutions per tick; first-scope open-terrain corridors are
validated over materialized chunks, not a global navmesh or finished obstacle AI.

One representative human/warrior, separate origin/history/allegiance, LPC-compatible
RaceVisualProfile reference, source-based attributes, trusted-event XP/reward
deduplication and sparse dispositions prove RPG. Procedural placeholders remain
presentation; they do not implement or contradict the approved final LPC pipeline.
XP amount comes from definition-owned canonical event causes, with persisted
source/sequence watermarks. Durable memory holds eight ordinary records and two
anchors with expiration/replacement and canonical-subject validation. Trusted
hearing and indexed observation change knowledge/plans; Node existence does not.
Class starting actions now seed the existing LearnedSkillSet rather than a copied
hardcoded list. Class equipment tags feed the same authority item port used by
Player/Bot, with validation before equipment/combat mutation; later learning is
not constrained to the starting list. Context disposal releases transient policy
callbacks and rematerialization reinstalls them from canonical class identity.

Committed resource harvesting produces non-threatening hearing records and an
NPC inspect activity; attack facts remain a separate threat/shelter response.
Generated NPC/Bot spawns are nonrenewing in this scope. Defeat interrupts their
activity and persists death through demotion/reload; it never borrows the Player's
automatic respawn. The existing Player death/respawn contract is retained.

## Persistence and performance

App0.5.0 has eleven modules/eight sections and explicitly migrates exact supported
P2 App0.4.0 saves once; all six old sections remain unchanged, new generated chunks/
actors start empty, and migration preparation invokes no generator. Current missing
P3 sections reject. Persist blueprint, baked records/deltas, actor state/combat/items, faction,
RPG/progression, durable memory and activity deadlines; not Nodes, visibility caches
or active casts. Cross-check world/region/chunk/actor/owner references before live
or residency mutation. Player RPG data does not duplicate the existing Player
health/actions/items ownership. Dirty chunk acknowledgment follows safe checkpoints.
Generic `CoreSavePages` is now wired into `CoreSaveStore` for `chunks` and `actors`
dictionary members while preserving the same logical format-1 snapshot and atomic
manifest commit. A lossless record codec enables exact reuse after hydration;
unchanged records write zero pages and one changed actor writes one page.
Unchanged installed chunks and actor records reuse bounded structural-validation
proofs; detached application ownership/memory/progression references are always
checked again against the current complete snapshot. Definition catalogs are
fixed for the runtime; restore/dispose clears actor proof caches. Missing/
corrupt pages reject. Full bounded snapshot capture/validation remains synchronous;
this is incremental record I/O, not an unmeasured database-scale claim.

A brand-new world durably commits its initial nine chunks during loading, before
their collision is attached. `NO_SAVE` still describes the startup input; it no
longer promises that world genesis leaves the slot absent. Named legacy migrations
remain read-only until explicit Save. Confirmed Delete Save retains the old unsaved
P1/P2 reset preview, with genesis deferred until explicit Save; pause/exit cannot
silently recreate a deleted slot. Restart tests compare hydrated logical snapshots,
not the storage manifest's page references. These are explicit P3 fixture updates,
not relaxed combat, custody, migration or corruption assertions.

Measure generation/load/materialize/unload, bounded resident chunks/bodies, memory
round trips, scheduled decision/path/perception counts and save delta. Bounded
main-thread scene work only; no SceneTree manipulation from workers. No global
AI scan/planner per frame or all-pairs perception. Preserve correctness under
budget deferral; long elapsed time resolves deadlines without historical replay.

The implementation decision and its extension limits are recorded in
[ADR-0019](../adr/ADR-0019-canonical-world-chunks-and-living-actors.md),
[SAVE_SYSTEM](../architecture/SAVE_SYSTEM.md) and
[DATA_ARCHITECTURE](../architecture/DATA_ARCHITECTURE.md).

## Implemented automated evidence paths

Separate suites cover `p3_worldgen_tests`, `p3_chunk_tests`, `p3_streaming_tests`,
`p3_save_pages_tests`, `p3_lod_tests`, `p3_perception_tests`, `p3_rpg_tests`,
`p3_bot_authority_tests`, `p3_actor_materialization_tests` and
`p3_persistence_tests`. They exercise pure contracts and the production composition
at their owning boundary. Explicit trusted test fixtures may instantiate domains;
they do not add a production client grant API.

`p3_restart_process.gd save|resume --p3-slot=/absolute/isolated-slot.json` is the
two-OS-process persistence proof. The save phase commits generated chunk (3,0),
depletes its mineral through the existing P2 ResourceService and committed fact
contract, and persists inventory/equipment plus two logical actors with health,
durable memory and progression. The fresh resume must preserve canonical hashes,
leave the mineral depleted, produce no duplicate actor, invoke worldgen zero times
and write zero unchanged pages. This deterministic fixture is distinct from the
required semantic gameplay scenario through Runtime MCP.

The production persistence suite also tests exact P2 migration, missing current
sections, incompatible generator version, corrupt base hash, world/Region/chunk
ownership, P2 placement/profile mismatch, orphan memory/faction/entity/reward
references, forged client world/XP requests, authoritative combat XP and reward
replay across resume. Invalid disk resumes must preserve every live section and
the current resident scene. Dirty-write tests measure unchanged saves, one changed
actor and unchanged save after hydration.

Final Godot Check passed. Both affected and all passed ten suites/44 test groups,
1,597 checks each, including 516 P3 checks and P1/P2 regressions. Diagnostics/LSP
returned no findings across 68 scripts. Actual stdio Runtime MCP proved the played
scenario, exact eight-section fresh-process resume with zero generator calls,
and semantic return/rematerialization without identity/custody/health/faction loss.
Checkpoint `bdad904b0beb05a05e46e9c6b1f9c856b03a9fe3` was pushed and its remote
SHA verified before the final gates, as requested. Detailed command/measurement
evidence is in [validation](C1_R1_P3_VALIDATION.md) and the adjacent machine-readable
runtime evidence. Cloud timings establish first-scope costs only; device FPS,
control comfort and presentation readability require the one Android outing.

## Completion gates

Separate deterministic suites for worldgen, lifecycle/persistence, streaming,
materialization/LOD, perception/memory, RPG/faction and Bot authority. Prove seeded
hash/stable IDs across processes; fresh-process chunk reload with zero generator
calls; persistent resource mutation; A-B-C-D-return bounded residency/memory;
128 logical actors with few active; long-time advancement and all adversarial
cases in the user/issue. Run Godot Check, affected and all; P1/P2 regression blocks
completion. Actual Runtime MCP must prove the integrated genesis/stream/perceive/
Bot/progress/mutate/save/new-process-resume loop. Publish P3 and verify remote SHA.
Android acceptance, if needed, is one integrated outing for subjective/device
behavior. Final content/presentation/balance is Run2/3; external transport is A7.
