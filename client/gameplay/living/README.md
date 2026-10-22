# Living actor and RPG domain

These value services own no SceneTree Nodes, save slot, network gateway or second
Combat/Items implementation. The application composes them behind the same
authority boundary and wraps existing Combatant, ActionExecutor, InventoryService
and EquipmentState persistent contracts.

`LivingActorState.player_state` is the single canonical movement capability.
`actor_id`, `position` and `facing` delegate to it, so a LocalAuthorityHost may use
the same PlayerState without maintaining a second transform. Logical identity,
home/work, needs, activity, allegiance, attributes, XP, memories and sparse
relationship references survive without a runtime body. Health is not copied into
another numeric field; the application retains the corresponding Combatant.

Generated NPC/Bot spawn profiles are nonrenewable in this first scope. Defeat
interrupts their action, movement, cached plan and logical activity; the dead actor
remains canonical across reduced simulation, reload and rematerialization. A
transient Bot host must not apply the Player's automatic respawn policy. Player P1
death/respawn remains unchanged. Future population replacement needs an explicit
authority-owned spawn/repopulation contract rather than recreating missing Nodes.

`LivingCatalog.defaults()` loads typed race/class/progression/faction/visual
definitions. Lookup results are copied. Race historic faction and current actor
allegiance are separate. The race visual profile contains curated LPC-compatible
body/palette/equipment references only; no production LPC pixels/licenses are
claimed by this data proof. `RpgAttributes` applies source-owned additive modifiers
to four representative base attributes. Exact final tuning remains content work.

`LivingProgression.award(cause, source, sequence, definition)` consumes trusted
gameplay causes; there is no arbitrary amount parameter. Persisted monotonic
per-cause/source watermarks reject replay/stale rewards. The first-scope ledger
allows 64 source keys, failing closed rather than forgetting replay protection.
Larger content needs measured durable watermark compaction/grouping, not an
unbounded event log. Root validates source existence and derives sequences from
canonical event state. No client progression-grant ingress belongs here.

`LivingScheduler` keeps one sorted deadline job per logical actor, capped at 256.
`advance(tick, budget=8)` processes only due jobs; it never replays historical
frames. L0 decisions may run each authority tick, L1 every5ticks, L2 every20ticks,
and L3 only deadlines/events. Combat correctness and already-started actions stay
in the existing host/executor, independently from deferrable AI job work. Promotion
and demotion retain canonical state and increment an epoch. Stale runtime intents
and path results must pass `valid_intent_epoch` before authority applies them.

`ActorSpatialIndex` updates on position/cell changes. Local queries inspect bounded
cells/candidates rather than scanning all actors. `LivingPerception.hear` consumes
trusted spatial facts and records knowledge only for nearby L0/L1 observers.
Audio playback/camera visibility never creates knowledge. Memory has 8 ordinary
expiring records plus 2 durable anchors, deterministic replacement and reference
validation. Transient perception/plan caches are absent from saves.

`LivingDecisionModel` combines immediate safety, bounded need/goal scoring and
cached plans. It returns semantic navigation/action/harvest requests. It cannot
settle damage, give items or bypass action eligibility. `LivingPathQueue` provides
32 queued local requests and at most 2 resolutions/tick; World supplies the routing
adapter and validates the current materialization epoch. Long-distance travel is
an analytical activity, not global full-detail pathfinding.

The living runtime materializes at most four actors. It rejects navigation goals
outside Region ownership and tests local arrival on the horizontal plane while
the canonical physics motor settles terrain height. Unavailable local paths retry
at most once per ten Core ticks (2 Hz); a failed route cannot permanently suppress
the same destination. Changed/cleared goals invalidate late queued path results.
Deadline completion wakes relevance even when the Player stands still.

Pure tests: `p3_rpg_tests.gd`, `p3_perception_tests.gd`, `p3_lod_tests.gd`. The LOD
fixture measures 128 logical actors with 2 L0/4 L1 and tests a large time jump. This is
a bounded foundation benchmark, not a claim of final server/Android capacity.
`p3_actor_materialization_tests.gd` exercises the production composition, including
repeated body cycles, stale hosts, shared Player guard, rematerialized Item context,
bounded path recovery and canonical death through latent simulation.
