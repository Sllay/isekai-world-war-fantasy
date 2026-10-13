# Save System

- **Status:** Draft

## Principles

- Cada módulo é responsável pelo próprio estado persistente.
- Saves devem usar IDs estáveis em vez de referências frágeis de runtime.
- O formato de save terá versão explícita.
- Mudanças incompatíveis em schema precisam de migração.
- Regiões distantes podem persistir estado agregado quando isso preservar o comportamento do mundo.
- O modelo final de autoridade/persistência multiplayer será decidido depois da prova técnica.

## Planned metadata

- save format version;
- game version;
- world identifier/seed;
- enabled module versions;
- per-module state sections.

A implementação concreta será definida depois da escolha da stack.
