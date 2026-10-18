# World Generation and Environment

- **Version:** 0.1.0
- **Status:** First-scope design contract
- **Updated:** 2026-10-18

## Purpose

Define the first production scope for generating a believable persistent continent, caves, hydrology, settlements, terrain suitability and mutable world surfaces without requiring every server to regenerate a completely different world on every launch.

## Core Rule

**Generation creates the world's initial canonical geography; persistence owns what happens afterward.**

A server/world is generated from a seed/configuration, validated, then becomes a persistent world. Reopening the server does not regenerate terrain as if nothing happened.

Server owners may choose a different seed/world-generation profile when creating a new world. Once the world is accepted, its seed/base generation plus persistent deltas define that world's geography.

## World Shape

The first chapter takes place on one large continent/continental island surrounded by ocean.

Generation should create a coherent large-scale geography rather than independent noise layers stacked without causality.

First-scope systems include:

- continental landmass;
- coast/ocean boundary;
- elevation/mountain ranges;
- valleys/plains;
- hydrology;
- biome/environment placement;
- cave entrances/cave systems;
- settlement suitability;
- roads/path corridors added after settlement planning;
- resource geology/depth integration;
- mutable terrain deltas.

## Deterministic Base + Persistent Delta

Do not store a full duplicate of every unchanged generated vertex/chunk when it can be reconstructed.

A practical model is:

`World = generator_version + seed + generation_profile + authored constraints + persistent mutable deltas`

Persist deltas such as:

- terrain modified by Player/NPC/world event;
- destroyed/built structures;
- depleted resource nodes where persistent;
- changed cave barriers;
- roads/settlement construction;
- world-state overlays not derivable from the immutable generation seed.

Breaking generator compatibility requires an explicit migration/version policy; never silently regenerate an existing world under a new algorithm.

## Natural Terrain Principle

Terrain should avoid obviously artificial extremes caused by unconstrained noise.

Generation evaluates constraints such as:

- plausible elevation slopes/gradients;
- connected drainage;
- basin/valley formation;
- coast compatibility;
- mountain continuity;
- traversal/gameplay accessibility;
- settlement-capable land supply;
- biome transition coherence.

Stylization is allowed; physical plausibility exists to make the world readable and believable, not to run a scientific Earth simulator.

## Hydrology

Water placement should be derived from terrain/elevation flow rather than scattering decorative disconnected rivers.

Conceptual process:

1. generate/smooth elevation field;
2. identify drainage directions/basins;
3. accumulate runoff/flow;
4. classify streams/rivers by accumulated flow;
5. route water toward lower basins/coast where valid;
6. create lakes/wetlands where terrain traps water;
7. mark significant elevation drops for waterfall presentation;
8. validate that major rivers do not climb terrain or terminate arbitrarily without a basin/geological reason.

Small fantasy exceptions may be authored explicitly.

## Waterfalls

When a valid watercourse crosses a significant elevation step, the environment system can represent a waterfall/cascade rather than forcing a flat river ribbon.

Waterfalls expose navigation/visual/audio hooks but do not require fully simulated fluid dynamics.

## Biomes

Biome placement consumes climate/elevation/world-role signals rather than only random paint.

Candidate inputs include:

- elevation;
- moisture/water access;
- temperature/latitude proxy if used;
- slope;
- geology;
- magical/convergence influence;
- authored regional constraints.

Biome definitions provide compatible terrain material profiles, flora/fauna/resource pools and environment presentation.

## Settlement Suitability

Generation evaluates potential locations for villages, cities and capitals.

Suitability may consider:

- reasonably buildable/flattenable area;
- slope/elevation;
- water access;
- food/farmland potential;
- resource access;
- road/route connectivity;
- defensibility;
- distance from severe hazards;
- strategic/faction position;
- room for future building expansion;
- chapter/world-design constraints.

## Settlement Count Guarantees

The first world profile should define target/minimum ranges for settlements so a bad seed does not accidentally create a continent with no viable towns.

Current design direction is approximately:

- many villages across both sides, potentially around forty total at full Chapter 1 scale;
- several cities per side;
- a small number of capitals per side, with three currently preferred as a strategic layout direction.

These are world-content/tuning targets, not hard-coded engine constants.

If the terrain lacks enough high-quality candidates, generation can use bounded remediation such as:

- local terrain relaxation/flattening;
- shifting settlement candidate position;
- widening a valley/plateau within limits;
- rerunning a local generation stage;
- rejecting the seed/profile if constraints remain impossible.

Do not place a capital on unusable terrain merely to satisfy a count.

## Capitals and Strategic Layout

Capitals can use stronger authored/strategic constraints than ordinary villages.

Current direction allows:

- one major forward/central capital supporting the contested war front;
- additional rear/flank capitals supporting resources, recovery and strategic depth.

Exact positions may be generated inside constrained strategic zones or use semi-authored anchor regions. The system should support both without making every village authored manually.

## Villages and Cities

Settlements are built from the canonical modular Building system.

World generation/settlement planning chooses:

- site/footprint;
- road entries;
- district/zoning anchors;
- blueprint families;
- initial population/economic role;
- required civic structures;
- defensive layout.

The resulting houses, walls and facilities remain real Building pieces rather than one indestructible settlement mesh.

## Roads and Paths

After important sites are chosen, route planning can connect settlements/resources/strategic points using terrain cost.

Road placement should prefer sensible gradients and crossings while allowing bridges, switchbacks and authored strategic roads where needed.

Roads are world state and can later be improved/damaged/redirected where gameplay supports it.

## Cave Generation

Caves are procedural/semi-procedural underground networks tied to region geology and depth.

A cave definition/system can include:

- entrance position;
- depth/elevation range;
- chamber/corridor graph;
- branch/dead-end rules;
- vertical transitions;
- water/lava/magical environment where applicable;
- biome/geology profile;
- resource depth bands;
- creature/ecology profile;
- breakable barriers;
- exit/connection constraints;
- seed/version.

Caves should remain navigable/readable rather than unrestricted random tunnels.

## Depth and Resource Geology

Cave depth is a first-class query used by resource generation.

A mineral/gem/resource definition declares valid depth/geology bands. Distribution happens only inside valid bands.

Deep host rock may transition to harder visual/material families such as provisional `blackstone`, enabling both visual progression and tool/structure gating.

Very rare resources can use global/world allocation validation to ensure a bounded minimum discoverable supply while preserving rarity.

## Breakable Cave Progression

Selected cave walls can be intentionally breakable to gate deeper routes.

They must be visually differentiated through cracks/material language and expose canonical durability/tool requirements.

Destroyed barriers persist and update traversal/navigation state.

## Terrain Modification by Players/Actors

The world supports bounded terrain editing rather than unlimited voxel excavation.

First direction:

- flatten local terrain;
- raise terrain by a limited amount;
- lower terrain by a limited amount;
- prepare ground for construction/roads/agriculture;
- preserve world/region constraints preventing destructive invalid geometry.

Terrain edits become persistent deltas and must integrate with collision/navigation/building support.

Large-scale tunneling through arbitrary terrain is not implied by this first scope.

## Props and Environment Placement

After base terrain/biomes, environment passes can place:

- trees;
- rocks;
- resource nodes;
- shrubs/grass;
- ruins;
- landmarks;
- biome props;
- cave entrances;
- water-edge content.

Placement uses biome/slope/density/clearance rules and keeps settlement/road reservations intact.

The visual system prefers reusable simple 3D meshes plus coherent material/surface profiles where possible.

## Runtime Streaming Boundary

World generation is not the same system as runtime streaming.

Generated world data is partitioned/addressed by Regions/Chunks. Runtime decides which visuals, collision, navigation and high-fidelity entities are resident according to the existing Region/Simulation LOD architecture.

Do not rerun expensive whole-world generation because a chunk becomes visible.

## Server Creation Modes

The architecture should support at least:

- **official/fixed world profile:** approved seed/profile used by official content;
- **private seeded world:** owner chooses/receives seed and generation options;
- **future custom/authored world profile:** selected constraints/overrides.

A world is generated at creation/administrative regeneration time, not every client connection.

## First Representative A2 World

A2 does not need the full Chapter 1 continent at final scale.

The first Player-complete environment should prove one representative region containing:

- natural height variation;
- stream/river segment connected logically to broader drainage;
- one waterfall or meaningful elevation-water interaction if suitable;
- biome/material transition;
- trees/rocks/resources;
- one cave with depth/resource bands and one readable breakable barrier;
- one settlement site/blueprint composition;
- traversal/jump/slope behavior;
- gatherable nodes;
- persistence of at least one terrain/resource/world change;
- streaming/performance measurement on target mobile hardware.

## Explicit Deferrals

Not frozen here:

- final continent dimensions;
- exact total village/city/capital counts;
- final biome list;
- full erosion/fluid simulation;
- full procedural city street planner;
- unrestricted terrain destruction;
- final cave algorithm implementation;
- complete Chapter 1 authored landmarks;
- final official world seed.

## Acceptance Principle

A2 is not Player Complete because Perlin/noise terrain exists. The representative region must look and behave like a coherent place: water follows terrain, resources respect geology/depth, settlements have viable sites, environment props belong to biome rules and persistent world changes survive reload.