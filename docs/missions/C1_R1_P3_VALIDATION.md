# C1-R1-P3 validation

P2 base: `c06d513e1df6705016c4f70f78b0e1232bb9b958`. Approved GDD direction:
`7d3f394208c3973ea0752b2084da1b1f19288afd`, integrated by `def8758` only in
`impl/c1-r1-p3-world-rpg-living`. Issue #11. No main merge, PR closure or
Environment reconfiguration belongs to this delivery.

## Deterministic gates

`tools/dev/test_world_living.sh` registers separate worldgen, lifecycle,
streaming, RPG/faction, perception/memory, LOD, Bot authority, production actor
materialization, immutable save pages and production persistence suites. It also
compares canonical hashes/IDs from independent Godot processes, runs the semantic
play scenario and launches two separate OS processes for save/reload proof.

Production corruption cases reject before mutating live state or residency.
Coverage includes forged world/XP changes, stale chunk revisions/actor epochs,
duplicate generation/reservation/materialization/reward, invalid generated and
faction/memory/ownership references, corrupt persisted pages/chunks, and Bot
commands rejected by the same combat/item validators as Player commands.

P1/P2 fixtures retain their gameplay/custody/security assertions. Exact legacy
fixtures strip the two new P3 modules/sections. Restart proofs compare hydrated
logical snapshots rather than physical page references. First genesis now commits
canonical data before terrain, while legacy migration reads and Delete Save retain
their previous no-overwrite/no-recreation guarantees. No warning suppression was
introduced. The lossless manifest/record codec preserves tiny clock fractions.

Final release gates on implementation checkpoint
`bdad904b0beb05a05e46e9c6b1f9c856b03a9fe3` (published before these gates):

| Gate | Result |
| --- | --- |
| `bash tools/dev/devctl.sh godot-check` | PASS, exit 0; import/parse clean |
| `bash tools/dev/devctl.sh test affected` | PASS, exit 0; all ten suites selected; 1,597 checks / 0 failures |
| `bash tools/dev/devctl.sh test all` | PASS, exit 0; ten suites, 44 groups, 1,597 checks / 0 failures |
| P3 subset in each test command | 516 checks / 0 failures, including the independent-process/restart proofs |
| P1/P2 regression | PASS, including authority, combat/guard/death/respawn, items/resources/crafting and persistence |
| Diagnostics/LSP | 68 affected scripts, no errors or warnings |
| Actual stdio Runtime MCP | PASS: play, save, fresh OS process, exact resume and semantic rematerialization |

The final persistence codec preserves both integer/float types and exact float
bits, including integral floats and the tiny clock fraction. This preserves P1/P2
safe-position, drop and migration equality checks without relaxing validators.
All commands above were run after the requested checkpoint push; the working tree
was clean at that checkpoint. No new agents or Environment changes were used.

Machine-readable per-group counts, canonical determinism hashes, runtime proofs
and metrics: [C1_R1_P3_RUNTIME_EVIDENCE.json](C1_R1_P3_RUNTIME_EVIDENCE.json).

## Actual Runtime MCP

`res://tests/p3_acceptance.tscn` uses the production root and an isolated slot.
`p3_scenario_driver.gd` produces only semantic PlayerIntent and bound-session
AuthorityGateway requests. It does not teleport, inject memory, grant stock,
edit health, grant XP or advance the clock directly. Bot decisions execute through
LocalAuthorityHost's trusted semantic ingress and the same P1/P2 validators.

The scenario defeats a P1 enemy, picks up actual carried loot, equips a pickaxe,
depletes an authored mineral, walks through chunks A/B/C/D, harvests a generated
resource near a living NPC, observes causal memory/inspect activity, observes Bot
gathering/XP, walks back through unloaded regions and saves. Runtime MCP inspects
canonical ledgers, actor capability state, memory, XP and storage counters.

The Editor stops the game and launches a new OS game process. Before the first
gameplay/physics tick, the fixture compares all eight logical snapshot sections,
requests an existing persisted chunk and requires zero generator calls before
and after. Mutations, identity, health, inventory, equipment, activity and memory
remain canonical. A second unchanged checkpoint must write zero record pages.

Observed: 40 canonical chunks, 18 logical living actors, at most four living
bodies and 15 loaded views during the played route. Player reached 80 XP/level3;
the representative Bot obtained six wood/nine XP through shared authority. The
NPC heard committed harvesting and selected `inspect`; structured memory survived
streaming and exact resume. The second unchanged save wrote zero pages/reused 58
records. The fresh process loaded all eight sections exactly, with generator
count 0 both before and after a persisted chunk request. A subsequent semantic
walk rematerialized the NPC, preserved the actor-ID set, health, inventory and
faction, and still invoked no generator.

Native Serena/Godot tools are not exposed in this agent session. Installed stdio
MCP servers provide the actual Editor/runtime, Serena symbols/references and
Diagnostics/LSP calls. Successful stdio communication is distinct from native
tool exposure. The existing Editor, LSP and runtime bridge remain in place.

## Performance interpretation

Machine-readable metrics accompany this document. Generation pipeline includes
validation/atomic commit; pure generation, hydrated-record validation/copy, full
manifest/page hydration and scene materialization are reported separately.

Cold work yields to active Player actions and nearby P1 threats. Idle prefetch
is spaced by four Core ticks, and persists spawn candidates without prematurely
creating their actor inventories/plans. First active relevance commits actor
birth; born actors remain logical after unload. Per-frame scene work is bounded
to one materialization/data job and one unload;
there are at most 25 views and four living runtime bodies. First collision
attachment is a loading phase. The logical world currently has a bounded 9×9
first region. Full snapshot capture/validation is synchronous; immutable pages
avoid rewriting unchanged records but do not claim database-scale CPU cost.
Prepared item catalog reuse avoids rebuilding all item definitions for each actor
validation. Explicit checkpoints can pause; mobile save/stream timing needs device
measurement. Cloud software-rendered Editor FPS is not an Android FPS benchmark.

| Measurement | Observed result |
| --- | --- |
| First chunk generate/validate/commit pipeline | 12.756 ms |
| Last pure generation | 1.394 ms |
| Persisted hydrated chunk request, fresh process | 0.532 ms; full 58-page snapshot hydration separately 57.643 ms |
| Last played scene materialization / unload | 1.369 ms / 0.563 ms |
| Peak loaded views / configured cap | 15 / 25 |
| Logical actors / peak living bodies in MCP | 18 / 4 |
| Synthetic scheduler | 128 logical, 2 L0, 4 L1; 799 jobs across 100 ticks, maximum 8/tick; 30.014 ms total decision work |
| Long-time advance | 128 due activities resolved once; no historical-frame replay |
| Round-trip streaming after warmup | 4-view fixture, peak +20 Nodes, post-unload memory plateau +104 bytes |
| Initial integrated memory growth | +5,521,100 bytes, including new canonical chunks/logical actors |
| Save size fixture, before / after / delta | 23,312 / 35,683 / +12,371 bytes, manifest plus record pages |
| Unchanged / one changed actor / unchanged after hydration | 0 / 1 / 0 new pages |
| Final unchanged checkpoint | 93.717 ms total, including capture/validate/atomic manifest |
| Maximum observed cold generation/commit pipeline | 1,536.329 ms under concurrent Cloud gates/debugger |
| Maximum measured snapshot commit | 1,065.632 ms total (196.188 capture, 286.883 validate, 582.561 write) |

The cold tail is a known limitation, not evidence of smooth streaming or meeting
Android p95. No final mobile FPS claim is made. Routine cold work yields to active
Player actions and nearby P1 threats; explicit loading/stream transitions and
checkpoints can still pause. Device measurement must guide any next storage/
capture scheduling work while retaining canonical commit-before-materialization.
This first-scope proof does not establish final world/population capacity.

The 128-actor scheduler benchmark proves a maximum eight due jobs per tick and
one-time deadline catch-up, rather than population times every historical frame.
Repeated isolated streaming cycles release all transient Nodes and plateau after
warmup. Initial integrated memory growth includes new canonical chunks/logical
actors; it is reported separately from the repeated-cycle leak test.

Open-terrain local corridors are the navigation adapter in this scope. L2 exposes
regional/activity scheduling without a completed village economy. Generated
NPC/Bot populations are nonrenewing; their defeated state persists. Player respawn
continues using P1. Final art, UI, balance, society/ecology, continental content,
external transport and full offline-presence product remain outside P3.

## One Android acceptance scenario

Open `res://tests/p3_manual_acceptance.tscn`. Fight/loot/gather in the starting
valley, walk east to chunks (2,0)/(3,0), observe an NPC responding to nearby
gathering and a Bot working, deplete a mineral, return, Save, close and reopen.
Return to that area and confirm persistent depletion/continuity while judging
controls, terrain traversal and streaming pauses. This is one integrated outing;
identity, determinism, corruption and replay checks are automated.
