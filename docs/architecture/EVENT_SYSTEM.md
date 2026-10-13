# Event System

## Goal

Desacoplar sistemas sem esconder fluxo de domínio.

## Domain Events

Eventos representam fatos que já aconteceram, por exemplo:

- `EntityDamaged`
- `EntityDied`
- `ItemCreated`
- `TerritoryCaptured`
- `ReputationChanged`
- `CreatureTamed`
- `BuildingDestroyed`
- `PlayerEnteredRegion`

## Principle

O produtor conhece o fato; não conhece todos os efeitos derivados.

Exemplo: Combat publica `EntityDied`. War, Crime, Quest e Reputation podem reagir independentemente.

## Rules

- Eventos devem ser tipados/estruturados, não strings soltas quando a stack permitir.
- Nomes devem descrever fatos no passado, não comandos vagos.
- Payload deve conter apenas dados necessários e IDs estáveis.
- Eventos não substituem toda comunicação síncrona; contratos diretos continuam válidos quando existe dependência real.
- Evitar cadeias invisíveis excessivamente longas.
- Eventos importantes devem possuir tracing em build de desenvolvimento.

## Event Envelope

Metadados recomendados:

```text
event_id
schema_version
timestamp/tick
source_module
correlation_id
payload
```

## Debugging

Ferramentas futuras devem permitir:

- observar eventos recentes;
- filtrar por entidade/módulo;
- seguir correlation IDs;
- medir frequência;
- detectar loops/event storms.

## Determinism

Eventos ligados à simulação persistente devem respeitar ordenação/tick definida quando a ordem puder alterar o resultado.
