# Shippable Definition of Done

This document separates technical completion from player-facing completion.

## Completion states

### Engineering Complete

A scoped technical change is Engineering Complete when:

- the intended architecture/contracts are implemented;
- tests for the scoped behavior pass;
- regressions caused by the change are resolved;
- persistence/network/data consequences are handled when in scope;
- gameplay-critical state has the authority boundary required by `SERVER_AUTHORITY.md`;
- performance-sensitive changes are measured against the relevant profile/budget when in scope;
- documentation accurately reflects the implementation;
- known validation gaps are explicitly recorded.

Engineering Complete does **not** imply that a player-facing feature is ready to present to BK or ship in a playable Macro Version.

### Player Complete / Shippable

A player-facing feature or Macro Version is Player Complete only when every applicable item below passes, plus all acceptance criteria in its Mission Contract.

## Player-facing gates

1. **Usable loop** — the player can enter, use, succeed/fail and exit the scoped loop without debug-only controls.
2. **Controls** — required mobile/desktop/controller inputs for the scoped version exist and are coherent.
3. **Readability** — important state, danger, success, failure and cooldown/resource consequences are legible without developer inspection.
4. **Feedback** — required visual/audio/animation/haptic feedback is present at representative quality when defined by the art/design direction.
5. **Presentation** — no essential player-facing element is left as an accidental debug placeholder when requirements are already known.
6. **Persistence** — state expected to survive save/resume does so through the canonical authority/persistence owner.
7. **Failure paths** — death, cancellation, invalid targets, missing resources and similar scoped failure paths behave intentionally.
8. **Authority/security** — gameplay-critical outcomes are committed by the AuthorityHost boundary; ordinary client-facing paths cannot authoritatively forge damage/health/resources/inventory/position or other scoped canonical state.
9. **Regression** — affected automated suites pass; broader suites are run when dependency/risk impact requires them.
10. **Runtime validation** — live/headless/scenario validation appropriate to the feature passes; a runtime-MCP outage is not permission to claim unverified behavior.
11. **Device acceptance** — mobile-sensitive UX/performance claims receive representative Android validation before they are called accepted.
12. **Performance budget** — applicable client/server benchmark stays within the currently accepted target profile or a measured/approved exception is recorded. “Feels fine in the editor” is not evidence.
13. **Network behavior** — if the scope is network-relevant, latency/retry/reconnect/prediction or other applicable boundaries are tested at the level required by the Mission Contract.
14. **No hidden deferral** — a specified, small, low-risk requirement cannot be silently moved to a future version merely to close the current task.

## Online-first rule

A player-facing system is not Player Complete if its intended production state is persistent/competitive multiplayer but the implementation only works by trusting local client outcomes.

A LocalAuthorityHost/loopback development mode is valid when it uses the same authority command/result semantics. A client-side “offline bypass” that becomes authority when disconnected is not.

A7 is not a blanket deferral for authority work introduced by A1-A6.

## Legitimate deferral

A requirement may be deferred when at least one is true:

- it depends on a system that does not yet exist and cannot be safely introduced in the active Macro Version;
- a real design decision remains unresolved;
- the requested fidelity is content-scale rather than system-scale (for example hundreds of mobs rather than a representative production set);
- measured technical risk justifies a separate proof or migration;
- a concrete external-server/transport feature can be safely deferred because the current Macro Version already established the correct AuthorityHost/domain boundary;
- the Mission Contract explicitly marks it out of scope.

Every material deferral must be named in the final report or `TECHNICAL_HANDOFF.md`.

## Internal/infrastructure exception

Pure infrastructure work can finish at Engineering Complete when it has no direct player-visible acceptance criteria. Infrastructure must not be mislabeled as completion of the player-facing system it supports.
