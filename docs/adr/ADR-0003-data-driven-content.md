# ADR-0003 — Data-driven Content

- **Status:** Accepted
- **Date:** 2026-10-13

## Context

O jogo precisa suportar muitas criaturas, itens, magias, receitas, profissões e variações sem exigir edição de código central para cada conteúdo novo.

## Decision

Adotar conteúdo data-driven com IDs estáveis, schemas validáveis e composição de comportamentos reutilizáveis.

## Consequences

### Positive
- criação de conteúdo mais rápida;
- menos branches hard-coded;
- melhor suporte a ferramentas internas;
- validação automática em CI;
- maior compatibilidade com agentes/IA.

### Cost
- schemas e migrações precisam ser mantidos;
- tooling inicial exige investimento.

## Rule

Se comportamento reutilizável já existe, novo conteúdo deve preferir definição de dados em vez de novo código específico.
