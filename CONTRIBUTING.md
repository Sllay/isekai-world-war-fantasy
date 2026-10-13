# Contributing

## Branches

Use branches curtas e focadas quando o projeto entrar em implementação.

Sugestões:

- `feat/<feature>`
- `fix/<bug>`
- `docs/<topic>`
- `refactor/<system>`
- `test/<system>`

## Commits

Preferir mensagens claras e pequenas, por exemplo:

- `feat: add module dependency validator`
- `fix: prevent duplicate entity ids`
- `docs: update combat ability contract`

## Pull Requests

Toda PR relevante deve explicar:

- problema/objetivo;
- solução adotada;
- módulos afetados;
- testes realizados;
- impacto em performance/mobile;
- documentação/ADR alterados.

## Architecture Checklist

Antes de concluir uma mudança:

- [ ] Não criou dependência circular.
- [ ] Não colocou gameplay específico no Core.
- [ ] Não duplicou sistema já existente.
- [ ] Dados novos usam IDs estáveis quando persistentes.
- [ ] Dependências do módulo estão declaradas.
- [ ] Testes relevantes foram adicionados/atualizados.
- [ ] Documentação continua verdadeira.

## Breaking Changes

Mudanças que alteram contratos, schemas persistentes ou arquitetura devem ser explicitamente documentadas. Quando necessário, criar ADR e estratégia de migração.
