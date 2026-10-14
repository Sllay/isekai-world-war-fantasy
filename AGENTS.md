# AGENTS.md

Operational rules for AI/Codex work in this repository.

Keep this file small. Read only the documentation relevant to the task; do not preload the whole repository or every design document.

## Source of truth

- Game vision: `docs/gdd/GDD.md`
- Architecture: `docs/architecture/`
- Decisions: `docs/adr/`
- Roadmap: `docs/roadmap/`
- Development workflow: `docs/development/`
- Detailed reusable workflow: `skills/project-development/SKILL.md`
- Visual art direction: `docs/design/ART_DIRECTION.md`
- Vector asset workflow: `skills/vector-art/SKILL.md`

## Before changing code

1. Identify the subsystem being changed.
2. Read only its relevant design/architecture document and related ADRs.
3. Check whether an existing module, contract, component, event or data definition already solves the problem.
4. Prefer the smallest correct change.

Do not read every project document for a local change.

For visual/vector asset work, read `docs/design/ART_DIRECTION.md` and `skills/vector-art/SKILL.md` before generating or integrating important assets.

## Production-intent rule

M1.1/M1.2 resolved the major stack/tooling/2.5D uncertainties. From M1.3 onward, default to **production-intent implementation**, not throwaway prototypes.

- Do not create a disposable prototype when the required behavior/contracts are already known.
- Temporary proofs require a named unresolved technical risk and must not silently become production architecture.
- Reuse proof code only when it cleanly satisfies production contracts.
- Generated visual assets should target real game use when their requirements are known; do not spend tokens generating low-quality temporary art for the same role first.
- Placeholders are acceptable only when visual fidelity is irrelevant to the task or final art would block an unresolved technical dependency.
- Prefer one complete small production slice over several temporary demonstrations.

## Architecture rules

- No God Classes, God Managers or monolithic scripts.
- Core must not contain feature-specific gameplay without an accepted architectural reason.
- Prefer composition to deep inheritance.
- Prefer contracts/capabilities and typed events to hard references between modules.
- Circular dependencies are architectural errors.
- New content should be data-driven when behavior is reusable.
- Do not create duplicate systems such as `CombatSystem2` or `NewInventoryManager`.
- Optional systems must degrade cleanly when unavailable.
- Mobile/Web constraints are first-class requirements.
- Canonical server state must never be reconstructed from presentation defaults.

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

## Godot / MCP policy

When the Godot MCP is available:

- use structured runtime/editor state before screenshots when possible;
- use screenshots only when visual verification is actually required;
- use deterministic stepping for reproducible gameplay tests when supported;
- profile before proposing optimization;
- do not let multiple subagents fight for the same live Godot editor connection;
- file edits remain normal repository edits; MCP is primarily for engine-aware inspection, execution and verification.

### MCP recovery rule

Do **not** improvise repeated Godot/Xvfb restarts when the MCP bridge is unavailable.

Use this bounded recovery flow only:

1. Run `bash tools/dev/ensure_godot_mcp_editor.sh` once.
2. Retry the failed MCP/editor read after the launcher reports healthy.
3. If connection still fails, wait briefly and retry at most one additional time.
4. After two failed MCP retries total, **stop retrying**, inspect `.codex-local/godot-editor.log`, and report the blocker.

Never launch ad-hoc `nohup`, `xvfb-run`, or raw background Godot editor commands when the project launcher scripts exist. Never enter an open-ended reconnect/restart loop.

See `docs/development/CODEX_MCP_WORKFLOW.md`.

## Implementing a feature

- Identify the owning module.
- Define inputs, outputs, data and events.
- Keep cross-module integration minimal.
- Add isolated tests where practical.
- Add/update a test world for visual/systemic behavior where appropriate.
- Update only affected documentation.
- Record architecture-changing decisions in an ADR.

## Change rule

If a feature requires unrelated edits across many systems, stop and re-evaluate the contract instead of forcing the implementation through.
