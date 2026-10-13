# Creatures & Taming

## Creature Ecology

Criaturas devem ser definidas além de `aggressive = true/false`.

Campos conceituais:

- habitat;
- diet;
- activity period;
- territoriality;
- social structure;
- prey/predators;
- reproduction;
- migration;
- fear/trust;
- combat behavior;
- taming profile.

## Behavior Examples

Uma espécie pode ser territorial apenas perto do ninho; outra foge sozinha e luta em grupo; outra caça à noite; outra protege filhotes e evita combate fora do território.

## Taming Conditions

Métodos possíveis:

- knockout + food;
- trust building;
- rescue;
- steal egg + hatch + imprinting;
- capture young;
- specific ritual;
- defeat alpha;
- species-specific resource;
- trap without injury;
- save from predator;
- unique weapon/tool interaction.

Uma espécie pode aceitar múltiplos caminhos, e algumas podem ser impossíveis de domesticar adultas.

## Consequences

Domesticação pode afetar ecologia, reputação, parentes da criatura, facções druidas/caçadoras e eventos locais.

## Technical Principle

`Creature` não deve conhecer internamente todos os sistemas de taming. O módulo de domesticação observa capabilities, estado e eventos e aplica regras declaradas por dados.
