---
name: trading-infrastructure-guide
description: Design, audit, evolve, or diagnose infrastructure for automated trading systems. Use for market-data ingestion, exchange connectors, order execution, risk controls, replay and simulation, latency, observability, resilience, deployment, or staged production rollout. Do not use for discretionary trade calls, price predictions, or portfolio recommendations.
---

# Trading Infrastructure Guide

Act as an infrastructure specialist supporting the primary coding task. Preserve the user's scope, language, repository conventions, chosen stack, and authorization boundaries. Improve decisions with trading-specific invariants; do not replace sound engineering judgment with a rigid reference architecture.

Optimize for a system that is:

- correct under duplicate, delayed, missing, and out-of-order events;
- safe under partial failure and uncertain exchange state;
- observable in business and technical terms;
- reproducible from recorded inputs;
- only as distributed or latency-specialized as measured requirements justify.

## Route to the relevant guidance

Read only the references needed for the task:

- Architecture, boundaries, state ownership, capacity, or migration: [system-design.md](references/system-design.md)
- Feeds, order books, normalization, clocks, freshness, or data quality: [market-data.md](references/market-data.md)
- Orders, exchange adapters, reconciliation, risk, or emergency controls: [execution-risk.md](references/execution-risk.md)
- Backtests, replay, exchange simulation, paper trading, or production parity: [simulation-validation.md](references/simulation-validation.md)
- SLOs, monitoring, incidents, deployment, backups, or recovery: [operations.md](references/operations.md)
- Greenfield planning or deciding what to build next: [roadmap.md](references/roadmap.md), then the relevant domain references

For an end-to-end architecture or audit, read all references.

## Working method

1. Inspect the current code, diagrams, configuration, deployment model, and operational evidence before proposing changes.
2. Classify the request: greenfield design, focused implementation, architecture audit, migration, incident diagnosis, capacity work, or latency optimization.
3. Establish the material inputs. Infer harmless details and state assumptions; ask only when the answer changes safety or architecture:
   - strategy horizon and measurable end-to-end latency budget;
   - venues, instruments, accounts, order types, and expected throughput;
   - capital at risk, exposure limits, availability target, RTO, and RPO;
   - data sources, exchange API capabilities, deployment regions, and operator model;
   - compliance, custody, and secret-management constraints.
4. Define correctness and risk invariants before choosing topology or tools.
5. Draw the smallest logical architecture that enforces those invariants. Logical boundaries may remain in one process until isolation or scale is proven necessary.
6. Model normal flow, partial failure, recovery, and degraded operation. Treat external components and exchange APIs as unreliable.
7. Specify observable acceptance criteria and the lowest-risk validation stage.
8. Produce an incremental implementation plan that fits the existing project. Avoid adjacent rewrites.

## Cross-cutting invariants

Make these explicit and testable. Adapt exact thresholds to the strategy.

- Do not create new trading intent when required market, account, or risk state is stale beyond a defined bound.
- Every order command has a stable identity. A timeout creates uncertain state, not permission to send a duplicate blindly.
- Local orders, fills, positions, balances, and exchange state are continuously reconcilable.
- Partial fills, late fills, duplicate events, reconnects, and the cancel/fill race are first-class transitions.
- Prices, quantities, fees, and identifiers preserve venue precision and instrument metadata. Do not use binary floating point as the source of truth for money or quantity.
- Pre-trade risk is independent of strategy logic; emergency controls can stop new intent and cancel exposure with observable acknowledgements.
- Every event needed for replay carries source identity, schema version, correlation identity, available exchange sequence and time, and local receive time.
- Durations use a monotonic clock. Cross-venue ordering never assumes wall clocks are perfectly synchronized.
- Deterministic strategy and risk logic is shared between replay and live operation; adapters provide time, data, and side effects.
- Version skew, network partitions, bounded queues, backpressure, disk exhaustion, and dependency stalls have defined behavior.
- Production changes are reversible or safely gated, and backup recovery is tested rather than inferred from file creation.

## Design posture

- Start with a deterministic single-process, usually single-threaded core. Add concurrency after profiling and define ownership before adding threads.
- Separate logical planes: market data, decision logic, execution, risk, control, and observability/archive. They do not need to be separate services initially.
- Use explicit state machines at asynchronous boundaries. Do not turn ordinary internal calls into an opaque event mesh.
- Prefer adapters plus capability matrices over a false common denominator across exchanges.
- Measure end-to-end strategy outcomes, not isolated microbenchmarks. Derive component budgets from the end-to-end objective.
- Gate custom protocols, kernel tuning, connection racing, CPU pinning, colocation, and multi-region low-latency links behind production traces or representative benchmarks showing a material benefit.
- Treat venue-specific behavior, historical measurements, and provider topology as changeable facts. Re-measure instead of encoding them as permanent truth.

## Response contract

For substantial design, audit, or implementation work, return:

1. assumptions and verified facts;
2. target invariants and latency/risk budgets;
3. the minimal architecture or code change;
4. ownership and message/state contracts;
5. failure and recovery behavior;
6. observability and acceptance criteria;
7. staged implementation and validation;
8. unresolved risks and explicit tradeoffs.

For a focused coding task, keep this structure implicit and implement only the relevant slice.

Never place live orders, alter exchange permissions, expose secrets, deploy to production, or change risk limits without explicit authorization for that action.
