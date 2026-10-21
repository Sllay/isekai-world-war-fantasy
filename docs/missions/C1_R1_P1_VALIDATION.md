# C1-R1-P1 — integrated foundation validation

## Delivery and scope

Continues A1 `f9dfc54` on `impl/a1-combat-foundation-completion`; the PR #9 base and
main remain untouched. This is one Player/Combat/Skills foundation delivery.
CombatService, ActionExecutor, PlayerIntent, telegraphs, enemies, movement and
persistence are reused. No parallel combat system or Cloud Environment changes.

The initial Git tree was clean. The existing Editor process was reused throughout;
Serena symbol/body/reference queries ran through its prepared stdio server. Serena
reference discovery returned empty results for the inspected symbols, so caller
inspection also used repository search. Diagnostics MCP used the linked Editor
workspace paths to avoid the known original-path duplicate-class alias issue.
Native Serena/Godot tool registration is absent in this agent session; actual MCP
tool calls work through stdio, including Editor and live game execution.

## Gaps closed beyond A1

- Fixed trusted action IDs became a validated typed loadout with primary and
  skill_1/2/3. Slot 3 is genuinely equip-capable but initially empty. Snapshots
  expose detached loadout values. Slot/loadout changes preserve action cooldowns.
- Mouse view projection and generic skill requests feed semantic world-space aim/
  slot intents. Simulation never branches on camera mode or hardware key.
- The existing executor now resolves bounded directional/point target queries,
  revalidates all targets at commit, and spends cost/cooldown once. Tests exercise
  two-target area and directional definitions with the same effect pipeline.
- Lock selection uses authority physics visibility. The integrated test inserts
  a real collider: lock and attack reject; removing it restores line of effect.
- Respawn clears aim, pointer aim, target selection and skill/input one-shots;
  it preserves other actors' stagger instead of clearing the global defense map.
- A failed/rear guard permits valid strong stagger; a successful guard retains
  its contracted protection. Presentation reads the confirmed defense outcome.
- Missing remote transport disables Region recovery as well as the motor. An
  actual remote-mode application test proves no local simulation/persistence
  promotion, even when a local mirror has an unsafe transform.
- HUD state is sampled once per authority tick. Pose updates remain render-rate
  presentation. VFX (eight live flashes) and audio (three voices) stay bounded;
  no global Engine time change or animation-triggered gameplay commit.

## Automated gates

Validated implementation: `29ee999` (Godot 4.7.2). Final results:

- `bash tools/dev/devctl.sh godot-check`: PASS, clean import/parse.
- `bash tools/dev/devctl.sh test affected`: PASS, eight suites / 24 groups /
  716 checks, zero failures.
- `bash tools/dev/devctl.sh test all`: PASS, eight suites / 24 groups /
  716 checks, zero failures.
- Diagnostics MCP/LSP: 23 changed scripts, zero diagnostics; final snapshot
  contract/consumer checks also clean. Editor MCP log: no errors.
- Live Runtime MCP: PASS, 1,031 scenario ticks, 23 confirmed damage facts, guarded
  hit, basic before Skill 1, stagger, enemy recovery/death, one player respawn,
  cleared targeting/aim and a confirmed hit after returning to combat.

The authority suite contains the original 52 checks,
44 C1 extension checks, nine actual remote-runtime checks and 13 integrated
scenario/collider/save checks. Other suites preserve existing domain, physical
movement, enemy, world and persistence regression coverage.

Adversarial coverage includes forged outcomes/actor identity, duplicate/replay,
stale/future commands, queue pressure, invalid/nonfinite aim, unknown/empty slots,
unknown actions, detached values, oversized/duplicate query results, occlusion,
commit-time range change and cooldown bypass through re-equipping. Loopback and
direct deterministic domain outcomes remain equivalent.

The save suites deliberately inject failed writes/invalid snapshots; expected
SAVE_WRITE_FAILED/load rejection diagnostics are exercised failure paths, not
suppressed production errors. Godot script errors/leaks still fail suite runners.

## Live validation and measurement

Reuses `res://tests/worlds/a1_acceptance.tscn`, with a fresh isolated test save and
the same application composition/semantic PlayerIntent ingress as ordinary play.
The controller performs approach/aim, enemy telegraph/recovery, guard, unguarded
damage, basic before Skill 1/strong, valid stagger, enemy defeat, second encounter,
player defeat, safe respawn with cleared target/aim, and confirmed combat after
respawn. Runtime MCP reads the actual scenario result/host state. The numeric
record is [C1_R1_P1_RUNTIME_EVIDENCE.json](C1_R1_P1_RUNTIME_EVIDENCE.json).

Timing captures the active scenario instead of only its idle tail. Application
callback work divided by Core steps excludes separately scheduled physics and
rendering; compare only that scoped p95 with the 25 ms gate. Recorded frame deltas
and the post-scenario profiler describe the shared cloud software renderer. They
do not prove the Android 30 FPS/33.3 ms budget, mobile memory or server capacity.
The cloud frame p95 exceeds that mobile target; this limitation is explicit.
Final active-scenario samples: application p95 1,999.5 us, max 17,583 us across
854 callback samples; frame p95 99,990.7 us across 1,232 samples under shared host
load. Post-scenario engine counters: 63,048,896 bytes static memory, 30 draw calls,
zero orphan Nodes. Engine static memory is not total process/device memory.
One screenshot review confirmed the technical health/energy/slot/cooldown/respawn
HUD fits the viewport. Procedural bodies/weapons are intentional Run 1 placeholders.

## One manual acceptance scenario

Run the ordinary main scene in an Editor/debug build. Move and aim toward the
first skirmisher; read its wind-up, guard with C, receive an unguarded hit, use F
basics and G/1 strong to stagger and defeat it. Approach the second opponent, let
it defeat you, wait for safe respawn and return to fighting. BK judges only control
comfort and whether danger, block/failure, confirmed impact and death/respawn are
clear in this single loop; deterministic state/numeric checks are already automated.

Final Chapter 1 content/three universal skills, refined art/animation/HUD/mobile
UX and real-device acceptance belong to Run 2. Deep AI/perception/interaction,
projectile/ranged arsenals, equipment UI and external A7 transport/prediction are
not claimed by this foundation.

State: FOUNDATION_COMPLETE / ENGINEERING_COMPLETE for the scoped Run 1 technical
foundation. Manual feel/readability acceptance remains pending; final Chapter 1
combat and mobile Player Complete are not claimed. Git contains only intentional
commits; no Environment configuration, main merge or PR #9 lifecycle change.
