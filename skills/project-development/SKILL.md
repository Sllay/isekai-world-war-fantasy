# Isekai World War Fantasy — Project Development Skill

Use esta skill ao planejar, implementar, revisar ou documentar qualquer parte deste repositório.

## 1. Read First

Antes de trabalhar:

1. `README.md`
2. `AGENTS.md`
3. `docs/architecture/ARCHITECTURE.md`
4. documentação específica do sistema afetado
5. ADRs relacionados
6. Mission Contract ativo, quando houver
7. `docs/development/SHIPPABLE_DEFINITION_OF_DONE.md` para trabalho player-facing

## 2. Project Priorities

Ordem de prioridade:

1. correção;
2. coerência do produto/jogabilidade entregue;
3. modularidade;
4. legibilidade/manutenção;
5. testabilidade;
6. performance mobile/Web;
7. facilidade de criação de conteúdo;
8. velocidade de implementação.

Não sacrificar arquitetura básica por conveniência de curto prazo sem registrar a decisão, mas também não criar infraestrutura futura que não seja necessária para a Macro Version ativa.

## 3. Delivery Model

O projeto trabalha por **Macro Versions jogáveis**, não por micro-slices como unidade de produto.

Exemplos:

- Combat Version;
- World Version;
- Inventory/Survival Version;
- Living NPC/Bot Version;
- RPG/Class Version;
- Networking Version;
- Game Shell/Release Version.

Cada Macro Version pode ser dividida internamente em grupos de implementação, commits e checkpoints. Esses grupos existem para engenharia; não devem virar uma sequência de entregas isoladas que deixam o loop do jogador incompleto.

Aplicar **foundation just-in-time**: construir a fundação que a versão precisa e então terminar o loop integrado antes de avançar para outro grande domínio.

## 4. Mission Workflow

### A. Define
- player-visible goal;
- owner do comportamento;
- inputs/outputs;
- dados persistentes;
- eventos publicados/consumidos;
- dependências obrigatórias/opcionais;
- critérios Engineering Complete;
- critérios Player Complete quando aplicável;
- assets/presentation necessários para representar a versão.

### B. Design
- verificar se contratos existentes bastam;
- preferir composição;
- decidir o que é código versus dados;
- definir failure modes;
- considerar mobile/Web;
- identificar quais fatos são automatizáveis e quais realmente exigem aceitação humana.

### C. Implement
- mudança mínima e localizada dentro de um resultado coerente;
- sem duplicar manager/sistema existente;
- sem dependência circular;
- sem acessar internals de outro módulo;
- usar Serena/símbolos/referências para navegação quando disponível;
- não reescrever arquivo grande quando patch localizado basta;
- não adiar requisito pequeno, especificado e de baixo risco só para encerrar a tarefa cedo.

### D. Validate
- affected tests primeiro;
- unit tests;
- integration tests;
- scenario/test world quando aplicável;
- schema/data validation;
- Godot runtime/editor validation quando disponível;
- performance sanity check;
- expandir regressão de acordo com risco/dependência.

Quando o runtime MCP cair após a recuperação limitada, continuar em modo DEGRADED com Serena/LSP, diagnósticos e testes headless. Registrar somente o gap que realmente não pôde ser provado.

### E. Player Experience Gate

Para trabalho visível ao jogador, verificar:

- controle utilizável;
- estado legível;
- feedback de sucesso/falha/dano/cooldown/recurso;
- apresentação coerente com o art/design já definido;
- fluxo sem dependência de debug;
- persistência esperada;
- failure states;
- mobile/device acceptance quando necessária.

Engineering Complete não fecha uma Macro Version player-facing.

### F. Document
- atualizar docs do sistema;
- atualizar roadmap/version status;
- atualizar changelog quando relevante;
- criar ADR para decisão arquitetural importante;
- registrar deferrals/gaps materiais em `TECHNICAL_HANDOFF.md`.

## 5. Module Rules

Todo módulo deve possuir identidade estável e declarar dependências.

Preferir:

`Gameplay -> Foundation -> Core`

Proibido:

- Core dependendo de feature de gameplay;
- dependência circular;
- módulo lendo estado privado de outro módulo;
- singleton global criado apenas para evitar contrato correto.

## 6. Event Rules

Use eventos para fatos de domínio com múltiplos consumidores.

Bom:
- `EntityDied`
- `TerritoryCaptured`
- `CreatureTamed`

Evite eventos vagos como `DoStuff` ou strings mágicas espalhadas.

Nem toda chamada precisa ser evento: quando A realmente depende de um serviço fornecido por B, use contrato explícito.

## 7. Data-driven Rules

Quando um comportamento já existe, prefira nova definição de dados.

Novo conteúdo deve usar IDs estáveis e namespaced.

Evite lógica como:

```text
if creature == wolf
if item == iron_sword
```

quando a diferença puder ser declarada em dados.

## 8. Entity Rules

Preferir capabilities/components.

Pergunte:
- `CanAttack?`
- `CanTrade?`
- `CanTalk?`
- `CanBeTamed?`

em vez de espalhar checagens de classes concretas.

## 9. AI/NPC Rules

NPCs não são oniscientes. Diferenciar:

- estado real do mundo;
- conhecimento do NPC;
- memória;
- relação/reputação;
- emoção/urgência.

Conhecimento deve viajar quando relevante por visão, testemunha, mensagem, rumor ou sistema equivalente.

Bots que representam companheiros/jogadores simulados devem usar as mesmas ações/capabilities públicas que um jogador equivalente sempre que isso for viável; evitar uma IA paralela com regras mágicas que o jogador nunca poderia executar.

## 10. Simulation Rules

Não simular em alta fidelidade o que ninguém observa.

Usar LOD de simulação:

- próximo: entidades completas;
- intermediário: atualizações reduzidas;
- distante: resolução agregada.

Resultados importantes devem convergir corretamente quando uma região volta à alta fidelidade.

## 11. Content Creation

Magias, bosses, criaturas, quests e itens devem reutilizar blocos genéricos antes de ganhar lógica exclusiva.

Lógica exclusiva é aceitável quando cria comportamento realmente único e não pode ser expressa de forma limpa pela composição existente.

Assets player-facing devem seguir a direção de arte existente. Codex pode integrar/rigar/configurar assets; geração de arte final deve usar a pipeline apropriada ao tipo de asset em vez de depender por padrão de SVG procedural de baixa fidelidade.

## 12. Testing Principle

Cada módulo importante deve ser carregável no menor ambiente possível com apenas suas dependências declaradas.

Uma feature que só funciona quando o jogo inteiro está aberto é um sinal de acoplamento excessivo.

BK não é o runner padrão de microtestes. Automatizar transições, valores e regressões determinísticas; reservar teste humano principalmente para feel, legibilidade, UX e comportamento específico do aparelho.

## 13. Documentation Principle

Documentos são parte do produto técnico. Não deixar documentação afirmar arquitetura ou status que o código já não segue.

Ao relatar conclusão, diferenciar `Engineering Complete` e `Player Complete`.

## 14. Scope Principle

**Large scope, coherent deliveries.**

Quebrar internamente o trabalho em passos pequenos e testáveis, mas entregar ao produto uma Macro Version integrada. Preferir um loop representativo completo a vários subsistemas tecnicamente elegantes porém desconectados para o jogador.
