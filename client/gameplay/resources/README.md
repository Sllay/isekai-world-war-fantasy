# Resource, loot and recipe domain

This gameplay domain depends on Foundation Items and Core IDs/numeric validation.
It owns no Nodes, input, clock, command queue, ActionExecutor or save slot. The
application's authority module owns the canonical service instances and composes
their state with inventory, equipment and world drops.

`ResourceCatalog.defaults()` loads the small authored Resource catalog. Lookups
return copies. Definitions distinguish logical node IDs, reusable resource
profiles, loot profiles and recipes. Logical node IDs are world-object keys, not
Core entity IDs.

`ResourceService.configure(inventory, catalog, world_seed)` initializes authored
nodes. `gather_check(actor, container, node, tick, position, tool)` validates
ownership, canonical range, reserve and tool capability/power without mutation.
`gather(...)` repeats validation, resolves the authority-seeded yield, commits the
inventory transaction, then commits reserve/deadline/counter changes in the same
synchronous call. Failed transactions change neither inventory nor node state.
The host additionally validates actor lifecycle, current region and equipped-tool
custody. Existing ActionExecutor work supplies windup/cancel/commit timing.

`snapshot(node, tick)` evaluates due regeneration on a detached value. Repeated
views never advance canonical state. A successful gather settles one due cycle;
there is no node polling or repeated catch-up loop. `capture`, `validate_state`
and `restore` persist exact node membership, authored identity/position, remaining
reserve and deadlines. Trees renew explicitly; the scoped stone/ore deposits do
not regenerate.

`LootResolver.resolve(profile, trusted_seed, item_catalog)` returns bounded,
deterministic definition/quantity outputs. It is suitable for initial real stock
and biological/resource yields. It must not reroll a humanoid's carried contents
at death. The authority transfers those actual contents into persistent custody.

`CraftingService.preview(actor, container, recipe, choices, station_tags,
known_recipes, tool)` resolves exact or material-family ingredients. Choices map
recipe slot IDs to definition IDs. Unselected slots choose a deterministic
compatible material, consuming the lowest acceptable condition first. Output
composition records the selected material for each slot. `craft` takes `tick`
after `recipe` and repeats planning, then removes inputs and grants output in one
InventoryService transaction. The host owns station proximity and trusted
knowledge/tool facts. Preview's internal operations are never accepted as client
commands.

The stable balm's item definition provides a healing effect hook; the host
composes consumption with CombatService. Hunger/thirst, perishable simulation,
full geology, station upgrades and NPC workshops are outside this Part.
