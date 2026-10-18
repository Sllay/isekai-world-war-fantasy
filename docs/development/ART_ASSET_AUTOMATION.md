# Art Asset Automation Direction

- **Status:** Planned enabling infrastructure; not a blocker for A1 Combat
- **Updated:** 2026-10-18

## Goal

Give Codex a controlled art/asset tool layer analogous to Serena's code layer: Codex requests an asset by semantic specification, while a dedicated service applies the project's visual rules, generates or transforms the source asset, validates metadata, and returns game-ready candidates for integration.

This must not turn Codex into a low-quality procedural SVG artist by default.

## Visual source of truth

The service must consume rather than duplicate:

- `docs/design/ART_DIRECTION.md`;
- relevant character/environment/UI/material design documents;
- `skills/vector-art/SKILL.md` where applicable;
- future machine-readable style profiles derived from those sources.

Durable art direction stays in repository docs. Model/LoRA settings are implementation details of the asset backend.

## Proposed interface

Future logical API/MCP surface:

```text
art.describe_profile()
art.generate_2d(spec)
art.generate_texture(spec)
art.generate_ui_asset(spec)
art.transform_source(spec, source_asset)
art.prepare_material(spec, maps)
art.validate(asset)
art.export(asset, target_profile)
```

Codex should provide a structured asset specification rather than a vague image prompt.

Example fields:

```yaml
asset_id: character.human.base_male_01
category: character_2d
style_profile: iwwf.chibi_cartoon.v1
views: [front, back, left, right]
layering:
  body: true
  hair: separate
  equipment_sockets: true
palette_profile: human_warm_01
line_profile: soft_clean
usage: gameplay
license/provenance_required: true
```

## Style model / LoRA direction

A future backend may use a LoRA or another style adapter trained/curated around approved IWWF examples. The important contract is broader than a LoRA:

- palette constraints;
- brush/line behavior;
- shape language;
- character proportions;
- view/camera conventions;
- material response rules;
- texture density/tiling rules;
- category-specific constraints for humanoids, monsters, props, UI and terrain;
- negative constraints preventing unwanted realism/noise/detail drift.

The generation backend must be replaceable. Game content must not depend on one paid API or model vendor.

## 2D scope

Primary 2D/generated-art candidates:

- characters/humanoids;
- creatures/monsters when the gameplay representation is 2D;
- held items/tools/weapons where the chosen presentation is 2D;
- icons/UI illustrations;
- portraits;
- decals/FX source art where appropriate.

Character output should support layered/modular composition when required by equipment/customization, rather than baking every combination into one flattened image.

## 3D world scope

The world is primarily 3D. The art service is **not** expected to procedurally invent every complex production mesh.

Preferred hybrid workflow:

```text
licensed/original 3D source mesh
        -> license/provenance check
        -> topology/scale/import normalization
        -> project material profile
        -> generated/retargeted textures when useful
        -> Godot import preset
        -> LOD/collision/mobile validation
```

Codex can automate integration, material assignment, collision/LOD/import settings and metadata. Complex meshes may come from approved asset libraries, authored sources or future 3D-generation tooling.

## Materials and textures

The future service should be useful even when meshes come from elsewhere.

Candidate outputs:

- terrain albedo/normal/roughness masks;
- stylized grass/soil/stone textures;
- recolorable masks;
- trim sheets;
- simple prop textures;
- weapon/tool textures;
- stylized material parameter presets;
- UI atlases/icons.

For mobile, generated texture output must obey explicit resolution/compression/repetition budgets rather than defaulting to oversized source images.

## Asset manifest

Every integrated production asset should eventually have machine-readable metadata covering at least:

```text
stable asset id
source/provenance
license
style profile/version
generator/backend version when generated
source prompt/spec hash when relevant
output files/import targets
mobile budget class
review/acceptance status
```

This lets Codex reason about assets without opening every image/model and reduces accidental license/style inconsistencies.

## Safety and project rules

- Do not train a project LoRA on third-party art without compatible rights.
- Do not silently copy a named living artist's style as the project identity.
- Do not import found 3D assets without recording license/provenance.
- Generated output is a candidate until it passes art-direction and technical validation.
- Do not commit huge model weights into the game repository.
- Prefer a local/free backend where practical; remote backends must be optional adapters.

## Rollout

### Stage 0 — now

Document the contract and keep normal/manual asset integration working. Do not block A1 Combat on this service.

### Stage 1

Create machine-readable style/asset manifests and a simple validation/import CLI.

### Stage 2

Add one generation backend for a narrow, high-value category such as icons/simple 2D items or tiling material textures.

### Stage 3

Add project-trained/curated style adapter only after enough approved source examples exist and licensing/training data are clean.

### Stage 4

Expose the stable service as MCP/API so Codex can request, validate and integrate assets as part of Macro Version missions.

## Success criterion

The automation succeeds when Codex can request something like `basic iron sword icon`, `grass material variant` or `humanoid base layer` and receive an asset that is stylistically constrained, traceable, technically valid and cheap to integrate — without making the entire art pipeline dependent on Codex hand-writing vector shapes.
