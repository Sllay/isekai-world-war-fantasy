# Combat Design

## Goal

Combate deve premiar leitura, posição, timing e construção de build, evitando uma simples corrida de DPS/tank.

## Chapter 1 / Run 1 / Part 1

C1-R1-P1 continues the accepted A1 first-scope below as one integrated foundation
delivery. Representative procedural visuals and the technical HUD are accepted in
Run 1. Final Chapter 1 combat content/readability refinement belongs to Run 2,
including the three definitive universal skills. Run 1 supplies primary attack,
three equip-capable skill slots (strong/heal/empty initially), authority/cost/
cooldown/targeting infrastructure and the entire victory/death/respawn/return loop.
This does not declare final combat, mobile UX or final-device performance accepted.

## A1 accepted first-scope contract

The Game Director explicitly closed the first-scope design blocker for
`COMBAT_A1_FOUNDATION_COMPLETION`. These are implementation decisions, not a claim
of Engineering or Player Complete:

- Representative weapon: one-handed melee. Primary basic attack and one strong
  action/skill reuse ActionExecutor/CombatService. Guard/block is the initial
  defense; foundation dodge is retained. Advanced parry is excluded.
- Light confirmed hits have visible body/procedural reaction and impact, but never
  gameplay stun-lock. Valid strong impacts may cause a short authoritative stagger
  with a bounded immunity window. Enemy wind-up, telegraph and recovery are legible.
- Minimum feedback: body reaction, impact visual, short bounded presentation-only
  hit-stop where useful, swing/impact SFX, unequivocal hit confirmation, and distinct
  guard success, guard failure and damage reduction/block messages.
- Death is defeated/dead, a short authority-timed wait, safe-point respawn with
  coherent health/resource/action/defense/movement state. No downed/revive in A1.
- Clients request gameplay; authority decides gameplay. Animation/VFX/audio never
  trigger damage, invulnerability, stagger, healing, cooldown or respawn commits.
- Development uses AuthorityGateway -> LocalAuthorityHost loopback, semantic
  commands, authenticated actor binding and bounded sequence/tick validation.
  Disconnect never promotes the client to authority. No full external A7 stack.

Initial tuning is authored data/policy, adjustable after feel acceptance: guard
reduces frontal blockable damage by 75% for 4 energy per impact, fails when energy
is insufficient or facing is wrong; dodge costs 8 energy, lasts 4 simulation ticks
and has a 20-tick reuse interval. Strong hits stagger for 6 ticks with 20 ticks of
immunity. Guard/dodge/stagger gate actions and movement through existing contracts.
Energy recovers 1 unit each 10 authority ticks outside defense/casting; no passive
health regeneration. Death waits 30 ticks (1.5 seconds at 20 Hz); respawn restores
health/energy, clears transient actions/defense/input and retains committed action
cooldowns. `entry.respawn` is authored outside the encounter's acquisition range
(fallback: the Region's default entry); clients supply no
coordinates. Reloading defeated state starts the same death policy, not a free heal.

Player acceptance is one integrated scenario: enter/spawn; move/turn/aim and
approach combat; read a telegraph; guard one attack; receive one without defense;
land basic attacks; use the strong action; stagger when valid; defeat an enemy;
face another; be defeated; enter death; respawn; return to combat without residual
state. Machines validate canonical outcomes; the Director validates feel/readability
and device control comfort in that scenario.

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
