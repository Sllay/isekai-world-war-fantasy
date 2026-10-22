# Isekai World War Fantasy — Art Direction

- **Version:** 0.2.0
- **Status:** Production direction
- **Updated:** 2026-10-22

## Visual thesis

The game uses a hybrid **3D systemic world + authored pixel-art presentation**.

The world remains true 3D for terrain height, hills, cliffs, bridges, jumping, structures, physics, camera rotation and spatial gameplay. Characters and many readable gameplay-facing assets use crisp pixel art integrated into that world through `Sprite3D`, controlled lighting and carefully authored materials.

The previous production direction based on modular vector characters, three-view vector rigs, procedural bone deformation and IK is retired. Existing placeholder vector/billboard work remains valid only as technical prototype evidence and must not define final character presentation.

Core visual goals:

- strong readability on mobile at gameplay zoom;
- coherent pixel density and palette discipline;
- expressive fantasy silhouettes without requiring high-cost bespoke character animation production;
- world depth, lighting and terrain that clearly remain 3D;
- characters that visually belong in the world despite being pixel sprites;
- scalable modularity for races, clothing, armor, weapons and tools;
- predictable asset generation that can be automated and validated.

## Character asset foundation — LPC

Production humanoid characters should use the **Universal Liberated Pixel Cup (LPC/ULPC) ecosystem** as the primary modular asset foundation when the selected asset licenses are compatible with the target distribution.

LPC is an upstream content source, not runtime authority and not a network dependency. The shipped game must never depend on an online LPC service to construct a player.

The project owns an offline import/composition pipeline that consumes pinned LPC source metadata and produces validated game-ready assets.

Detailed pipeline and licensing contract: `docs/design/LPC_CHARACTER_PIPELINE_AND_LICENSING.md`.

## Pixel density and filtering

- Preserve nearest-neighbor pixel edges for character sprites and intentionally pixel-art textures.
- Avoid unintended smoothing, mip bleeding and sub-pixel shimmer.
- Atlas padding must prevent neighboring animation frames from bleeding into one another.
- Pixel density is authored around gameplay readability rather than arbitrary screen resolution.
- Camera and sprite scaling should prefer stable pixel presentation where practical, but gameplay camera motion must not become mechanically constrained merely to force integer-perfect rendering.

## Character presentation in the 2.5D world

Characters are upright `Sprite3D`-style presentations inside the true 3D world.

The production contract is **four-direction authored facing** when using standard LPC content:

- north/back;
- south/front;
- east/side;
- west/side.

Eight-direction art may be supported later by content that explicitly provides it, but the game architecture must not fabricate diagonal art by rotating or distorting a four-direction sprite.

### World-facing versus camera-facing

Gameplay facing belongs to the actor/world state. Camera rotation does not rotate the canonical character direction.

A presentation-only `DirectionResolver` compares:

- the actor's canonical horizontal facing vector;
- the camera's horizontal basis/view vector.

It selects the correct LPC visual direction relative to the current camera. Therefore a character physically facing east can appear front, side or back as the camera rotates around that actor while the underlying actor orientation remains east.

Use angular hysteresis/dead bands around direction boundaries to prevent rapid visual flipping when the camera sits close to a quadrant threshold.

The sprite plane may use a constrained vertical/Y billboard strategy so it remains readable toward the camera without tilting unnaturally with an inclined camera.

## Character composition model

LPC content is modular, but production gameplay should not naively keep every body/clothing/equipment layer as an independently animated `Sprite3D` draw object.

Preferred pipeline:

1. resolve race/body/appearance/equipment data;
2. resolve required LPC layers and palette variants;
3. composite compatible layers into game-ready animation sheets or cached textures;
4. validate animation/frame alignment;
5. present the composed result through a minimal number of runtime draw surfaces.

Runtime-separated layers remain allowed when they provide a real benefit, for example special foreground effects, independently moving equipment, emissive overlays or exceptional occlusion cases. They are the exception rather than the default.

Benefits:

- lower draw-call/material pressure on mobile;
- no layer drift between body, clothes and equipment;
- simpler animation synchronization;
- deterministic appearance caching;
- easier normal-map generation;
- cleaner persistence/network representation.

## Race visual profiles

Race identity is curated. Character creation does not expose every LPC body component as an unrestricted assembly kit.

Each playable race has a data-driven `RaceVisualProfile` that declares:

- allowed body/base families;
- required racial layers/features;
- allowed skin palette set;
- allowed eye palette set;
- allowed hair/facial-hair families and colors where applicable;
- allowed starter clothing families;
- body scale/presentation profile;
- compatible equipment/body tags;
- optional markings, ears, horns, tusks or race-specific overlays.

Examples of direction, not final content counts:

- humans/dwarves: curated human skin ranges;
- elves: mandatory elf ear/body profile plus curated human/fantasy skin ranges;
- ogres: blue/green and blue-green skin families with ogre-specific body/marking profiles;
- vampires: intentionally pale or deeply saturated skin variants with stronger fantasy eye palettes.

A saved appearance stores stable IDs and palette choices, not raw generated pixels as canonical identity.

Example conceptual data:

```text
race_id = dwarf
body_variant = adult_a
skin_palette = skin_05
hair_style = long_03
hair_palette = brown_02
eye_palette = green_01
outfit_profile = starter_02
```

Required racial pieces are derived from the race profile rather than trusted from the client.

## Body scale and gameplay geometry

Visual race scale may vary, but visual scale must not implicitly become collision/gameplay authority.

A dwarf may render at a smaller uniform visual scale and an ogre at a larger scale, while canonical gameplay capsules, reach, camera anchors and navigation dimensions are defined by race/gameplay data.

Do not non-uniformly stretch pixel characters merely to create race proportions.

## Equipment, tools and material recoloring

Equipment remains data-driven gameplay state. Visual equipment references LPC-compatible layers or project-authored compatible art.

Tools and equipment should support palette/material variants rather than duplicate nearly identical sheets for every material.

Conceptual example:

```text
tool_visual = pickaxe_01
handle_material = oak
head_material = iron
```

Presentation maps canonical material IDs to approved visual palettes such as wood, iron, gold or fantasy materials.

Gameplay statistics come from item/material definitions. Color never becomes gameplay authority.

Material recoloring should preserve authored pixel clusters, ramps and contrast instead of applying arbitrary hue shifts that destroy the LPC visual language.

## Animation architecture

LPC frame data is imported into a project-owned animation definition layer.

Godot presentation should use:

- `AnimationPlayer` as the authored/imported clip holder where appropriate;
- `AnimationTree` / state machines / one-shot transitions for high-level presentation flow;
- semantic gameplay animation requests rather than combat code directly selecting frame numbers.

Expected semantic states include:

- idle;
- walk/run;
- attack families;
- cast;
- gather/tool-use;
- hurt/stagger;
- jump/fall/land where supported;
- sleep/offline-body pose;
- death.

Not every upstream LPC asset supports every expanded animation. Content validation must know which animation families exist for a composition and provide explicit fallback policy rather than silently misalign layers.

Gameplay timing remains authoritative in gameplay systems. Animation presents wind-up/commit/recovery; it does not decide whether damage, harvest or crafting succeeded.

## Pixel normal-map direction

The project intends to build an internal sprite-normal tool specialized for pixel art and spritesheets.

Generic whole-image normal generators are not accepted as the final pipeline because adjacent frames and transparent atlas borders can contaminate gradients.

The intended pipeline is frame-aware:

1. read the sheet/frame manifest;
2. isolate each animation frame with transparent padding;
3. derive or ingest a height/surface mask;
4. compute per-frame pixel-preserving normal information;
5. avoid cross-frame bleeding;
6. rebuild a normal atlas with identical frame coordinates;
7. validate orientation in Godot lighting.

Possible sources include silhouette distance fields, controlled luminance-to-height, semantic material masks and project-authored height hints. Filters must remain pixel-aware and configurable by material family.

The normal map is presentation only. Failure to generate one must never modify gameplay geometry or collision.

## Environment direction

The environment should visually support the pixel characters rather than reproduce the retired clean-vector style.

Preferred language:

- stylized/pixel-aware terrain albedo;
- clear material families for grass, dirt, stone, wood, ore and constructed surfaces;
- controlled texture repetition;
- true 3D terrain/structures with readable pixel-texture treatment;
- limited high-frequency noise;
- lighting that gives volume without washing out pixel clusters;
- VFX/UI that can be smoother when useful but remain stylistically compatible.

Environment texture tooling may be custom-built and can generate/recolor tileable material families independent of LPC.

## Palette language

The game uses curated palette families rather than unrestricted RGB selection for canonical character creation.

Palette families should exist for:

- skin;
- fantasy skin;
- eyes;
- hair;
- cloth;
- leather;
- wood;
- neutral/colored metals;
- magic/faction accents;
- biome/world materials.

Players choose approved variants exposed by race/body/equipment rules. This preserves racial art direction and avoids visually broken combinations.

## Asset identity and cache keys

Generated appearance is derived data.

A deterministic visual cache key should be derived from stable source data such as:

- pinned LPC source/catalog version;
- body/race profile IDs;
- ordered layer IDs;
- palette IDs;
- animation profile;
- composition pipeline version;
- normal-map pipeline version when relevant.

Two actors with the same visual recipe should be able to reuse composed assets rather than generate duplicate textures.

## Mobile/Web performance rules

- Prefer composed/cached character sheets over many independently animated transparent layers.
- Avoid per-frame texture composition.
- Rebuild appearance only when appearance/equipment changes.
- Use lazy generation plus bounded cache eviction where required.
- Keep logical appearance data tiny for networking/persistence.
- Do not synchronize texture bytes over gameplay networking when peers can resolve approved asset IDs locally.
- Profile overdraw, texture memory, atlas size, material switches and normal-map cost on Android.
- Allow distance LOD to simplify animation frequency, shadow/normal usage or presentation detail without changing canonical actor state.

## Licensing and provenance requirement

No LPC-derived asset enters production without machine-readable provenance.

Every imported source piece must retain, where available:

- source asset ID/path;
- upstream revision;
- author/attribution parties;
- source URL;
- license option(s);
- modification/derivative status;
- generated output dependencies.

The project keeps both:

1. a complete upstream LPC legal/catalog archive, including entries not currently used;
2. an exact build manifest of assets actually used/generated by this game.

The in-game Credits screen is generated from project manifests. Full details: `docs/design/LPC_CHARACTER_PIPELINE_AND_LICENSING.md`.

## Acceptance checklist

Reject/revise character presentation when any of these are true:

- camera rotation changes canonical actor facing;
- direction flips rapidly near quadrant boundaries;
- body/clothing/equipment frames drift out of alignment;
- a race can select combinations outside its visual profile;
- palette recoloring destroys pixel clusters/value hierarchy;
- equipment color is treated as gameplay material truth;
- appearance requires an online LPC service at runtime;
- generated assets have missing author/license/source provenance;
- atlas filtering causes frame bleed or blurred pixel edges;
- normal generation leaks neighboring frame information;
- runtime composition produces unacceptable mobile draw-call or memory cost;
- presentation logic becomes authoritative for combat/items/movement.

## Migration from the retired vector direction

The previous vector/IK character direction is superseded by this document.

Keep reusable concepts only where they remain valid:

- data-driven appearance;
- equipment as gameplay-owned visual state;
- race compatibility tags;
- strong mobile readability;
- true 3D world/camera/elevation.

Retire as production assumptions:

- three-view front/back/side vector character sets;
- full modular body rendering as independent vector pieces;
- bone/IK-driven deformable humanoid characters as the default player pipeline;
- vector-only world identity;
- procedural squash/stretch as the primary humanoid animation method.

No completed gameplay/authority work needs to be rewritten solely because of this art migration.