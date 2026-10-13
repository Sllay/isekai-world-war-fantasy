# Milestones

## M0 — Repository Foundation

Exit criteria:
- repository structure exists;
- GDD v0.1 exists;
- architecture documents exist;
- ADR process exists;
- agent rules exist;
- roadmap exists.

## M1 — Technical Proof

Exit criteria:
- stack/engine chosen from evidence;
- Web/mobile prototype runs on target phone/browser;
- camera/2.5D spatial model validated;
- basic asset/character rig pipeline validated;
- performance baseline recorded;
- persistent simulation scheduler shown feasible;
- active <-> aggregate simulation transition demonstrated;
- minimal authoritative networking flow demonstrated;
- basic persistence/restart restoration demonstrated;
- M1 experiment evidence and unresolved risks documented.

Detailed plan: `docs/roadmap/M1_TECHNICAL_PROOF.md`.

## M2 — Modular Core

Exit criteria:
- modules load by manifest;
- dependency validation works;
- Event Bus works;
- data registry works;
- debug/module inspector exists in minimal form;
- automated tests cover core contracts.

## M3 — Combat Slice

Exit criteria:
- player + enemy combat loop playable;
- modular abilities demonstrated;
- equipment can alter ability behavior;
- one multi-pattern boss encounter playable.

## M4 — World Simulation Slice

Exit criteria:
- two factions simulate a conflict without player input;
- player intervention changes outcome;
- near/far simulation modes demonstrated;
- state persists through save/load.

## M5 — Survival/Building Slice

Exit criteria:
- gather -> craft -> build loop playable;
- modular room/wall/floor system validated;
- occlusion works without leaking hidden information.

## M6 — Emergent World Slice

Exit criteria:
- reputation/lealdade;
- systemic quests;
- basic dynamic economy;
- creature ecology;
- at least two distinct taming methods.

## M7 — Chapter 1 Alpha

Exit criteria:
- representative region of the first kingdom;
- all core loops integrated;
- mobile performance target defined and met for alpha scope;
- save/network strategy validated for intended play mode.
