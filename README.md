# Isekai World War Fantasy

> **Large scope, small steps.**

Isekai World War Fantasy é um RPG de fantasia 2.5D, mobile-first e orientado a sistemas, inspirado por MMORPGs de guerra, survival e sandbox emergente.

O mundo nasce da fusão de dois universos de fantasia. Suas raças, culturas e facções entram em conflito por território, recursos e sobrevivência. O jogador não é o centro da simulação: a guerra, a economia, as cidades, as criaturas e os NPCs continuam existindo sem ele. Porém, suas ações podem alterar profundamente a história do mundo.

## Pilares

- RPG de raças, classes, disciplinas, habilidades e builds.
- Guerra dinâmica entre facções e territórios.
- Mundo sandbox que continua simulando sem o jogador.
- Survival, coleta, crafting e construção modular.
- Criaturas com ecologia e métodos de domesticação próprios.
- Quests autorais + sistêmicas derivadas do estado real do mundo.
- Economia dinâmica com moedas, câmbio, comércio e contrabando.
- Combate baseado em posição, leitura, esquiva, telegraph e execução.
- Visual 2.5D com assets 2D vetoriais em espaço com altura real.
- Mobile como plataforma principal; desktop como plataforma secundária.
- Arquitetura modular, data-driven, testável e preparada para expansão.

## Filosofia técnica

1. Core pequeno e estável.
2. Features entram como módulos, não como código espalhado.
3. Sistemas se comunicam por contratos, eventos e dados.
4. Conteúdo deve ser data-driven sempre que possível.
5. Nenhuma feature deve exigir uma God Class.
6. Dependências circulares são erro arquitetural.
7. Cada módulo deve poder ser testado isoladamente.
8. Alterações devem ser cirúrgicas e localizadas.
9. Web/mobile são restrições de primeira classe desde o início.
10. Documentação e código evoluem juntos.

## Estrutura

- `docs/` — GDD, arquitetura, design, lore, ADRs e roadmap.
- `src/` — núcleo executável e código compartilhado.
- `modules/` — módulos de gameplay e features opcionais.
- `data/` — definições data-driven.
- `assets/` — arte, áudio e recursos visuais.
- `tests/` — testes unitários, integração e test worlds.
- `tools/` — ferramentas internas, validadores e geração de conteúdo.
- `skills/` — instruções operacionais para agentes/IA.

## Estado

**Fase atual:** pré-produção / arquitetura / GDD v0.x.

Data de bootstrap: 2026-10-13.
