# ADR-0001 — Modular Architecture

- **Status:** Accepted
- **Date:** 2026-10-13

## Context

O projeto possui escopo grande e muitos sistemas que evoluirão em ritmos diferentes. Acoplamento excessivo tornaria mudanças arriscadas e testes caros.

## Decision

Adotar arquitetura modular em camadas `Core -> Foundation -> Gameplay`, com dependências declaradas, contratos públicos e isolamento de features.

## Consequences

### Positive
- alterações mais cirúrgicas;
- testes isolados;
- features opcionais;
- menor risco de regressão em cascata;
- expansão mais segura.

### Cost
- exige disciplina de contratos;
- exige loader/registry e validação de dependências;
- aumenta trabalho inicial de infraestrutura.

## Rule

Gameplay não pode ser introduzido no Core apenas por conveniência.
