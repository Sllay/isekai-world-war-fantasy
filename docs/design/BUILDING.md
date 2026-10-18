# Building Design

- **Version:** 0.2.0
- **Status:** First-scope design contract
- **Updated:** 2026-10-18

## Purpose

Define the first production scope for modular construction so Player, NPCs, player-like Bots and authored world structures can share the same building language instead of each system inventing its own structures.

The target experience is closer to an **ARK-like structural building system** than to voxel construction or pre-baked whole houses. Large structures such as houses, forts, castles, camps and civic buildings are compositions of reusable structural pieces plus materials, ownership, damage and interior state.

This document freezes the first-scope rules needed to avoid incompatible implementations. It does **not** freeze final balance values, every future structural piece, every architectural style or every construction material.

## Core Principles

1. **Structures are compositions, not monoliths.** A castle should not exist only as one indivisible gameplay mesh when the same result can be represented by real building pieces.
2. **The same canonical system serves Player, NPC, Bot and authored-world construction.** They may use different planners or permissions, but not different building physics/state systems.
3. **Piece geometry and material are separate concepts.** `wall.full` + `material.wood` and `wall.full` + `material.stone` reuse the same structural role while changing cost, durability, appearance and other material-driven properties.
4. **Placement is snap/constraint based, not restricted to a rigid square voxel grid.** Quantization/grid assistance may be used for usability and performance, but canonical compatibility comes from structural snap points and placement rules.
5. **Presentation never becomes gameplay authority.** Preview meshes, fade/occlusion and placement colors display state; canonical placement/damage/ownership rules live in gameplay/state systems.
6. **First-scope construction must remain mobile-friendly.** Building freedom cannot require precision controls that are impractical on touch devices.

## Structural Piece Families

The system is data-driven. A structural piece definition declares geometry role, snap points, support/occupancy rules, dimensions, allowed material families and presentation references.

Initial piece families should support at least:

### Foundations

- square/rectangular foundation;
- triangular foundation;
- smaller/half-size foundation where useful;
- future shape variants through data rather than Building-core branches.

Foundations normally establish stable ground attachment and the base snap network for later structural pieces.

### Floors / Ceilings / Platforms

The same structural surface may serve different architectural roles depending on placement/context:

- floor;
- upper-floor platform;
- ceiling;
- flat roof/deck where the material/style allows it;
- square/rectangular and triangular variants where required.

### Walls

Initial wall family should support:

- full wall;
- half wall;
- triangular/gable wall;
- wall with window opening;
- door frame;
- arch/open frame;
- railing/low barrier where applicable.

Openings are structural states/piece variants. A door is normally a separate interactive piece attached to a compatible frame rather than a permanent visual painted into a wall.

### Roofs

Roof building must support more than one pre-baked house roof.

Initial direction:

- sloped roof piece;
- ridge-compatible roof connections;
- corner/transition pieces as required by practical layouts;
- triangular/gable wall support;
- flat roof through compatible floor/ceiling pieces;
- future valley/intersection/cap pieces through the same definition system.

The system may later provide automatic or assisted roof generation for enclosed rooms, but authored/manual structural pieces remain canonical.

### Vertical Access

- stairs;
- ramps;
- ladders where appropriate;
- future vertical connectors through data.

### Openings and Access

- door;
- gate;
- hatch where supported;
- future shutters/portcullis or style-specific access pieces.

### Utility / Interior Pieces

These use the same world placement/ownership model but may belong to different capability families:

- storage;
- crafting stations;
- beds/rest points;
- tables/chairs and other furniture;
- lighting;
- defensive/utility objects;
- decoration where it has no gameplay authority.

## Snap Graph Instead of Hard Grid

The world may expose a placement grid/quantization aid, but the structural system is defined by a **Snap Graph**.

Each structural piece may expose named/type-safe snap points such as:

- foundation edges;
- foundation corners;
- foundation top/bottom anchors;
- wall bottom/top/side anchors;
- floor edges;
- roof edges/ridges;
- door/frame anchors;
- stairs/ramp connection anchors.

A snap point carries enough information to determine compatibility, for example:

- local transform;
- orientation;
- snap category;
- allowed compatible categories;
- occupancy state;
- optional support requirements;
- size/profile tags.

This permits square, triangular, half-height, roof and other piece families without forcing every structure into one Minecraft-like cell model.

## Placement Pipeline

All actors should reach the same canonical placement request regardless of camera or controller.

Conceptual flow:

`Input/AI/Blueprint -> Placement Intent -> Surface/Snap Query -> Placement Candidate -> Validation -> Commit`

A `PlacementCandidate` should be able to represent at least:

- piece definition ID;
- material definition ID/profile;
- proposed world transform;
- selected snap point/host if any;
- surface/terrain reference when ground-attached;
- owner/builder identity;
- validity/failure reasons.

### Validation

Placement validity may consider:

- compatible snap geometry;
- occupied snap point;
- terrain/slope rules;
- intersection/clearance;
- support requirements;
- ownership/territory rules;
- restricted/protected area rules;
- resource/crafting requirements;
- actor permissions;
- world bounds/region state;
- future server authority.

Invalid placement should produce a structured reason rather than only `false`, allowing useful mobile/desktop feedback and agent/NPC planning.

## Camera-Independent Building Interaction

Building gameplay must not depend directly on one camera mode.

Top-down and future third-person views may produce placement candidates differently:

- top-down can use world cursor/touch projection around the Player;
- third person can use a center-screen/camera ray or shoulder-view placement ray;
- NPCs/Bots can submit planner-selected world positions/snap targets;
- authored blueprints can submit deterministic placement intents.

After candidate creation, the same validation and commit path is used.

This protects Building from future view-mode changes.

## Shared Player / NPC / Bot Building

The canonical Building system does not know whether a valid request came from a human Player, Bot, NPC planner, world-generation tool or authored settlement blueprint.

Different actors can have different:

- available recipes;
- skill/profession requirements;
- resource access;
- permissions;
- planning sophistication;
- allowed blueprints;
- build speed;
- labor requirements.

But placed structures use the same piece identity, material data, ownership, health/durability, persistence and world interaction rules.

## Blueprints and Authored Structures

NPCs and world-authored settlements should not require procedural architecture intelligence for every building.

A **Building Blueprint** describes a composition of canonical pieces and constraints.

Blueprints may define:

- required/optional structural pieces;
- relative transforms/snap relationships;
- room/connectivity expectations;
- door/window candidate locations;
- allowed material/style profiles;
- interior sockets/zones;
- construction order/dependencies;
- optional variation parameters.

Semi-procedural variation may safely change bounded choices such as:

- mirroring;
- doorway candidate;
- window count/placement;
- roof variant;
- furniture arrangement;
- decorative set;
- limited footprint variants.

The result remains a real set of Building pieces, not a fake visual structure disconnected from gameplay.

## Construction Process

A committed final structure may be built instantly only where game rules explicitly allow it. The architecture should support construction states such as:

- planned/ghost;
- material-reserved or waiting;
- under construction;
- completed;
- damaged;
- destroyed.

NPC settlements can therefore create jobs such as gather resources -> deliver -> construct pieces instead of magically spawning completed cities.

Exact labor/build-time rules remain balance/content decisions.

## Materials and Construction Tiers

Structural role and material are separate.

Examples of first-scope material progression direction include:

- thatch/straw;
- rough logs;
- worked wood;
- ordinary stone;
- stronger/deeper stone families such as provisional `blackstone`;
- raw/rough iron or iron-heavy construction;
- refined/polished iron/metal families;
- later silver, mithril/fantasy alloys and higher-grade materials.

These names are content direction, not permission to hard-code tiers into Building logic.

A material definition may influence properties such as:

- build resource cost;
- mass;
- structural/damage resistance;
- health/durability contribution;
- flammability;
- corrosion/weather behavior;
- repair requirements;
- tool effectiveness;
- visual material profile;
- sound/VFX profile;
- future magic/conductivity properties.

The dedicated Materials/Resources design contract should own the final taxonomy.

## Health, Damage, Repair and Raids

Placed structural pieces are world entities/state records capable of participating in damage and repair rules.

At minimum the architecture must permit:

- canonical piece health/durability;
- material-dependent resistance;
- damage source validation;
- destroyed/open state;
- repair costs/actions;
- ownership/permission checks;
- raid/war damage policies;
- persistent damage state.

A wall destroyed during a raid can create a real opening because the structure is composed from pieces. Avoid a separate fake "raid wall" system.

Exact PvP protection windows, decay/upkeep, offline raid protection and balance values are deferred until multiplayer/economy rules are mature.

## Ownership, Groups and Political Context

Building state must be capable of representing:

- individual ownership;
- party/group/guild ownership;
- settlement/faction/world ownership;
- access permissions;
- doors/storage permissions;
- protected/restricted regions;
- contest/raid conditions;
- transfer/abandonment where supported.

Two organizations belonging broadly to the same war side may still own different structures and enter local conflict over territory/resources if later political rules permit it. Building ownership must therefore not collapse directly into only `Blue` or `Red` faction identity.

## Rooms and Interior Topology

Buildings may contain multiple floors and enclosed spaces. The Building representation should expose enough topology for other systems to infer rooms/interiors without relying solely on visual meshes.

Useful derived state may include:

- enclosed room volumes/cells;
- openings/doors/windows;
- connected floors;
- interior/exterior classification;
- room ownership/use tags;
- navigation portals.

This supports later occlusion, perception, temperature/weather, NPC housing and interior furnishing.

Exact room-detection algorithm is an architecture decision and may evolve, but gameplay must not rely on hand-authored "this is inside" booleans for every player-built room.

## Contextual Occlusion and Perception

Building presentation must support the top-down 2.5D view without leaking unknown information.

Examples:

- roof/ceiling fades or hides when the controlled character occupies the relevant interior;
- blocking walls can fade/cut away for camera readability;
- when outside, unknown interiors can remain hidden/darkened;
- windows and open doors may expose valid lines of sight;
- contextual silhouettes may represent already-known relevant actors/objects.

Critical rule:

> **Camera visibility is not gameplay knowledge.**

A camera angle, transparent roof or hidden wall must never reveal an enemy/object the Player character has not legitimately perceived.

A dedicated View/Interaction/Perception contract should own the shared rules used by Building, Combat, NPCs and camera presentation.

## Persistence and Networking Boundary

Persistent structure state should be reconstructible from canonical data such as:

- stable structure/piece IDs;
- definition IDs;
- material IDs;
- transforms/snap relationships;
- health/durability/construction state;
- ownership/permissions;
- relevant interactive state.

Presentation meshes are not authoritative save state.

In multiplayer, canonical placement, removal, damage, repair and ownership transitions belong to the authoritative world/server boundary. Clients may preview placement locally but do not authorize it.

## Performance Direction

Large settlements may contain many repeated structural pieces. The design must permit optimizations without collapsing canonical piece identity, including where profiling justifies them:

- shared meshes/materials;
- instancing/batching;
- distance-based presentation LOD;
- simplified collision for distant/noninteractive structures;
- chunk/region streaming;
- reduced update frequency for inactive structures;
- separation between canonical piece state and rendered aggregate representation.

Do not merge canonical buildings into an irreversible static mesh merely for visual optimization.

## First-Scope Player Experience

The first representative Building version does not need every architectural style or material. It should prove the complete loop with a small production-quality set.

A reasonable first-scope set is:

- square foundation;
- triangular foundation;
- full wall;
- half wall;
- door frame + door;
- window wall;
- triangular/gable wall;
- floor/ceiling;
- stairs or ramp;
- sloped roof pieces sufficient for a small complete roof;
- one storage/utility example;
- at least two materially distinct construction families.

The Player should be able to select pieces, preview placement, understand valid/invalid state, snap pieces, build a small multi-piece shelter, enter it, experience correct occlusion/interior behavior, damage/repair representative pieces and save/resume the structure.

NPC/Bot use of the same canonical system can initially be proven by one authored blueprint rather than requiring a general autonomous architect.

## Explicitly Deferred From First Scope

Not required to call the first Building contract successful:

- every roof/intersection shape;
- advanced structural-collapse simulation;
- hundreds of decoration pieces;
- unrestricted freeform mesh deformation;
- complete city-generation AI;
- final PvP raid balance;
- final upkeep/decay economy;
- every material tier;
- final server replication strategy;
- final building editor UX polish.

These must extend the same contracts rather than introduce parallel building systems.

## Acceptance Principles

A future Building Macro Version is not Player Complete merely because a wall can spawn.

Acceptance should prove at least:

- several structural families snap/compose correctly;
- top-down placement is usable on mobile;
- placement validity gives understandable feedback;
- structure survives save/resume;
- materials alter the same piece without separate hard-coded systems;
- damage/repair uses canonical piece state;
- one NPC/Bot/blueprint path produces the same canonical pieces;
- room/interior/occlusion behavior does not leak hidden gameplay information;
- larger repeated structures remain within measured mobile performance budgets.
