# Isekai World War Fantasy — Vector Art Creation Skill

Use this skill whenever creating, revising or integrating visual vector assets for the project.

Read first:

1. `docs/design/ART_DIRECTION.md`
2. the relevant gameplay/design document for the asset being created
3. this file

Do not generate visual assets from a vague prompt alone.

## 1. Define before drawing

For every asset, establish:

- gameplay role;
- expected on-screen size;
- whether it is focal, supporting or background;
- required views (`front`, `back`, `side`, or environment-only);
- whether side mirroring is allowed;
- palette family;
- material family;
- attachment/pivot requirements;
- expected layer order;
- whether the asset is modular, static or deformable.

If these are unknown, infer the smallest sensible set from the project art direction rather than inventing unrelated style.

## 2. Silhouette first

Before fine detail:

- make the outer silhouette readable;
- keep large masses simple;
- make the subject recognizable at gameplay zoom;
- avoid thin decorative noise that disappears on mobile.

Do not polish an unreadable silhouette.

## 3. Layer plan before SVG construction

Write the intended visual stack before drawing complex modular assets.

Character/equipment example:

```text
rear_accessory
rear_hair
rear_arm
rear_leg
body
clothing_base
front_leg
front_arm
head
face
front_hair
helmet_back/head/helmet_front as required
held_item
front_effect
```

This is a conceptual plan, not a mandatory fixed order for every pose.

If an object wraps around another object, split it into front/back visual pieces instead of forcing one incorrect layer.

Never accept mistakes such as:

- hat hidden behind the whole head when it should overlap;
- hand behind weapon when grip requires the opposite;
- rear leg drawn over the torso;
- armor plate intersecting the body because the asset was built as one flat image.

## 4. Modular character rules

Character body, equipment and accessories should be authored so bones/IK can control them independently.

Prefer separate pieces when movement or depth order can differ:

- upper/lower arms when needed;
- hands;
- upper/lower legs when needed;
- feet;
- torso;
- head;
- front/rear hair;
- front/rear equipment pieces;
- held weapons/tools.

Each piece should have:

- stable asset/group name;
- sensible local origin;
- pivot near its intended joint;
- no accidental transparent padding that changes alignment;
- clean bounds.

## 5. Three-view character language

Production humanoid characters use:

- front view;
- back view;
- side view;
- mirrored side view for the opposite lateral direction when visual asymmetry allows it.

Do not create four separate directions by default.

Create a dedicated left/right asset only when mirroring would produce a meaningful error, such as asymmetrical heraldry, a one-sided prosthetic, a unique weapon sheath or a hairstyle whose orientation matters.

## 6. Palette discipline

Use project palette families before inventing colors.

Rules:

- focal saturation > background saturation;
- avoid pure black shadows by default;
- shift hue in shadows/highlights when appropriate;
- keep material families coherent;
- do not introduce a unique color language for one asset without design reason;
- faction colors are accents, not an excuse to flood every surface with one hue.

Before approval, compare the asset with at least one existing world asset or palette reference.

## 7. Detail discipline

Add detail in this order:

1. silhouette;
2. primary masses;
3. major material/color breaks;
4. secondary forms;
5. focal small details;
6. wear/damage accents.

Never compensate for weak shape design with hundreds of tiny vector paths.

## 8. SVG construction rules

Prefer:

- named groups;
- meaningful path grouping;
- closed shapes where possible;
- minimal clipping/masks;
- limited gradients;
- no gratuitous filters;
- clean transforms;
- reusable colors/tokens;
- deterministic layer order.

Avoid:

- anonymous auto-generated path soup;
- hidden duplicate geometry;
- unnecessary blur/shadow filters;
- deeply nested transforms without purpose;
- tiny paths used as fake texture noise;
- geometry extending far outside visible bounds.

Vector masters must remain editable by humans and agents later.

## 9. Cute + war damage language

Base forms can be cute and expressive.

Damage should remain stylized rather than photorealistic.

Allowed direction includes:

- blood accents;
- bandages;
- bruising;
- chipped armor;
- torn cloth;
- burns/soot;
- broken gear;
- scars;
- damaged foliage/structures.

The contrast should communicate consequence without abandoning the project's stylized visual identity.

## 10. Environment asset rules

For trees, rocks, buildings, props and terrain decorations:

- match the same edge softness and palette logic as characters;
- keep gameplay silhouettes clean;
- use broad forms before texture detail;
- avoid photoreal textures pasted into a vector world;
- keep supporting assets quieter than playable characters and combat effects;
- verify that adjacent assets feel authored for the same world.

## 11. Equipment and skins

Armor/accessories/tools/weapons are modular visual layers, not permanent paint on the base body.

When creating equipment, define:

- supported body families;
- supported views;
- socket/bone;
- pivot;
- front/back split if needed;
- draw layer/class;
- mirror rules;
- palette/material variants.

Equipment should remain reusable across compatible characters without redrawing the whole character.

## 12. Runtime-aware authoring

Source format may be vector, but runtime cost still matters.

Before finalizing:

- remove unnecessary paths;
- avoid effects that require expensive compositing;
- keep animated piece count justified;
- consider whether distant LOD can hide secondary pieces;
- preserve vector masters even if runtime uses imported/rasterized textures;
- test on Android at real gameplay zoom.

Do not claim an asset is optimized solely because it is SVG.

## 13. Review workflow

For a new important asset:

### Pass A — structure
Check:

- silhouette;
- proportions;
- required views;
- layer plan;
- pivots/sockets;
- mirror behavior.

### Pass B — style
Check:

- palette;
- material consistency;
- shape language;
- detail density;
- compatibility with the world.

### Pass C — runtime
Check:

- Godot import;
- actual gameplay size;
- clipping;
- view switching;
- IK/bone deformation;
- equipment overlap;
- mobile performance when the asset is repeated.

Do not skip directly from generation to production use.

## 14. Common rejection reasons

Immediately revise when:

- a hat or armor layer is visibly behind/in front of the wrong body part;
- limbs detach or intersect under normal IK poses;
- side mirroring produces incorrect visual semantics;
- the asset looks like generic stock vector art;
- the palette feels unrelated to neighboring assets;
- detail is either empty/unfinished or excessively noisy;
- a character only looks correct when fully facing the camera;
- equipment cannot be separated from the base body;
- the SVG is technically valid but practically uneditable.

## 15. Output expectation for Codex/agents

When asked to create an important visual asset, report:

- intended gameplay role;
- views created;
- layer plan;
- palette/material profile;
- pivots/sockets;
- mirror rules;
- SVG path/group complexity at a high level;
- Godot validation performed;
- known visual compromises.

Do not spend large token budgets polishing an asset that has not passed silhouette/layer review first.
