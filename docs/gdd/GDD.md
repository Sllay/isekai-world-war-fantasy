# Game Design Document — Isekai World War Fantasy

- **Version:** 0.2.0
- **Status:** Draft
- **Updated:** 2026-10-15

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

A interação mobile separa **seleção** de **execução**: tocar em um slot de habilidade normalmente arma/seleciona a ação; um controle contextual executa conforme o modo de alvo da habilidade. Isso permite botão simples, direção, mira livre/de precisão e ground targeting sem transformar a tela em uma hotbar de desktop.

Lock-on e aim assist são ferramentas de acessibilidade/usabilidade, não auto-acerto universal. Ataques declarados como dependentes de precisão continuam exigindo mira.

Chefes usam fases, padrões, partes destrutíveis, regras de arena e mudanças comportamentais.

## 8. Mobile Combat and Quick Access

A UI principal nasce para toque:

- zona esquerda de joystick dinâmico, criado no ponto de toque dentro de uma área segura;
- botão de pulo separado;
- três slots de habilidade visíveis por página;
- rotação de páginas para conjuntos maiores de habilidades;
- um slot rápido dedicado a consumível;
- controle contextual de ataque/execução que pode funcionar como botão ou direção/mira;
- hotbar inferior separada, inicialmente com 8 bindings, para armas, ferramentas, itens, consumíveis e construção.

A ordem das páginas de habilidades faz parte da expressão de build. A quantidade máxima final de habilidades equipadas é decisão de progressão/balanceamento e não deve ser hard-coded pela apresentação.

Especificação detalhada: `docs/design/MOBILE_COMBAT_UI_AND_INVENTORY.md`.

## 9. Classes and Magic

Estrutura prevista:

`Classe principal + disciplinas + escolas + talentos + equipamentos + habilidades adquiridas`

Magias serão montadas de componentes reutilizáveis, como forma, elemento, trajetória, impacto, alvo, status e modificadores. Equipamentos podem modificar propriedades genéricas como número de projéteis, custo, área ou encadeamento.

## 10. Survival and Crafting

Recursos do mundo alimentam:

- crafting;
- construção;
- reparo;
- economia;
- sobrevivência;
- profissões.

Bancadas, forjas e estações melhores desbloqueiam receitas e capacidade de produção.

## 11. Inventory, Weight and Bags

Inventário e bolsas usam estado real de itens/stacks; a UI é apenas apresentação.

Princípios atuais:

- cada item físico possui massa base canônica;
- peso do stack deriva de quantidade e massa dos itens;
- bolsa pode modificar **peso efetivo** por categoria sem alterar a massa base do item;
- limite de slots e limite de peso são restrições independentes;
- bolsas podem usar capacidade de slots fixa ou alocação dinâmica de slots/stacks;
- alocação dinâmica não significa peso infinito nem memória/UI infinita;
- stacks compatíveis são preenchidos antes da criação de um novo slot, respeitando condition/decay lots.

No mobile, o inventário aparece como popup central com grid e scroll vertical. Aproximadamente cinco colunas são o alvo inicial de legibilidade, podendo chegar a seis quando o dispositivo comportar.

Com o inventário aberto, movimento e pulo permanecem possíveis, enquanto combate/skill aim/execução ficam bloqueados ou ocultos por contexto de input.

Detalhes: `docs/design/BAGS_AND_CONTAINERS.md` e `docs/design/MOBILE_COMBAT_UI_AND_INVENTORY.md`.

## 12. Building

Construção modular por fundações/células e bordas. O jogador posiciona pisos, paredes, portas, janelas, escadas, móveis e estações. Ambientes fechados podem gerar telhado automaticamente. Occlusion contextual esconde/faz fade em paredes e tetos sem revelar informação de gameplay desconhecida pelo personagem.

## 13. Creatures and Taming

Criaturas possuem ecologia própria: habitat, dieta, territorialidade, horário, grupo social, reprodução e comportamento. Métodos de domesticação podem incluir confiança, alimentação específica, knockout, resgate, ovo/filhote, ritual, captura, imprinting ou condições exclusivas da espécie.

## 14. Quests

Quatro origens principais:

1. história principal autoral;
2. quests regionais semi-autorais;
3. quests sistêmicas baseadas no estado do mundo;
4. eventos emergentes produzidos pela simulação.

Quests sistêmicas devem nascer de necessidades reais do mundo sempre que possível.

## 15. Economy

Dois sistemas monetários principais vinculados às facções podem possuir câmbio variável. Valor pode responder a oferta, confiança, guerra, controle de recursos e eventos. Comércio oficial, mercado entre jogadores, contrabando e mercado negro fazem parte do espaço de design.

## 16. Equipment

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

## 17. Professions

Profissões podem incluir produção e atividades sociais/sistêmicas: mineração, carpintaria, ferraria, agricultura, alquimia, cozinha, cura, pesca, comércio, contrabando, mercenarismo, caça de recompensas, espionagem e outras.

## 18. Presentation

Visual 2.5D/top-down inclinado. Assets principais são 2D vetoriais e modulares, animados por rig, IK, transformações, squash/stretch e deformação. O espaço de jogo deve suportar altura real, colinas, pontes, quedas, pulo e rotação de câmera.

HUD mobile deve preservar a leitura do centro da tela, responder a safe areas/aspect ratios e evitar painéis opacos gigantes. Controles finais seguem a mesma direção visual vetorial/estilizada do projeto e devem comunicar seleção, cooldown, indisponibilidade e modo de mira com clareza.

## 19. Platforms

- **Primary:** mobile/Web.
- **Secondary:** desktop.
- Distribuição inicial desejada: Web/Itch.io ou hospedagem própria, conforme validação técnica.

Desktop pode apresentar mais bindings simultâneos, mas usa os mesmos action IDs, inventário, cooldowns e regras canônicas do mobile.

## 20. Production Timing Rule

Direção de design não implica implementação imediata.

UI final de combate, inventário, hotbar, bolsas, aim assist e construção deve ser implementada por partes quando o sistema proprietário existir em produção. Não criar sistemas temporários duplicados apenas para completar visualmente o HUD antes da hora.

## 21. Non-goals for v0.x

- Não fechar dezenas de raças antes da taxonomia racial.
- Não escrever milhares de quests manualmente.
- Não construir todas as features antes de provar o Core.
- Não criar MMO-scale networking antes de validar a simulação local/vertical slice.

## 22. Change Policy

Este GDD é vivo durante versões `0.x`. Mudanças relevantes entram em `docs/gdd/CHANGELOG.md`; mudanças arquiteturais importantes também exigem ADR quando aplicável.
