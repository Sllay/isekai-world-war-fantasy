# Isekai World War Fantasy — Art Direction

## Visual thesis

The game uses a modern stylized vector look with a deliberate contrast:

**cute, readable and vibrant on the surface; harsh, war-torn and emotionally heavy underneath.**

The target is not photorealism, retro pixel art or a generic flat-vector look. The world should feel authored, coherent and immediately recognizable as this game.

Core visual goals:

- soft/cute silhouettes without becoming childish;
- vibrant but controlled color;
- strong readability on mobile;
- clean vector construction with enough secondary detail to avoid looking unfinished;
- stylized damage, scars, blood, dirt and war consequences as a controlled "light gore" layer rather than photorealistic gore;
- consistent shape language across characters, creatures, foliage, props, buildings and equipment;
- modular character visuals that support equipment, animation, IK and view-dependent layering.

## Shape language

Prefer:

- rounded primary masses;
- readable silhouettes;
- compact, slightly exaggerated proportions;
- asymmetry in secondary details where it adds character;
- large readable forms first, small detail second;
- restrained sharp accents for weapons, armor, hostile creatures, ruins and corrupted magic.

Avoid:

- random flat geometric shapes with no material logic;
- over-detailed silhouettes that collapse at mobile scale;
- one visual language for characters and a completely different one for the environment;
- black outline everywhere by default;
- generic stock-vector appearance.

The visual hierarchy should usually be:

1. silhouette;
2. major color blocks;
3. face/equipment/material read;
4. secondary detail;
5. small accents.

## Palette system

The game uses a shared palette language rather than independent colors per asset.

### Global behavior

- medium-to-high saturation for focal objects;
- lower saturation for background/supporting surfaces;
- warm/cool contrast used to separate factions, danger, magic and biome mood;
- shadows should normally shift hue, not merely become black;
- highlights should remain controlled so vector assets do not become plastic/glossy by accident.

### Provisional palette families

These are direction tokens, not immutable final hex values:

- natural green: grass, foliage, food, life;
- warm earth: soil, leather, wood, homes;
- cool stone: rock, metal-neutral architecture;
- warm gold: wealth, light, selected magical accents;
- saturated blue family: temporary Blue-faction visual language;
- saturated red family: temporary Red-faction visual language;
- violet/cyan/unstable contrast: Convergence / Dead Zone phenomena;
- controlled deep crimson: wounds/blood, used as an event accent rather than a permanent dominant palette.

Asset authors must reuse palette tokens or documented variants before inventing new hues.

## Cute + dark contrast

The setting must support adorable creatures, expressive faces and pleasant towns while still making war feel consequential.

The darker layer may include:

- blood decals/effects;
- bruises, bandages and wounds;
- chipped/broken armor;
- damaged equipment;
- burnt vegetation;
- ruins;
- bodies/remains where appropriate;
- dirt, ash and battle wear;
- frightened, exhausted or grieving expression sets.

Keep this stylized and readable. Do not chase anatomical gore realism. The contrast works because the base world is appealing and alive.

## Character presentation in the 2.5D world

The M1.2 proof may use a simple camera-facing billboard. That is a technical placeholder only.

The intended production presentation is camera-relative **three-view character art**:

- front;
- back;
- side.

The side view is mirrored horizontally (`flip_h`) for left/right rather than requiring a fourth authored view.

The selected view depends on the character/world facing direction relative to the camera. The final rig should not force the complete character image to stare at the camera at all times.

## Modular character rig

Characters are assembled from separate visual parts driven by bones/IK and procedural transforms rather than full-body frame-by-frame spritesheets.

Typical authored parts may include:

- rear hair/accessories;
- rear hand/arm;
- rear leg/foot;
- torso/body;
- clothing base;
- front leg/foot;
- front arm/hand;
- neck/head;
- ears/horns/species features;
- face features;
- front hair;
- helmet/hat;
- chest/shoulder armor;
- held item/weapon/tool;
- front accessories/effects.

Exact ordering changes by view and pose. Layer order is therefore metadata, not an assumption baked into one SVG.

### Layering rule

Every modular visual asset must declare whether it belongs behind, inside or in front of the body region it attaches to.

Example: a hat must not accidentally render entirely behind the head if its brim/crown should visually overlap the face/hair.

Complex equipment may be split into multiple pieces such as `helmet_back` and `helmet_front` so the rig can place the head between them.

## Equipment as visual skin layers

Armor, accessories, weapons and tools use the same modular attachment system as character visuals.

Equipment definitions should be able to provide:

- one or more visual pieces;
- supported views;
- attachment socket/bone;
- local pivot/offset;
- draw/layer class;
- optional palette/material variants;
- optional deformation/secondary-motion behavior.

A sword is not painted permanently onto the character. It is an equipped visual attached to the hand/weapon socket. The same principle applies to tools, shields, backpacks, hats and visible accessories.

## View-dependent layer ordering

The rig must support ordering changes by orientation.

For example, the same sword may be:

- behind the torso in one side/back pose;
- in front of the torso in another;
- partially occluded by a hand or sleeve.

Do not rely on one global static Z-order for all views.

## Vector authoring rules

Vector is the authoring language, not permission to create arbitrarily complex SVGs.

Prefer:

- clean closed shapes;
- named groups/layers;
- stable pivots;
- small number of purposeful gradients;
- minimal masks/clipping paths;
- no gratuitous SVG filters;
- reusable material/palette tokens;
- simple geometry that remains readable after rasterization/import.

Avoid:

- hundreds of tiny paths for texture noise;
- unnecessary blur/filter stacks;
- hidden junk geometry;
- accidental overlapping shapes that only look correct at one scale;
- relying on SVG DOM order alone when the runtime needs modular layering.

Source vector files remain editable. Runtime representation may be rasterized/imported/atlased when profiling shows it is cheaper on mobile/Web.

## Asset metadata

Production visual pieces should eventually expose metadata such as:

- `asset_id`;
- `view` (`front`, `back`, `side`);
- `attachment_socket`;
- `pivot`;
- `layer_class`;
- `layer_bias`;
- `mirror_allowed`;
- `palette_profile`;
- `material_profile`;
- `bounds`;
- `secondary_motion_profile`;
- compatibility tags for race/body/equipment families.

Do not encode all of this implicitly in filenames or hardcoded scene logic.

## Environment consistency

Trees, rocks, buildings, props and terrain decorations must use the same world language:

- similar edge softness;
- similar value contrast;
- compatible palette;
- compatible amount of detail;
- compatible light/shadow logic;
- readable silhouettes at gameplay zoom.

An asset is not approved merely because it looks good in isolation. It must look like it belongs in the same world.

## Detail budget

Detail is hierarchical.

### Character/interactive focal assets

May receive:

- layered clothing seams;
- material breaks;
- readable buckles/plates/pouches;
- small race features;
- surface wear;
- facial details.

### Environment/support assets

Use broader shapes and fewer high-frequency details so they do not compete with characters or UI-relevant action.

The game should never become a wall of equally loud detail.

## Mobile/Web performance rules

- Design assets for gameplay zoom first.
- Preserve vector masters, but do not assume live complex vector rendering is free.
- Minimize draw pieces that do not contribute meaningful animation/layering.
- Prefer reusable pieces and palettes over unique duplicated textures.
- Profile rig complexity, overdraw, material switches and attachment count on Android.
- LOD may reduce secondary visual pieces or animation complexity at distance.

## Asset creation workflow

Before producing an asset:

1. Define gameplay role and expected screen size.
2. Choose the palette family/material language.
3. Define the silhouette.
4. Define required views.
5. Write a layer/occlusion plan.
6. Define pivots/sockets when modular.
7. Create the vector shapes from large to small.
8. Validate layer order and mirror behavior.
9. Validate at actual gameplay scale.
10. Validate inside the Godot world, not only in an SVG preview.
11. Only then polish secondary detail.

## Acceptance checklist

Reject or revise an asset when any of these are true:

- it looks like unrelated stock vector art;
- its palette breaks the world palette without a reason;
- major layers are in the wrong depth order;
- equipment clips through the body in normal poses;
- the silhouette fails at mobile scale;
- detail is inconsistent with neighboring assets;
- side mirroring exposes asymmetry that should have its own variant;
- pivots/sockets are missing or wrong;
- the asset depends on accidental SVG ordering;
- a character/equipment piece only works from one camera angle despite requiring multiple views.

## Current M1.2 feedback

The first 2.5D proof validates the technical concept:

- true 3D world;
- visually 2D player presentation;
- rotatable inclined camera;
- ground movement and jump/elevation;
- stable ~60 FPS observed on the initial Android test, with occasional 59 FPS dips.

This does **not** freeze the final art implementation. In particular:

- camera rotation sensitivity should be tuned upward from the first proof;
- full camera-facing billboard behavior is temporary;
- production characters should adopt the three-view modular rig described above;
- final vector art requires stronger palette, detail and layer discipline than placeholder assets.
