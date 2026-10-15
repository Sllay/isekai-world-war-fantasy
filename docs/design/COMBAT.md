# Combat Design

## Goal

Combate deve premiar leitura, posição, timing e construção de build, evitando uma simples corrida de DPS/tank.

## Ability Properties

Habilidades podem declarar propriedades como:

- cast while moving;
- turn while casting;
- interruptible;
- telegraphed;
- area/shape;
- free aim / lock-on;
- projectile / hitscan / beam / link;
- blockable;
- dodgeable;
- parryable;
- channelled;
- chargeable;
- friendly fire rules;
- resource cost;
- cooldown/charges.

## Mobile Combat Interaction

O combate é **mobile-first** e não deve copiar literalmente uma hotbar densa de MMO de desktop.

Regra central:

> **Selecionar uma habilidade não é o mesmo que executá-la.**

No mobile, slots de habilidade selecionam/armam uma ação. A execução acontece por um controle contextual de combate compatível com o modo de alvo da habilidade.

O sistema deve suportar progressivamente:

- execução instantânea/contextual;
- ataque direcional;
- mira livre/de precisão;
- alvo travado/assistido;
- ponto/área no mundo;
- alcance fixo ou variável;
- telegraph/preview antes do commit quando aplicável.

Lock-on é uma ajuda de usabilidade, não uma garantia universal de acerto. Habilidades marcadas como dependentes de precisão continuam exigindo mira mesmo quando existe um alvo travado.

A UI mobile prevista usa três slots de habilidade visíveis por página, com rotação de páginas para conjuntos maiores. A ordem das páginas faz parte da expressão de build. Um slot rápido separado atende consumíveis; uma hotbar inferior independente atende armas, ferramentas, itens e construção.

Detalhes de interação, inventário e layout estão em `MOBILE_COMBAT_UI_AND_INVENTORY.md`.

## Targeting Families

Ações devem declarar sua necessidade de alvo de forma explícita, permitindo pelo menos a evolução para:

- self;
- explicit/current entity;
- last attacked/assisted target;
- actor-facing direction;
- camera-relative/free aim;
- world point;
- area/shape.

O sistema de simulação decide validade/range/relationship. A UI apenas seleciona, mostra preview e solicita execução; ela não inventa alvo válido nem altera estado de combate diretamente.

## Combat Verbs

- attack;
- block;
- dodge;
- parry;
- interrupt;
- dash;
- reposition;
- crowd control;
- cleanse;
- counter;
- channel;
- commit.

## PvP Principle

Equipamento e build importam, mas execução também. A vantagem de stats não deve transformar toda luta em resultado inevitável.

## Bosses

Bosses devem ser encontros, não mobs com muita vida. Ferramentas previstas:

- fases;
- padrões de ataque;
- arena mutável;
- summons;
- weak points;
- partes destrutíveis;
- reações a comportamento do grupo;
- transições por HP, tempo, objetivos ou estado da arena.

## Modular Implementation

Bosses devem montar comportamento a partir de controllers/patterns reutilizáveis, evitando scripts únicos gigantes.
