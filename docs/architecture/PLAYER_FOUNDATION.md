# Production Player Foundation

## Current authority interpretation

The existing Player foundation was implemented before the external AuthorityHost existed and therefore currently runs locally in Godot. Its semantic input/motor/presentation separation remains useful, but **local physical state must not be mistaken for production multiplayer authority**.

ADR-0016 and `SERVER_AUTHORITY.md` now define the production boundary:

- `PlayerInput` and raw hardware handling remain client-local;
- `PlayerIntent` is the semantic command/input boundary;
- camera/view mode remains client-local presentation state;
- canonical network gameplay position/velocity/grounded/gameplay-facing state belongs to the AuthorityHost;
- the local PlayerMotor/state may act as prediction/reconciliation mirror for the owning client;
- remote actor movement is driven from authoritative snapshots/interpolation rather than local input;
- a client cannot submit an unconstrained final transform and have it accepted as persistent truth;
- losing network connection does not promote the production client to canonical movement authority.

The local deterministic motor remains valuable for prediction, local-authority development and tests; it does not need to be discarded merely because ownership changes.

## Module ownership

Historical Slice 2 composed `foundation.player` with `core.runtime` in `client/runtime/game_runtime.gd`. Core remains independently bootable with `--core-smoke`; no player rules or input dependencies are added to Core.

The module declares its Core dependency and provides `foundation.player` (`PlayerState`) and `foundation.player_capabilities` (`EntityComponents`). The latter exposes `foundation.movement` and remains stable across restores so later systems can attach capabilities without inspecting physical/visual Nodes.

The entity ID is allocated by Core. The historical local-save section persists ID, position, velocity and horizontal facing. Ground contact and pending input are transient and reset on restore. Save files retain the matching Core entity section; application SaveIntegrity validates that reference.

For an authoritative networked world, the server/AuthorityHost owns the canonical persistent Player state. A client snapshot/cache is not an alternate save source. LocalAuthorityHost development may continue using the same domain save contracts through authority ownership.

See `SAVE_SYSTEM.md` and `SERVER_AUTHORITY.md`.

## Semantic input

`PlayerIntent` carries semantic movement, one-shot jump, camera rotation and later combat/action intent fields. Only `PlayerInput` reads hardware events.

Touch, keyboard and controller map into the same intent model. Input devices are presentation/control concerns, not canonical world state.

For remote-authority networking, client commands should carry bounded/validated subsets of this semantic intent with sequence/tick metadata rather than serializing arbitrary PlayerState mutations.

## Motor and prediction boundary

Historically the motor consumes intent in fixed physics steps, uses CharacterBody3D floor/slope collision, and writes physical results to local PlayerState. Rendering never supplies physical state.

For production networking this path is split conceptually:

```text
Input -> PlayerIntent -> command sequence -> AuthorityHost motor/validation -> canonical PlayerState
                         \
                          -> owning-client prediction motor -> predicted mirror
```

When prediction is enabled:

1. client numbers/sends semantic movement inputs;
2. client predicts locally using compatible movement rules;
3. authority processes canonical movement in tick order;
4. authority snapshot includes canonical state + acknowledged input sequence;
5. client corrects to authority and replays still-unacknowledged inputs;
6. presentation smooths small corrections without altering truth.

Server validation can enforce movement/action gates, speed/acceleration bounds, collision/traversal state and impossible displacement.

The exact external transport does not belong inside PlayerMotor.

## Movement direction and gameplay facing

Movement remains camera-relative at the input/view adapter level where appropriate.

The client may translate a top-down or third-person camera orientation into a semantic movement/aim direction. The authority receives/validates the resulting gameplay intent; it does not need the entire camera presentation transform as canonical state.

Distinguish:

- **camera/view orientation** — local presentation;
- **aim intent** — semantic gameplay request;
- **gameplay facing/orientation** — authority-owned when it affects combat/interactions;
- **render sprite/rig facing** — presentation derived from canonical/predicted gameplay state.

This allows top-down and future third-person views without networking the camera itself or trusting camera transforms as combat authority.

## Tuning

`default_tuning.tres` uses exported `PlayerTuning` defaults for movement, floor snap/angle, camera distance/inclination, smoothing and device sensitivity.

Historical defaults include touch/mouse/controller camera sensitivity and bounded camera inclination/distance. Those remain tuning data, not authority policy.

Movement tuning used for authoritative simulation/prediction must be version-compatible between authority and client prediction. The server remains authoritative if they diverge.

## Camera

Camera state is local presentation state and excluded from persistent physical authority by default.

Top-down and future third-person cameras are View Adapters defined by `VIEW_INTERACTION_PERCEPTION.md`. They may create semantic aim/interact/build intents, but Combat/Building/Interaction must not branch on a trusted `camera_mode` to decide canonical rules.

Camera collision/occlusion/cutaway can differ by view without changing Player authority.

## Presentation

`PlayerPresentation.present` passes gameplay/predicted state and a resolved view to the visual adapter.

The presentation layer owns:

- modular character parts;
- rig/bones/IK;
- equipment/accessory visual layers;
- held-item sockets;
- view-dependent ordering;
- animation blending;
- interpolation/correction smoothing.

Presentation state is never the source of canonical movement/combat values.

## Region/world placement

Historical Slice 3 replaced `RuntimePlayerHost` with Region-owned placement/collision. `PlayerAvatar` retains reusable motor/input/camera/presentation composition; World/Region handles entry placement and world context.

Physical Player positions use world-space coordinates. Region supplies the borrowed `foundation.location` capability without making Player depend directly on Region internals.

In the networked architecture:

- AuthorityHost owns canonical world/region membership and gameplay transform;
- client Region/Avatar presentation materializes the relevant authoritative state;
- server-driven spawn/respawn/teleport/world transitions are explicit authoritative operations;
- client prediction cannot permanently move itself between regions or through invalid geometry.

See `WORLD_REGION_FOUNDATION.md`.

## Combat integration

Phase 2 attached `foundation.combatant` through a separate Player Combat adapter rather than coupling movement/input/camera to Combat.

That separation is preserved.

A1 adds an AuthorityGateway/Host seam so semantic Player action intent reaches host-owned ActionExecutor/CombatService state. The client can predict safe presentation but cannot submit final damage, health, cooldown or resource outcomes.

See `COMBAT_FOUNDATION.md`, `COMBAT_ACTIONS.md` and the A1 mission.

## Targeting / aim

`PlayerIntent` supports semantic primary/secondary/cancel actions plus stable-ID/world-space target/aim values.

Those values are **requests/hints**, not proof of a valid hit. Authority revalidates target identity, relationship, perception/LOS, range, action constraints and canonical spatial state before commit.

## Recovery / respawn

Region safe-transform/recovery behavior and current targeting were added in the historical enemy/telegraph work. Future death/respawn policy must be authority-owned because it changes canonical position/lifecycle and may interact with corpse/item custody.

The client may request a valid respawn option; it does not choose arbitrary coordinates.

## Validation

Existing Core/Player/World tests remain regression coverage for deterministic local domain behavior.

A1 authority integration extends validation with:

- semantic movement command -> authority state;
- forged final transform rejection/non-existence in client command protocol;
- correction/reconciliation proof;
- gameplay-facing/aim validation independent from camera presentation;
- LocalAuthorityHost deterministic behavior;
- no network-disconnect -> local canonical authority fallback.

Android/device acceptance continues to validate control comfort, camera behavior and prediction/correction presentation when that layer exists; deterministic movement correctness should be automated where practical.
