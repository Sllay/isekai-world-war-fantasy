# ADR-0007 — Networking Transport and Interest Management

- **Status:** Proposed — selected for M1 proof
- **Date:** 2026-10-13

## Context

The client is Web/mobile-first and the server is authoritative. The world may contain far more entities than any one client needs. Network cost must therefore scale with client relevance, not total world size.

Godot Web has built-in WebSocket/WebRTC paths, while WebTransport became broadly available across current browsers in 2026 but is not a built-in Godot multiplayer transport.

## Decision

### M1 transport baseline

Use secure **WebSocket/WSS** for the first authoritative end-to-end proof because it is the lowest-risk common path across Godot Web/native and a custom server.

### Experimental fast path

Prototype **WebTransport** separately after the WSS proof. If integration, browser coverage and operational complexity are acceptable, use:

- reliable streams for transactions/control;
- unreliable datagrams for replaceable state such as movement snapshots.

Do not make M1 dependent on WebTransport.

### Interest management

Implement a ReplicationGraph-like relevance layer independent of transport:

- spatial AOI/cell subscriptions;
- always-relevant and owner-only sets;
- distance/relevance tiers;
- frequency buckets;
- dormancy for unchanged state;
- event-driven wakeup;
- delta/state revision replication.

Never broadcast the entire world to each client.

### Wire schema

Use explicit, versioned messages. Protocol Buffers is the first candidate, subject to a Godot 4.7.2 compatibility proof. CBOR with explicit message/version contracts is the fallback.

## Consequences

Positive:

- M1 can start on a simple, universally supported transport;
- relevance architecture does not depend on transport;
- future WebTransport can improve real-time channels without rewriting domain replication;
- authoritative transactions remain reliable/idempotent.

Risks:

- TCP/WebSocket head-of-line behavior may be inadequate for high-frequency combat under packet loss;
- WebTransport Godot integration requires browser/JavaScript plumbing and HTTPS/HTTP3 operations;
- protocol adapters add implementation work.

## Acceptance Gate

M1 must measure:

- movement/combat responsiveness under latency/loss simulation;
- messages/sec and bytes/sec;
- AOI entity counts;
- relevance computation cost;
- reconnect/resume behavior;
- duplicate/retried command safety;
- feasibility of WebTransport integration before any final transport ADR is accepted.
