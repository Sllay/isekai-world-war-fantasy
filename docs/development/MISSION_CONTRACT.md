# Mission Contract Template

Use this template for each material implementation group inside a Macro Version. The contract tells Codex where the work stops; Codex does not invent completion criteria after implementation begins.

```yaml
mission_id: <macro-version>/<group>
macro_version: <name>
owner: <module/system>

player_visible_goal: >
  Describe what the player can actually do/see when this mission is integrated.

engineering_goal: >
  Describe the contracts/data/runtime work required to support that outcome.

authority:
  client_intents:
    - <semantic command/input accepted from client>
  canonical_owner:
    - <state owned by AuthorityHost/server>
  validation_before_commit:
    - <checks authority performs>
  replicated_results:
    - <fact/snapshot/revision returned to clients>
  client_only_prediction_presentation:
    - <state allowed to exist locally without authority>

must_ship:
  - <required behavior>

must_integrate_with:
  - <existing subsystem/contract>

performance_profile:
  target: <client_reference | private_4gb | official | n/a>
  benchmark:
    - <scenario/metric that must be measured>
  allowed_regression: <explicit threshold or n/a>

quality_gates:
  automated:
    - <test/check/scenario>
  adversarial_authority:
    - <forged/replayed/invalid command test when applicable>
  runtime:
    - <behavior that must be exercised>
  android_manual:
    - <only subjective/device-specific acceptance>

assets_and_presentation:
  required:
    - <representative/final-for-scope asset or feedback>
  placeholders_allowed:
    - <only where fidelity is intentionally irrelevant>

allowed_deferrals:
  - <explicitly out-of-scope content or dependency>

forbidden_shortcuts:
  - duplicate parallel systems
  - debug-only completion of player-facing behavior
  - client-authoritative gameplay outcome when SERVER_AUTHORITY requires host authority
  - server-disconnect -> trust-local-state fallback
  - silent TODO for a specified low-risk requirement
  - broad rewrite when a localized change is sufficient

completion:
  engineering_complete: false
  player_complete: false
```

## Execution rules

1. Read only the active contract plus relevant system docs/ADRs.
2. For gameplay-critical work, read `SERVER_AUTHORITY.md` and explicitly fill the authority section rather than assuming A7 will solve it later.
3. Use Serena/symbol navigation when available before broad repository scanning.
4. Reuse existing contracts before creating new managers/frameworks.
5. Implement the smallest coherent set of changes that satisfies the whole mission.
6. Run affected tests early; broaden regression testing according to impact/risk.
7. For performance-sensitive work, benchmark against `PERFORMANCE.md`; do not claim optimization from code inspection alone.
8. Use FULL runtime validation when available; if runtime MCP fails after bounded recovery, switch to DEGRADED mode and continue all deterministic validation.
9. Do not request BK to manually verify deterministic facts that automated/runtime checks can prove.
10. Do not close a player-facing mission at Engineering Complete when Player Complete criteria remain.
11. Report exact deferrals, authority gaps and validation gaps rather than saying `done` generically.
