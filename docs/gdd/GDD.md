# Game Design Document — Isekai World War Fantasy

- **Version:** 0.1.0
- **Status:** Draft
- **Updated:** 2026-10-13

## 1. High Concept

RPG de fantasia 2.5D, mobile-first, com guerra sistêmica, survival, construção, roleplay e sandbox emergente. Dois mundos de fantasia colidiram e se fundiram; seus povos disputam território, recursos e futuro. O jogador é uma alma exterior reencarnada nesse mundo, capaz de influenciar a história sem ser o centro automático da simulação.

## 2. Design Pillars

1. **The world lives without the player.** Guerra, economia, NPCs e ecologia continuam simulando.
2. **The player can change the world.** Ações persistentes podem alterar território, relações, cidades e destino de povos.
3. **Freedom with consequences.** Raça, origem, facção, lealdade e reputação são variáveis separadas.
4. **Systems over scripts.** Conteúdo emerge da interação de regras reutilizáveis.
5. **Build expression.** Classes, disciplinas, equipamentos e modificadores permitem combinações profundas.
6. **Readable action combat.** Posição, telegraph, esquiva, interrupção e execução importam.
7. **Survival supports RPG.** Coleta, crafting e construção enriquecem a aventura, não substituem o RPG.
8. **Mobile first.** Interface, performance e legibilidade nascem para celular.

## 3. World Premise

Dois mundos de fantasia originalmente separados sofreram a **Convergência** e passaram a ocupar uma única realidade. Biomas, culturas, ruínas, criaturas e sistemas mágicos colidiram. A fusão gerou uma guerra entre grandes blocos provisoriamente chamados de **Azul** e **Vermelho**.

O primeiro capítulo do jogo ocorre em um grande reino dividido inicialmente em:

- 49% de influência Azul;
- 49% de influência Vermelha;
- 2% de Zona Morta/Convergente, instável e não dominável de forma permanente.

Esses valores são estado inicial, não resultado fixo.

## 4. Player Premise

O jogador escolhe sua raça e acredita inicialmente pertencer naturalmente àquele mundo. A verdade é revelada progressivamente: sua alma veio de uma realidade exterior e foi inserida por uma divindade neutra incapaz de escolher diretamente o vencedor da guerra. O jogador é uma variável externa — uma anomalia — e não um herói obrigado a defender um lado específico.

## 5. Factions, Race and Loyalty

Raça não determina permanentemente facção.

O personagem mantém identidades separadas:

- raça;
- origem cultural;
- origem mundial;
- facção histórica;
- lealdade atual;
- reputação local;
- reputação por organização;
- crimes, títulos e status sociais.

Isso permite deserção, neutralidade, infiltração, espionagem, mercenarismo e reconciliação.

## 6. World Simulation

Regiões mantêm estado abstrato de:

- controle territorial;
- população;
- forças militares;
- moral;
- suprimentos;
- comida;
- recursos;
- fortificações;
- rotas comerciais;
- ameaças;
- atividade inimiga.

Perto de jogadores, a simulação usa entidades detalhadas. Longe deles, usa resolução abstrata de menor custo.

## 7. Combat

Combate deve evitar simples troca de DPS. Habilidades podem variar por:

- movimento durante conjuração;
- tempo de compromisso;
- telegraph;
- mira livre ou lock-on;
- bloqueio;
- esquiva;
- interrupção;
- parry;
- área;
- canalização;
- projétil;
- mobilidade;
- controle de grupo.

Chefes usam fases, padrões, partes destrutíveis, regras de arena e mudanças comportamentais.

## 8. Classes and Magic

Estrutura prevista:

`Classe principal + disciplinas + escolas + talentos + equipamentos + habilidades adquiridas`

Magias serão montadas de componentes reutilizáveis, como forma, elemento, trajetória, impacto, alvo, status e modificadores. Equipamentos podem modificar propriedades genéricas como número de projéteis, custo, área ou encadeamento.

## 9. Survival and Crafting

Recursos do mundo alimentam:

- crafting;
- construção;
- reparo;
- economia;
- sobrevivência;
- profissões.

Bancadas, forjas e estações melhores desbloqueiam receitas e capacidade de produção.

## 10. Building

Construção modular por fundações/células e bordas. O jogador posiciona pisos, paredes, portas, janelas, escadas, móveis e estações. Ambientes fechados podem gerar telhado automaticamente. Occlusion contextual esconde/faz fade em paredes e tetos sem revelar informação de gameplay desconhecida pelo personagem.

## 11. Creatures and Taming

Criaturas possuem ecologia própria: habitat, dieta, territorialidade, horário, grupo social, reprodução e comportamento. Métodos de domesticação podem incluir confiança, alimentação específica, knockout, resgate, ovo/filhote, ritual, captura, imprinting ou condições exclusivas da espécie.

## 12. Quests

Quatro origens principais:

1. história principal autoral;
2. quests regionais semi-autorais;
3. quests sistêmicas baseadas no estado do mundo;
4. eventos emergentes produzidos pela simulação.

Quests sistêmicas devem nascer de necessidades reais do mundo sempre que possível.

## 13. Economy

Dois sistemas monetários principais vinculados às facções podem possuir câmbio variável. Valor pode responder a oferta, confiança, guerra, controle de recursos e eventos. Comércio oficial, mercado entre jogadores, contrabando e mercado negro fazem parte do espaço de design.

## 14. Equipment

Slots iniciais previstos:

- cabeça;
- torso;
- luvas;
- calças;
- botas;
- arma principal;
- mão secundária;
- três slots universais de acessórios.

Acessórios devem permitir mudanças de build além de bônus numéricos simples.

## 15. Professions

Profissões podem incluir produção e atividades sociais/sistêmicas: mineração, carpintaria, ferraria, agricultura, alquimia, cozinha, cura, pesca, comércio, contrabando, mercenarismo, caça de recompensas, espionagem e outras.

## 16. Presentation

Visual 2.5D/top-down inclinado. Assets principais são 2D vetoriais e modulares, animados por rig, IK, transformações, squash/stretch e deformação. O espaço de jogo deve suportar altura real, colinas, pontes, quedas, pulo e rotação de câmera.

## 17. Platforms

- **Primary:** mobile/Web.
- **Secondary:** desktop.
- Distribuição inicial desejada: Web/Itch.io ou hospedagem própria, conforme validação técnica.

## 18. Non-goals for v0.x

- Não fechar dezenas de raças antes da taxonomia racial.
- Não escrever milhares de quests manualmente.
- Não construir todas as features antes de provar o Core.
- Não criar MMO-scale networking antes de validar a simulação local/vertical slice.

## 19. Change Policy

Este GDD é vivo durante versões `0.x`. Mudanças relevantes entram em `docs/gdd/CHANGELOG.md`; mudanças arquiteturais importantes também exigem ADR quando aplicável.
