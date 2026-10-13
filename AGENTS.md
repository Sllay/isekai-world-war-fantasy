# AGENTS.md

Regras obrigatórias para qualquer agente/IA que trabalhe neste repositório.

## Antes de modificar código

1. Leia `README.md`.
2. Leia `docs/architecture/ARCHITECTURE.md`.
3. Leia a documentação do sistema afetado.
4. Consulte `docs/adr/` por decisões relacionadas.
5. Verifique se já existe módulo, contrato ou evento que resolve parte do problema.

## Regras de arquitetura

- Não criar God Classes, God Managers ou scripts monolíticos.
- Não adicionar feature específica diretamente ao Core sem justificativa arquitetural registrada em ADR.
- Preferir composição a herança profunda.
- Preferir contratos/capabilities e eventos tipados a referências diretas entre módulos.
- Não criar dependência circular.
- Conteúdo novo deve ser data-driven quando a lógica puder ser reutilizada.
- Não duplicar sistemas existentes (`CombatSystem2`, `NewInventoryManager`, etc.).
- Módulos devem declarar dependências obrigatórias e opcionais.
- Sistemas opcionais devem degradar graciosamente quando ausentes.
- Toda feature deve considerar mobile/Web desde o desenho inicial.

## Ao implementar uma feature

- Identifique o módulo proprietário do comportamento.
- Defina entradas, saídas, eventos e dados.
- Mantenha integração mínima com outros módulos.
- Adicione teste isolado sempre que aplicável.
- Adicione/atualize test world para comportamentos visuais ou sistêmicos.
- Atualize documentação impactada.
- Registre decisões arquiteturais importantes em ADR.

## Convenção de mudança

A menor alteração correta é preferível à alteração ampla. Se uma feature exige editar muitos sistemas sem uma razão fundamental, pare e reavalie o contrato entre módulos.

## Fonte de verdade

- Visão do jogo: `docs/gdd/GDD.md`
- Arquitetura: `docs/architecture/`
- Decisões: `docs/adr/`
- Planejamento: `docs/roadmap/`
- Instruções detalhadas para agentes: `skills/project-development/SKILL.md`
