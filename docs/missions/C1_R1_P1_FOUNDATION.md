# C1-R1-P1 — Player, Combat & Skills Foundation

Chapter 1 / Run 1 / Part 1 is the current macro delivery. It continues the A1
implementation at `f9dfc54`; it does not replace its services or reopen its accepted
first-scope. Final Chapter 1 combat content and presentation belong to Run 2.

## Contract

Player-visible goal: enter a session, move/orient/aim, read and guard an enemy
attack, take an unguarded hit, use one-handed basic/strong attacks, cause a valid
stagger, defeat an enemy, lose the next encounter, wait dead, respawn safely and
fight again. Representative procedural visuals/audio and a technical HUD are
accepted for this foundation. Human acceptance concerns the readability/feel of
this one integrated loop; numeric transitions are automated.

Owners: existing Player/Input/View adapters, CombatService, ActionExecutor,
CombatDefense, EnemyModule and application-composed AuthorityGateway /
LocalAuthorityHost. Core remains independent of gameplay.

Clients request semantic movement, facing/aim, action slot, target hint,
guard/dodge/cancel. The bound authority owns transforms, action validation,
resource/cooldown, hit/damage, defense/stagger, death/respawn and save state.
Envelopes reject forged fields/actor identity, duplicates, stale/future commands
and overload. Disconnect never promotes a client to authority. Results are typed
facts and detached snapshots; camera, HUD, body reactions, VFX/SFX and bounded
pose-only hit-stop are read-only presentation.

## Audit and implementation scope

- Preserve the working A1 movement/collision/camera, authoritative combat,
  data-driven basic/strong/heal, enemy wind-up/commit/recovery, guard/dodge,
  stagger immunity, death/respawn and persistence contracts/tests.
- Replace fixed host slot mappings with an authority-installed validated loadout:
  primary and Skill Slots 1/2/3, empty slots supported. Changing loadouts must not
  reset action cooldowns. Final three universal skills/equipment UI are not due.
- Complete the world-space aim/target request boundary. Camera-specific projection
  belongs in a view adapter; target/range/occlusion checks remain authoritative.
  Hidden actors must not become eligible locks merely because a Node exists.
- Make target resolution a bounded authority-side strategy shared by the existing
  executor, including fail-closed directional/point query integration. Prove a
  multi-target query using the same effects/cost/cooldown pipeline. Do not build
  a ranged arsenal/projectile simulation or deep AI in this Part.
- Clear transient input/aim/target selection across death/respawn; retain committed
  cooldowns and persistent canonical state. Prove combat after respawn.
- Keep presentation work bounded and independent of simulation. Measure the live
  integrated scenario; cloud software rendering is not Android acceptance.

## Gates

Automated: valid/invalid basic, range/LOS, canonical damage, valid/invalid block,
stagger/immunity, cooldown/cost, death/respawn/no residual state, duplicate/stale/
forged/actor mismatch, loopback equivalence, slot/loadout validation and spatial
query fail-closed/revalidation. Run `godot-check`, `test affected`, `test all`.
Use Serena symbols/references, LSP/Diagnostics and real Runtime MCP. Record runtime
state and active-scenario timing with limits, not only screenshots/headless tests.

Performance target: Compatibility mobile client / private_4gb authority, 20 Hz
canonical tick, p95 application tick <=25 ms in the representative cloud scenario;
report render/physics scope separately. No population/device capacity claim.

Deferred: final three universal skills, classes/archetypes/content arsenal,
equipment/loadout UI, final art/HUD/mobile UX, advanced parry/downed/revive,
deep AI/perception/world interaction breadth, A7 external transport/hosting,
full network prediction/replay and real Android performance acceptance.

## Completion

Status: IMPLEMENTING. Foundation/Engineering completion requires the entire
integrated loop and all applicable gates above; it is not final Chapter 1 combat
or Player Complete on mobile. Preserve the Environment and PR #9; no main merge.
