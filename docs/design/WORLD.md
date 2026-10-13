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

## Military Defeat Is Not Extinction

A vitória de uma facção não elimina automaticamente os povos historicamente associados ao lado derrotado.

Guerra deve produzir resultados intermediários e humanos antes de chegar a uma catástrofe populacional:

- retirada;
- rendição individual ou coletiva;
- prisioneiros de guerra;
- deserção;
- fuga de civis;
- refugiados;
- ocupação;
- perda de território;
- dissolução de unidades militares;
- assimilação parcial;
- resistência e insurgência;
- exílio;
- tratados e cessar-fogo;
- mudança de lealdade;
- sobrevivência de minorias dentro de território inimigo.

A facção derrotada pode deixar de existir como potência militar enquanto as raças e culturas que a compunham continuam existindo como minorias, diásporas, comunidades ocupadas, refugiados ou novos grupos políticos.

Extinção racial ou cultural completa é um resultado extremo, não o resultado padrão de uma derrota territorial.

## Positive and Negative Pressures

A simulação deve possuir forças de deterioração e forças de recuperação.

Exemplos de pressões negativas:

- guerra;
- fome;
- doença;
- perda territorial;
- predação;
- baixa moral;
- escassez;
- colapso logístico.

Exemplos de pressões positivas ou estabilizadoras:

- rendição;
- retirada;
- abrigo;
- migração;
- alianças;
- ajuda externa;
- comércio;
- reconstrução;
- reprodução;
- reassentamento;
- cessar-fogo;
- defesa organizada;
- diplomacia;
- integração de refugiados;
- recuperação de recursos.

O objetivo não é proteger o mundo de consequências, mas impedir que sistemas incompletos ou RNG ordinário causem massacres e extinções por falta de variáveis de recuperação.

## Information Model

Conhecimento não é automaticamente global. Crimes, mortes, espionagem e eventos locais podem exigir testemunhas, mensageiros, descoberta ou comunicação antes de alterarem conhecimento de NPCs/facções.

## Player Influence

O jogador pode influenciar o mundo por combate, logística, economia, diplomacia, espionagem, construção, quests e ações emergentes. Grandes mudanças devem resultar de cadeias de consequência, não de botões de roteiro arbitrários.
