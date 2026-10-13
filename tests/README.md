# tests

Testes unitários, integração e test worlds.

## Planned layout

- unit/
- integration/
- worlds/
- fixtures/

## Rules

- Lógica pura deve preferir unit tests.
- Contratos entre módulos devem ter integration tests.
- Sistemas visuais/sistêmicos devem possuir test worlds mínimos.
- Um módulo importante deve ser testável com apenas suas dependências declaradas.
- Bugs relevantes devem ganhar teste de regressão quando possível.
