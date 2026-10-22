# Offline Player Presence & Server Residency Retention

- **Version:** 0.1.0
- **Status:** First-scope design contract
- **Updated:** 2026-10-22

## Purpose

Define what happens to a player character when the human disconnects/logs out and how servers avoid accumulating meaningless player-residency records forever.

This system supports the project's living-world pillar:

> Leaving the client does not necessarily remove the character from the world.

## Core design decision

A player character remains a world entity after the controlling client/session leaves the server.

The first production direction is:

- connected player: human-controlled actor;
- disconnected/logged-out player: server-controlled **offline body** in a sleep/rest state;
- reconnecting player: authoritative session rebinds to the existing actor if it still exists and the account is eligible to resume it.

The body does not teleport to safety or disappear simply because the client closed.

## Player expectation

Intentional logout/exit must clearly warn the player that:

- the character remains in the world;
- the body may be seen by other players;
- the body can remain exposed to world threats;
- other players may attack/kill it where server rules allow;
- other players may steal/loot accessible possessions where canonical inventory/loot rules allow;
- world simulation continues while the user is offline.

A warning is product UX, not a security boundary. Force-closing the app or losing network still transitions to offline presence.

## State transition

Conceptual state machine:

```text
ONLINE_CONTROLLED
    ↓ disconnect/logout/session loss
OFFLINE_TRANSITION
    ↓ authoritative control detached
OFFLINE_SLEEPING
    ↓ reconnect/account validation
ONLINE_CONTROLLED
```

Death or other world outcomes may happen while offline:

```text
OFFLINE_SLEEPING
    ↓ lethal world/player event
DEAD / CORPSE / RESPAWN_ELIGIBLE
```

On return, the player receives the current authoritative result rather than a copy of their pre-disconnect state.

## Authority boundary

The server owns:

- whether the player session is considered disconnected;
- when control is detached;
- offline-body transform/state;
- damage/health/death;
- inventory/custody;
- loot/theft outcomes;
- world interactions;
- reconnect/rebind eligibility.

The client cannot request `despawn_me_because_i_logged_out` as a trusted result.

There is no automatic disconnect -> local-authority fallback.

## Offline sleep presentation

Presentation direction:

- character transitions to a sleep/rest pose/animation;
- body remains visually identifiable as the same character;
- no giant UI marker is required by default;
- server rules may choose whether nameplates/status communicate offline state;
- visual sleep state must not change collision, inventory or combat authority by itself.

LPC character presentation should eventually include a compatible sleep/offline-body pose or an approved fallback.

## Position and world continuity

The offline body normally remains at the actor's last authoritative valid position.

Do not:

- teleport to town on logout;
- move inventory to a magic safe container automatically;
- despawn the actor merely for performance convenience.

If the last transform is invalid because of a crash, void, world migration or corrupted region reference, normal authoritative recovery/migration rules may relocate it to a validated recovery anchor. This is exceptional integrity handling, not a logout benefit.

## Simulation fidelity while offline

Persistent presence does not require every offline body to consume full active-player simulation forever.

The server may reduce simulation fidelity when the body is irrelevant/distant, while preserving canonical state.

Examples:

- high fidelity near active players or threats;
- lower-frequency aggregate evaluation in unloaded/low-interest regions;
- materialize full physics only when the body becomes relevant;
- preserve scheduled/environmental threats that can legitimately affect it.

The player must not become invulnerable merely because the region was abstracted.

## Interaction and theft

Offline bodies participate in ordinary authoritative rules.

Whether another player can steal from or loot an offline player depends on the same systems that govern:

- PvP;
- incapacitation/death;
- inventory access;
- protected containers;
- faction/crime rules;
- server configuration.

Do not implement a separate client-trusted `offline steal` inventory path.

If theft is permitted while the victim is alive/sleeping, it must use explicit server-side rules and auditable custody transactions.

## Death while offline

If the character dies while the player is disconnected:

- death is canonical;
- items follow the configured death/loot/corpse rules;
- the account does not restore an old pre-death inventory on reconnect;
- reconnect enters the appropriate corpse/death/respawn state;
- important unique-item custody must remain valid.

## Combat-logout abuse

Persistent bodies naturally reduce classic combat-logging abuse because disconnecting does not remove the target.

Additional server policy may define:

- disconnect transition delay;
- whether an online actor continues current movement briefly before sleep;
- hostile/combat-state markers;
- logout warnings;
- moderation/audit signals for repeated disconnect abuse.

No policy may let the client choose invulnerability by disconnecting.

## Account identity versus server residency

A global account can have state in many servers.

Server-specific residency may include:

- actor/character ID;
- race/appearance;
- progression;
- inventory/equipment;
- position/world region;
- reputation/crime;
- relationships;
- ownership/property;
- quests/contracts;
- unique/rare item custody;
- structures/containers;
- last activity and lifecycle state.

The account identity itself is not deleted merely because one server residency is pruned.

## The storage-spam problem

Players may join many servers once, create default/trivial state and never return.

Keeping full player snapshots, journals and empty world references forever is unnecessary.

However, deleting a residency based only on inactivity or low level is unsafe because even a low-level character can own or reference meaningful world state.

Therefore cleanup is based on **significance and references**, not simply time.

## Residency significance

A server residency is considered **meaningful/protected** if any configured significance anchor exists.

Examples include:

- non-trivial progression above the server's cleanup threshold;
- rare/unique/limited item custody;
- non-default equipment the server chooses to preserve;
- meaningful currency/economic balance;
- player-built structures;
- property/land/container ownership;
- persistent storage contents;
- active contracts/quests that cannot be safely abandoned;
- faction/reputation/crime/wanted state with world consequences;
- social/family/guild/organization references;
- authored story flags;
- trades/escrow/economic obligations;
- world office/role/title;
- corpse/death state still holding items/references;
- any external object that refers to the actor/account residency.

A single common wood/stone stack does not automatically need to protect a residency forever; policy can classify starter/common/trivial holdings separately.

## Trivial residency candidate

A residency can become a cleanup candidate only when all required conditions are true, conceptually:

- inactive longer than the server's configured retention window;
- no active online/offline body requiring simulation;
- no meaningful progression anchor;
- no protected item/property/currency anchor;
- no inbound persistent world references;
- no moderation/legal/financial hold;
- no pending transaction;
- only default/starter/common disposable state within configured limits.

The retention window and significance thresholds are server configuration, not hard-coded constants.

Official servers should use conservative defaults. Private servers may choose tighter cleanup within integrity constraints.

## Compact before delete

Prefer a staged lifecycle:

```text
ACTIVE_RESIDENCY
  ↓ inactivity
DORMANT_RESIDENCY
  ↓ eligible
COMPACTED_RESIDENCY
  ↓ retention + no references
PURGE_CANDIDATE
  ↓ transactional verification
PURGED / TOMBSTONED
```

Compaction may drop rebuildable caches, verbose transient logs and presentation data long before deleting canonical identity/state.

Deletion is the final step, not the primary storage optimization.

## Tombstones and rejoin behavior

A pruned residency should leave the minimum tombstone/audit metadata necessary to prevent duplicate/lifecycle ambiguity when appropriate.

If the account later rejoins that server after a safe purge:

- create a new residency/character according to server onboarding rules;
- do not resurrect deleted items/state from stale clients;
- stable global account identity remains the same;
- server may retain a non-sensitive prior-visit marker if useful for moderation/migration.

## Unique/rare item safety

Cleanup must never duplicate or silently destroy unique/limited items.

Before pruning a residency holding protected custody, policy must instead preserve/transfer/resolve that custody according to canonical item rules.

If safe resolution is not defined, the residency is not purgeable.

## World-reference safety

Deletion requires a reverse-reference/invariant check.

Examples that block deletion:

- structure owner points to player actor;
- chest/container belongs to actor;
- quest/contract references actor;
- relationship graph references actor;
- guild/office membership requires the actor;
- bounty/crime record requires identity;
- world event stores actor as participant;
- unique item provenance/custody points to actor.

Never solve storage pressure by leaving orphan references.

## Persistence model

Offline presence should integrate with the existing snapshot/transactional persistence strategy:

- authoritative actor state remains canonical;
- significant transitions are persisted;
- high-frequency movement does not need an unbounded event log;
- inventory/custody changes remain transactional/idempotent;
- reconnect reads current authoritative state;
- cleanup jobs use explicit migrations/transactions.

See `docs/adr/ADR-0008-persistence-and-transactional-state.md`.

## Server configuration

Future `ServerRuleProfile` may expose bounded policy such as:

- offline-body enabled/required by game mode;
- interaction/PvP rules applying to sleeping bodies;
- offline simulation fidelity budgets;
- trivial-residency retention window;
- cleanup significance thresholds;
- compaction schedule;
- audit/tombstone retention.

Hard integrity rules cannot be disabled merely to save storage.

## Privacy/data minimization

Retention should keep only what the world/server needs.

Do not treat "persistent world" as justification for retaining unrelated authentication secrets, unnecessary device information or unlimited telemetry.

Account/authentication data lifecycle is separate from game-world residency cleanup.

## Observability

Cleanup and offline-state systems should expose metrics/logs for:

- active offline bodies;
- compacted residencies;
- purge candidates;
- blocked purges by reason;
- storage reclaimed;
- orphan-reference/invariant failures;
- reconnect/rebind success;
- offline deaths/loot where operationally useful.

## First representative proof

A future implementation proof should cover:

1. player joins and obtains an item;
2. player disconnects outside a safe hub;
3. actor remains in world and enters sleep state;
4. second authoritative actor can observe/interact according to server rules;
5. first player reconnects and rebinds to the same current actor state;
6. offline damage/death is preserved across reconnect;
7. a purely trivial test residency becomes cleanup-eligible after simulated retention;
8. a residency with a protected item/property/reference is refused cleanup;
9. cleanup/rejoin does not duplicate items or resurrect stale state.

## Non-goals for first implementation

Do not require initially:

- offline AI that actively plays the character like a bot;
- automatic travel to safety;
- sleeping-player NPC schedules;
- insurance systems;
- premium safe logout;
- complex inheritance after permanent death.

Offline means persistent presence, not autonomous adventuring.

## Acceptance gate

The system is valid when:

- disconnect does not despawn the canonical actor;
- reconnect cannot roll back world consequences;
- offline bodies can be affected under normal server rules;
- reduced simulation fidelity preserves correctness;
- trivial residency cleanup is reference-safe and transactional;
- meaningful residencies are protected from accidental purge;
- unique items and world references cannot be orphaned/duplicated;
- cleanup policy is configurable without weakening authority/integrity.