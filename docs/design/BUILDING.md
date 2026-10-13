# Building Design

## Goal

Construção modular e legível, evitando casas prontas como imagens únicas.

## Structure Model

- fundações/células;
- bordas de célula para parede, porta, janela, arco ou grade;
- pisos;
- escadas e conexões verticais;
- móveis;
- estações de crafting;
- telhados derivados de ambientes fechados quando aplicável.

## Floors

Construções podem possuir múltiplos níveis. Escadas conectam layers/andares e a apresentação prioriza o andar atual do jogador.

## Contextual Occlusion

- teto pode fazer fade quando o jogador entra;
- paredes podem fazer fade quando bloqueiam o personagem;
- objetos relevantes conhecidos pelo jogador podem receber silhueta contextual;
- transparência visual nunca deve revelar inimigos ou informação ainda desconhecida pelo personagem.

## Ownership and Permissions

O sistema deve futuramente suportar:

- propriedade individual;
- grupo/guilda;
- permissões;
- acesso a portas/baús;
- áreas protegidas/restritas;
- dano e reparo conforme regras do mundo.

## Technical Principle

Peças de construção são dados + comportamento reutilizável. Novas peças compatíveis não devem exigir alterações no core de building.
