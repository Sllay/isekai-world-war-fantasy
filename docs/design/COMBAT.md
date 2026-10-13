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
