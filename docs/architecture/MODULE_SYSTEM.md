# Module System

## Purpose

Permitir adicionar, remover, testar e substituir features sem alterar o projeto inteiro.

## Module Manifest

Todo módulo deve declarar metadados equivalentes a:

```yaml
id: gameplay.taming
version: 0.1.0
requires:
  - core.entities
  - gameplay.creatures
optional:
  - gameplay.reputation
  - gameplay.quests
provides:
  - capability.taming
```

O formato concreto poderá mudar conforme a stack final, mas o contrato conceitual permanece.

## Lifecycle

1. Discover
2. Validate manifest
3. Resolve dependency graph
4. Register contracts/data
5. Initialize
6. Start
7. Run
8. Stop
9. Dispose

## Rules

- IDs de módulo são estáveis e únicos.
- Inicialização deve respeitar dependências.
- Dependência ausente deve gerar erro legível antes do runtime principal.
- Dependências opcionais nunca podem ser assumidas como presentes.
- Um módulo deve possuir uma responsabilidade dominante.
- Módulos não acessam internals de outro módulo.
- Integração usa contratos públicos, eventos ou registries.

## Module Categories

### Core Modules
Infraestrutura essencial e pequena.

### Foundation Modules
Capacidades reutilizadas amplamente.

### Gameplay Modules
Features concretas do jogo.

### Tooling Modules
Debug, profiling, editor tools, validators e geração de conteúdo.

## Module Manager

Responsabilidades previstas:

- descobrir manifests;
- resolver dependências;
- detectar ciclos;
- ordenar startup;
- controlar feature flags;
- expor estado e erros;
- oferecer hooks de debug/reload quando seguro.

O Module Manager não implementa gameplay.

## Module Inspector

Ferramenta de desenvolvimento desejada:

```text
✓ core.entities
✓ core.events
✓ gameplay.combat
✓ gameplay.inventory
✗ gameplay.taming
  Missing: gameplay.creatures >= required version
```

## Isolation Test

Todo módulo importante deve possuir um cenário mínimo capaz de carregá-lo com apenas suas dependências declaradas.
