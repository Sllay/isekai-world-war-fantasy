# View, Interaction and Perception

- **Version:** 0.1.0
- **Status:** First-scope cross-system design contract
- **Updated:** 2026-10-18

## Purpose

Define how top-down and future third-person presentation feed the same gameplay systems, and how what a camera can render remains separate from what a Player/NPC/Bot actually perceives or knows.

This contract protects Combat, Building, Interaction, Stealth and AI from being rewritten when camera modes change.

## Core Rules

1. **Gameplay systems consume semantic world intents, not camera implementation details.**
2. **Camera visibility is not gameplay knowledge.** Rendering geometry through a roof or camera clipping does not grant target/AI knowledge.
3. **Player, NPC and Bot perception use compatible world-query concepts.** Different senses/presentation are allowed, but simulation facts are not invented by HUD/camera code.
4. **Top-down and third person are view adapters over the same canonical actor/world state.**

## View Modes

### Top-down / Inclined 2.5D

Primary mobile-first exploration/combat view.

Supports:

- inclined rotatable camera;
- camera-relative movement;
- world-space aiming around the Player;
- contextual room/roof/wall visibility;
- world-space placement previews;
- zoom/occlusion tuning.

### Third Person

Future supported view mode using the same movement/action/world state.

Direction:

- shoulder/behind-character presentation;
- center-screen reticle where applicable;
- camera ray for aim/interact/placement candidate creation;
- no separate combat/inventory/building rules merely because the camera changed.

Third person is not required to become first person.

## Local View State

Camera mode, yaw/pitch/zoom/shoulder offset and smoothing are local presentation/input state unless a specific gameplay rule explicitly needs them.

Canonical simulation should not save/replicate arbitrary camera transform as actor physics state.

## Semantic Intent Boundary

Raw input is converted before gameplay execution.

Conceptual flow:

`Touch/Mouse/Controller -> View/Input Adapter -> Semantic Intent -> Gameplay System`

Examples of semantic intents:

- MoveIntent;
- AimIntent;
- TargetIntent;
- InteractIntent;
- PlacementIntent;
- ActionIntent;
- CameraIntent (presentation only).

Combat/Building should never need `if camera_mode == THIRD_PERSON` in their canonical resolution logic.

## Aim Intent

An `AimIntent` can represent the meaningful output of a view/input adapter, for example:

- actor/origin reference;
- world direction;
- optional world point;
- optional entity candidate/locked target;
- targeting family/mode;
- precision/assist information where needed;
- timestamp/sequence for input resolution.

The action/targeting system remains authoritative for range, line-of-effect, disposition, validity and hit resolution.

### Top-down Aim

Top-down can project touch/mouse input into the world and produce a direction/point relative to the actor.

The player-facing aim visual may orbit/rotate around the character as a world-space indicator rather than a fixed center HUD crosshair.

### Third-person Aim

Third person can use a screen-center reticle/camera ray to produce the same world direction/point/candidate target.

Camera ray hit is a candidate query, not guaranteed action validity.

## Interaction Intent

World interactions use shared interaction queries/capabilities.

Examples:

- open/use door;
- talk;
- loot corpse/container;
- harvest resource;
- activate station;
- inspect object;
- pick up item;
- operate mechanism.

Top-down may select by projected world cursor/proximity/context.
Third person may select by center-screen ray/context.
NPC/Bot planners may select a known world target directly.

After selection, the same canonical interaction validation executes.

## Interaction Candidate Ranking

When multiple interactables are valid, presentation can rank candidates from factors such as:

- explicit aim/cursor proximity;
- actor distance;
- line of interaction;
- current input context;
- semantic priority;
- relationship/permission;
- recent selection/sticky focus.

Presentation ranking never bypasses canonical permission/range rules.

## Perception vs Knowledge

Separate three concepts:

### Physical Existence

What is actually present in the world.

### Current Perception

What an actor can currently sense through supported senses/rules.

Examples:

- vision;
- hearing;
- scent/tracking;
- magical detection;
- touch/proximity;
- communicated information.

### Knowledge / Memory

What the actor believes/remembers from prior perception, communication or evidence.

A target can physically exist without being currently perceived. An actor can remember a location without currently seeing it. Memory can be stale or incomplete.

## Vision Queries

Vision can consider:

- world position/orientation;
- range;
- field/shape appropriate to actor/view;
- occluders;
- doors/windows/openings;
- illumination/visibility modifiers where modeled;
- stealth/concealment;
- actor-specific senses;
- vertical separation;
- room/portal connectivity where useful.

Do not use rendered-screen visibility as the authoritative vision test.

## Hearing and Event Perception

Significant actions can emit perception events containing bounded information such as:

- origin;
- loudness/radius/profile;
- category;
- source identity only when perceivable;
- time;
- uncertainty.

Examples include combat, footsteps, alarms, breaking structures and calls for help.

Far/aggregate simulation may resolve hearing/communication analytically without physical audio playback.

## Scent, Tracks and Forensic Evidence

Tracking gameplay can use explicit world evidence rather than magical omniscient markers.

Evidence sources may include:

- blood;
- scent;
- footprints/travel trail;
- disturbed environment;
- stolen-item provenance;
- witnesses;
- last-known sightings.

Evidence has lifetime, strength and access requirements. Specialized creatures, skills or items may interpret evidence better than an ordinary actor.

## Room and Interior Model

Buildings should expose enough structural information to reason about interiors independently of the camera.

Useful concepts include:

- room/interior volume;
- structural boundaries;
- portal/opening: door/window/arch;
- connected visible spaces;
- roof association;
- floor/level;
- known/unknown interior state.

The Building system supplies structural facts; Perception determines what is visible/known; Presentation decides fade/cutaway/darkening.

## Top-down Interior Presentation

When the Player is inside a structure:

- the current interior/connected perceived space can be presented clearly;
- roof sections may fade/hide;
- walls blocking the avatar/camera may fade/cut away;
- outside areas can remain visible only according to openings/perception rules;
- unknown actors/rooms are not revealed merely because the top-down camera could geometrically render them.

When the Player is outside:

- exterior remains readable;
- interior can be hidden/darkened unless visible through doors/windows/other valid perception;
- window/door sight can reveal bounded portions of interior.

This is inspired by readable top-down games such as Project Zomboid but remains adapted to the game's 3D world and own art direction.

## Third-person Interior Presentation

Third-person normally renders physical architecture from the camera position and uses near-camera occlusion handling when required.

Perception/targeting still use canonical visibility/knowledge. Camera clipping or a debug camera cannot reveal valid target locks or NPC knowledge through opaque structures.

## Occlusion Presentation

Possible presentation techniques include:

- roof fade/hide;
- wall transparency/cutaway;
- silhouette of the Player/known relevant object;
- room darkening;
- portal-based visibility;
- local dither/fade for near-camera geometry.

These techniques display perception/comfort state; they never mutate the underlying world or authorize interaction.

## Targeting and Perception

Target selection may require current perception/knowledge depending on action.

Examples:

- ordinary direct attack: requires a valid currently targetable/perceived entity or valid free-aim trajectory;
- projectile fired toward remembered location: may be allowed without a currently locked target;
- tracking spell: may operate on evidence/knowledge rules;
- UI must not hard-lock a hidden enemy behind a wall simply because its Node exists.

Aim assist is similarly restricted to eligible perceived/candidate targets.

## Building Placement and View

Both view modes can create the same `PlacementCandidate`/semantic placement request:

- top-down: projected touch/world cursor and snap queries;
- third person: camera ray/reticle and snap queries.

NPC/Bot/Blueprint planning can produce candidates without a camera.

Canonical Building validation is independent of the producer.

## Interaction Contexts

The existing input-context model should expand coherently around:

- `GAMEPLAY_FREE`;
- `GAMEPLAY_ACTION_AIM`;
- `BUILD_MODE`;
- `INTERACTION_FOCUS` where useful;
- `INVENTORY_OPEN`;
- dialogue/menu/future contexts.

Changing context changes which intents can be produced/accepted; it should not teach every gameplay system to inspect UI Nodes.

## NPC/Bot Perception Interface

Autonomous actors consume perception/knowledge facts rather than SceneTree scans of all world entities.

Their planners can query concepts such as:

- perceived threats;
- known food/resources;
- known people/relationships;
- current evidence;
- remembered locations;
- communicated settlement information.

This permits simulation LOD and prevents omniscient AI.

## Information Communication

Knowledge can move through:

- direct observation;
- conversation/report;
- messenger;
- guild/settlement records;
- faction communication;
- alarms;
- tracking evidence;
- magical communication where defined.

A remote crime/death does not automatically update every NPC's knowledge.

## Persistence

Persist only knowledge/memory that matters to ongoing world causality.

Examples:

- discovered settlements for Player/Bot respawn/navigation;
- significant relationship memories;
- last-known location of a unique artifact/person;
- important witnessed crimes;
- discovered map/region facts.

Transient frame-by-frame visibility caches are not save state.

## Performance

Perception must support spatial partitioning and staggered/batched updates.

Do not perform all-pairs line-of-sight every frame.

Use combinations of:

- spatial query/interest sets;
- event-driven hearing;
- reduced perception frequency at distance;
- room/portal pruning;
- cached/static occluder data where appropriate;
- simulation LOD.

Exact budgets belong in `PERFORMANCE.md`.

## Representative First Proof

The first cross-system proof should demonstrate:

1. Player can switch/use top-down and a development third-person adapter without changing canonical combat state;
2. both modes create compatible aim/interact intents;
3. one Combat action executes through both modes;
4. one Building placement candidate validates through both modes;
5. an enemy hidden behind an opaque wall is not lockable merely because the camera can theoretically render its Node;
6. opening a door/window changes legitimate visibility;
7. top-down roof/wall presentation reveals the Player/interior without revealing an unknown hidden enemy;
8. one NPC receives a perception/memory event and changes later behavior;
9. save/load preserves selected durable knowledge but not transient visibility cache.

## Explicit Deferrals

Not frozen here:

- final third-person camera offsets/sensitivity;
- exact crosshair art;
- final stealth formula;
- full lighting-based detection;
- final room-portal implementation algorithm;
- all magical senses;
- every tracking item;
- final camera transition animation.

## Acceptance Principle

The view system is not complete because two Camera3D nodes exist. It is complete enough only when multiple views feed the same gameplay contracts and neither presentation nor AI becomes omniscient because it can access raw scene data.