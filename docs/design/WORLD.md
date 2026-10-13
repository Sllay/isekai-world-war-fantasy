# World Design

## Core Rule

**The world exists without the player; the player can change the world.**

## Chapter 1 Scope

A primeira versão do mundo foca em um único grande reino. Novos reinos e continentes são expansão futura, não requisito para provar o core.

Estado inicial conceitual:

- 49% influência Azul;
- 49% influência Vermelha;
- 2% Zona Morta/Convergente.

Controle territorial pode mudar com a simulação.

## Region State

Cada região pode manter valores agregados como:

- owner/influence;
- military strength;
- population;
- morale;
- food;
- supplies;
- fortification;
- trade access;
- danger;
- creature pressure;
- resource availability;
- active events.

## Simulation Independence

Conflitos e mudanças podem ocorrer mesmo sem jogadores próximos. A simulação longe dos jogadores deve ser abstrata e barata; perto deles, converte-se em entidades e ações detalhadas.

## War Front

O mapa deve comunicar:

- território estável;
- território contestado;
- ataques;
- cercos;
- comboios;
- eventos relevantes;
- áreas instáveis.

Atualização visual pode ser periódica em vez de frame-a-frame.

## Information Model

Conhecimento não é automaticamente global. Crimes, mortes, espionagem e eventos locais podem exigir testemunhas, mensageiros, descoberta ou comunicação antes de alterarem conhecimento de NPCs/facções.

## Player Influence

O jogador pode influenciar o mundo por combate, logística, economia, diplomacia, espionagem, construção, quests e ações emergentes. Grandes mudanças devem resultar de cadeias de consequência, não de botões de roteiro arbitrários.
