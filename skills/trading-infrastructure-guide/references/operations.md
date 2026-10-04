# Operations

Use this reference for SLOs, readiness, telemetry, alerting, deployment, incidents, backups, and recovery.

## Measure trading readiness, not process existence

Separate liveness from readiness. A process can answer pings while its feed is stalled, clock is wrong, queues are stale, risk state is unavailable, or orders cannot be canceled.

A composite trading-readiness gate should include the strategy's required subset of:

- market-data freshness, continuity, and clock confidence;
- private-stream and reconciliation health;
- venue and execution latency/reject health;
- risk-engine availability and limit headroom;
- control-plane reachability and desired run state;
- queue age/backpressure and resource headroom;
- ability to cancel or activate the defined emergency path.

Readiness failure should prevent new intent and have an explicit policy for existing orders and exposure.

## Core telemetry

### Market data

- event age, inter-arrival time, gaps, duplicates, reordering, parse errors, and resync duration;
- connection quality and arbitration outcome;
- clock offset, drift, uncertainty, and timestamp truncation;
- publish/consumer queue age and dropped events.

### Execution and risk

- decision-to-send, send-to-ack, cancel-to-ack, fill-delivery, hedge, and total end-to-end distributions;
- open, pending, unknown, rejected, partial, duplicate, and late order/fill counts;
- rate-limit use, reconnects, and venue error classes;
- reconciliation lag and position/order/balance discrepancies;
- gross/net exposure, unhedged quantity and age, P&L, drawdown, risk blocks, and emergency-control coverage.

### Infrastructure

- CPU saturation/steal, memory, garbage collection, context switches, file descriptors, packet loss, retransmits, bandwidth, disk space/inodes/latency, and queue depth;
- dependency health, configuration version, artifact version, and schema version;
- backup age, size, destination success, retention/quota consumption, and restore-test age.

### Business outcome

Connect infrastructure to expected value: opportunity capture, fill probability, slippage, adverse selection, fees, missed opportunity, and the end-to-end threshold beyond which the strategy loses its edge.

Make equity and P&L provenance explicit. Separate trading result from deposits and withdrawals, funding, fees and rebates, valuation-source changes, and missing telemetry intervals. Surface gaps rather than drawing a continuous curve through them, and keep safety decisions independent from a dashboard or statistics pipeline whose outage can hide or fabricate a drawdown.

## SLOs and alerts

Define SLOs around user/business harm and safety invariants, not only host uptime. Use tail percentiles and sustained-window/burn-rate logic where appropriate.

Every page should have an owner, severity, evidence, and actionable runbook. Group related failures, deduplicate repeated events, rate-limit notifications, and retain full detail in telemetry. An alert flood that hides the root incident is an observability failure.

## Safe deployment

Before changing a trading path:

1. identify affected state, orders, accounts, regions, and version compatibility;
2. define pause/cancel/reconcile behavior and rollback criteria;
3. create an immutable, identifiable artifact and versioned configuration;
4. verify emergency controls before exposure;
5. deploy to a canary scope and compare it with a stable control where practical, observing readiness, reconciliation, tail latency, rejects, and trading outcome;
6. expand gradually and prevent unsafe version skew;
7. preserve evidence and revert or stop when criteria fail.

Use feature flags for behavior, not as a substitute for removing obsolete paths. Test both activation and rollback. Do not leave dormant production code reachable through stale configuration.

## Backups and recovery

- Keep backup work and retention from exhausting resources used by trading.
- Bound local staging with quotas, retention, and deletion only after verified remote durability.
- Monitor the complete pipeline, including transfer destination and free space.
- Encrypt and restrict backup access.
- Define RPO/RTO by data class: configuration, journals, raw market data, telemetry, and derived state have different needs.
- Run restore drills and verify application-level consistency, not only archive readability.

## Incident response

1. Move to the documented safe state and confirm which scope actually stopped.
2. Preserve raw events, commands, configuration/artifact versions, clock state, and external status.
3. Bound impact: exposure, unknown orders, data gaps, affected accounts/venues, and time window.
4. Reconcile with authoritative venue state before resuming.
5. Form and test a falsifiable hypothesis; avoid repeated restarts without new evidence.
6. Restore incrementally with explicit readiness gates.
7. Record root cause, contributing controls, detection gap, recovery gap, and a focused preventive change.

Classify recurring failures as systemic. Prefer removing the failure mode or adding independent detection over stacking watchdogs that depend on the component they monitor.

## Failure review prompts

- What happens if a dependency stalls without closing its connection?
- What happens if stop reaches only some workers?
- What happens if telemetry, backups, or logs saturate disk/network?
- What happens if the venue accepted a command but the response was lost?
- What happens if clocks step or two venues disagree?
- What happens during reconnect storms or a slow consumer?
- What happens when a canary and old version process the same state?
- How is safe recovery proven before trading resumes?
