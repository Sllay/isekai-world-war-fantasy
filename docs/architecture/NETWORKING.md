# Networking Architecture

- **Version:** 0.2.0
- **Status:** Authority contract frozen; transport/scale still under proof
- **Updated:** 2026-10-18

## Purpose

Networking is not a late wrapper around an offline game. From A1 onward, gameplay-critical systems must expose an authority boundary even before the final production transport/server implementation is complete.

The invariant source of truth is `SERVER_AUTHORITY.md` and ADR-0016.

Transport, hosting scale and exact deployment topology remain subject to M1 evidence through ADR-0005/0007.

## Product Modes

The same authority/domain rules support:

- project-operated official/public servers;
- player-hosted private/community servers;
- a development-only LocalAuthorityHost reached through loopback command semantics.

A release client losing its connection does not switch to a client-authoritative fallback.

## Command / State Model

Clients primarily send semantic **commands/intents**, not trusted outcomes.

Examples:

- movement input;
- jump/action button;
- aim direction/point hint;
- requested target;
- use/equip/craft/build request;
- dialogue/trade/admin request where permitted.

Server/authority decides canonical results.

Examples of state that is never trusted merely because a client reported it:

- final transform;
- damage dealt;
- health/resources;
- cooldown completion;
- inventory quantity/custody;
- money/XP;
- Building placement success;
- quest/world-state completion.

## Authority Ingress

Before a command reaches domain mutation, the authority layer owns:

- session authentication/state;
- peer -> actor binding;
- protocol/schema validation;
- command size/range validation;
- sequence/duplicate/replay checks;
- timing window checks;
- command rate/backpressure limits;
- authorization/permission checks.

Domain services then validate gameplay state such as movement gates, cooldown, resource, target, range, relationship and inventory ownership.

## Movement Replication

Own actor:

- send input/intent;
- server simulates canonical result;
- client may predict;
- authoritative snapshots acknowledge processed input sequence;
- client reconciles and replays unacknowledged inputs.

Remote actors:

- receive relevance-filtered snapshots/events;
- interpolate buffered authoritative states;
- use only short bounded extrapolation if needed;
- never turn extrapolation into persistent canonical state.

Camera orbit/pitch/view mode normally stays client-local. Replicate gameplay-facing/aim state only when a mechanic requires it.

## Combat Replication

Client requests an action, not damage.

Authority owns cast/commit/recovery, costs, cooldowns, range/LOS/perception validation and final effects.

Replicate semantic facts/state sufficient for presentation, for example:

- action started/committed/cancelled;
- authoritative impact/result;
- health/resource revision;
- block/dodge/parry result;
- defeat/respawn state;
- relevant telegraph timing.

Clients derive animation/VFX/UI from these facts and may predict non-authoritative feedback where safe.

## Delivery Classes

Do not force every message through the same reliability/frequency policy.

### Durable / reliable

Examples:

- inventory/custody transfers;
- trade/economy commits;
- quest/contract commits;
- Building placement/destruction;
- unique-item ownership;
- server configuration/admin mutations;
- save/migration acknowledgements.

These require reliable ordering/idempotency semantics appropriate to the command.

### Replaceable real-time state

Examples:

- movement snapshots;
- aim/facing samples;
- high-frequency nearby motion.

Older samples can often be superseded by newer authoritative state. Exact transport mode remains an implementation proof decision.

## Interest Management

Network cost scales with relevance, not total world size.

Use a transport-independent ReplicationGraph-like layer:

- region subscription;
- spatial AOI/uniform-grid cells;
- neighboring/relevant cell subscriptions;
- owner-only state;
- group/party relevance;
- always-relevant bounded critical state;
- distance/relevance tiers;
- frequency buckets;
- dirty-state revisions;
- dormancy;
- event-driven wakeup.

Never broadcast the full world simulation to every client.

Perception rules may further restrict what a client is allowed to receive. Occluded/unknown hostile information must not be leaked merely because it exists in the server ECS.

## Simulation LOD Integration

Networking follows the same canonical world represented at different fidelities:

- L0/L1 nearby actors can replicate individual state;
- L2 regional/cohort systems replicate relevant summaries/events;
- L3 latent state normally produces no continuous replication.

Promotion/demotion cannot duplicate or delete canonical item/actor state.

## Tick and Snapshot Separation

Authority simulation tick and per-client snapshot frequency are separate controls.

A `private_4gb` server may run an L0 authority tick around the initial 20 Hz proof target while sending different state families at lower/higher relevance-dependent frequencies.

Client render may run at 30/60 FPS independently.

See `PERFORMANCE.md` for provisional budgets.

## Reconnect / Resync

Reconnect cannot assume the client retained correct state.

A resume flow should:

1. authenticate session/player identity;
2. resolve canonical actor/world state;
3. establish protocol/config/world revisions;
4. send a bounded authoritative baseline/snapshot for relevant owned state;
5. establish AOI subscriptions;
6. resume command sequence from an agreed boundary;
7. reconcile/discard stale local prediction.

Persistent item/cooldown/world state comes from authority storage, not client cache.

## Transport Direction

ADR-0007 currently selects for proof:

- WSS/WebSocket as the lowest-risk cross-platform baseline for custom server proof;
- WebTransport as a later experimental fast path when Godot/Web integration and operations are validated.

Godot native high-level ENet remains useful for engine-hosted experiments, but the product architecture must support the selected custom server boundary.

Do not make gameplay/domain code depend on a specific transport.

## Wire Schema

Messages are explicit and versioned.

Current candidates:

- Protocol Buffers, after Godot compatibility/tooling proof;
- CBOR with strict explicit schemas as fallback.

Schema rules:

- bounded collections/string/blob sizes;
- stable message/version IDs;
- optional-field/default behavior documented;
- compatibility/migration rules;
- no serialized arbitrary executable code from private-server configs.

## Security Invariants

- all client input is untrusted;
- peer identity is resolved server-side;
- never trust client position/timers/cooldowns/resources without authority validation;
- validate RPC/message arguments before mutation;
- rate-limit spam-sensitive commands;
- no client-admin operation without authenticated authorization;
- local debug authority is not a production network fallback;
- client prediction cannot grant canonical state;
- server configuration cannot disable these trust boundaries through ordinary gameplay settings.

## Server Customization

Official/private server configuration is specified in `docs/design/SERVER_CONFIGURATION.md`.

Customization may change world/rates/NPCs/Bots/rules inside validated profiles. It does not require a fork of network authority and cannot make a private server trust client damage/position simply because the owner changed gameplay settings.

## Current Development Rule

A1-A6 do not need production-scale session discovery/hosting operations yet, but every gameplay-critical subsystem must answer:

- what command/intent enters from a human client;
- which state the authority owns;
- which validation happens before commit;
- what facts/snapshots return to clients;
- what is prediction/presentation only.

This prevents A7 from becoming a rewrite.

## A7 Scope

Macro Version A7 is **Multiplayer / Server Productization**, not the first server authority pass.

It will focus on:

- proven external transport;
- session/connect/auth lifecycle;
- server discovery/join flow;
- reconnect/resume hardening;
- private-server packaging/config/admin UX;
- official deployment/observability/backups;
- scale/capacity testing;
- version/protocol compatibility;
- server update/migration operations;
- abuse/security hardening from measured threats.

## Acceptance Proofs

Before the networking foundation is considered production-ready, prove:

- forged client outcome/state is rejected;
- duplicate/retry safety for durable commands;
- prediction/reconciliation under latency/loss;
- AOI filtering correctness and cost;
- no perception-state leak through replication;
- reconnect/resync consistency;
- private-server and official profile share the same authority rules;
- bandwidth/messages-per-second/tick cost reported by repeatable benchmarks.
