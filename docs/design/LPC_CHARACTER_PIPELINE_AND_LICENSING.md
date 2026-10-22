# LPC Character Pipeline, Provenance & Licensing

- **Version:** 0.1.0
- **Status:** First-scope production contract
- **Updated:** 2026-10-22

## Purpose

Define how Isekai World War Fantasy consumes Universal Liberated Pixel Cup (LPC/ULPC) character assets safely, reproducibly and offline while preserving attribution, license provenance and mobile-friendly runtime output.

This document covers the asset pipeline. It does **not** make LPC a runtime dependency and does not make any external generator authoritative for gameplay.

## Upstream source

Primary upstream reference:

- `LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator`

The upstream generator maintains structured spritesheets, palette definitions, source metadata and a `CREDITS.csv` catalog. Upstream documentation explicitly requires attribution for non-CC0 art and notes that individual pieces can have different supported license options/restrictions.

The project must pin a known upstream revision/commit before importing assets. Never silently rebuild shipped character art from an unpinned moving upstream branch.

## Core rule

> Every imported visual piece must be traceable from game output back to a pinned upstream source, author attribution and license record.

No production LPC-derived sprite is accepted if that chain is unknown.

## Repository layout — conceptual

The eventual project tooling should converge on a structure similar to:

```text
third_party/lpc/
  UPSTREAM_REVISION.txt
  upstream_credits.csv
  license_texts/
  catalog/
    lpc_full_catalog.json
    LPC_FULL_LICENSE_CATALOG.md
  manifests/
    lpc_used_assets.json
    lpc_generated_outputs.json
  presets/
    race_profiles/
    appearance_recipes/
  generated/
    characters/
```

Exact paths may change when implementation begins, but separation between upstream evidence, normalized catalog data and generated runtime output is mandatory.

## Full-catalog legal archive

The project intentionally stores a normalized legal/credit record for the **full pinned LPC catalog**, including entries not currently used in the game.

This is an archival/compliance convenience, not a claim that every upstream asset is used by Isekai World War Fantasy.

The extractor should preserve, where available:

- upstream asset path/ID;
- title/description;
- author(s)/attribution parties;
- source URL(s);
- supported license option(s);
- original attribution instructions;
- upstream revision;
- optional notes/restrictions;
- catalog extraction timestamp/tool version.

Generated outputs:

- machine-readable `lpc_full_catalog.json`;
- human-readable `LPC_FULL_LICENSE_CATALOG.md`;
- copies/links of relevant canonical license texts.

The extractor must be deterministic for a pinned upstream revision.

## Used-asset manifest

A second manifest records only assets actually included in a build or used to compose shipped sprites.

Each used entry should include:

- stable upstream asset ID/path;
- chosen license option when multiple are offered;
- author(s);
- source URL;
- whether the art was modified;
- derivative output IDs;
- race/body/equipment profiles that reference it where useful;
- first project version/build that used it;
- removal/deprecation state.

The distinction is important:

- **full catalog** = everything known from the pinned LPC source;
- **used manifest** = exact dependency graph of this game/build.

Do not list unused assets as if they were used credits.

## License policy and target-store compatibility

LPC assets may be available under combinations including CC0, CC-BY, CC-BY-SA, OGA-BY and GPL-family options. Requirements differ.

The project therefore needs a target-aware license policy rather than assuming that all LPC assets are equally safe for every distribution channel.

For every target build (Web, Android/APK, future store package, desktop), tooling should classify selected assets as:

- `ALLOWED`;
- `ALLOWED_WITH_ATTRIBUTION`;
- `ALLOWED_WITH_DERIVATIVE_DISTRIBUTION_REQUIREMENT`;
- `REVIEW_REQUIRED`;
- `BLOCKED_FOR_TARGET`.

This classification is project policy, not legal advice. When a license/target combination is uncertain, block release and require review rather than guessing.

A broad upstream catalog archive does not grant permission beyond each asset's actual license.

## DRM / share-alike caution

Some Creative Commons variants and GPL-style options can create distribution obligations or technical-measure/DRM concerns depending on the platform and selected license option.

Therefore:

- keep the selected license option per used asset;
- preserve original attribution instructions;
- track modified/derivative assets;
- keep distributable derivative/source art available when required;
- do not assume a store build is compliant merely because a Web build is compliant;
- prefer compatible license options/assets when equivalent visual choices exist.

## Generated character provenance

A composed character sheet is derived output, not a provenance dead-end.

Each generated artifact should include a sidecar manifest conceptually containing:

```json
{
  "output_id": "character.dwarf.starter_02.hash",
  "pipeline_version": 1,
  "upstream_revision": "<commit>",
  "layers": [
    {"asset_id": "...", "palette_id": "...", "license_choice": "..."}
  ]
}
```

The exact schema may evolve, but generated PNGs must never become orphan assets whose sources cannot be reconstructed.

## Deterministic appearance recipes

Canonical player appearance is represented by stable game data, for example:

- race profile;
- body variant;
- hair/eye/skin palette IDs;
- clothing/equipment visual IDs;
- animation profile.

The visual compositor resolves those IDs against the approved catalog and creates/reuses a cached artifact.

Do not persist generated texture bytes as the only definition of appearance.

## Race-profile validation

`RaceVisualProfile` controls which upstream layers and palette families are legal for a race/body combination.

The import/build validator should catch:

- missing required racial layers;
- unsupported animation combinations;
- incompatible body/equipment bases;
- layer ordering conflicts;
- missing palette mapping;
- license-incompatible dependencies;
- source entries with missing provenance.

A player/client may choose only among server-approved appearance IDs. Clients cannot inject arbitrary upstream asset paths.

## Composition pipeline

Preferred offline pipeline:

```text
pinned LPC source/catalog
        ↓
metadata/license normalization
        ↓
race + appearance recipe validation
        ↓
palette/material resolution
        ↓
layer composition per animation/frame
        ↓
optional pixel-normal generation
        ↓
atlas validation/padding
        ↓
generated manifest + cache key
        ↓
Godot import
```

No network call is required during gameplay.

## Pixel normal-map integration

Normal maps must be generated frame-by-frame using the same frame manifest as the albedo sheet.

The normal pipeline must record:

- source albedo artifact ID;
- frame-layout version;
- normal generator version;
- preset/material profile;
- any height/mask inputs.

Normal output must share frame coordinates with albedo output exactly.

Avoid whole-atlas gradient generation that allows one animation frame to influence neighboring frames.

## Credit generation

Credits are generated from structured manifests rather than maintained manually as the only source of truth.

The pipeline should produce at least:

- `CREDITS_GENERATED.md` for human-readable project attribution;
- a runtime-friendly structured credit resource (JSON/resource/database form);
- `LPC_FULL_LICENSE_CATALOG.md` for the complete archived upstream catalog;
- full license text/reference bundle required for distribution.

The runtime Credits screen may show concise grouped attribution and allow access to the detailed legal catalog.

## Credits-screen categories

The global Credits UI should support categories such as:

1. creator / project direction;
2. development contributors;
3. audio/music contributors;
4. visual/art contributors;
5. LPC/third-party visual attribution;
6. tools/libraries/open-source dependencies when required;
7. community/supporter/donor acknowledgements where consent exists;
8. full licenses/legal notices.

A donor/supporter section is acknowledgement only and must not blur into asset authorship/licensing.

## Automation requirements

Future tooling should expose commands conceptually equivalent to:

```text
lpc sync --revision <pinned>
lpc catalog validate
lpc compose <appearance_recipe>
lpc credits build
lpc licenses verify --target android
```

CI should fail when:

- a used LPC asset has no provenance entry;
- author/source/license data is missing for a non-CC0 dependency;
- generated output references an unknown layer;
- selected license policy is blocked for the target;
- a generated credit manifest is stale relative to used assets.

## Upstream updates

Updating LPC is an explicit dependency upgrade:

1. fetch candidate upstream revision;
2. regenerate full catalog;
3. diff authors/licenses/paths/palettes/frame definitions;
4. identify removed/renamed assets;
5. validate all project appearance recipes;
6. regenerate deterministic sample characters;
7. visual regression test representative races/equipment;
8. re-run license-target checks;
9. only then update the pinned revision.

Do not auto-track upstream `master` in production builds.

## Shipping policy

Every release that contains LPC-derived art must ship/disclose required attribution and legal notices in a reasonably discoverable way.

The main-menu Credits entry is part of this requirement, not decorative UI.

The game should also preserve credits/legal notices in exported files or package documentation where required by the chosen asset licenses.

## Non-goals

This contract does not:

- require every LPC asset to be bundled in the game;
- require unused sprites to consume runtime/storage budget;
- imply all LPC licenses are compatible with all stores;
- replace legal review for uncertain distribution scenarios;
- permit clients to select arbitrary unapproved layers;
- make art metadata authoritative for gameplay stats.

## Acceptance gate

The LPC production pipeline is ready when the project can prove:

- one pinned upstream revision;
- complete normalized upstream credit/license catalog;
- exact used-asset manifest;
- one race profile composed deterministically;
- one equipment/material palette change composed correctly;
- generated output traceable back to every source layer;
- generated runtime credits match used assets;
- target-license validator catches a deliberately blocked/unknown entry;
- gameplay runs without any LPC network/service dependency.