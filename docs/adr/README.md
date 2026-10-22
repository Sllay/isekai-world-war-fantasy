# Architecture Decision Records

ADRs registram decisões arquiteturais importantes para preservar contexto histórico.

## Status

- `Proposed` — em discussão ou selecionada para prova, mas ainda não validada por evidência suficiente.
- `Accepted` — decisão vigente e validada ou uma invariável de produto/arquitetura deliberadamente congelada.
- `Superseded` — substituída por ADR posterior.
- `Deprecated` — não deve mais orientar novas implementações.

## Index

### Accepted

- ADR-0001 — Modular Architecture
- ADR-0002 — Event-driven Integration
- ADR-0003 — Data-driven Content
- ADR-0009 — Production Core Runtime
- ADR-0010 — Production Player Boundaries
- ADR-0011 — World/Region Ownership
- ADR-0012 — Production Local Save/Resume
- ADR-0013 — Canonical Combat Capabilities and Transactions
- ADR-0014 — Production Combat Action Execution
- ADR-0015 — Region Actor State and Recovery
- **ADR-0016 — Online-first Authority Boundary**
- ADR-0017 — Authority Loadouts and World-space Target Queries
- ADR-0018 — Authoritative Item Custody and Transactional Work

### Proposed / proof candidates

- ADR-0004 — Client Runtime Candidate: Godot 4.7.2
- ADR-0005 — Authoritative Server Candidate: Rust + ECS
- ADR-0006 — Hybrid Simulation Scheduling and Fidelity
- ADR-0007 — Networking Transport and Interest Management
- ADR-0008 — Persistence and Transactional World State

ADRs 0004–0008 capture implementation candidates that still require the corresponding measurements/evidence before promotion to Accepted.

ADR-0016 freezes a higher-level product invariant independently from which candidate server/transport wins: production clients do not own gameplay-critical canonical state, and local development uses the same authority semantics rather than a client-side fallback bypass.

Novas decisões devem usar sequência numérica e explicar contexto, decisão, consequências, alternativas relevantes e, quando aplicável, critérios objetivos de aceitação.
