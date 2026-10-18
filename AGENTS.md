# AGENTS.md

Operational rules for AI/Codex work in this repository.

Keep this file small. Read only the documentation relevant to the task; do not preload the whole repository or every design document.

## Source of truth

- Game vision: `docs/gdd/GDD.md`
- Architecture: `docs/architecture/`
- Server authority: `docs/architecture/SERVER_AUTHORITY.md`
- Server configuration: `docs/design/SERVER_CONFIGURATION.md`
- Decisions: `docs/adr/`
- Roadmap: `docs/roadmap/`
- Development workflow: `docs/development/`
- Design readiness audit: `docs/development/DESIGN_SCOPE_AUDIT.md`
- Shippable gate: `docs/development/SHIPPABLE_DEFINITION_OF_DONE.md`
- Mission contract: `docs/development/MISSION_CONTRACT.md`
- Developer <-> Technical Design handoff: `docs/development/TECHNICAL_HANDOFF.md`
- Detailed reusable workflow: `skills/project-development/SKILL.md`
- Visual art direction: `docs/design/ART_DIRECTION.md`
- Vector asset workflow: `skills/vector-art/SKILL.md`

## Before changing code

1. Identify the subsystem being changed.
2. Read only its relevant design/architecture document and related ADRs.
3. Check whether an existing module, contract, component, event or data definition already solves the problem.
4. For gameplay-critical Player/Combat/World/Inventory/Building/NPC/Bot work, read `SERVER_AUTHORITY.md` and preserve its command/authority boundary.
5. For non-trivial production work, read the active Mission Contract.
6. For a major player-facing domain, verify that its design contract is first-scope complete enough for implementation; use `DESIGN_SCOPE_AUDIT.md` as a readiness guide.
7. Prefer the smallest correct change inside the active Macro Version.

Do not read every project document for a local change.

If an owning design document is intentionally incomplete, do not silently invent permanent product behavior. The Mission Contract must either bound the unresolved decision, declare a temporary proof, or route the decision back to Technical Design before it becomes architecture.

For visual/vector asset work, read `docs/design/ART_DIRECTION.md` and `skills/vector-art/SKILL.md` before generating or integrating important assets.

## Delivery model: Macro Versions, not micro-slices

The user-facing unit of development is a **Macro Version**: a coherent playable outcome that groups related systems needed to make one part of the game actually usable.

Examples: Combat Version, World Version, Inventory/Survival Version, Living NPC Version, Networking Version.

Internal engineering work may still be split into tasks, commits, workstreams or checkpoints, but those are not independent product deliveries and must not redefine completion around isolated infrastructure.

Rules:

- Do not create a new product milestone for every small subsystem.
- Group strongly related work that is needed for the same player loop.
- Use foundation just-in-time: build the infrastructure required by the active Macro Version, then finish the player-facing loop before moving on.
- Preserve completed historical slice records for traceability; do not continue the old micro-slice workflow for new work.
- A Macro Version may have several implementation groups, but BK should normally validate the integrated candidate rather than every micro-change.

## Online-first authority rule

The product is online-first in **authority** from A1 onward. A7 is not the milestone where gameplay suddenly becomes server-aware.

For gameplay-critical systems:

- the production client sends semantic intent/commands, not trusted final outcomes;
- canonical damage/healing, health/resources, cooldowns, inventory/custody, money/XP, Building commits, persistent world mutations and authoritative gameplay transforms belong behind the AuthorityHost boundary;
- a client may predict presentation/movement, but prediction never becomes persistent truth merely because it ran locally;
- camera/view/UI/VFX/SFX can remain local unless a mechanic explicitly derives a validated gameplay intent from them;
- a disconnected production client must never fall back to trusting local damage/position/inventory state;
- development without a remote server uses `LocalAuthorityHost`/loopback command semantics, not an offline gameplay bypass;
- unit tests may directly instantiate domain services only inside explicit test harnesses;
- official and private servers share the same trust/authority invariants; private configuration changes rules/content/budgets, not who is trusted.

When adding a gameplay feature, define:

1. client/user/AI intent entering the system;
2. authority-owned canonical state;
3. validation before commit;
4. authoritative fact/snapshot returned;
5. presentation/prediction-only state.

Do not add a client-only gameplay mutation with a note saying “make authoritative in A7 later.”

## Completion states

Never use the word `complete` without qualifying the state when ambiguity matters.

- **Engineering Complete**: architecture/contracts/code/tests for the scoped technical work pass, but player-facing acceptance may still be missing.
- **Player Complete / Shippable**: the scoped player-visible experience satisfies `SHIPPABLE_DEFINITION_OF_DONE.md` and the active Mission Contract.

For a player-facing Macro Version, Engineering Complete is not sufficient to close the version.

## Production-intent rule

M1.1/M1.2 resolved the major stack/tooling/2.5D uncertainties. From M1.3 onward, default to **production-intent implementation**, not throwaway prototypes.

- Do not create a disposable prototype when the required behavior/contracts are already known.
- Temporary proofs require a named unresolved technical risk and must not silently become production architecture.
- Reuse proof code only when it cleanly satisfies production contracts.
- Generated visual assets should target real game use when their requirements are known; do not spend tokens generating low-quality temporary art for the same role first.
- Placeholders are acceptable only when visual fidelity is irrelevant to the task or final art would block an unresolved technical dependency.
- For player-facing work, do not stop at scaffolding, debug-only interactions or backend-only completion when the Mission Contract requires presentation/UX.
- Do not defer a small, specified, low-risk requirement merely to create another future task. Deferral requires a real dependency, unresolved design decision, content-scale concern or material technical risk.

## Architecture rules

- No God Classes, God Managers or monolithic scripts.
- Core must not contain feature-specific gameplay without an accepted architectural reason.
- Prefer composition to deep inheritance.
- Prefer contracts/capabilities and typed events to hard references between modules.
- Circular dependencies are architectural errors.
- New content should be data-driven when behavior is reusable.
- Do not create duplicate systems such as `CombatSystem2` or `NewInventoryManager`.
- Optional systems must degrade cleanly when unavailable.
- Mobile/Web and low-resource private-server constraints are first-class requirements.
- Canonical server state must never be reconstructed from presentation defaults.
- Do not reorganize many files merely because a new tool is available; refactor only for a concrete architectural or product reason.
- Profile before replacing a simple deterministic scheduler/data structure with a more complex optimization.

## Agent budget policy

Default to **one primary agent**.

Subagents are optional, not the default. Spawn one only when the task has a clearly independent subproblem whose parallel work is expected to save more context/time than it costs.

Rules:

- normal task: 0 subagents;
- complex task: at most 2 concurrent subagents unless the user explicitly requests more;
- never create recursive agent trees for routine coding;
- do not spawn separate agents for trivial research, formatting, linting, or file discovery;
- reuse an existing subagent/thread for follow-up work instead of spawning another;
- summarize subagent findings before carrying them forward;
- prefer deterministic tools/tests over asking another agent to re-check obvious facts.

Token/context efficiency matters. Avoid dumping large logs, whole files, screenshots or MCP results into context when a narrow query or structured state is sufficient.

## Semantic code navigation policy

When Serena is available, use it for symbol-level discovery, references and surgical edits before broad file scanning. Serena is a navigation/editing aid, not a replacement for architecture docs, tests or runtime validation.

- Prefer symbols/references over line-number anchors.
- Retrieve only enough surrounding context to make a safe change.
- Preserve unaffected code and file structure for localized changes.
- If Serena/LSP is unavailable, continue using repository search and deterministic tests; do not block all work on one tool.

See `docs/development/SERENA_WORKFLOW.md`.

## Godot / MCP policy

The development pipeline has three supported modes:

- **FULL**: Serena/LSP + minimal Godot diagnostics + Godot runtime/editor MCP.
- **DEGRADED**: repository + Serena/LSP and/or minimal diagnostics + headless tests; live editor bridge unavailable.
- **STATIC**: repository inspection + deterministic/headless checks available to the host; no live editor dependency.

When the full Godot MCP is available:

- use structured runtime/editor state before screenshots when possible;
- use screenshots only when visual verification is actually required;
- use deterministic stepping for reproducible gameplay tests when supported;
- profile before proposing optimization;
- do not let multiple subagents fight for the same live Godot editor connection;
- file edits remain normal repository/Serena edits; runtime MCP is primarily for engine-aware inspection, execution and verification.

Use `minimal-godot-mcp` for fast GDScript diagnostics/DAP console when available. It complements, rather than replaces, the runtime/editor MCP.

### MCP recovery rule

Do **not** improvise repeated Godot/Xvfb restarts when the runtime MCP bridge is unavailable.

Use this bounded recovery flow only:

1. Run `bash tools/dev/ensure_godot_mcp_editor.sh` once.
2. Retry the failed MCP/editor read after the launcher reports healthy.
3. If connection still fails, wait briefly and retry at most one additional time.
4. After two failed runtime-MCP retries total, **stop retrying**, inspect `.codex-local/godot-editor.log`, switch to DEGRADED mode, and continue every validation that does not require the live bridge.
5. Report only the validation gap that genuinely remains; do not ask BK to manually test facts already covered deterministically.

Never launch ad-hoc `nohup`, `xvfb-run`, or raw background Godot editor commands when the project launcher scripts exist. Never enter an open-ended reconnect/restart loop.

See `docs/development/CODEX_MCP_WORKFLOW.md`.

## Human acceptance policy

BK is Game Director, not the default micro-QA runner.

Ask BK for device/manual validation primarily when the remaining question is subjective or device-specific, for example:

- control comfort;
- visual/readability quality;
- animation/feedback feel;
- mobile UX;
- representative real-device performance;
- a design decision machines cannot resolve.

Do not request manual acceptance merely to verify a deterministic state transition, numeric result, parser error or regression that can reasonably be automated.

## Developer <-> Technical Design handoff

Use `docs/development/TECHNICAL_HANDOFF.md` as the concise asynchronous communication channel from Codex/engineering to Technical Design.

Before finishing a Macro Version or material implementation group, add/update a handoff entry when there is a material tool failure, unresolved design/architecture question, bounded workaround, validation gap, discovered future risk, or non-obvious invariant the next work must preserve. Do not log routine narration, raw logs, secrets, or private reasoning. Durable decisions still belong in the appropriate GDD/design/architecture/ADR document, and the normal final task report is still required.

## Implementing a feature or Macro Version group

- Identify the owning module.
- Define the player-visible outcome when applicable.
- Define inputs, outputs, data and events.
- Define the authority boundary for gameplay-critical state.
- Keep cross-module integration minimal.
- Add isolated tests where practical.
- Add adversarial/forged-command tests when network authority is involved.
- Add/update integration/scenario coverage for systemic behavior when appropriate.
- Add/update a test world for visual/systemic behavior where appropriate.
- Update only affected documentation.
- Record architecture-changing decisions in an ADR.
- Run affected tests first, then broaden regression coverage according to impact/risk.
- Check the resulting diff against the Mission Contract; unexpected broad edits require re-evaluation.

## Change rule

If a feature requires unrelated edits across many systems, stop and re-evaluate the contract instead of forcing the implementation through. A Macro Version may legitimately touch several related systems, but each edit must serve the same coherent player/product outcome.
