# Mission — A1/G1 Combat Foundation Completion

- **Macro Version:** A1 — Combat & Player Gameplay
- **Mission state:** HOLD — release after Combat first-scope feel/feedback contract closes
- **Mission type:** production implementation + gap closure + first authority integration
- **Primary goal:** finish the missing combat foundation needed by A1, move gameplay-critical execution behind the online-first authority boundary, and reuse rather than rebuild the combat systems that already exist.

## Codex command

Implement this mission, not just an audit, **after the HOLD is removed**.

Start by reading `AGENTS.md`, `docs/development/MISSION_CONTRACT.md`, `docs/development/SHIPPABLE_DEFINITION_OF_DONE.md`, `docs/architecture/SERVER_AUTHORITY.md`, ADR-0016, this file, and only the combat/player/network architecture/design/ADR documents required to understand the existing implementation.

Use Serena first for GDScript symbol/reference discovery when available. Do not preload the whole repository.

Audit the existing combat/player/action/enemy/telegraph implementation against the required foundation below. Produce a concise gap list in your task report, then immediately implement the missing in-scope pieces in the same work session. Do not stop after analysis unless a genuine unresolved design/architecture decision blocks safe implementation.

Reuse the existing CombatService, ActionExecutor, PlayerIntent, combatants, Player adapters, targeting/telegraph contracts, persistence and enemy boundaries. Do not create parallel `CombatSystem2`, duplicate resource systems, or a new player architecture.

## Player-visible outcome enabled by this mission

After integration with the remaining A1 presentation work, the player foundation must be capable of a complete combat loop with health/resources, attacks, healing, defensive verbs, interruption/cancellation, defeat and persistence **without the production client owning canonical combat outcomes**.

This mission is the foundation-completion group, so it may finish at Engineering Complete. It must not claim the whole A1 Macro Version is Player Complete if HUD/presentation/assets/mobile feel work remains.

## Required authority audit and closure

The current deterministic local services are domain foundations, not permission for production client authority.

Implement the smallest production-intent authority seam that proves the A1 pattern without prematurely building all of A7.

Required direction:

- gameplay-facing client code sends semantic commands/intents through an `AuthorityGateway`-style boundary instead of directly owning durable outcomes;
- a development `LocalAuthorityHost`/loopback path processes the same command/result semantics with canonical validation;
- remote-authority/protocol adapters can replace the loopback transport without changing Combat/Player domain rules;
- release/runtime architecture must not contain an automatic `server unavailable -> trust local damage/state` fallback;
- direct CombatService/ActionExecutor instantiation remains valid in unit/domain tests;
- existing deterministic CombatService/ActionExecutor logic should be host-owned/reused rather than duplicated;
- PlayerIntent remains the natural semantic input boundary where appropriate;
- command envelope/sequence/correlation semantics must be bounded enough to support future authentication, retry/deduplication and server tick validation;
- current local `transaction_id` correlation must not be falsely treated as durable network idempotency.

### Forged-state protection proof

At minimum, integration tests must demonstrate that ordinary client-facing authority APIs cannot directly commit:

- arbitrary damage/health;
- arbitrary resource/cooldown state;
- arbitrary final persistent position as trusted outcome.

The authority path derives/validates canonical outcomes.

Do not implement a fake anti-cheat layer that merely compares a client-submitted damage number to another client value.

## Movement authority boundary

Do not rewrite the whole motor in this mission unless required, but establish/prove the intended seam:

- semantic movement intent is client-produced;
- canonical gameplay transform belongs to authority;
- client prediction is explicitly non-authoritative;
- authoritative snapshots can reconcile state;
- camera/view remains client-local except for validated gameplay aim/facing intent.

If a full network prediction implementation is too broad for this foundation group, provide the real adapter/state contract and deterministic reconciliation proof rather than a TODO-only interface. Do not leave PlayerMotor permanently classified as production network authority.

## Required combat foundation audit and closure

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
- Keep raw input/camera ownership in the existing player/presentation boundary; move canonical outcome authority behind the host seam instead of stuffing networking into UI.
- Keep combat content data-driven where an action/archetype definition already supports it.
- Do not defer a small specified foundation requirement merely to create a future task.
- Do not perform broad file moves/refactors unless a concrete correctness/architecture problem requires them.
- Do not implement the entire external Rust server, matchmaking, discovery or final transport merely to satisfy this mission; prove the authority boundary and make the domain hostable.

## Performance constraints

Read `docs/architecture/PERFORMANCE.md`.

The authority seam must avoid obvious per-command/per-tick allocation or global scans that would conflict with the `private_4gb` direction.

Do not add all-world broadcast or all-pairs actor validation. Server-side range/target lookups should remain compatible with future spatial/AOI indices.

## Validation

Run, at minimum, the affected existing suites and broaden when impact requires it:

```bash
bash tools/dev/devctl.sh godot-check
bash tools/dev/devctl.sh test affected
```

For combat/authority contract changes, expect the affected set to include combat/actions/enemy/player/save-related coverage. Run `bash tools/dev/devctl.sh test all` before declaring Engineering Complete when shared boundaries change.

Add deterministic tests for:

- semantic command -> authority validation -> canonical combat result;
- duplicate/replayed command behavior where the new boundary owns sequence/deduplication;
- forged direct outcome/state rejection;
- LocalAuthorityHost result equivalence with direct domain expectation for the same deterministic scenario;
- movement reconciliation seam/contract if movement state is touched.

When Godot LSP is active:

- use Serena references/symbol diagnostics;
- use `godot_diagnostics` for changed-file/workspace GDScript diagnostics where useful.

When the full runtime MCP is active:

- exercise the integrated combat path through the client-facing authority command boundary;
- verify defensive action state/cancellation/resource consequences;
- verify UI/debug presentation does not bypass canonical authority;
- do not use screenshots for facts that structured state can prove.

If full runtime MCP fails after the bounded recovery policy, switch to DEGRADED mode and continue deterministic validation. Record the exact live validation gap instead of blocking the entire mission.

## Acceptance — Engineering Complete

This mission can be marked Engineering Complete only when:

- the audit confirms every required foundation item is either already production-capable or implemented in this mission;
- no duplicate combat/resource/defense framework was introduced;
- gameplay-critical A1 state has an explicit AuthorityHost/Gateway ownership boundary;
- development local play goes through authority semantics rather than a client outcome bypass;
- forged direct damage/health/resource/final-state paths are rejected/unavailable through the client-facing contract;
- changed GDScript parses cleanly;
- affected automated suites pass;
- broader regression suites pass when required by impact;
- persistence expectations remain correct;
- performance/validation gaps/deferrals are explicit;
- architecture docs/tests are updated when behavior/contracts changed.

## Not enough to call complete

The following are not valid completion states:

- only adding interfaces/TODOs for dodge, block or authority;
- debug keys that bypass canonical actions/resources/authority;
- `if offline: apply_damage_locally()` in production gameplay;
- networking wrappers that still trust client-reported final damage/health/position;
- a defensive animation/telegraph without canonical gameplay behavior;
- tests that only instantiate classes but do not verify the state/result contract;
- claiming A1 Combat is complete while player-facing HUD/feedback/mobile acceptance remains out of scope for this group.

## Final report format

Return a concise report with:

1. **Existing foundation reused** — what was already correct.
2. **Authority gaps found** — where current runtime was locally authoritative.
3. **Gameplay gaps found** — concrete missing/incomplete combat items.
4. **Implemented** — exact systems/symbols changed.
5. **Validation** — diagnostics/tests/runtime/adversarial evidence.
6. **Performance impact** — any hot-path/allocation/query implications.
7. **State** — `ENGINEERING_COMPLETE` or `BLOCKED`, never generic `done`.
8. **Remaining A1 work** — only player-facing/presentation/content items that truly remain after foundation completion.
