# Market Data

Use this reference for feeds, order books, normalization, timestamps, freshness, replay evidence, and data quality.

## Treat every feed as fallible

Assume a venue can omit timestamps or sequence numbers, delay selected events, emit duplicates, reorder updates, send invalid payloads, disagree across public and private streams, stall while the connection remains open, or change schema without a clean cutover.

The adapter must make uncertainty visible. Never fabricate confidence by assigning local sequence numbers and calling them exchange ordering.

## Canonical event envelope

Preserve the raw payload and normalize into a versioned envelope containing, when available:

```text
event_id
schema_version
venue / market / instrument_id / instrument_metadata_version
feed_type / event_type / connection_id
exchange_sequence / connection_sequence / snapshot_id
exchange_event_time
local_receive_wall_time
local_receive_monotonic_time
normalized_publish_time
clock_offset_estimate / clock_uncertainty
freshness_state / validation_flags
raw_payload_reference
```

Define timestamp units explicitly. Store high-resolution timestamps as integers plus a declared unit, not floating-point seconds. Use fixed-point integers or exact decimals for price, quantity, fee, and notional, with tick and lot metadata versioned alongside the event.

Record each channel's publication cadence, batching or coalescing behavior, and timestamp resolution. Do not infer ordering below that resolution or assume a published liquidation, stop, or trade event is the matching-engine action itself; retain distinct semantic times when the venue exposes them.

## Feed lifecycle state machine

A useful baseline is:

```text
DISCONNECTED -> CONNECTING -> SNAPSHOTTING -> SYNCING -> LIVE
LIVE -> STALE | GAP_DETECTED | DISCONNECTED
STALE | GAP_DETECTED -> RESYNCING -> LIVE
any state -> DISABLED
```

Define transition evidence and time bounds. A healthy socket is not proof of fresh data.

For snapshot-plus-delta feeds:

1. begin buffering deltas;
2. obtain a bounded-age snapshot;
3. validate the snapshot/delta sequence relationship;
4. apply only valid ordered deltas and deduplicate by the venue's identity rules;
5. publish `LIVE` only after continuity checks pass;
6. on a gap, stop trading from that state and resynchronize rather than guessing.

Document venue-specific sequence semantics; they are not interchangeable.

Treat subscribe and unsubscribe as stateful protocol operations. Track acknowledgements and resulting coverage, use hysteresis instead of rapid subscription churn, and define resync behavior when the venue rate-limits or disconnects a frequently changing subscription set.

## Freshness and arbitration

Define freshness per venue, feed, instrument, and strategy horizon. Track:

- age by local monotonic receive time;
- exchange-time age only with an explicit offset and uncertainty model;
- inter-arrival distribution and stall threshold;
- sequence gaps, reordering, duplicates, and resync duration;
- disagreement between redundant connections or feed types;
- packet loss, parse failures, queue delay, and consumer lag.

When combining redundant feeds, choose events with deterministic rules and retain provenance. Racing connections can reduce latency but adds deduplication, ordering, cost, and reconnect complexity; use it only when end-to-end evidence justifies it.

## Clock model

Keep three concepts separate:

- exchange event time: the venue's claim about when an event occurred;
- local wall time: useful for human correlation and cross-system records;
- local monotonic time: authoritative for durations, deadlines, and local ordering.

Measure wall-clock offset and uncertainty continuously. Do not infer cross-venue causality from timestamps alone. Where server-time endpoints are used, retain round-trip samples and a robust offset estimate rather than dividing one round trip and treating it as truth.

Alert on clock step, drift, degraded source quality, and disagreement between time services. Prevent clock correction from producing negative durations or reordering monotonic processing.

## Normalization and instrument metadata

Maintain a capability and metadata record per venue instrument:

- canonical symbol and venue symbol;
- underlying identity and, where applicable, network, contract address, expiry, product lineage, and mapping evidence;
- base, quote, settlement asset, and contract multiplier;
- tick size, lot size, minimum quantity, minimum notional, and precision;
- trading status, sessions, expiry/roll, and relevant price bands;
- order types and flags supported;
- fee and rebate schedule version;
- market-data channels and their semantics.

Reject or quarantine events that cannot be normalized safely. A silent unit conversion is worse than an explicit outage.

Never join cross-venue instruments by ticker text alone. The same ticker can refer to different assets or contracts, and a venue can replace or migrate the product behind a familiar symbol.

## Visible book versus executable liquidity

The API-visible book may exclude hidden or participant-specific liquidity. Matching eligibility, priority, and latency can depend on order origin, account entitlement, flags, or an opt-in liquidity segment. Represent these capabilities explicitly and calibrate fills against actual executions; do not treat an ordinary L2 snapshot as the complete executable market for every account and order path.

## Evidence retention

Retain enough raw and normalized evidence to reproduce a decision:

- exact input events and adapter versions;
- connection and clock-quality context;
- configuration and instrument metadata versions;
- normalized events published to the strategy;
- gaps, drops, resyncs, and arbitration choices.

If full raw capture is too expensive, define loss-aware sampling separately from the minimum audit trail needed for orders and incidents.

## Validation scenarios

Test missing sequences, duplicate snapshots, out-of-order deltas, stalled sockets, reconnect storms, malformed payloads, metadata changes, timestamp truncation, clock drift, queue overload, and disagreement between public/private or REST/WebSocket views.
