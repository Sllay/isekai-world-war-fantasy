# Mission — A1/G1 Combat Foundation Completion

- **Macro Version:** A1 — Combat & Player Gameplay
- **Mission state:** READY FOR CODEX
- **Mission type:** production implementation + gap closure
- **Primary goal:** finish the missing combat foundation needed by A1 without rebuilding the combat systems that already exist.

## Codex command

Implement this mission, not just an audit.

Start by reading `AGENTS.md`, `docs/development/MISSION_CONTRACT.md`, `docs/development/SHIPPABLE_DEFINITION_OF_DONE.md`, this file, and only the combat/player architecture/design/ADR documents required to understand the existing implementation.

Use Serena first for GDScript symbol/reference discovery when available. Do not preload the whole repository.

Audit the existing combat/player/action/enemy/telegraph implementation against the required foundation below. Produce a concise gap list in your task report, then immediately implement the missing in-scope pieces in the same work session. Do not stop after analysis unless a genuine unresolved design/architecture decision blocks safe implementation.

Reuse the existing CombatService, ActionExecutor, combatants, Player adapters, targeting/telegraph contracts, persistence and enemy boundaries. Do not create parallel `CombatSystem2`, duplicate resource systems, or a new player architecture.

## Player-visible outcome enabled by this mission

After integration with the remaining A1 presentation work, the player foundation must be capable of a complete combat loop with health/resources, attacks, healing, defensive verbs, interruption/cancellation, defeat and persistence.

This mission is the **foundation-completion group**, so it may finish at Engineering Complete. It must not claim the whole A1 Macro Version is Player Complete if HUD/presentation/assets/mobile feel work remains.

## Required foundation audit and closure

Verify what already exists before changing anything. Implement only missing or incomplete production-intent behavior required for:

- canonical health/attributes/resource pools used by combat;
- resource costs and validation for combat actions;
- required resource recovery/regeneration rules already defined by combat design;
- damage/healing/defeat transactions and typed facts;
- action cooldowns/cancellation/interruption;
- dodge/evasion defensive verb according to accepted combat design;
- block/guard defensive verb according to accepted combat design;
- interruption/stagger/cancel interaction required by those defensive verbs;
- movement/action gates needed for those verbs;
- targeting/disposition integration;
- enemy use of the same canonical combat/action contracts rather than special-case damage logic;
- persistence/save-resume for combat state that the existing architecture says must persist;
- extension point for the minimum equipment path if the current contracts cannot yet express equipped combat modifiers without hacks.

Do **not** invent equipment breadth, many skills, many enemies, final HUD or final art in this mission. Those are later A1 groups unless a tiny integration hook is necessary to avoid a knowingly wrong foundation.

## Required engineering behavior

- Prefer surgical edits to existing symbols/files.
- If changing a public combat/action contract, inspect references before editing.
- Keep `Gameplay -> Foundation -> Core` dependency direction.
- Keep combat authority out of telegraph/presentation code.
- Keep player movement/input ownership in the existing player foundation.
- Keep combat content data-driven where an action/archetype definition already supports it.
- Do not defer a small specified foundation requirement merely to create a future task.
- Do not perform broad file moves/refactors unless a concrete correctness/architecture problem requires them.

## Validation

Run, at minimum, the affected existing suites and broaden when impact requires it:

```bash
bash tools/dev/devctl.sh godot-check
bash tools/dev/devctl.sh test affected
```

For combat-contract changes, expect the affected set to include combat/actions/enemy/save-related coverage. Run `bash tools/dev/devctl.sh test all` before declaring Engineering Complete if the change crosses shared combat/player/world boundaries.

When Godot LSP is active:

- use Serena references/symbol diagnostics;
- use `godot_diagnostics` for changed-file/workspace GDScript diagnostics where useful.

When the full runtime MCP is active:

- exercise the integrated combat path with structured runtime state/input where practical;
- verify defensive action state/cancellation/resource consequences;
- do not use screenshots for facts that structured state can prove.

If full runtime MCP fails after the bounded recovery policy, switch to DEGRADED mode and continue deterministic validation. Record the exact live validation gap instead of blocking the entire mission.

## Acceptance — Engineering Complete

This mission can be marked Engineering Complete only when:

- the audit confirms every required foundation item is either already production-capable or implemented in this mission;
- no duplicate combat/resource/defense framework was introduced;
- changed GDScript parses cleanly;
- affected automated suites pass;
- broader regression suites pass when required by impact;
- persistence expectations remain correct;
- material validation gaps/deferrals are explicit;
- architecture docs/tests are updated when behavior/contracts changed.

## Not enough to call complete

The following are not valid completion states:

- only adding interfaces/TODOs for dodge or block;
- debug keys that bypass canonical actions/resources;
- a defensive animation/telegraph without canonical gameplay behavior;
- tests that only instantiate classes but do not verify the state/result contract;
- claiming A1 Combat is complete while player-facing HUD/feedback/mobile acceptance remains out of scope for this group.

## Final report format

Return a concise report with:

1. **Existing foundation reused** — what was already correct.
2. **Gaps found** — concrete missing/incomplete items.
3. **Implemented** — exact systems/symbols changed.
4. **Validation** — diagnostics/tests/runtime evidence.
5. **State** — `ENGINEERING_COMPLETE` or `BLOCKED`, never generic `done`.
6. **Remaining A1 work** — only player-facing/presentation/content items that truly remain after foundation completion.
