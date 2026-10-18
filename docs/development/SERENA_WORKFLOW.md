# Serena Semantic Workflow

- **Status:** Active Block 1.5 integration
- **Updated:** 2026-10-18

## Purpose

Serena is the project's semantic code-navigation/editing layer. It is used to keep Codex from repeatedly scanning large GDScript files or relying on unstable line-number anchors as the codebase grows.

Serena does not replace the architecture docs, tests or Godot runtime MCP. It helps Codex retrieve and edit the right symbols with less context.

## Project configuration

Repository config:

- `.serena/project.yml`
- `.codex/config.toml` -> `mcp_servers.serena`

The Serena workspace is deliberately narrowed to `client/` because that is the Godot project containing `project.godot` and the GDScript codebase.

Current language backend:

```yaml
language_servers: ["gdscript"]
ls_workspace_folders: ["client"]
```

## Runtime requirement

Serena's GDScript support connects to Godot's built-in Language Server Protocol endpoint. Godot must already be running with the project open and LSP enabled.

Project convention:

- GDScript LSP: `127.0.0.1:6008`
- DAP: `127.0.0.1:6006`
- full runtime MCP bridge: `127.0.0.1:6550`

If the Godot LSP is unavailable, Serena's GDScript semantic operations may be unavailable or degraded. This does not block repository search/headless tests.

## Installation

Codespaces installs Serena through `tools/dev/bootstrap_codespace.sh` using the project's pinned development version.

To verify:

```bash
serena --version
codex mcp list
bash tools/dev/devctl.sh health
```

## Codex policy

For non-trivial GDScript changes, prefer this order:

1. identify the active Mission Contract and owning subsystem;
2. use Serena to find the class/function/signal/resource-facing symbol;
3. inspect references/callers/dependents relevant to the change;
4. retrieve only the body/context required to edit safely;
5. make a surgical edit when existing contracts are sufficient;
6. run changed-file/workspace diagnostics;
7. run affected deterministic tests;
8. use runtime MCP only for facts requiring live Godot state;
9. broaden regression testing according to impact/risk.

## Good use

Example request:

> Change stamina regeneration after dodge.

Desired navigation pattern:

```text
concept
 -> relevant resource/attribute symbol
 -> owning method
 -> direct references
 -> relevant tests
 -> localized patch
```

Avoid defaulting to:

```text
open every player/combat file
 -> reread thousands of lines
 -> rewrite a whole file
```

## Surgical editing rules

- Prefer symbol identity over line numbers.
- Preserve unrelated code/comments/order for local fixes.
- Do not reorganize a subsystem merely because Serena exposes its symbols.
- If a public contract changes, inspect its references and expand validation accordingly.
- If the semantic result looks incomplete, verify with repository search and/or Godot diagnostics before editing.
- Never assume semantic navigation alone proves runtime correctness.

## Memory policy

Serena memories can preserve concise project knowledge, but durable design/architecture remains in repository documents.

Good memory candidates later:

- terse subsystem maps;
- repeated navigation facts;
- known tool quirks;
- stable naming conventions.

Do not copy the entire GDD/architecture into Serena memories. Do not store secrets. Do not create a second contradictory source of truth.

## Block 2 direction

Serena is the first semantic layer, not the entire future Project Brain.

Block 2 may complement Serena with Godot/project-specific indexing for:

- `.tscn` / `.tres` relationships;
- resource UIDs;
- scene ownership;
- module dependency graph;
- typed events/data links;
- affected-test resolution;
- impact analysis;
- deterministic scenario/replay indexing.

Build those additions only where Serena + existing repository tools cannot answer the question cheaply enough.
