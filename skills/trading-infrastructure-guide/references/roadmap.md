# Staged Roadmap

Use this reference to choose the next build step for greenfield or immature systems. Adapt stages to existing capabilities; do not rebuild working components to match the list.

## Stage 0 — Contracts and evidence

Deliver:

- strategy event, horizon, venue scope, throughput, and end-to-end latency hypothesis;
- instrument and venue capability matrix;
- market-event and order-lifecycle schemas;
- state ownership and risk invariants;
- initial SLOs, telemetry plan, and explicit safe state.

Exit when critical units, timestamps, identities, stale/unknown behavior, and risk limits are unambiguous.

## Stage 1 — Deterministic core

Build a single-process, usually single-threaded vertical slice:

- one venue and a small instrument set;
- validated market-data adapter and canonical event stream;
- deterministic strategy/risk logic with injected clock;
- structured decision journal and reproducible replay;
- no live order side effects.

Exit when representative input replays deterministically, gaps/staleness stop intent, and numerical/state invariants are tested.

## Stage 2 — Execution sandbox

Add:

- venue-specific order state machine and capability checks;
- stable command identity, persistence/journal, rate limits, and reconciliation;
- pre-trade risk and emergency control path;
- exchange simulator plus sandbox/paper adapter.

Exit when injected timeouts, crashes, partial fills, cancel/fill races, duplicates, reconnects, and position drift converge safely.

## Stage 3 — Production shadow

Run production feeds and infrastructure without sending live orders. Measure:

- data continuity and freshness;
- clock quality;
- decision determinism;
- predicted fills/costs versus observable venue behavior;
- end-to-end and component latency distributions;
- operational load, alert quality, and recovery drills.

Exit when unexplained replay/shadow divergence is bounded and operating procedures work.

## Stage 4 — Live canary

With explicit authorization, enable the smallest venue/account/instrument/capital scope. Require hard risk limits, operator coverage, tested stop/cancel paths, reconciliation, and predefined rollback criteria.

Exit when live fills, slippage, exposure, end-to-end latency, incidents, and P&L attribution agree with the model within defined bounds.

## Stage 5 — Scale and resilience

Increase only one dimension at a time: instruments, accounts, strategies, venues, regions, or capital. Add process/service separation, redundancy, backpressure, and independent failure domains only where evidence requires them.

Exit when peak load, failover, version skew, partition, reconnect-storm, and recovery tests satisfy SLOs without increasing unresolved state.

## Stage 6 — Latency specialization

Only after end-to-end evidence shows latency is the binding constraint, evaluate regional placement, colocation, private links, binary protocols, allocation reduction, custom data structures, CPU isolation, connection racing, kernel bypass, or specialized hardware.

For each optimization record:

- business metric and expected gain;
- baseline and representative benchmark;
- tail impact, not only median;
- correctness and operability cost;
- fallback and rollback;
- recurring infrastructure cost;
- revalidation trigger when venue/provider topology changes.

## Minimum durable artifacts

Keep artifacts proportional to the system, but make these decisions inspectable:

- system context and logical data/control flow;
- state ownership and order/feed state machines;
- venue capability matrix and instrument metadata contract;
- risk limits and emergency semantics;
- SLOs, dashboards, alerts, and runbooks;
- replay/simulation assumptions and validation evidence;
- deployment/rollback and backup/restore procedures;
- ADRs for expensive or irreversible infrastructure choices.
