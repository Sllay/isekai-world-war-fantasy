# Live Battle Simulation

- **Version:** 0.1.0
- **Status:** Design hypothesis
- **Updated:** 2026-10-13

## Core Principle

A battle is not two health bars. It is a temporary system composed of people, units, command, morale, terrain, objectives, logistics, information and escape routes.

The same battle must be representable at different simulation fidelities without becoming a different reality.

## Battle Layers

### Strategic

Represents why the battle exists:

- capture/hold territory;
- protect/destroy supply;
- rescue/capture a person;
- delay an army;
- break a siege;
- raid;
- escape;
- defend civilians.

### Command

Commanders and officers create intent:

- advance;
- hold;
- retreat;
- flank;
- regroup;
- protect artillery/healers;
- escort wounded;
- surrender;
- pursue;
- disengage.

Orders are not perfect telepathy. Units can receive them late, misunderstand them, refuse them, lose contact, or become unable to execute them.

### Unit

Squads/platoons carry shared state such as:

- cohesion;
- morale;
- fatigue;
- ammunition/resources;
- formation;
- casualties;
- leadership;
- current objective;
- threat assessment.

### Individual

When high fidelity is required, individual actors resolve:

- movement;
- perception;
- attacks;
- blocks/dodges;
- abilities;
- wounds;
- fear;
- surrender/flee decisions;
- personal relationships and memories.

## Rank Does Not Determine Death

Military rank modifies behavior; it does not hard-code it.

A general is normally less likely to panic than an untrained levy because the general may have:

- experience;
- discipline;
- ideological commitment;
- responsibility for the army;
- bodyguards;
- escape plans;
- political consequences attached to capture.

However, generals can still:

- retreat;
- order surrender to preserve troops;
- be captured;
- desert;
- defect;
- fight to the death;
- abandon troops;
- negotiate;
- escape while subordinates delay the enemy.

Different commanders may react differently to the same situation.

## Decision Factors

A surrender/retreat/fight decision may consider:

- current morale;
- wounds and exhaustion;
- perceived chance of victory;
- perceived chance of escape;
- expected treatment as prisoner;
- loyalty;
- ideology;
- courage/fear;
- discipline;
- personality traits;
- cultural norms;
- reputation/honor concerns;
- orders;
- family or dependents;
- responsibility for subordinates;
- presence of allies/reinforcements;
- value of current objective;
- enemy reputation;
- previous atrocities;
- availability of defensive terrain.

No single factor should decide every case.

## Morale and Cohesion

A unit can cease to function before most members are dead.

Example states:

`organized -> pressured -> shaken -> broken -> routed`

Consequences of low cohesion/morale include:

- slower response to orders;
- poorer formation;
- more individual retreat;
- surrender clusters;
- desertion;
- panic spreading to nearby units;
- officers spending effort restoring order instead of attacking.

## Surrender

Surrender can exist at several scales:

- individual;
- squad;
- unit;
- garrison;
- army;
- city.

A surrendered actor becomes a persistent person with a new legal/military state rather than being treated as dead.

Possible outcomes:

- prisoner of war;
- parole;
- prisoner exchange;
- ransom;
- forced labor where setting/law permits;
- recruitment/defection;
- escape;
- release after treaty;
- rescue quest.

## Command Casualties

Killing/capturing an officer can matter beyond raw damage.

Possible effects:

- temporary command delay;
- morale shock;
- succession by next officer;
- conflicting orders;
- retreat;
- opportunity for enemy push;
- political consequences if the commander is important.

The system should support a chain of command so that one death does not automatically freeze an army.

## Generals Fighting Generals

Generals do not automatically seek cinematic duels.

A duel may happen when:

- both are physically present;
- tactical circumstances bring them together;
- culture encourages personal challenges;
- one deliberately hunts the other;
- scripted/lore conditions justify it.

Normally, a competent commander prioritizes commanding, survival, objectives and preservation of forces.

## Wounds

Combat should distinguish at least conceptually between:

- minor injury;
- serious injury;
- incapacitation;
- unconscious/downed;
- death.

This supports medics, rescue, capture, retreat and long-term consequences without requiring every defeated soldier to die.

## High-Fidelity Performance Strategy

Large live battles should not give every soldier an expensive planner every frame.

Prefer:

- squad-level intent;
- staggered AI decision ticks;
- local steering at higher frequency;
- spatial partitioning;
- batched perception;
- shared target/threat data;
- formation slots;
- cached paths where safe;
- simplified AI for actors outside the player's relevant combat bubble.

A soldier can obey squad intent while still reacting individually to immediate threats.

## Promotion From Abstract Battle

A distant battle may exist as aggregate state.

When a player approaches:

1. current forces, wounds, morale, leaders and objectives are read from persistent battle state;
2. representative/important actors are materialized;
3. units receive positions/formations consistent with the strategic situation;
4. the battle continues in high fidelity;
5. after relevance decreases, survivors and results are folded back into aggregate state.

The player must not be entering a freshly generated fake battle unrelated to what was simulated before arrival.

## Diagnostics

Record at least:

- casualties by cause;
- wounded/incapacitated;
- surrendered;
- captured;
- routed;
- deserters;
- morale transitions;
- commander loss/succession;
- time spent in each fidelity level;
- battle outcome and objective state.

These statistics are essential to detect accidental massacre-heavy balance.
