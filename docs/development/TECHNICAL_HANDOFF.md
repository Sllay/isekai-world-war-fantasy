# Developer <-> Technical Design Handoff

- **Purpose:** asynchronous technical discussion between the implementing developer/Codex and the Technical Designer/Architect.
- **Audience:** Codex/developer, Technical Designer/Architect, and BK when a translated product/design decision is needed.
- **Status:** Active project workflow.

This file is **not** a replacement for architecture docs, ADRs, tests, issues, or the final task report. It is the small communication channel for facts that can otherwise disappear inside a long Codex session.

The intended flow is:

`BK / Art & Game Direction -> Technical Design -> Codex / Engineering -> Technical Design -> BK`

Codex should communicate technical facts here when they materially affect design, architecture, validation, schedule, or a later slice. The Technical Designer can then review the note, answer it, move a decision into the proper source-of-truth document, and explain the relevant consequence to BK in normal language.

## What belongs here

Add a concise entry when at least one of these happens:

- a required tool, MCP bridge, editor integration, CI service, or test environment is unavailable;
- an implementation assumption was necessary because the design/contract was ambiguous;
- a requested behavior could not be implemented exactly and a bounded alternative/workaround was used;
- a real bug, migration concern, performance risk, architectural tension, or future integration risk was discovered;
- an approach was attempted and rejected for a concrete technical reason that future work could accidentally repeat;
- automated coverage exists but an important behavior still requires Android/visual/manual acceptance;
- a later slice must preserve a non-obvious invariant or reuse a particular contract;
- the developer needs a design/architecture decision before safely proceeding;
- the developer believes a prompt/request conflicts with an accepted architecture or design rule.

Do **not** add routine implementation narration, raw logs, private chain-of-thought, token-by-token reasoning, or every minor error that was immediately fixed and has no future relevance.

## Entry format

Use the shortest entry that preserves the useful fact.

```md
### YYYY-MM-DD — <short topic>
- **Status:** OPEN | INFO | RESOLVED
- **Branch / slice:** `<branch>` / `<slice>`
- **Developer note:** What happened, in concrete terms.
- **Impact:** What this changes or does not change.
- **Evidence:** test/file/log/commit reference when useful.
- **Needs Technical Design:** a direct question or `No`.
- **Resolution:** filled by Technical Design when resolved; move durable decisions into GDD/design/architecture/ADR as appropriate.
```

`OPEN` means a response/decision is needed. `INFO` means the developer is surfacing an important fact but is not blocked. `RESOLVED` means the question has an accepted answer or the blocker has been cleared.

## Communication rules

1. **Facts before interpretation.** Say what failed, what was tried within project policy, and what remains unverified.
2. **Do not hide degraded validation.** If MCP, Android, CI, visual inspection, or a required external dependency was unavailable, say so here and in the final task report when relevant.
3. **Do not silently redesign.** If the accepted design cannot be implemented cleanly, create an `OPEN` note before substituting a materially different behavior.
4. **Do not duplicate source of truth.** Once a decision becomes durable, update the correct GDD/design/architecture/ADR document and leave only a short resolution/link here.
5. **Keep it cheap to read.** Prefer a few lines and exact references over pasted logs or giant summaries.
6. **No secrets or credentials.** Never put keys, tokens, private account data, or sensitive local-machine information here.
7. **No fake certainty.** Automated/headless validation is not Android acceptance; a placeholder presentation is not final art; a future extension hook is not an implemented feature.

## Current open / recent notes

### 2026-10-15 — Slice 3 live Godot MCP unavailable
- **Status:** RESOLVED
- **Branch / slice:** `phase2/enemy-telegraphs` / Phase 2 Slice 3
- **Developer note:** The bounded MCP recovery procedure was followed. The official launcher reported healthy, but both permitted MCP read retries returned `Not connected`. Recovery was stopped and the editor log inspected as required.
- **Impact:** Automated/headless coverage passed, but live telegraph readability, live interaction, and Android/device behavior are not proven by MCP.
- **Evidence:** `docs/architecture/ENEMY_TARGETING_TELEGRAPHS.md`; automated result recorded there as 598 checks / 0 failures.
- **Needs Technical Design:** Confirm Android acceptance should remain the merge gate for this slice.
- **Resolution:** Technical Design confirms Android acceptance remains the merge gate. The implementation can proceed to device testing, but must not be merged solely on headless evidence.

### 2026-10-15 — Enemy movement boundary is intentionally minimal
- **Status:** INFO
- **Branch / slice:** `phase2/enemy-telegraphs` / Phase 2 Slice 3
- **Developer note:** The first enemy uses a direct CharacterBody3D movement adapter on the open Home Valley terrain. Combat decisions call a movement port; no general navigation/pathfinding framework was introduced.
- **Impact:** This is sufficient for the current open-terrain encounter. Complex obstacles/terrain will require a navigation implementation behind the existing movement boundary rather than changes to CombatService or ActionExecutor.
- **Evidence:** `client/gameplay/enemies/enemy_controller.gd`, `client/gameplay/enemies/enemy_body.gd`.
- **Needs Technical Design:** No.
- **Resolution:** Future navigation work should preserve the movement-port boundary.

### 2026-10-15 — Melee telegraph circle is a warning range, not AoE authority
- **Status:** INFO
- **Branch / slice:** `phase2/enemy-telegraphs` / Phase 2 Slice 3
- **Developer note:** The current orange/gold circle presents the melee strike's range during windup. It does not damage every entity inside the circle and does not authorize a hit.
- **Impact:** The selected entity still has to be valid/in range when ActionExecutor commits; leaving range during windup cancels the hit. Future cone/line/ground-area actions may use different telegraph definitions without changing damage authority.
- **Evidence:** `client/foundation/telegraphs/telegraph_tracker.gd`, `client/foundation/telegraphs/telegraph_renderer.gd`, `docs/architecture/ENEMY_TARGETING_TELEGRAPHS.md`.
- **Needs Technical Design:** No.
- **Resolution:** Preserve the rule that telegraphs visualize canonical action intent but never become gameplay authority.

### 2026-10-15 — First enemy instance is intentionally single-content scope
- **Status:** INFO
- **Branch / slice:** `phase2/enemy-telegraphs` / Phase 2 Slice 3
- **Developer note:** `EnemyModule` currently owns the one authored Home Valley skirmisher instance needed by this slice. The archetype registry/family belongs to the module, while the instance is Region-owned persistent state.
- **Impact:** Future enemy scaling should extend this ownership into multiple authored/runtime actor records under the same contracts; it should not create one new Core module or a parallel combat framework per enemy instance.
- **Evidence:** `client/gameplay/enemies/enemy_module.gd`, `client/foundation/world/region_actor_state.gd`.
- **Needs Technical Design:** No.
- **Resolution:** Accepted for Slice 3. Revisit spawning/collection ownership only when the next content scale requires more than this one production actor.
