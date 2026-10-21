# GitHub Actions

CI is active through `ci.yml`.

Current gate:

1. checkout with full history;
2. install exact Godot 4.7.2 and verify its SHA-256;
3. headless project import/parse;
4. run the existing deterministic Core/Player/Combat/Actions/Enemy/World/Save suites;
5. publish a concise GitHub Actions summary.

The workflow intentionally does **not** claim live MCP, Android touch/UX or real-device performance validation. Those remain runtime/device gates defined by the active Mission Contract and `SHIPPABLE_DEFINITION_OF_DONE.md`.

Future CI additions should be evidence-driven. Likely Block 2 additions include architecture dependency validation, scenario/replay tests, data/schema validation and impact-aware test selection.
