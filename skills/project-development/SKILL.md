# Isekai World War Fantasy — Project Development Skill

Use esta skill ao planejar, implementar, revisar ou documentar qualquer parte deste repositório.

## 1. Read First

Antes de trabalhar:

1. `README.md`
2. `AGENTS.md`
3. `docs/architecture/ARCHITECTURE.md`
4. documentação específica do sistema afetado
5. ADRs relacionados

## 2. Project Priorities

Ordem de prioridade:

1. correção;
2. modularidade;
3. legibilidade/manutenção;
4. testabilidade;
5. performance mobile/Web;
6. facilidade de criação de conteúdo;
7. velocidade de implementação.

Não sacrificar arquitetura básica por conveniência de curto prazo sem registrar a decisão.

## 3. Feature Workflow

Para cada feature:

### A. Define
- objetivo;
- proprietário do comportamento;
- inputs/outputs;
- dados persistentes;
- eventos publicados/consumidos;
- dependências obrigatórias/opcionais.

### B. Design
- verificar se contratos existentes bastam;
- preferir composição;
- decidir o que é código versus dados;
- definir failure modes;
- considerar mobile/Web.

### C. Implement
- mudança mínima e localizada;
- sem duplicar manager/sistema existente;
- sem dependência circular;
- sem acessar internals de outro módulo.

### D. Validate
- unit tests;
- integration tests;
- test world quando aplicável;
- schema/data validation;
- performance sanity check.

### E. Document
- atualizar docs do sistema;
- atualizar changelog quando relevante;
- criar ADR para decisão arquitetural importante.

## 4. Module Rules

Todo módulo deve possuir identidade estável e declarar dependências.

Preferir:

`Gameplay -> Foundation -> Core`

Proibido:

- Core dependendo de feature de gameplay;
- dependência circular;
- módulo lendo estado privado de outro módulo;
- singleton global criado apenas para evitar contrato correto.

## 5. Event Rules

Use eventos para fatos de domínio com múltiplos consumidores.

Bom:
- `EntityDied`
- `TerritoryCaptured`
- `CreatureTamed`

Evite eventos vagos como `DoStuff` ou strings mágicas espalhadas.

Nem toda chamada precisa ser evento: quando A realmente depende de um serviço fornecido por B, use contrato explícito.

## 6. Data-driven Rules

Quando um comportamento já existe, prefira nova definição de dados.

Novo conteúdo deve usar IDs estáveis e namespaced.

Evite lógica como:

```text
if creature == wolf
if item == iron_sword
```

quando a diferença puder ser declarada em dados.

## 7. Entity Rules

Preferir capabilities/components.

Pergunte:
- `CanAttack?`
- `CanTrade?`
- `CanTalk?`
- `CanBeTamed?`

em vez de espalhar checagens de classes concretas.

## 8. AI/NPC Rules

NPCs não são oniscientes. Diferenciar:

- estado real do mundo;
- conhecimento do NPC;
- memória;
- relação/reputação;
- emoção/urgência.

Conhecimento deve viajar quando relevante por visão, testemunha, mensagem, rumor ou sistema equivalente.

## 9. Simulation Rules

Não simular em alta fidelidade o que ninguém observa.

Usar LOD de simulação:

- próximo: entidades completas;
- intermediário: atualizações reduzidas;
- distante: resolução agregada.

Resultados importantes devem convergir corretamente quando uma região volta à alta fidelidade.

## 10. Content Creation

Magias, bosses, criaturas, quests e itens devem reutilizar blocos genéricos antes de ganhar lógica exclusiva.

Lógica exclusiva é aceitável quando cria comportamento realmente único e não pode ser expressa de forma limpa pela composição existente.

## 11. Testing Principle

Cada módulo importante deve ser carregável no menor ambiente possível com apenas suas dependências declaradas.

Uma feature que só funciona quando o jogo inteiro está aberto é um sinal de acoplamento excessivo.

## 12. Documentation Principle

Documentos são parte do produto técnico. Não deixar documentação afirmar arquitetura que o código já não segue.

## 13. Scope Principle

**Large scope, small steps.**

Quebrar trabalho em feature slices executáveis. Preferir uma feature completa verticalmente a cinco sistemas pela metade.
