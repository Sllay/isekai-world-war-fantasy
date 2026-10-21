# ADR-0017 — Authority loadouts and world-space target queries

- Status: Accepted for C1-R1-P1
- Date: 2026-10-21

## Context

A1's executor was reusable, but its target validator only executed SELF/ENTITY and
the host hardcoded primary/strong/heal IDs. Part 1 must support three skill slots
and future targeting families without replacing combat, input or authority.

## Decision

ActionLoadout is trusted typed content: primary plus skill_1/2/3, optionally empty
skills. The host validates against ActionCatalog and copies an installed loadout
only while idle/cancelled. Clients request slots; they cannot equip arbitrary IDs.
Cooldown identity remains the action ID across slot/loadout changes. Strong/heal
remain legacy wire aliases for slots 1/2. The authored representative loadout
equips strong, heal and an empty third slot; these are not the three final skills.
Future approved sets can reuse install_loadout without duplicating execution.
Persisting player-customized equipment/sets needs its future owning save contract;
the present fixed authored loadout is not reconstructed from client state.

ActionTargetResolver owns generic validation over copied world-space hints. The
same ActionExecutor resolves at start and again at commit, then invokes existing
ActionEffectRunner/CombatService in stable target-ID order. Spatial modes require
a trusted world_query port selected by an authored query ID; absent/invalid queries
fail closed. World owns geometry, shape/spatial indices and perceived candidates.
Actions revalidates capability, alive state, range, visibility and relationship.
Fan-out is 1..8 targets, no duplicates. Cost/cooldown commit once per execution.
Target effects remain sequential, not a multi-target atomic transaction; no retry
or refund once commit begins, including partial rejection by downstream policy.

Existing entity-targeted ranged/hitscan content needs no melee-specific executor
branch. Direction/point/AoE query integration is exercised with the same executor
in deterministic tests. Projectile travel/collision and new effect kinds belong
to authority-owned effect/world adapters extending ActionEffectRunner, not camera
or VFX callbacks. This Part does not claim a playable projectile arsenal.

PlayerAimAdapter projects view input to world direction/point candidates. Other
views, touch controls and bots can supply identical values. Authority never sees a
camera-mode rule. TargetingService shares the authority visibility port so a wall
blocks selection as well as action commit. Full perception/memory remains separate.

## Consequences

No new CombatService, Core rule or parallel skill executor. Typed action facts now
include target IDs/aim values while preserving the original single target ID for
existing consumers. Existing action/cooldown save schema stays valid: target hints,
active casts and selections are transient. Respawn clears those hints/selections
and only the player's active defense windows, preserving unrelated actors and
committed cooldowns. Numeric and real-collider integration tests cover the boundary.
