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

must_ship:
  - <required behavior>

must_integrate_with:
  - <existing subsystem/contract>

quality_gates:
  automated:
    - <test/check/scenario>
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
  - silent TODO for a specified low-risk requirement
  - broad rewrite when a localized change is sufficient

completion:
  engineering_complete: false
  player_complete: false
```

## Execution rules

1. Read only the active contract plus relevant system docs/ADRs.
2. Use Serena/symbol navigation when available before broad repository scanning.
3. Reuse existing contracts before creating new managers/frameworks.
4. Implement the smallest coherent set of changes that satisfies the whole mission.
5. Run affected tests early; broaden regression testing according to impact/risk.
6. Use FULL runtime validation when available; if runtime MCP fails after bounded recovery, switch to DEGRADED mode and continue all deterministic validation.
7. Do not request BK to manually verify deterministic facts that automated/runtime checks can prove.
8. Do not close a player-facing mission at Engineering Complete when Player Complete criteria remain.
9. Report exact deferrals and validation gaps rather than saying `done` generically.
