# C1-R1-P2 — Items, resources and survival foundation

Implemented first-scope; application save version 0.4.0. See
[mission](../missions/C1_R1_P2_FOUNDATION.md) and
[ADR-0018](../adr/ADR-0018-authoritative-item-custody-and-work.md).

## Ownership and integration

`foundation/items` owns typed ItemDefinition/ItemCatalog, InventoryService,
EquipmentState and LearnedSkillSet. Definitions are copied content; inventory
entries carry stable instance/lot IDs, quantity, condition, composition and legal
provenance owner. The current container's owner is the holder. Loot changes
custody without erasing provenance. Equipment references the same inventory entry.

`gameplay/resources` owns typed resource/node/loot/recipe definitions and pure
ResourceService/CraftingService. `gameplay.items_resources` composes these domains
as one CoreModule, using the existing Player, Combat and Enemy capabilities.
Player's EntityComponents exposes `foundation.inventory`, `foundation.equipment`
and `foundation.skills`; no physical Node is required for a logical item/node.

ItemsAuthorityPort is installed only by the explicitly selected LocalAuthorityHost.
It extends the existing bound-session inbox and replay/stale/actor checks through
AuthorityCommandPort. It does not create another gateway, sequence or clock.
Disconnected remote mode cannot mutate this state. Clients may request:

| Intent | Payload |
| --- | --- |
| `item.pickup` | drop ID |
| `item.equip`, `item.unequip` | compatible slot and owned entry / slot |
| `item.move` | owned entry, destination bag/stash, quantity |
| `item.split`, `item.merge` | owned entry and quantity / source and target |
| `item.harvest` | authored node ID |
| `item.craft` | recipe, station and material-definition choices |
| `item.consume` | owned entry ID |
| `skill.equip` | eligible skill ID and skill_1/2/3 slot |

Unknown fields, grant/output/yield/final-state data and malformed quantities are
rejected. Live actor/guard/stagger/action gates apply before mutations. Storage
transfer requires proximity to Home Valley storage. Pickups and stations require
canonical Region, distance and visibility. Equipped entries cannot be moved,
split, merged or consumed as crafting ingredients through these commands.

## Inventory, equipment and skills

InventoryService stages an entire bounded batch on detached state, validates
ownership, capacity, integer mass and all entries, then commits once. Failure
preserves quantities, identities, serial allocation and revisions. Compatible
stacks require equal definition, condition, composition, provenance and legal
owner; there is no condition averaging. Partial transfer/split creates a new
stable lot ID. Whole transfer preserves identity. Explicit merge destroys only
the consumed compatible source reference.

The representative bag has 24 slots/50 kg; owned storage 48 slots/200 kg. Service
safety caps are 64 containers, 256 stacks/container and 64 operations/batch.
There are weapon/tool/armor slots. Tool tags/power come from the equipped,
nonbroken item definition. The tempered sword contributes +2000 basis points to
the existing CombatModifier DAMAGE_SCALE channel; ordinary basic damage changes
from 12 to 14 through CombatService, without UI damage logic.

Learned skills retain permanent learning sources separately from temporary
equipment grants. Availability/eligibility validates the existing ActionLoadout.
Removing an equipment source revokes only its grants and clears now-ineligible
slots. Changing slots never resets the action's cooldown. Starting basic,
strong and heal remain representative P1 actions, not Run 2's final three skills.

## Work and canonical results

Harvest, craft and consume use the same ActionExecutor wind-up, movement/cancel
gates, commit, recovery and cooldown. Typed CAPABILITY effects require an
authority-owned ActionCapabilityPort. Missing adapters fail closed. The current
transactional capability form permits one SELF effect and zero resource cost;
mixed partially committed combat/inventory effect lists are rejected.

The command port copies the semantic context, checks it at activation and again
at commit. There is no await between validation and domain commit. Capacity
previews use a detached ledger; final gathering atomically adds the authority's
seeded yield before changing reserve/deadline/counters. Failed requests do not
reroll the next yield. Recipe execution atomically removes inputs and adds output,
including selected material composition. Forge recipes validate station proximity,
knowledge and optional tool/context requirements from trusted state.

Stable balm proves consume -> remove one -> CombatService healing. A rejected
heal restores the exact ledger and emits no health facts. Accepted observers see
both item and health mutations. Hunger/thirst and perishable simulation are not
implemented or implied by this stable nonperishable proof.

ItemOperationResolved publishes coherent operation code/revision. Detached host
snapshots expose bag, storage, equipment, skills, drops and nodes. The technical
Items panel and world silhouettes consume this state; buttons issue requests only.
Desktop I/R/J/U and touch controls share the same gateway. Presentation refresh is
bounded to 0.15 seconds; inventory rows rebuild only on dirty/revision changes.

## World custody and resources

Each P1 opponent receives seeded actual carried stock once on a new game.
Defeat transfers that stock into a persistent, player-reserved world cache once.
Pickup atomically transfers every remaining entry and marks the cache claimed.
Duplicate or replayed pickups cannot create items. Claimed cache tombstones remain
in the two-actor authored world; they are not a scalable cleanup/pooling policy.

Four logical authored nodes prove two wood variants, stone and iron ore. The axe
harvests wood; the pickaxe supports stone/ore and required tool power. Nodes track
remaining reserve, extraction count, cycle and simulation-tick regeneration
deadline. Tree renewal is lazy and detached until the next successful harvest;
stone/ore are finite. No node has an autonomous per-frame authoritative poll.
Recipes prove hand-crafted balm/tool and forge ore -> ingot -> tempered sword.
Finite coin stock uses the same inventory/custody path; there is no separate
wallet, price simulation, shop or economy engine.

## Save/resume and validation

ItemsModule owns section `gameplay.items_resources` v1. It persists inventory,
equipment, learning/grants, loadout, recipe knowledge, nodes, cache custody and
loot completion. CoreSaveStore still owns generic capture/prepare/restore; the
application's SaveIntegrity checks cross-section actor ownership, exact containers,
equipment modifiers, skill grants, actor death/loot and regeneration deadlines.
Pending work, UI, active casts and visual markers are transient.

Only an exact supported 0.3.0 P1 release migrates to initial P2 state. Saved HP,
cooldowns, enemies and position remain canonical. Already defeated P1 actors get
empty claimed tombstones, no invented stock or retroactive loot. Current 0.4.0
missing/corrupt state rejects before canonical/residency mutation; it never refills
defaults. A repeated resume neither duplicates loot nor resets depleted nodes.

`test_items_resources.sh` covers domain, adversarial, persistence, integrated
semantic-input scenario and two independent OS-process checkpoint tests. Runtime
MCP launches `tests/p2_acceptance.tscn`, queries real canonical state, stops the
game, launches it again and compares all six persistent sections exactly. This
fixture owns an isolated test slot and does not alter the player's production save.
Production uses the same runtime, gateway, actions and domains.

For hands-on Android acceptance, `tests/p2_manual_acceptance.tscn` runs the ordinary
runtime and controls without a bot, using `user://tests/p2-android-manual.json`.
Its Save/Delete controls affect only that separate slot. No existing P1 save
must be deleted or edited to obtain a fresh representative encounter.
