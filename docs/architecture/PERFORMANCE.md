# Performance Architecture

- **Status:** Draft / stack-agnostic

## Primary Constraint

Mobile/Web é o alvo principal. Desktop recebe margem extra de hardware, não o contrário.

## Principles

- medir antes de otimizar;
- usar simulation LOD;
- evitar updates completos por entidade quando batching/ticks escalonados servirem;
- streaming por região/chunk;
- pooling para objetos frequentes;
- separar estado da simulação da apresentação visual;
- reduzir trabalho quando entidades estão fora da área relevante;
- budgets explícitos para CPU, memória, draw calls, partículas, áudio e rede após escolha da stack.

## Simulation LOD

- High: entidades próximas/visíveis.
- Medium: regiões relevantes com frequência reduzida.
- Abstract: estado agregado para áreas distantes.

## Validation

Toda milestone executável deve registrar baseline em pelo menos um dispositivo mobile alvo e um navegador suportado.

O projeto não deve depender de milhares de NPCs fisicamente ativos para simular uma guerra distante.
