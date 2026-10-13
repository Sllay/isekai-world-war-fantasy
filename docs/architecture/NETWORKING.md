# Networking Architecture

- **Status:** Open decision / constraints only

A arquitetura multiplayer final ainda não está congelada. Este documento registra requisitos que qualquer solução deverá respeitar.

## Requirements

- mobile/Web compatibility;
- bandwidth awareness;
- authoritative ownership clearly defined;
- no assumption that every world entity is replicated at full fidelity;
- interest management by region/relevance;
- compatibility with simulation LOD;
- deterministic/stable handling for important world-state transitions where required;
- reconnect/resync strategy;
- protection against trusting client state for sensitive competitive actions.

## Replication Principle

Clients should receive what is relevant to perception/gameplay, not the entire simulation state.

## World Simulation

Distant wars, economies and ecology should replicate outcomes/state summaries rather than thousands of continuously networked actors.

## Open Questions

To decide after technical proof:

- hosting model;
- server technology;
- session/world persistence model;
- max players per shard/instance;
- dedicated vs listen/hybrid options;
- rollback/prediction needs for action combat;
- Web transport constraints.

A dedicated ADR will freeze the chosen model after prototype evidence exists.
