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
forge pine generate \
  --combine-strategies tqqq_phase2,gld_bh,tlt_bh \
  --combine-allocation equal \
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
forge pine generate \
  --combine-strategies qqq_hmm_v1,tqqq_v1,gld_v1 \
  --allocation equal \
  --with-training-data \
  --portfolio-id combine_hmm_v1
```

## symbolic verify (issue [#975](https://github.com/ysakae/alpha-forge/issues/975)) {#symbolic-verify}

`forge pine verify --combine-strategies` validates that the generated
Pine and the alpha-forge backtest combine share the same intent — without
talking to TradingView at all.

```bash
forge pine verify \
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

## Known limitations

- **No Strategy Tester**: combine Pine is an Indicator, so TradingView
  cannot show Sharpe / CAGR / MDD natively. Use symbolic verify or
  alpha-forge backtest combine for portfolio-level metrics.
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
