# Execution and Risk

Use this reference for order execution, venue adapters, reconciliation, account state, risk checks, and emergency controls.

## Model orders as state machines

Do not represent an order as a successful HTTP call. Use explicit states adapted to the venue, for example:

```text
INTENT_CREATED -> RISK_ACCEPTED -> SEND_PENDING -> SUBMITTED_UNKNOWN
SUBMITTED_UNKNOWN -> ACKED_OPEN | PARTIALLY_FILLED | FILLED | REJECTED | UNKNOWN
ACKED_OPEN | PARTIALLY_FILLED -> CANCEL_PENDING
CANCEL_PENDING -> CANCELED | PARTIALLY_FILLED | FILLED | UNKNOWN
UNKNOWN -> RECONCILING -> any authoritative state
```

Persist or durably journal enough intent before sending to recover after a crash. Treat request timeout, disconnect, malformed response, and missing acknowledgement as `UNKNOWN`; reconcile before issuing a conflicting replacement.

## Stable identity and idempotency

- Give every strategy intent, order attempt, cancel, fill, and hedge a stable correlation identity.
- Use venue `clientOrderId` when available, respecting length, alphabet, and uniqueness rules.
- Keep retry policy inside the venue adapter, where idempotency capabilities are known.
- Deduplicate private events and fills by authoritative venue identity; use a documented composite only when the venue omits one.
- Do not encode critical state only inside an identifier unless the encoding is versioned, validated, collision-safe, and recoverable elsewhere.

Treat successive amend, replace, and cancel commands as a causally ordered stream. An older request can arrive after a newer one and restore an obsolete price or quantity. Carry a desired-state generation locally, use exchange-enforced sequence or expiry windows where available, and otherwise serialize or coalesce mutations. After ambiguous ordering, reconcile actual exchange state against the latest desired generation.

## Venue capability matrix

Keep explicit, versioned facts per venue/account mode:

- order, time-in-force, post-only, reduce-only, amend/move, and self-trade-prevention semantics;
- client ID rules and idempotent endpoints;
- rate-limit scopes, weights, headers, and ban behavior;
- acknowledgement, execution-report, and private-stream semantics;
- open-order, recent-fill, balance, and position reconciliation endpoints;
- mass cancel, cancel-on-disconnect, dead-man switch, and session behavior;
- maintenance, trading halts, and error/reject classifications;
- account/margin mode and precision/minimum constraints.
- effective entitlements per credential, account, and instrument: fee tier, rate limits, private feeds, liquidity segments, and order permissions.

Do not flatten these differences into a lowest-common-denominator interface that hides safety behavior. Expose capabilities and require callers to choose an allowed fallback.

Verify effective entitlements during onboarding and readiness, and again after reconnects, maintenance, or account-tier changes. Do not assume a parent account's status, fees, or limits were inherited by a subaccount or new credential.

## Reconciliation is continuous

On startup, reconnect, stream gap, ambiguous response, and periodically during normal operation:

1. fetch authoritative open orders, positions, balances, and recent executions;
2. compare them with the local journal and projections;
3. classify mismatches by risk;
4. repair derived state only from defined evidence;
5. block conflicting new intent while material uncertainty remains;
6. alert with correlation IDs and a bounded operator action.

Track reconciliation lag and unresolved discrepancies as production metrics.

## Layer risk independently of strategy

Pre-trade checks should cover at least:

- data and account-state freshness;
- instrument status, tick/lot/minimum rules, and order flags;
- price collars, fat-finger bounds, notional, position, leverage, and available margin;
- aggregate exposure across strategies, accounts, venues, and correlated instruments;
- open-order and order-rate limits;
- maximum unhedged quantity and duration;
- venue health, execution latency, reject rate, and ability to cancel.

Treat request capacity as a safety resource. Budget quote placement and replacement by priority, and reserve independently enforceable capacity for cancels, reconciliation, risk actions, and emergency control so ordinary quote churn cannot consume the only path to safety.

Runtime controls should watch realized/unrealized loss, exposure drift, hedge backlog, reconciliation state, risk-engine health, and limit consumption. Decide whether each breach pauses new intent, widens quotes, cancels orders, reduces exposure, or requires an operator.

Keep the venue-reported account or index valuation alongside a conservative executable valuation based on relevant bid/ask depth, fees, price bands, and liquidation haircut. Label the basis used for risk and P&L. An index-valued equity number can move independently of realizable close value and should not be the only trigger for drawdown controls.

## External position changes and closeability

Positions can change without a local order command through auto-deleveraging, liquidation, expiry, settlement, exercise, venue correction, or administrative action. Treat these as authoritative external transitions. If one leg of a hedge or basket changes, invalidate the group-level hedge assumption and execute the predefined pause, re-hedge, reduce, or operator-escalation policy.

Cancel-all does not imply flat exposure, and market-close is not guaranteed to fill in an empty book or through a venue price band. Track residual position separately from open orders, bound repeated close attempts, and test the emergency path under missing liquidity, rejects, rate pressure, and forced venue transitions.

## Emergency control semantics

A stop button is a distributed protocol, not a boolean column.

- Persist a versioned desired state such as `RUNNING`, `PAUSE_NEW`, `CANCEL_OPEN`, or `EMERGENCY_STOP`.
- Give commands stable IDs/generations and require acknowledgements from every responsible worker.
- Make restart behavior preserve the latest desired state.
- Detect partial delivery and surface which venue/account/instrument remains active.
- Use venue dead-man or cancel-on-disconnect features where available, but monitor their renewal and test their semantics.
- Prefer fail-closed behavior for new intent when control, risk, or required state is unavailable.
- Exercise the entire path regularly, including network partitions and supervisor restarts.

Define whether emergency handling cancels only, reduces exposure, or flattens positions. Flattening creates market risk and must be an explicit policy, not an assumed default.

## Secrets and permissions

Use separate identities for environments and responsibilities. Trading credentials should normally exclude withdrawals; isolate transfer credentials when transfers are an explicit workflow. Apply least privilege, encryption, audited access, rotation, redaction, and IP restrictions when compatible with availability requirements. Never log raw keys, signed requests, or secrets embedded in URLs.

## Validation scenarios

Test timeout after the exchange accepted an order, fill during cancel, late/duplicate fills, partial fills, rate-limit exhaustion, private-stream gap, process crash after send, stale balance, position mismatch, venue maintenance, invalid precision, risk-service outage, partial stop propagation, and restart while stopped.
