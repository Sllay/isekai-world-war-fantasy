# Magic Design

## Principle

Magias são composição de blocos reutilizáveis, não scripts exclusivos para cada spell.

## Composition Axes

Uma magia pode combinar:

- **Source:** mana, life, rage, pact, item, ritual;
- **Element/School:** fire, ice, lightning, light, dark, poison, arcane, etc.;
- **Form:** projectile, beam, link, nova, aura, field;
- **Trajectory:** straight, homing, bouncing, chain, arc;
- **Impact:** direct, explosion, piercing, persistent area;
- **Effect:** burn, freeze, stun, drain, heal, knockback, curse;
- **Targeting:** self, ally, enemy, ground, cone, area;
- **Modifiers:** count, duration, radius, jumps, decay, cost.

## Example

`Fireball = Projectile + Fire + Explosion + Burn`

Um acessório pode alterar `Projectile.Count += 1` sem conhecer Fireball especificamente.

## Class Philosophy

Classe define fundação; disciplinas/escolas e equipamentos expandem o estilo. Moralidade não é determinada por escola mágica.

Mago e Bruxo podem coexistir como paradigmas diferentes de acesso ao sobrenatural, não como sinônimos.

## Technical Requirement

Cada bloco deve expor contratos claros e ser combinável apenas quando compatível. Validação de dados deve impedir combinações inválidas antes do runtime principal.
