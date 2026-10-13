# ADR-0002 — Event-driven Integration

- **Status:** Accepted
- **Date:** 2026-10-13

## Context

Sistemas como combate, guerra, crime, reputação e quests precisam reagir aos mesmos acontecimentos sem criarem dependências diretas entre si.

## Decision

Adotar eventos de domínio tipados/estruturados para representar fatos consumíveis por múltiplos módulos.

## Consequences

### Positive
- reduz acoplamento;
- facilita extensão;
- permite múltiplos consumidores;
- melhora testes por módulo.

### Cost
- fluxo pode ficar difícil de rastrear sem tooling;
- eventos excessivos podem gerar event storms.

## Mitigation

Criar tracing de eventos, correlation IDs e ferramentas de inspeção em builds de desenvolvimento.
