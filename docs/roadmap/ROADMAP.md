# Project Roadmap

## Development Principle

**Large scope, small steps.**

O projeto será construído por vertical slices e feature slices. Nenhuma fase deve exigir implementar o universo inteiro antes de produzir algo executável.

## Phase 0 — Pre-production

- consolidar GDD v0.x;
- definir arquitetura modular;
- registrar ADRs;
- escolher stack/engine após prova técnica Web/mobile;
- definir direção de arte vetorial;
- criar schemas/IDs iniciais;
- preparar testes e CI.

## Phase 1 — Core Prototype

Objetivo: provar que a fundação funciona.

- bootstrap do runtime;
- Module Manager;
- Event Bus;
- entity identity/components;
- input mobile/desktop;
- personagem movimentável;
- câmera 2.5D inicial;
- data registry;
- logging/debug overlay;
- primeiro test world.

## Phase 2 — Combat Vertical Slice

- attributes/health/resources;
- combat foundation;
- abilities modulares;
- um inimigo;
- telegraphs;
- dodge/block/interruption conforme protótipo;
- um mini-boss modular;
- equipment mínimo.

## Phase 3 — Living World Slice

- região/chunk;
- faction state;
- NPC foundation;
- simulation LOD;
- pequeno conflito Azul/Vermelho independente do player;
- território contestado;
- mapa estratégico debug.

## Phase 4 — Survival Slice

- resources;
- inventory;
- crafting;
- stations;
- construção modular mínima;
- contextual occlusion.

## Phase 5 — Emergent RPG Slice

- reputação;
- lealdade/deserção;
- quests sistêmicas;
- economia básica;
- criatura/ecologia;
- primeiro método de taming.

## Phase 6 — Chapter 1 Vertical Slice

Combinar os sistemas anteriores em uma pequena região representativa do primeiro reino, adequada para testes reais de gameplay.

## Expansion

Somente após estabilidade do vertical slice entram escala de conteúdo, mais raças/classes, regiões, profissões, economia avançada, multiplayer ampliado e novos reinos.
