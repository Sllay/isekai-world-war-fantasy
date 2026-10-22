# C1-R1-P2 — integrated foundation validation

## Delivery

One Items/Resources/Survival foundation, continuing the completed Android-accepted
P1 remote SHA `86d0c49bbf001415963a74ad2475b6cea13a3f48` on
`impl/c1-r1-p2-items-resources-survival`. Main and P1 are preserved; no PR lifecycle,
merge or Cloud Environment configuration change. Issue #10 and the macro mission
define the scope. See [implementation contracts](../architecture/ITEMS_RESOURCES_FOUNDATION.md).

The Items-domain work supplies typed definitions, bounded atomic inventory,
stack/transfer/split/merge, instance equipment and source-owned skills. The
Resource-domain work supplies typed nodes, seeded yields/initial stock, tool
capabilities and atomic recipes. Integration composes these existing domains
under the same P1 host/executor and save engine, rather than creating parallel
command validation or work systems. A final independent review checked their
authority, rollback and restore paths.

## Deterministic gates

Validated integration commit: `a24cc28bf066c44fcff9b54c9edfcfc2269fa896`.

| Gate | Final result |
| --- | --- |
| `bash tools/dev/devctl.sh godot-check` | PASS, Godot 4.7.2 clean import/parse, no leaks |
| `bash tools/dev/devctl.sh test affected` | PASS, 9 suites / 31 groups / 1,081 checks / 0 failures |
| `bash tools/dev/devctl.sh test all` | PASS, 9 suites / 31 groups / 1,081 checks / 0 failures |
| P2 groups | 87 inventory +79 resources +102 authority +85 persistence +8 scenario +1 process save +1 process resume =363 |
| P1 regression | 718 checks, including two new disconnected-item immutability checks |
| Diagnostics MCP/LSP | 47 scripts, zero warnings/errors |
| Serena | Actual symbol overviews/references; repository search supplements empty reference discovery |
| Runtime MCP | Integrated live scenario and exact new-process restore PASS |
| Manual-test scene | Clean headless boot and actual MCP boot with separate slot/capability binding |

Diagnostics use linked Editor workspace paths, avoiding
the known duplicate-class original/mirror alias. All new warnings were corrected;
no error/leak filter was weakened. Expected invalid-save/write-failure diagnostics
in adversarial fixtures are exercised outcomes, not hidden parser/runtime errors.

P2 test groups cover pure items/resources, real-host adversarial commands,
persistence, semantic-input integration and two independent OS processes.
They include forged grant/quantity/yield/output, foreign actor/holder, unowned
equipment/consume, invalid slots/tools/range, depleted nodes, duplicate/stale
pickup/harvest/craft, missing ingredients, capacity rollback, skill eligibility,
modifier integration and remote-disconnected inventory immutability.

Current-schema corruption rejects before canonical/residency mutation. Explicit
P1 migration preserves HP73/resource29/strong cooldown17 and old dead enemies
without retroactive loot. Pending work is discarded without later commit. A real
defeat at a fractional transform survives two save/resume cycles; a displaced
cache still rejects. The fix compares exact engine Vector3 positions, not a
tolerance that authorizes moved loot.

Existing P1 gameplay assertions remain. Old-release migration fixtures explicitly
remove the new P2 module/section; runtime module/section counts now include it.
These fixture/schema updates do not relax combat, death, respawn or authority.

## Actual Runtime MCP

Installed Godot MCP stdio tool calls launched `res://tests/p2_acceptance.tscn`.
The bot uses semantic movement/aim/actions and gateway item requests only; it
does not write canonical transforms, health, inventory, ticks or loot results.
Structured evidence is [C1_R1_P2_RUNTIME_EVIDENCE.json](C1_R1_P2_RUNTIME_EVIDENCE.json).

The live scenario completed in 399 Core ticks: received real combat damage,
defeated the P1 opponent, transferred its exact carried entries/IDs/provenance
to a world cache and then the bag, harvested/depleted wood with an axe, gathered
stone and ore with a pick, crafted balm and forge ingot/sword, preserved selected
iron/common-wood composition, consumed crafted balm (HP84 ->99), and equipped
the crafted weapon. Claimed loot did not duplicate; carried NPC stock became empty.

MCP stopped the game and launched a new process. It reported `resumed:true`,
`passed:true`, `exact_snapshot:true` for all six persistent sections. A final
new-process recheck saved/resumed again with error0, identical item state and
correct EntityComponents equipment binding. Editor MCP returned no messages.
Game was stopped after validation; the existing FULL Editor/LSP/bridge stayed up.

Serena symbol/reference navigation, Diagnostics and Runtime tools were actually
invoked through prepared stdio servers; native tools are not registered in this
agent session. The documented launcher was consulted once and reported the
existing editor healthy. A 3-second post-connect handshake resolved the initial
short-timeout read. No package download, editor restart or cloud repair occurred.

## Performance and scope

Live application callback cost/Core steps: p95 **5751.5 us**, max **56810 us**,
256 samples during active play. The scoped p95 is below the 25 ms application
target; the isolated cloud spike is retained. This excludes independently
scheduled physics/rendering. A post-scenario engine snapshot recorded 65,776,158
bytes static memory, 54 draw calls and zero orphan Nodes. It is not an active
frame-time distribution or total device/process memory measurement.

No Node per logical item, no global resource-node poll, bounded ledger/batches,
one-time loot lifecycle and dirty inventory rows. Four authored nodes/two enemies
prove the first-scope path; larger populations need measured spatial/lifecycle
budgets. Cloud software-renderer metrics do not establish Android FPS/capacity.

Stable goods do not claim perishable cohorts/decay or final hunger/thirst. Final
inventory/equipment/skill UI, catalogs, balance, economy, deeper materials chains,
world generation, external transport and A7 remain deferred to owning Runs/Parts.

## One Android acceptance scenario

Open `res://tests/p2_manual_acceptance.tscn` in an Editor/debug Android build; it
uses a separate manual-test save and the ordinary controls, with no bot. In one
outing, fight/loot the first skirmisher with **Interact**, open **Items**, use the
axe on the common tree and pick on stone/ore, craft balm, smelt/forge near the
orange Forge, equip the crafted sword and use balm after damage. Save, close,
reopen the same scene and continue the outing. Judge only touch comfort and the
readability of stock/equipment, tool/depletion/craft feedback and save/resume.
Deterministic outcomes and P1 combat regression already have automated evidence;
this is not a request to rerun individual microtests or delete the production save.

State: FOUNDATION_COMPLETE / ENGINEERING_COMPLETE for the scoped Run 1 technical
foundation. Manual acceptance remains required only for new panel touch comfort
and feedback readability. Branch publication is checked against local HEAD at
delivery; no merge or P1/main modification is part of this mission.
