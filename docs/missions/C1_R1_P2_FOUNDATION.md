# C1-R1-P2 — Items, Resources & Survival Foundation

Chapter 1 / Run 1 / Part 2. Status: FOUNDATION_COMPLETE / ENGINEERING_COMPLETE
for the scoped technical foundation; new Android controls/readability acceptance
remains pending. Reference:
https://github.com/Sllay/isekai-world-war-fantasy/issues/10 (read through its public
page; the GitHub API returned Forbidden). One integrated macro delivery, continuing
the Android-accepted P1. No final inventory, crafting, equipment or skill UI.

## Base and protected state

Before editing: clean working tree, P1 branch at
`86d0c49bbf001415963a74ad2475b6cea13a3f48`. All remote heads were fetched explicitly
because the configured fetch refspec was narrow. Remote main:
`0c47848b623603bd5a5fa81f2a1703d7c9c4a45f`. P2 branch:
`impl/c1-r1-p2-items-resources-survival`, created directly from remote P1. Preserve
main/P1/PRs and the existing FULL Environment; publish P2 after validation.

## Architecture and authority

Clients request pickup/equip/unequip/move/split/merge/harvest/craft/consume and skill
loadout choices. The existing bound-session AuthorityGateway/LocalAuthorityHost
continues to own envelope, sequence, stale/future, queue and actor identity checks.
Typed command ports extend payload validation/dispatch without a second command
queue or trust model. No client grants, yield/output numbers or final item state.

Inventory owns logical definitions/instances/lots, custody, bounded slots and
integer mass, stack compatibility and atomic multi-operation transactions. Current
holder/container and legal provenance owner are distinct. Equipment references
the same owned instance rather than copying it into another container. Its
representative damage contribution uses the existing CombatModifier contract;
tool capability/power comes from equipped item data. Known skills retain explicit
sources and validate eligibility for the existing ActionLoadout slots.

Harvest/craft/consume use the existing ActionExecutor's wind-up/cancel/commit/
recovery via a typed authority capability-effect port. Absent ports fail closed.
The authority captures request context and revalidates position/tool/stock at
commit. Typed facts and detached snapshots drive the technical panel/world visuals.
Inventory/effects commit coherently before presentation facts; crafting failures
leave all ingredients/output unchanged. No animation/UI callback decides gameplay.

## Representative content and bounded decisions

- Primary bag and owned storage; fixed capacity and integer gram safety limits.
  Stable stackable wood/stone/ore/ingots/balm/coin and individual sword/axe/pick/
  armor instances. Incompatible condition/composition/provenance never averages.
- Stable nonperishable balm proves inventory consumption -> canonical healing.
  This Part does not finalize hunger/thirst or perishable decay/cohort tuning.
- Currency is finite coin stock through the same inventory/custody path; no
  separate infinite wallet, shops or price simulation.
- Seeded loot definitions establish real initial NPC stock once. Humanoid defeat
  moves current carried stock to a persistent player-reserved world cache once;
  pickup transfers that same custody. No death reroll, reload refill or cleanup
  destroying unclaimed items. P1 actors already dead during upgrade get no newly
  invented carried stock or retroactive loot.
- Authored tree, stone and ore nodes (plus a compatible wood variant if useful),
  capability/power gates, range/work, remaining/depletion. Tree renewal uses a
  declared simulation-tick deadline at the same location; stone/ore are finite.
  No global node polling, RNG reroll on failed transactions or arbitrary deposits.
- Typed hand-craft balm/tool and forge ore->ingot/representative weapon recipes.
  Actual selected material composition survives output/save. Station tags/range
  and recipe knowledge come from authority. The larger materials design proof
  (full processing chain, station upgrades, NPC commissioning/geology) is outside
  this Part, whose required flow is the user/issue's integrated foundation.
- Minimal technical inventory/equipment/interaction/craft/consume panel and world
  silhouettes. Desktop and touch issue the same semantic commands. No final art.

## Persistence

One new application-owned gameplay module owns versioned items/resources state,
with pure validation and infallible prepared restore through existing Core saves.
Explicit P1 release migration introduces starting stock only once and preserves
old HP/actions/enemies. Current missing inventory/resource/equipment data rejects;
it never recreates template defaults. Validate cross-section actor/custody,
equipment modifiers, skill/loadout ownership and world content references before
changing canonical state/residency. Pending work and UI stay transient; committed
inventory/resources/effects and cooldowns persist.

## Gates and delivery

Integrated scenario: spawn -> defeat P1 enemy -> actual-stock loot cache -> pickup
-> equip/use -> gather with proper tool -> deplete -> atomic recipe -> consume
-> save -> close/reopen/resume -> same coherent inventory/equipment/resource state.
Use real Runtime MCP state and process-boundary save/resume tests, not just visuals.

Deterministic/adversarial tests cover stacks/capacity/atomic rollback, custody,
equipment/skill eligibility, seeded stock, duplicate/stale/forged pickup/harvest/
craft/consume, invalid tools/range/depleted node, missing ingredients, lifecycle,
reload without duplication/reset, and P1 regressions. Run godot-check, test affected
and test all. Use Serena symbols/references and LSP/Diagnostics.

Performance: private_4gb 20 Hz application p95 target <=25 ms in the scoped live
scenario, bounded containers/caches and change-driven presentation. Report physics/
render and cloud limitations separately; no Android capacity claim. Subjective
touch/readability acceptance, if needed, is one integrated Android scenario.

Completion requires all first-scope systems, tests, live integrated validation,
clean intentional commits and a pushed P2 branch with remote SHA matching HEAD.
Final Chapter 1 catalogs/UI/balance/decay/economy/art belong to later Runs; external
multiplayer transport and A7 are not implemented here.

## Delivery evidence

Implemented integration commit: `a24cc28bf066c44fcff9b54c9edfcfc2269fa896`;
earlier P2 commits define this contract and the reusable pure domains. Final
Godot Check passed. Affected and all runs each passed nine suites / 31 groups /
1,081 checks, zero failures (363 P2 checks plus 718 regression checks). Diagnostics
MCP/LSP returned zero warnings/errors for 47 scripts.

Actual Runtime MCP passed the complete acquire/equip/gather/deplete/craft/consume
flow, then launched a new game process and verified all six save sections exactly.
Repeated production save/resume also passed with unchanged items and correct
capability references. The game was stopped; the FULL Editor remained active.

See [validation and the one Android scenario](C1_R1_P2_VALIDATION.md) and
[structured Runtime evidence](C1_R1_P2_RUNTIME_EVIDENCE.json). P2 publication is
verified by matching origin's branch SHA to local HEAD at delivery. Main/P1 and
Environment configuration remain unchanged. Foundation completion does not claim
final Chapter 1 content/UI/balance or Android acceptance of the new panel.
