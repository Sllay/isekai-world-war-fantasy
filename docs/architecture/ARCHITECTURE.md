# Technical Architecture

- **Version:** 0.1.0
- **Status:** Draft
- **Updated:** 2026-10-13

## Objective

Permitir que um jogo de escopo grande seja desenvolvido em fatias pequenas, testáveis e substituíveis, minimizando regressões e dependências acidentais.

## Architectural Layers

### Core

Responsável apenas por infraestrutura indispensável:

- lifecycle do jogo;
- module registry/loader;
- event bus;
- entity identity;
- clocks/ticks;
- save/load foundation;
- networking foundation;
- data registry;
- logging/diagnostics;
- feature flags;
- service/contracts registry.

O Core não deve conhecer regras específicas de domesticação, magia, guerra, farming, quests ou qualquer feature de gameplay.

### Foundation Modules

Sistemas reutilizados por grande parte do gameplay:

- entities/components;
- attributes/status;
- movement;
- interactions;
- inventory;
- combat foundation;
- abilities foundation;
- faction identity;
- world state foundation.

### Gameplay Modules

Features independentes e expansíveis:

- war;
- quests;
- professions;
- economy;
- building;
- taming;
- crime;
- diplomacy;
- bosses;
- farming;
- magic;
- crafting;
- trading;
- infiltration;
- ecology.

## Dependency Rule

Fluxo preferido:

`Gameplay -> Foundation -> Core`

Core nunca depende de Gameplay.

Dependências circulares são proibidas. Sistemas que precisam reagir uns aos outros devem preferir eventos, contratos ou dados compartilhados bem definidos.

## Composition over Inheritance

Entidades são compostas por capacidades/componentes reutilizáveis em vez de grandes hierarquias de classes.

Exemplo conceitual:

- HealthComponent
- MovementComponent
- CombatComponent
- FactionComponent
- AIComponent
- LootComponent

Uma criatura não deve carregar dentro de si todos os sistemas opcionais que podem interagir com ela.

## Data-driven Content

Código implementa regras reutilizáveis; dados definem conteúdo.

Adicionar uma nova criatura, item, receita ou magia não deve exigir editar managers centrais quando os comportamentos necessários já existem.

## Event-driven Integration

Eventos representam fatos do domínio, por exemplo:

- EntityDamaged
- EntityDied
- TerritoryCaptured
- ReputationChanged
- CreatureTamed
- BuildingDestroyed

O produtor do evento não conhece todos os consumidores.

## Module Isolation

Cada módulo deve declarar:

- ID estável;
- versão;
- dependências obrigatórias;
- dependências opcionais;
- contratos fornecidos;
- eventos publicados/consumidos;
- dados registrados;
- estado persistente;
- testes.

## Feature Flags

Features incompletas ou experimentais devem poder ser desativadas em builds de desenvolvimento sem remover código.

## Testing Strategy

- unit tests para lógica pura;
- integration tests para contratos entre módulos;
- test worlds para comportamento visual/sistêmico;
- validação de schemas e dependências em CI;
- smoke test de build Web/mobile.

## Simulation LOD

A simulação usa níveis de detalhe:

- **High fidelity:** região próxima de jogadores; entidades e comportamento completos.
- **Reduced fidelity:** regiões relevantes porém distantes.
- **Abstract simulation:** conflitos, economia e ecologia resolvidos por estado agregado longe de jogadores.

## Failure Policy

Um módulo opcional com erro não deve derrubar silenciosamente o jogo inteiro. O loader deve:

1. validar manifesto;
2. validar dependências;
3. impedir inicialização inválida;
4. produzir erro legível;
5. expor status no Module Inspector.

## Performance Principles

- mobile/Web first;
- evitar updates por entidade quando processamento em lote servir;
- ticks escalonados por sistema;
- pooling para objetos frequentes;
- streaming por região/chunk;
- dados separados da representação visual;
- simulação abstrata fora da área ativa;
- profiling antes de micro-otimização.

## Change Rule

Se adicionar uma feature exige modificar muitos sistemas não relacionados, isso é sinal para revisar o contrato arquitetural antes de continuar.
