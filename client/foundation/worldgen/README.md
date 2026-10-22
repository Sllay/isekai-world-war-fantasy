# World genesis domain

These are pure data contracts attached by the application's existing World/Region
composition. They own no Node, physics object, clock, file, save format or second
SaveManager.

- `WorldBlueprint.create(world_id, seed, chunk_size=32, coord_limit=4,
  authored_resources=[])` creates versioned logical identity and macro metadata.
  Pass the existing P2 resource catalog as integer-millimeter descriptors; do not
  duplicate its definitions. Restore loads the persisted blueprint instead.
- `WorldGenesis.generate(blueprint, coord, tick, region_id)` creates a detached
  validated `ChunkRecord`. Terrain/resources/spawns use independently derived
  SHA256 streams. Feature IDs are namespaced hashes; actor IDs are stable 32hex
  IDs compatible with existing Core identity storage. The center preserves the
  P1 ridge and imported P2 resources. The configurable grid has 9x9 samples;
  sample values and feature positions use integer millimeters.
- `ChunkLedger.configure(blueprint, commit)` binds the existing durable save
  transaction callback. `request(coord,tick)` returns existing persisted records
  without invoking the generator. Missing chunks reserve their identity, generate,
  validate, stage a complete candidate ledger, call `commit(candidate)->Error`,
  and publish only after success. Reentrant requests return GENERATION_BUSY;
  failures release the reservation and publish no partial data.
- The callback is an adapter to CoreSaveStore/SaveCoordinator, not another file
  path. The application replaces its candidate world section before preparing
  and atomically writing the ordinary save. There is no SceneTree mutation in
  generation or validation.
- `mark_modified(coord,expected_revision,patch)` accepts typed monotonic
  `removed_resources`/`spawn_claims` references only. Immutable generated base/hash
  stays separate. Dirty chunks are acknowledged after the application's safe
  batched save; no rewrite is triggered merely by movement or each simulation
  frame. P2 remains owner of harvest/yield/depletion, which is not duplicated here.
- `capture/validate_state/restore` preserve canonical blueprint/chunks and reject
  bad checksum, world/region/version/ID/reference data without fallback generation.
  JSON integer-valued floats normalize before exact data/hash comparisons.
- `StreamingRelevance.plan` is bounded active/prefetch/unload policy. The adapter
  alone creates/frees runtime scenes, acknowledges materialization, and enforces
  collision/navigation readiness. Policy defaults: radius1, ring1, 12-tick
  hysteresis, one materialization/frame, 25 resident chunks maximum. Residency is
  transient and never substitutes for canonical persisted records.

`generation_invocation_count`, persisted reads and generation/load costs are
instrumentation, not persisted gameplay state. `p3_worldgen_tests.gd -- --hash-only`
prints canonical hashes/IDs for independent OS-process determinism comparison.
The domain tests cover staged failure, concurrent requests, mutation persistence,
zero generation on restore/read and repeated bounded streaming policy transitions.
The application/runtime suites separately prove actual storage and scene lifecycle.
