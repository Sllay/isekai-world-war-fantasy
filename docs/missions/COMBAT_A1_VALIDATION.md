# A1 combat foundation — integrated acceptance

Branch: `impl/a1-combat-foundation-completion`, based on PR #9 commit
`3f70dd49a8c9d060777a5f168aafb9e46729a7fe`. No merge into main or PR closure.

## Implemented scope

Reuses CombatService, ActionExecutor, PlayerIntent/Motor, targeting, telegraphs,
Region actor persistence and SaveCoordinator. PlayerAuthorityAdapter sends strict
semantic commands to AuthorityGateway; LocalAuthorityHost owns validation and
canonical state. Loopback is explicit development configuration. Release or
`--authority-remote` cannot turn disconnection into local authority.

Ingress binds a session to its actor; validates version/sequence/tick/schema and
finite bounded values; rejects forged outcomes/transforms, duplicates/replays,
stale/future ticks and full queues (eight queued, four consumed per tick).
Content/loadout derive damage and costs. Commit checks lifecycle, range, LOS,
disposition, resources, cooldown and defense. Snapshots are value copies; the
mirror reconciler rejects obsolete corrections. Remote A7 transport/authentication
productization and full prediction/replay are outside this mission.

Representative one-handed basic/strong attacks, guard, dodge, regeneration,
strong-only stagger with immunity, enemy wind-up/recovery, procedural sword/body
reaction, impact flashes, visual-only 40 ms pose holds and synthesized SFX form
the playable loop. Presentation never commits gameplay. The HUD distinguishes
incoming damage, confirmed hits, defense results, health/energy and death.

Defeat waits 30 host ticks; respawn uses authored `entry.respawn` outside enemy
acquisition range, restoring coherent health/resource/motion/input while retaining
committed action cooldowns. Player Combat section v3 retains dodge reuse/stagger
immunity; active defense windows/casts remain transient. App version 0.3.0
explicitly migrates 0.2.0 saves to add the second persistent opponent without
resetting existing damaged/defeated actors. Missing current actor data rejects.

## Automated and live validation

Engineering evidence: eight suites, 659 executed checks, zero failures; clean
Godot import, affected-test selection and complete regression. Live Runtime MCP
confirmed one guarded hit, strong stagger, enemy defeat, Player death, one safe
respawn and return to combat (23 confirmed damage facts in the representative
run). Machine-readable evidence is in COMBAT_A1_RUNTIME_EVIDENCE.json. The recorded
post-scenario application-tick window had p95 1.233 ms/max 3.587 ms (128 samples); this is a
single-player/two-opponent cloud sample, not a hardware capacity or Android claim.

```bash
bash tools/dev/devctl.sh godot-check
bash tools/dev/devctl.sh test affected
bash tools/dev/devctl.sh test all
```

`test_authority.sh` includes adversarial/domain proofs and a real-physics scenario
using PlayerIntent. Existing movement regressions now cross an authority tick;
identity checks expect two opponents. Scenario tests additionally cover
save/resume, migrations and retained defense cooldowns.

Run `res://tests/worlds/a1_acceptance.tscn` through Runtime MCP. Its bot uses only
PlayerIntent in an isolated fresh slot. Query the GameRuntime node's
`scenario._mcp_state()` and require guard, stagger, death, respawn, reentry and
`result.passed`. `timing_summary()` provides a bounded 128-sample application-tick
window. This is not a whole-server, scale or Android performance benchmark.

Serena symbol discovery/references and Diagnostics MCP were used. The editor
opens a local linked view; diagnostics on original absolute URIs can falsely
report a global class hiding its linked copy. Editor-view URI diagnostics and
clean headless imports are the effective parser evidence. No Environment or
versioned Serena configuration was modified to work around this alias.

## Single remaining human acceptance scenario

Play normal `res://scenes/runtime/game_runtime.tscn`, preferably on Android, not
the automated bot world. Move/turn/approach; read a wind-up; guard one attack;
take one unguarded hit; land basics and a strong stagger; defeat the first enemy;
approach the second and let it defeat you; observe death/safe respawn; return and
land a hit. Desktop: WASD, Q/E or right-drag camera, T target, F basic, G strong,
C held guard, V dodge, H heal. Touch controls use the same semantic intents.

Judge only control comfort, telegraph/recovery readability, reaction/impact/
hit-stop/audio feel and device performance. Deterministic outcomes are automated.
This subjective/device acceptance remains the Player Complete gate. Primitive
silhouettes are representative foundation presentation, not final character art.
