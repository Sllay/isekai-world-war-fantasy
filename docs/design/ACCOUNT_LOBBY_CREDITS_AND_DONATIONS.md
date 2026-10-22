# Account, Main Lobby, Credits & Donations

- **Version:** 0.1.0
- **Status:** Product-shell design contract
- **Updated:** 2026-10-22

## Purpose

Define the first product-shell direction for account identity, login state, official/community server entry, settings, credits/legal attribution and optional project donations.

This document defines UX/product behavior and authority boundaries. It does not select the final authentication provider or payment platform.

## Main-menu role

The main menu is the player's **lobby/product shell**, not merely a splash screen.

It is responsible for:

- account/session state;
- official-server entry;
- community/private-server entry;
- options;
- credits/legal notices;
- donation/support entry;
- exit where the platform permits it.

The lobby may use a lightweight animated background/shader/noise treatment that communicates the game's pixel-fantasy identity without consuming gameplay-level simulation resources.

## Logged-out state

Primary focus:

- central `Login` / account-entry action;
- `Credits` accessible at the lower-left region;
- `Donate/Support` accessible separately, planned for the lower-right region;
- settings/legal/help affordances may remain accessible without login where useful.

Do not hide legally required credits/notices behind authentication.

## Logged-in state

After successful authentication:

- the central login action disappears;
- the player's public account name appears in the upper-left account area;
- primary actions appear in the central menu.

Initial primary order:

1. `Play` — official/project-operated servers;
2. `Multiplayer` — community/private/non-official servers;
3. `Options`;
4. `Exit` where supported.

Exact button names/localization may change while preserving this information architecture.

## Public account identity

Every account has at least two distinct identifiers:

### Internal account ID

- opaque/stable canonical identity;
- generated/owned by authoritative account services;
- not intended as the normal public identity shown to other players;
- never changes when the public name changes.

### Public account name

- human-readable visual identity shown to players;
- unique according to the account service's normalization rules;
- renameable under cooldown/policy;
- never used as the sole durable database foreign key.

Conceptual first-scope constraints:

- maximum 12 visible identifier characters;
- no spaces;
- allowed identifier alphabet initially limited to Latin letters, digits, underscore `_` and hyphen `-`;
- case/normalization policy is server/account authoritative;
- reserved/prohibited-name rules remain configurable.

The final minimum length and Unicode/localization expansion are product decisions and should remain data/config driven.

## Rename policy

Rename is server/account-authoritative.

First-scope direction:

- one successful public-name change starts a roughly monthly rename cooldown;
- the cooldown is attached to the account, not the client device;
- deleting local app data does not bypass it;
- the internal account ID remains unchanged;
- previous names may be retained in an abuse/moderation audit history according to privacy policy.

The client only requests a rename and displays the authoritative eligibility/result.

## Account panel

Tapping/clicking the public account identity may open a compact account panel containing first-scope actions such as:

- account/session information;
- rename, when eligible;
- logout;
- future account/security entry points.

Do not expose internal numeric/opaque IDs as the normal social identity unless a future moderation/support screen has a specific need.

## Official versus community servers

`Play` and `Multiplayer` intentionally represent two trust/product classes:

### Play / official

Project-operated servers using official rule profiles, identity integration and project moderation/operations.

### Multiplayer / community

Player/community-operated servers using the same authoritative simulation core but independently hosted/configured within supported server rules.

Community servers must remain visibly distinguishable from official servers so a private host cannot impersonate an official environment through ordinary configuration.

Detailed server-rule direction remains in `docs/design/SERVER_CONFIGURATION.md`.

## Options

First menu-level option tabs:

1. **Audio**
2. **Graphics**
3. **Language**

Additional categories may be added later without changing the initial shell architecture.

Options should work before joining a server. Device-local presentation settings are not server-authoritative gameplay state.

## Credits screen

Credits are a first-class menu destination because third-party LPC art and future audio/tools require discoverable attribution.

Presentation direction:

- dedicated full-screen/panel experience;
- lightweight animated pixel/fantasy background shader/noise;
- automatic vertical credit roll;
- manual scroll/seek must also be possible;
- pause/resume control should be considered for accessibility;
- readable text at mobile scale;
- legal notices remain accessible without requiring the user to wait through the entire roll.

Suggested logical sections:

1. creator / project direction;
2. developers/contributors;
3. audio/music;
4. visual/art contributors;
5. LPC/third-party asset attribution;
6. open-source tools/libraries when attribution is required;
7. community/supporter/donor acknowledgements with consent;
8. detailed licenses/legal notices.

Credits should be generated from structured project manifests wherever possible rather than maintained only as hand-written UI text.

LPC-specific credit generation is defined in `docs/design/LPC_CHARACTER_PIPELINE_AND_LICENSING.md`.

## Full LPC catalog versus used credits

The project intentionally preserves a complete legal/catalog archive for the pinned LPC source, including unused assets.

The runtime presentation must distinguish:

- **assets actually used by the game/build**;
- **complete upstream LPC license/catalog archive**.

This avoids falsely implying that every catalog entry is part of the shipped visual composition while still preserving all upstream legal metadata requested by the project.

## Donations / support

The lobby may expose a clearly separated `Donate` / `Support Project` action.

Principles:

- optional support must never be required to access legally required credits/notices;
- donation UX must not impersonate a gameplay reward unless a future monetization design explicitly defines and reviews such a system;
- default direction is project support, not pay-to-win power;
- external payment/service integration must be isolated from authoritative gameplay state;
- platform/store rules determine whether the action opens an external page or uses another compliant flow.

Future supporter acknowledgement may appear in Credits only with appropriate consent and moderation controls.

## Login/authentication architecture boundary

This document intentionally does not choose email/password, OAuth, platform identity, passkey or another login provider.

Required invariants regardless of provider:

- authentication secrets are never stored in plaintext gameplay saves;
- authoritative services map authentication identity to the stable internal account ID;
- gameplay servers receive only the identity/session claims they need;
- clients cannot self-assert another account ID/public name;
- logout invalidates/ends the relevant local session according to the authentication architecture.

## Server-local player state

A global account identity and a character's state inside one game server are distinct.

Conceptually:

```text
Account
  ├─ stable account_id
  ├─ public account name
  └─ authentication/session state

Server Residency
  ├─ server/world ID
  ├─ player actor/character state
  ├─ inventory/equipment/progression
  ├─ relationships/reputation/crime
  └─ world references
```

Joining a server may create a residency/character record, but the project should not retain meaningless server records forever merely because a player connected once.

Retention/cleanup and persistent offline-body behavior are defined in `docs/design/OFFLINE_PLAYER_PRESENCE_AND_RETENTION.md`.

## Loading/session flow — conceptual

```text
App boot
  ↓
Lobby
  ↓
Authentication
  ↓
Official or community server selection
  ↓
Session/identity validation
  ↓
Server residency load/create
  ↓
World join
```

A failed server connection returns to the lobby/server browser; it must not silently turn the client into local authority.

## Mobile UX requirements

- safe-area aware account/menu positioning;
- thumb-readable central actions;
- credits/donate affordances separated spatially from primary play actions;
- back-navigation behavior consistent across Android/Web/desktop;
- no tiny legal text as the only attribution surface;
- animated background must respect reduced-motion/accessibility settings when supported;
- menu performance must remain low-cost on budget mobile hardware.

## Security / abuse notes

Public-name validation must be performed on the authoritative account service, including:

- allowed-character validation;
- length/normalization;
- uniqueness;
- rename cooldown;
- reserved/prohibited-name checks;
- rate limiting.

Client-side validation is user feedback only.

## Non-goals for first shell

Do not block the first product shell on:

- social graph/friends;
- guild UI;
- store/cosmetic shop;
- elaborate account recovery UI;
- paid rename tokens;
- achievement feeds;
- news carousel;
- complex donor tiers.

## Acceptance gate

The first production shell is acceptable when it proves:

- logged-out and logged-in lobby states;
- stable internal identity distinct from public name;
- validated/cooldown-aware rename request contract;
- official and community server entry separated;
- Audio/Graphics/Language options entry;
- discoverable Credits/legal screen;
- generated LPC attribution can be rendered there;
- optional Donate/Support entry remains separate from gameplay authority;
- world join/load path respects server authority and server residency state.