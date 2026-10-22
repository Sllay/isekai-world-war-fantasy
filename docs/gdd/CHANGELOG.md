# GDD Changelog

## [0.3.0] - 2026-10-22

### Added
- Universal LPC/ULPC as the primary modular humanoid pixel-art asset foundation.
- Camera-relative four-direction character presentation while preserving canonical world-space facing.
- Data-driven `RaceVisualProfile` direction for curated race bodies, required features and palette choices.
- Offline/cached LPC composition instead of defaulting to many independently animated runtime layers.
- `AnimationPlayer` + `AnimationTree` semantic presentation direction for LPC animation state flow.
- Internal frame-aware pixel normal-map tooling direction for spritesheets.
- Full pinned-upstream LPC license/catalog archive plus exact used-asset manifest.
- Generated in-game Credits/legal resources and target-aware license validation direction.
- Main lobby/account shell with logged-out/logged-in states, official/community server separation and Audio/Graphics/Language options.
- Stable hidden account ID separated from a unique public account name and server-authoritative rename cooldown.
- Discoverable Credits screen and separate Donate/Support entry.
- Persistent offline player-body design: disconnect leaves the canonical character sleeping in the world.
- Offline death/theft/world consequences persist across reconnect.
- Server-residency lifecycle and cleanup based on significance/reference safety rather than inactivity alone.
- Active -> dormant -> compacted -> purge-candidate lifecycle for trivial server residencies.

### Changed
- Retired the production assumption of custom modular vector humanoids using three views, bones/IK and procedural deformation.
- Character/world presentation now targets a true 3D systemic world with pixel-art character and material language.
- GDD Presentation section now references LPC art/provenance contracts and ADR-0017.
- Player persistence now explicitly treats presence after disconnect as a gameplay/world rule rather than merely a save concern.
- Credits/legal attribution is now a first-class product-shell requirement.

### Preserved
- Existing gameplay authority, combat, movement, items/resources and persistence contracts remain valid; the LPC migration is a presentation/art-pipeline change and does not restart C1-R1-P2.

## [0.2.0] - 2026-10-15

### Added
- Mobile-first combat interaction contract separating skill selection from execution.
- Dynamic left-side joystick zone and contextual right-side combat control direction.
- Three visible skill slots per page with page rotation for larger equipped skill sets.
- Dedicated quick-consumable binding and separate bottom utility hotbar direction.
- Explicit targeting families for contextual, directional, precision/free-aim and ground/area actions.
- Inventory popup behavior that preserves movement/jump while suppressing combat context.
- Vertical mobile inventory grid direction with approximately five columns, responsive up to six.
- Fixed-slot versus dynamic-slot bag capacity semantics.
- Canonical item mass / effective bag weight separation and category-specific weight modifiers.
- Production timing rule: document future UX now, implement each part only when its owning gameplay system is ready.

### Updated
- Combat design now treats lock-on as optional assistance rather than universal auto-aim.
- Bag design now separates slot capacity from weight capacity and defines stack allocation behavior.
- GDD mobile-first pillar now has concrete combat/inventory interaction direction.

## [0.1.0] - 2026-10-13

### Added
- High concept e pilares do projeto.
- Premissa da Convergência entre dois mundos.
- Guerra dinâmica Azul/Vermelho.
- Separação entre raça, origem, facção, lealdade e reputação.
- Premissa isekai do jogador como anomalia externa.
- World Simulation independente do jogador.
- Direção de combate, classes, magia modular e bosses.
- Survival, crafting, building, criaturas e domesticação.
- Quests sistêmicas, economia dinâmica, profissões e equipamentos.
- Direção visual 2.5D e foco mobile/Web.
