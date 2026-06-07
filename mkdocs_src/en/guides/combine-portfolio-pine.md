# Combine Portfolio Pine — running multiple strategies in one Pine

`alpha-forge pine generate --combine-strategies` packages several
buy-hold-overlay strategies into a single Pine v6 Indicator that runs on
TradingView. Each sub-strategy fires `alert()` calls that are routed to
the alpha-strike webhook and executed on moomoo / OANDA.

## Why an Indicator?

Pine v6 `strategy()` is **single-instrument only**, so it cannot express
a multi-ticker portfolio. The combine portfolio Pine takes a different
shape:

- Sub-strategy prices are pulled with `request.security()` per ticker
- A `target_qty` is recomputed on every bar close per sub-strategy
- Quantity changes (or a rebalance trigger) emit `alert()` calls
- The receiving side (alpha-strike) parses the webhook v2 payload and
  places orders on moomoo / OANDA

As a side effect the TradingView Strategy Tester does not work on
combine Pine (Strategy Tester only attaches to `strategy()`). Use the
[symbolic verify](#symbolic-verify) flow instead to guarantee that the
emitted Pine matches the alpha-forge backtest combine logic.

## Quick start

### 1. Generate the combine Pine

```bash
alpha-forge pine generate \
  --combine-strategies tqqq_phase2,gld_bh,tlt_bh \
  --allocation equal \
  --rebalance-freq monthly \
  --rebalance-threshold 0.05 \
  --portfolio-id beat_qqq_hedged_v1 \
  --with-webhook \
  --webhook-broker moomoo \
  --webhook-run-mode paper
```

Options:

| Option | Meaning |
|--------|---------|
| `--combine-strategies sid1,sid2,...` | Comma-separated strategy IDs (≥2) to combine |
| `--allocation equal\|custom` | Equal split or custom weights via `--weights` |
| `--weights tqqq=0.5,gld=0.3,tlt=0.2` | Custom weights (sum 1.0 ± 0.01) |
| `--rebalance-freq weekly\|monthly\|quarterly\|yearly\|none` | Periodic rebalance frequency |
| `--rebalance-threshold 0.05` | Trigger rebalance when weight drift exceeds ±5% |
| `--allow-non-buy-hold` | Allow mean-reversion / trend-following inside combine (Phase 2 experimental) |
| `--with-training-data` | Fetch training data in parallel for HMM strategies and embed Forward Algorithm parameters (issue [#974](https://github.com/ysakae/alpha-forge/issues/974)) |
| `--portfolio-id <id>` | Indicator name + webhook payload portfolio_id |

### 2. Paste into the TradingView Pine Editor

Open `output/pinescript/<portfolio_id>.pine`, paste into the Pine Editor,
and click "Add to chart".

### 3. Configure the alert

| Field | Value |
|-------|-------|
| **Condition** | The `<portfolio_id>` indicator → `Any alert() function call` |
| **Frequency** | `Once Per Bar Close` (matches `alert.freq_once_per_bar_close` in Pine) |
| **Webhook URL** | `https://strike.alforgelabs.com/webhook` (replace per environment) |
| **Message** | **Leave empty** — Pine's `make_payload()` returns the full JSON itself |

After saving, the first 3-ticker entry fires on the next daily bar close.

## Webhook payload shape

`make_payload()` emits the alpha-strike webhook v2 payload on a single
line:

```json
{
  "passphrase": "<i_passphrase input>",
  "broker": "moomoo",
  "asset_class": "US",
  "action": "buy",
  "ticker": "US.TQQQ",
  "quantity": 33,
  "target_qty": 47,
  "strategy_id": "beat_qqq_hedged_v1",
  "sub_strategy_id": "tqqq_phase2",
  "portfolio_id": "beat_qqq_hedged_v1",
  "signal_id": "20260529-135959",
  "run_mode": "paper",
  "timeframe": "1D"
}
```

`run_mode` is `paper` or `live`, switchable from the TradingView input
panel. Keep `paper` during validation to route to moomoo SIMULATE.

`target_qty` is the sub-strategy's **absolute target holding** (alpha-forge
[#1037](https://github.com/ysakae/alpha-forge/issues/1037)). alpha-strike
v0.7.0+ re-resolves the order side/quantity from the difference between
`target_qty` and the broker's actual position, so even if zero fills,
partial fills, or rounding drift Pine's assumed position, the real holding
converges back to the target on the next signal (closed-loop). `quantity`
remains as the delta fallback for versions without `target_qty` support.

## HMM Forward Algorithm reproduction (issue [#974](https://github.com/ysakae/alpha-forge/issues/974))

When the combine includes an HMM regime strategy, pass
`--with-training-data` to fetch each HMM's training data in parallel,
embed the transition matrix / means / variances, and run the Forward
Algorithm inside Pine bar by bar.

- Parallel fetch via `concurrent.futures.ThreadPoolExecutor`
- Identifiers stay disjoint across HMMs through a prefix scheme
  (`s0_hmm_transmat`, `s1_hmm_transmat`, `s0_f_hmm_step`,
  `s1_f_hmm_step`, ...)
- Without training data the volatility regime proxy (`ta.stdev`) is
  used as a fallback (backward compatible)

```bash
alpha-forge pine generate \
  --combine-strategies qqq_hmm_v1,tqqq_v1,gld_v1 \
  --allocation equal \
  --with-training-data \
  --portfolio-id combine_hmm_v1
```

## symbolic verify (issue [#975](https://github.com/ysakae/alpha-forge/issues/975)) {#symbolic-verify}

!!! note "Paid plans only"
    `alpha-forge pine verify` is **available on paid plans (Lifetime / Annual / Monthly) only**. See [Trial limits](trial-limits.md) for Trial plan restrictions.

`alpha-forge pine verify --combine-strategies` validates that the generated
Pine and the alpha-forge backtest combine share the same intent — without
talking to TradingView at all.

```bash
alpha-forge pine verify \
  --combine-strategies tqqq_phase2,gld_bh,tlt_bh \
  --combine-allocation equal \
  --combine-rebalance-freq monthly \
  --combine-rebalance-threshold 0.05 \
  --combine-portfolio-id beat_qqq_hedged_v1 \
  --check-mode metrics
```

Sample output:

```text
# Combine Portfolio Verify — beat_qqq_hedged_v1

**Status**: ✅ PASSED (0 violation(s) / 12 checks)

## Metrics

| Metric            | Value     |
|-------------------|-----------|
| total_return_pct  | 915.5400  |
| cagr_pct          | 15.3000   |
| sharpe_ratio      | 1.0401    |
| max_drawdown_pct  | 23.3200   |
| volatility_pct    | 14.7700   |

## Integrity Checks (excerpt)

| Key                                     | Expected | Observed | OK |
|-----------------------------------------|----------|----------|----|
| pine_syntax                             | 0 errors | 0 errors | ✅ |
| weight:tqqq_phase2                      | 0.333333 | 0.3333   | ✅ |
| hedge_exposure:tqqq_phase2              | 0.4      | 0.4      | ✅ |
| rebalance_freq                          | monthly  | monthly  | ✅ |
| rebalance_threshold                     | 0.05     | 0.05     | ✅ |
```

Integrity checks cover:

- `pine_syntax` — Pine v6 syntax verify (PineV6Validator)
- `weight:<sid>` — Pine `s{i}_weight` versus backtest combine `weight_map[sid]`
- `base_exposure:<sid>` — exposure during normal regime
- `hedge_exposure:<sid>` — hedge state `target_exposure_pct`
- `rebalance_freq` — `ta.change(month)` etc. matched against CLI spec
- `rebalance_threshold` — `i_rebalance_threshold` input value

Pass `--check-mode compile_only` for syntax verify only (no backtest
required).

## hybrid-strategy mode (issue [#985](https://github.com/ysakae/alpha-forge/issues/985)) {#hybrid-strategy-mode}

The default `indicator` mode emits a single Pine v6 Indicator and the
Strategy Tester will not attach. When you want **partial metrics for at
least the main symbol** from the TradingView Strategy Tester, use
`--combine-mode hybrid-strategy`.

```bash
alpha-forge pine generate \
  --combine-strategies tqqq_phase2,gld_bh,tlt_bh \
  --combine-mode hybrid-strategy \
  --main-strategy tqqq_phase2 \
  --portfolio-id beat_qqq_hedged_v1 \
  --with-webhook \
  --webhook-broker moomoo
```

Behaviour:

- The strategy passed to `--main-strategy` is emitted as a
  **chart-native `strategy()`** (`default_qty_value = weight × 100`,
  position managed via `strategy.entry` / `strategy.close`). Apply it to
  the main symbol's chart and the Strategy Tester computes Sharpe / CAGR /
  MDD and so on.
- The remaining sub-strategies still trade through `request.security()` +
  `alert()` to alpha-strike (identical to indicator mode).
- The main strategy must be **buy-hold-overlay** (emitting mean-reversion /
  trend-following as `strategy()` is not supported).

| Option | Meaning |
|--------|---------|
| `--combine-mode indicator\|hybrid-strategy` | Output mode. `indicator` is the default (backward compatible) |
| `--main-strategy <sid>` | Main strategy ID emitted as `strategy()` in hybrid mode (a buy-hold-overlay included in the combine) |

!!! note "Metrics are an approximation"
    The main strategy's `strategy.entry` / `strategy.close` does not match
    AlphaForge backtest combine (vectorbt) exactly, and sub-strategies are
    not included in the Strategy Tester metrics. Keep
    [symbolic verify](#symbolic-verify) or alpha-forge backtest combine as
    the source of truth for portfolio metrics; use hybrid-strategy as an
    aid to eyeball / sanity-check the main symbol's behaviour on TradingView.

### Auto-verify the Strategy Tester result (issue [#986](https://github.com/ysakae/alpha-forge/issues/986))

After applying the hybrid-strategy Pine to the main symbol's chart and running
the Strategy Tester, use `alpha-forge pine verify --verify-mode
tradingview-strategy-tester` to automatically compare the **main symbol
component's Sharpe / Max Drawdown** against alpha-forge backtest combine's
same-symbol component. The Strategy Tester aggregates are fetched via the MCP
server (vinicius / tradesdontlie).

```bash
alpha-forge pine verify \
  --combine-strategies tqqq_phase2,gld_bh,tlt_bh \
  --combine-mode hybrid-strategy \
  --main-strategy tqqq_phase2 \
  --check-mode metrics \
  --verify-mode tradingview-strategy-tester \
  --symbol TQQQ --interval D \
  --mcp-server-flavor vinicius
```

How it works:

- alpha-forge backtests the main strategy standalone, then blends its equity to
  the weight allocation (`(1-w) + w·ratio`, equivalent to the Pine
  `default_qty_value = weight × 100`) to build the reference metrics. This keeps
  Sharpe / Max Drawdown consistent with the Strategy Tester (percent_of_equity
  sizing).
- TradingView side fetches the Strategy Tester aggregates on the main symbol's
  chart via MCP.

!!! warning "Only the main component is comparable"
    Portfolio-level Sharpe cannot be derived from the Strategy Tester (single
    symbol only). The TradingView Strategy Tester also does not expose Calmar
    directly, so PASS/FAIL is gated on **Sharpe + Max Drawdown** and the
    reference-side Calmar is shown for information only. Use
    [symbolic verify](#symbolic-verify) for portfolio-level validation.

## Known limitations

- **No Strategy Tester in indicator mode**: the default combine Pine is an
  Indicator, so TradingView cannot show Sharpe / CAGR / MDD natively. Use
  symbolic verify or alpha-forge backtest combine for portfolio-level
  metrics, or [hybrid-strategy mode](#hybrid-strategy-mode) for partial
  metrics on the main symbol.
- **Once Per Bar Close enforced**: Pine sets
  `alert.freq_once_per_bar_close` to suppress intrabar firing — please
  pick the same frequency in the alert dialog.
- **First entry timing**: each sub-strategy alert fires only after its
  bar closes, so initial entries land on the first daily close after
  the alert is saved.

## Related guides

- [Bringing Pine Scripts into TradingView](tradingview-pine-integration.md) — for single-strategy flow
- [TradingView × alpha-strike Integration](tradingview-alpha-strike.md) — webhook receiver side
- [alpha-strike Setup Guide](alpha-strike-setup.md) — webhook server bootstrap
