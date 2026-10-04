# System Design

Use this reference for architecture, boundaries, state ownership, capacity, migration, and scaling decisions.

## Start from measurable requirements

Capture the smallest useful requirement set:

| Dimension | Questions that change the design |
|---|---|
| Strategy | What event creates intent? How quickly does the edge decay? What is the maximum unhedged interval? |
| Venues | Which feeds, private streams, order types, rate limits, and recovery APIs actually exist? |
| Scale | Instruments, accounts, connections, events/second, orders/second, retained history, and peak multipliers |
| Risk | Per-order, instrument, venue, strategy, account, and global exposure limits |
| Reliability | Availability objective, degraded modes, RTO, RPO, and acceptable manual intervention |
| Latency | Measured end-to-end target and tail percentile; do not substitute an average or an isolated function time |
| Operations | Who deploys, responds to alerts, rotates credentials, and approves risk or venue changes? |

If the strategy has no quantified end-to-end requirement, instrument the current path before selecting low-latency technology.

## Prefer logical planes before physical services

Model these responsibilities even when they initially share one process:

```text
Venue feeds -> Market-data adapters -> Canonical events -> Deterministic decision core
                                                          |
                                                          v
Control plane -> Risk gate -> Execution intent -> Venue adapter -> Exchange
                     ^                              |
                     |                              v
              Account truth <- Reconciliation <- Private events / REST snapshots

All planes -> Telemetry + append-only replay evidence
```

- **Market-data plane:** acquire, validate, normalize, sequence, timestamp, and publish feed state.
- **Decision plane:** deterministic features, signals, quoting, hedging, and position intent.
- **Execution plane:** venue-specific order state machines, rate limits, acknowledgements, and recovery.
- **Risk plane:** pre-trade gates, aggregate exposure, stale-state checks, and emergency policy.
- **Control plane:** desired run state, configuration versions, deployment coordination, and operator commands.
- **Evidence plane:** metrics, structured logs, traces, raw inputs, decisions, commands, and reconciliations.

Split a logical plane into another process or service only for a concrete reason: fault isolation, independent scaling, security boundary, deployment cadence, region placement, or a measured latency/throughput constraint.

## Assign state ownership

For each state item, record:

- the authoritative source;
- the component allowed to mutate it;
- consistency model and acceptable age;
- persistence and replay behavior;
- recovery after restart or partition;
- consumers and their behavior when it is unavailable.

Important state includes instrument metadata, normalized market state, strategy configuration, desired run state, order lifecycle, fills, positions, balances, risk consumption, connection health, and clock quality.

Avoid two writable sources of truth. Derived caches must be disposable and rebuildable.

## Define contracts before topology

Each asynchronous contract should specify:

- schema and version compatibility;
- stable event or command identity;
- ordering scope, if any;
- delivery semantics and deduplication key;
- timestamp semantics and clock domain;
- bounded queue and backpressure behavior;
- retry policy and idempotency boundary;
- stale, unknown, and terminal states;
- observability fields and redaction rules.

Event-driven boundaries are useful for external facts and asynchronous lifecycle transitions. Direct calls are often clearer inside an owned synchronous component. Do not use an event bus to hide call order or ownership.

## Concurrency and performance

Build the deterministic path sequentially first unless an existing system already has safe concurrency. Then:

1. profile with representative event rates and payloads;
2. identify the end-to-end critical path and tail behavior;
3. partition by explicit ownership, such as venue, account, instrument group, or strategy instance;
4. define cross-partition ordering and consistency;
5. bound queues and implement load shedding or fail-safe gating;
6. test overload, reconnect storms, and slow consumers.

Minimize shared mutable state. A fast race condition is still a correctness failure.

Trace the complete hot path from received bytes through parsing, state update, decision, risk, and serialized command. Include queue age, allocation and garbage-collection pauses, scheduler wakeups, implicit task creation, context switches, CPU run-queue delay, and cache or virtual-machine interference. A fast function benchmark or low average CPU utilization can coexist with damaging tail latency and consumer backlog.

When one component can own the relevant state, a serialized event loop can process market-data events and execution completions without blocking or spawning work per command. Keep log formatting, analytics, and heavy calculations off that path; preallocate or reuse hot data structures where measurements justify it. Busy spinning, affinity, dedicated cores, and bare metal remain measured tail-latency tradeoffs, not defaults.

## Latency budget

Express the business path as stages, for example:

```text
exchange event -> local receive -> normalize -> decide -> risk -> send
-> exchange acknowledge/fill -> private receive -> hedge decision -> hedge fill
```

For each stage record p50, p95, p99 or a more appropriate tail, sample count, timestamp confidence, and failure rate. The useful target is the largest end-to-end delay compatible with positive expected value after fees, slippage, adverse selection, and missed fills.

For cross-venue strategies, trace the full source-event-to-destination-acknowledgement or fill path rather than comparing exchange RTTs in isolation. Benchmark the exact candidate host, zone, endpoint, protocol, and account path; separate cold and warm DNS, connect, TLS, time-to-first-byte, steady-state stream age, and order RTT. Record resolved edge or backend identity where observable. A matching cloud region or low ping does not prove an equivalent route when CDN, anycast, load balancing, or provider routing can change independently.

Only after this budget exists should the design consider specialized network links, colocation, binary protocols, custom event loops, busy polling, connection racing, CPU isolation, or in-memory-only hot paths. Every such optimization needs a measured benefit, failure mode, fallback, and operating cost.

## Architecture review checklist

- Can a feed gap or stale quote reach strategy logic as if it were current?
- Can a retry duplicate an order or hedge?
- Can any restart forget an open order, fill, position, or desired stop state?
- Can a control command reach only part of the fleet without detection?
- Does one slow consumer create unbounded memory or stale decisions?
- Can a venue or schema change silently corrupt prices, quantities, or identifiers?
- Can observability or backups exhaust the same resources as trading?
- Are latency claims end-to-end, tail-aware, and measured in the target environment?
- Does the design have a simpler phase that proves the same business hypothesis?
