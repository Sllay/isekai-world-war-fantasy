# Changelog

Todas as mudanças relevantes de escopo, arquitetura e implementação serão registradas aqui.

## C1-R1-P2 — Items, Resources & Survival Foundation (2026-10-22)

- Continued the completed, Android-accepted P1 on its own P2 branch; retained
  CombatService, ActionExecutor, semantic intent and the same authority inbox.
- Added typed item definitions, atomic bounded inventory/stack/custody, instance
  equipment, source-owned skill learning/grants and eligible persistent loadouts.
- Connected actual enemy carried stock to one-time world loot/pickup, authored
  wood/stone/ore nodes, equipped tools, seeded gathering and atomic material-aware
  hand/forge recipes. Stable balm consumes owned stock through canonical healing;
  finite coins share the same inventory path.
- Added minimal desktop/touch Items controls and world silhouettes; no final UI,
  item catalog, economy, survival balance or external server transport.
- Added save 0.4.0 with explicit P1 migration, custody/equipment/skill/resource
  cross-checks, forged/replay tests and exact fresh-process runtime validation.
  Repeated-save cache positions retain canonical transform precision.
- Preserved P1 gameplay assertions; old-release fixtures now explicitly remove
  the new module when modeling pre-P2 saves. See the P2 mission validation record.

## C1-R1-P1 — Foundation candidate (2026-10-21)

- Continued the integrated A1 Player/Combat/Authority implementation without
  replacing CombatService, ActionExecutor, telegraphs, enemy or save systems.
- Added trusted data-driven primary/three-skill loadouts, world-space mouse aim
  and bounded directional/point target-query integration in the existing executor.
- Added physics visibility to lock-on; reset aim/selection at respawn while
  preserving unrelated actors' stagger and committed cooldowns. Failed guard no
  longer grants accidental stagger immunity.
- Kept disconnected motor/recovery/combat fail-closed; expanded deterministic,
  adversarial, real-collider and integrated Runtime MCP validation. Final combat
  content, three universal skills, mobile UX/art and Android acceptance are Run 2.

## [0.1.0] - 2026-10-13

### Added
- Fundação inicial do repositório.
- Filosofia modular e data-driven.
- Estrutura de documentação.
- Regras para agentes/IA.
- GDD e arquitetura técnica iniciais em preparação.

### Project status
- Pré-produção.
- Nenhuma engine ou stack final foi congelada ainda.
