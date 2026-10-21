# Changelog

Todas as mudanças relevantes de escopo, arquitetura e implementação serão registradas aqui.

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
