# Simulation and Validation

Use this reference for backtests, deterministic replay, exchange simulation, paper/shadow operation, and production validation.

## Share deterministic domain logic

Keep strategy, feature, sizing, and risk decisions independent from network and wall-clock side effects. Supply them through interfaces such as:

- event source;
- monotonic and wall clock;
- instrument metadata;
- execution adapter;
- state/evidence sink.

Live feeds, recorded replay, and an exchange simulator should drive the same decision code. Do not maintain a simplified backtest implementation that only resembles production logic.

Record every decision with input event identity, configuration version, current state, risk result, intended action, and reason. The goal is to answer: “Given the exact information available then, should this action have occurred?”

## Model the venue, not only prices

A useful execution simulator includes the material behavior of the target venue and strategy:

- snapshot/delta ordering and data gaps;
- send, gateway, matching, acknowledgement, private-feed, cancel, and hedge latency distributions;
- price-time, pro-rata, queue position, or other matching rules when they affect fills;
- partial, late, duplicate, and missed fills;
- cancel/fill races and ambiguous order state;
- rate limits, rejects, outages, maintenance, and reconnects;
- fees, rebates, funding, slippage, price impact, and minimum constraints;
- position, balance, margin, liquidation, and instrument lifecycle behavior;
- clock truncation, offset, and uncertainty.

Use measured distributions when available. Label assumptions and stress them rather than tuning one favorable constant.

Historical replay is counterfactual: the system's own quotes, cancels, and size would have changed the queue and sometimes the visible market. Treat capacity as a curve, not one P&L number. State those assumptions and validate size, order-rate, instrument, and capital increases in controlled live increments.

## Protect causal validity

- Process events only with information available at that simulated time.
- Distinguish exchange event time, local receive time, and decision time.
- Version instrument metadata and fee schedules.
- Detect look-ahead, survivorship, selection, and feature leakage.
- Separate train, calibration, validation, and untouched evaluation periods when models are fitted.
- Include downtime and missing-data intervals; do not silently remove difficult periods.
- Evaluate after all explicit and implicit trading costs.
- Model scheduled boundaries such as funding, auctions, expiry, and delisting as venue-specific intervals when inclusion near the published timestamp is uncertain; do not assume settlement is atomic merely because the schedule shows one time.

## Validation ladder

Advance only when the current stage has measurable exit criteria:

1. **Unit and property tests:** arithmetic, state transitions, deduplication, precision, and risk invariants.
2. **Deterministic replay:** same inputs and versions produce the same decisions and state.
3. **Scenario and fault simulation:** gaps, stalls, rate limits, partial fills, latency tails, partitions, and restarts.
4. **Paper or sandbox execution:** adapter contracts and venue behavior without production capital; do not assume testnet liquidity resembles production.
5. **Shadow mode:** consume production data and compute intent without sending orders; compare simulated and observed venue state.
6. **Live canary:** smallest explicitly authorized risk scope, strict limits, emergency controls, and operator coverage.
7. **Controlled scale-up:** increase one dimension at a time and compare error, tail latency, fill quality, reconciliation, and P&L attribution.

Define rollback or stop criteria before each stage.

## Acceptance evidence

Prefer behavioral evidence over tests that merely assert wording or configuration presence:

- a replay hash or decision trace demonstrating determinism;
- state-machine coverage including ambiguous transitions;
- fault-injection results and recovery time;
- reconciliation converging after injected divergence;
- latency distributions from the target environment;
- shadow/live divergence and explained residuals;
- risk-control and emergency-stop drills;
- realized fill, slippage, adverse-selection, and end-to-end hedge metrics.
- capacity curves and explained replay-to-live divergence as size or order rate increases.
