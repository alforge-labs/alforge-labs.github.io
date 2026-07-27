# alpha-forge backtest

Run backtests and analyze results. Provides single-strategy runs, parallel batch runs, automated diagnostics, listing/reporting/migrating saved results, multi-strategy comparison, portfolio backtests, dashboard chart navigation, Monte Carlo simulation, and signal count checks.

!!! info "About sample output"
    Sample outputs in this page are based on the formats read from the `alpha-forge` source. Actual numbers depend on the data and environment.

## Subcommands

| Command | Description |
|---------|-------------|
| [`alpha-forge backtest run`](#alpha-forge-backtest-run) | Run a backtest for the given symbol and strategy |
| [`alpha-forge backtest batch`](#alpha-forge-backtest-batch) | Run parallel backtests for multiple strategy JSON files |
| [`alpha-forge backtest timeframes`](#alpha-forge-backtest-timeframes) | Backtest the same strategy across multiple timeframes and compare |
| [`alpha-forge backtest diagnose`](#alpha-forge-backtest-diagnose) | Automatically diagnose performance issues in a strategy |
| [`alpha-forge backtest list`](#alpha-forge-backtest-list) | Show saved backtest results |
| [`alpha-forge backtest report`](#alpha-forge-backtest-report) | Display a saved backtest result |
| [`alpha-forge backtest migrate`](#alpha-forge-backtest-migrate) | Import existing JSON report files into the database |
| [`alpha-forge backtest compare`](#alpha-forge-backtest-compare) | Compare multiple strategies side by side on the same symbol and period |
| [`alpha-forge backtest combine`](#alpha-forge-backtest-combine) | Run a combined portfolio backtest across multiple strategies |
| [`alpha-forge backtest portfolio`](#alpha-forge-backtest-portfolio) | Run a portfolio backtest across multiple symbols |
| [`alpha-forge backtest chart`](#alpha-forge-backtest-chart) | Display dashboard URL to navigate to charts |
| [`alpha-forge backtest signal-count`](#alpha-forge-backtest-signal-count) | Fast signal count check without running the full backtest |
| [`alpha-forge backtest monte-carlo`](#alpha-forge-backtest-monte-carlo) | Run a Monte Carlo simulation from an existing backtest result |
| [`alpha-forge backtest prune-orphans`](#alpha-forge-backtest-prune-orphans) | Delete orphaned backtest / optimization results whose strategy definition no longer exists (destructive) |

---

## alpha-forge backtest run

Run a backtest. Specify either `--strategy` or `--strategy-file`.

### Synopsis

```bash
alpha-forge backtest run <SYMBOL> (--strategy <ID> | --strategy-file <PATH>) [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `SYMBOL` | argument (required) | - | Symbol (e.g. SPY, AAPL, CL=F) |
| `--strategy` | option | - | Strategy ID (mutually exclusive with `--strategy-file`) |
| `--strategy-file` | option | - | Path to a strategy JSON file (no DB registration required) |
| `--json` | flag | false | Output results as JSON to stdout |
| `--summary` | flag | false | (With `--json`) Exclude heavy arrays (`trades` / `monthly_returns` / `annual_returns` / `equity_curve`) and emit a lightweight JSON of scalar metrics + verdict only (issue #1224, to save tokens for agents / MCP; [details](#json-summary)) |
| `--start` | option | - | Start date `YYYY-MM-DD` |
| `--end` | option | - | End date `YYYY-MM-DD` |
| `--split` | flag | false | Split into in-sample / out-of-sample periods ([details](#is-oos-split)) |
| `--benchmark` | option | config | Benchmark symbol (per-`asset_type` defaults apply, see below) |
| `--no-benchmark` | flag | false | Disable benchmark comparison entirely (F-304). Useful for FX / commodities where a SPY comparison is meaningless |
| `--check-criteria` | flag | false | Run acceptance criteria check |
| `--cagr-min` | float | `20.0` | Minimum CAGR (%), used with `--check-criteria` |
| `--sharpe-min` | float | None (falls back to goal or `1.0`) | Minimum Sharpe ratio |
| `--max-dd` | float | None (falls back to goal or `25.0`) | Max drawdown limit (%); also used for `pre_filter_pass` |
| `--win-rate-min` | float | `55.0` | Minimum win rate (%) |
| `--pf-min` | float | `1.3` | Minimum profit factor |
| `--min-trades` | int | - | Minimum trade count; exits with code 1 if below |
| `--regime` | flag | false | Display per-regime statistics on the console |
| `--trades-csv` | path | - | Write a per-trade CSV to the given path (issue #800, [details](#trades-csv-export)) |
| `--debug` | flag | false | Raise the `alpha_forge.*` loggers to DEBUG (issue #800) |
| `--goal` | option | - | Goal name (e.g. `default`, `stocks`); auto-loads `pre_filter` thresholds from `goals.yaml` into `--sharpe-min` / `--max-dd` |
| `--cost-preset` | option | - | Cost preset name (issue #785, e.g. `moomoo-crypto-spot` / `binance-spot-vip0` / `ibkr-us-stock-fixed`); overrides the strategy's `risk_management` commission/slippage in-memory at run time (strategy JSON is untouched) |
| `--dividend-reinvest` | flag | false | Include dividend-reinvest metrics in the result (#958); requires saved dividends data (`data fetch --with-dividends`) |
| `--regime-filter` | option | - | Post-hoc entry gating by macro regime (issue #1012); format `<source>:<label>` (e.g. `macro:risk_on`), source=`macro` only; requires FRED data fetched in advance (`data alt fetch FRED:T10Y3M`) |
| `--carry` | flag | false | Accrue FX carry (swap) and include `carry_adjusted_metrics` ([details](#carry)). Resolution order: real swap CSV (`data alt import-swap`) > rate-differential approximation. Major 8 currencies resolve via the builtin rate-series mapping without configuration (pre-fetched FRED rate data is still required) |

### Approximate FX carry (swap) with `--carry` {#carry}

To evaluate FX swap/carry strategies, the daily carry is approximated from the **short-term rate differential** (instead of broker swap points) and reported as `carry_adjusted_metrics` (total_return_pct / cagr_pct / max_drawdown_pct / sharpe_ratio / volatility_pct) alongside the price-only metrics.

```
daily carry fraction = (base short rate − quote short rate − spread_pct) / 100 / 365 × elapsed calendar days
```

**Major pairs work without configuration**: when `backtest.carry` has no entry for the pair, the builtin currency → series mapping below resolves it automatically (reported at runtime as an optimistic `spread_pct=0` value; a user-defined mapping always takes precedence).

| Currency | FRED series | Description |
|----------|-------------|-------------|
| USD | `DFF` | Effective federal funds rate (daily) |
| JPY | `IRSTCI01JPM156N` | Uncollateralized O/N call rate (OECD, monthly) |
| EUR | `ECBDFR` | ECB deposit facility rate (daily) |
| GBP | `IUDSOIA` | SONIA (daily) |
| AUD | `IRSTCI01AUM156N` | RBA cash-rate equivalent (OECD, monthly) |
| CAD | `IRSTCI01CAM156N` | BoC O/N equivalent (OECD, monthly) |
| CHF | `IR3TIB01CHM156N` | 3-month interbank rate (OECD, monthly) |
| NZD | `IR3TIB01NZM156N` | 3-month interbank rate (OECD, monthly) |

For CHF/NZD the O/N series stopped updating in 2024, so the still-updated 3-month rates are used (a small additional approximation error from the tenor difference). If a series' last observation is roughly 6+ months older than the end of the backtest period, a staleness warning is printed.

**Importing real swap points (higher fidelity)**

If you have a broker-published history of real swap points, import it with [`data alt import-swap`](data.md#alpha-forge-data-alt-import-swap) and it is **automatically preferred** over the rate-differential approximation (no mapping needed; values are net of broker margin so `spread_pct` does not apply).

```bash
alpha-forge data alt import-swap USDJPY=X --csv swap_usdjpy.csv
```

**Setup (2 steps — to customize the rate-differential approximation)**

1. Define the pair → rate-series mapping under `backtest.carry` in `forge.yaml`:

    ```yaml
    backtest:
      carry:
        "USDJPY=X":
          base_rate_series: "DFF"               # short rate of the base currency (USD; effective fed funds, % p.a.)
          quote_rate_series: "IRSTCI01JPM156N"  # short rate of the quote currency (JPY; uncollateralized O/N call, % p.a.)
          spread_pct: 0.5                       # broker margin (% p.a.; deducted regardless of direction)
    ```

2. Fetch the rate data from FRED (stored as look-ahead-free vintage panels):

    ```bash
    alpha-forge data alt fetch FRED:DFF --start 2015-01-01 --end 2026-01-01
    alpha-forge data alt fetch FRED:IRSTCI01JPM156N --start 2015-01-01 --end 2026-01-01
    ```

```bash
alpha-forge backtest run USDJPY=X --strategy usdjpy_carry_v1 --carry
```

**Behavior notes**

- Weekend days accrue on the Monday bar as 3 days' worth (calendar-day gap from the previous bar; the "triple Wednesday" T+2 convention is not modeled)
- Holding short flips the sign of the rate differential; `spread_pct` is deducted regardless of direction
- Flat bars accrue nothing; this is an adjunct — the main equity curve (SL/TP evaluation etc.) is unaffected
- A missing mapping or unfetched rate data prints a warning and the backtest continues without carry (the run does not fail)
- The approximation assumes daily or higher timeframes (a warning is printed on sub-daily timeframes, where accrual clusters on day-crossing bars)
- With `--split`, `carry_adjusted_metrics` is an IS-period value
- Real broker swap points deviate from the theoretical differential by the broker margin (roughly 0.2–1.0% p.a.) — tune `spread_pct` accordingly

### Export per-trade CSV with `--trades-csv` {#trades-csv-export}

`backtest run --trades-csv <path>` writes a one-row-per-trade CSV. Use it to cross-check against another engine (e.g. TradingView Strategy Tester) or to investigate divergences like the `profit_factor` artifact in issue #791.

```bash
alpha-forge backtest run AAPL --strategy sma_crossover_v1 --trades-csv trades.csv
```

| Column | Meaning |
|--------|---------|
| `trade_idx` | 0-origin trade index |
| `entry_bar_idx` / `exit_bar_idx` | Entry / exit bar index |
| `entry_time` / `exit_time` | Date (`YYYY-MM-DD` for `1d` timeframes) |
| `entry_price` / `exit_price` | Fill price |
| `direction` | `long` / `short` |
| `pnl_pct` / `pnl_abs` | Return (%) / absolute PnL |
| `bars_held` | Holding period in bars |
| `sl_price` / `tp_price` | SL / TP price at entry (empty when unset) |
| `mae_pct` / `mfe_pct` | Maximum adverse / favorable excursion (%) |
| `entry_reason` | One-line summary of strategy entry conditions (shared across trades in Phase 1) |
| `exit_reason` | `strategy_exit` placeholder (Phase 2 will distinguish SL/TP/trailing) |

Even with zero trades, the header row is still written so that `sort` / `uniq` / `diff` pipelines do not break on empty stdout. `--debug` raises the `alpha_forge.*` loggers to DEBUG level, but a backtest that completes normally emits almost no additional DEBUG output (most detailed logs are for diagnosing exceptions). Detailed logs appear on stderr in error paths such as data-fetch failures or signal-evaluation errors.

### Benchmark selection logic (F-304) {#benchmark-selection}

Resolution order when `--benchmark` is omitted:

1. Explicit `--benchmark <SYM>` (highest priority)
2. `forge.yaml` `report.benchmark_symbol`, if set to anything other than the default `SPY`
3. Per-`asset_type` map on the strategy JSON (used when (2) is still default `SPY`)

| `asset_type` | Default benchmark |
|--------------|------------------|
| `stock` / `etf` | `SPY` |
| `fx` | `DX-Y.NYB` (Dollar Index) |
| `crypto` | `BTC-USD` |
| `commodity` / `future` | `DBC` (commodity ETF) |
| Other / unset | `SPY` (fallback) |

To disable benchmark comparison entirely, pass `--no-benchmark`. This is the right choice when alpha / beta / correlation against SPY is meaningless (e.g. FX or commodities strategies).

### IS / OOS Split (`--split`)  {#is-oos-split}

When `--split` is specified, the full data range is divided into an In-Sample (IS / training) period and an Out-of-Sample (OOS / validation) period. The IS performance is then independently validated on the OOS period, making it the recommended approach for evaluating strategy generalization.

![IS / OOS Split Flow](../assets/illustrations/backtest/backtest-is-oos-split.png)

### Progress bar (Rich UI)

While running in a TTY, a Rich-powered progress bar is shown on stderr. The backtest progresses through 6 phases below; with `--split`, both IS and OOS flows run, totaling 12 steps.

| Phase | Description |
|---|---|
| `指標計算` (Indicators) | Pre-compute technical indicators |
| `変数評価` (Variables) | Evaluate intermediate boolean variables |
| `シグナル生成` (Signals) | Evaluate entry/exit conditions and apply risk masks |
| `シミュレーション` (Simulate) | Run the vectorbt portfolio simulation |
| `メトリクス算出` (Metrics) | Compute Sharpe / MDD / win rate, etc. |
| `レジーム分析` (Regime) | Compute per-regime metrics (no-op when not configured) |

![Backtest 6-Phase Pipeline](../assets/illustrations/backtest/backtest-pipeline-6phases.png)

The progress bar is rendered on **stderr**, so combining it with `--json` keeps stdout as pure JSON (when `--json` is passed and stderr is a TTY, the dashboard is still drawn on stderr). When stderr is not a TTY (CI, pipes, redirected files), the progress bar is automatically suppressed. This way, `--json` invocations from agent loops like `/explore-strategies` show progress in interactive terminals without polluting CI logs.

### Sample output (text)

The leading icon is driven by whether the trade count is statistically sufficient (`is_valid` = `total_trades >= 30`): `✅` when sufficient, `⚠️` when not. The signal quality score line always carries a hint about how to read the score (`≥0.7` is reliable / `0.4–0.7` caution / `<0.4` low reliability).

```text
Running backtest: SPY x sma_crossover_v1
⚠️ Backtest complete  Signal quality score: 0.38/1.0 (<0.4: low reliability, treat as reference only)
    → Docs: https://alforgelabs.com/en/docs/cli-reference/backtest/#signal-quality-score
Total Return: +52.30%  CAGR: 5.40%
SR: 0.92  Sortino: 1.15  Calmar: 0.32
MDD: -16.80%  Duration: 187d  Recovery: 92d
PF: 1.74  Win%: 50.0%  avg_win: 4.20%  avg_loss: -2.40%
Kelly: 0.21  Payoff: 1.75  Expectancy: 0.90%/trade  GPR: 0.42  Ulcer: 0.0480  Recovery: 3.11
Trades: 14  Avg hold: 28.5d(28bar)  Max: 65.0d(65bar)  Win streak: 4  Loss streak: 3
Win rate CI(90%): 35.2% - 64.8%
```

The `Kelly:` line shows extended trade-quality metrics: the Kelly criterion (theoretically optimal position fraction), payoff ratio (average win ÷ |average loss|), expectancy (expected return per trade), Gain/Pain ratio, Ulcer Index, and recovery factor (total return ÷ |max drawdown|). With `--json` these are available as `kelly_criterion` / `payoff_ratio` / `expectancy_pct` / `expected_daily_return_pct` (and monthly / yearly) / `ulcer_index` / `serenity_index` / `gain_to_pain_ratio` / `recovery_factor`; values are `null` when the denominator is undefined (e.g. no losing trades, no drawdown).

!!! note "Monetary metrics assume USD (issue #1191)"
    Turnover and cost-related monetary metrics are computed **assuming a USD base**. No FX conversion is applied for non-USD accounts or symbols, so interpret the reported monetary amounts as USD. Ratio metrics such as return percentage, Sharpe, and win rate are currency-independent.

When the score or trade count fails the recommended thresholds, a warning and a one-line docs link are added (F-302):

```text
⚠️  Backtest complete  Signal quality score: 0.43/1.0 (0.4–0.7: caution, more validation suggested)
    → Docs: https://alforgelabs.com/en/docs/cli-reference/backtest/#signal-quality-score
⚠️  Warning: trade count is insufficient (trades=27, minimum 30 recommended)
    → Fewer than 30 trades is statistically noisy and may be filtered out by
      optimization / WFT pre_filter. Consider widening the data period (`--start`
      to go further back).
    → Docs: https://alforgelabs.com/en/docs/cli-reference/backtest/#signal-quality-score
```

### Signal Quality Score and Minimum Trades (F-302) {#signal-quality-score}

#### Signal Quality Score (`signal_quality_score`, 0.0–1.0)

```python
sharpe_score        = min(max(sharpe_ratio / 2.0, 0.0), 1.0)             # 30%
profit_factor_score = min(max((profit_factor - 1.0) / 1.5, 0.0), 1.0)    # 20% (0 when profit_factor is None)
win_rate_score      = max(0.0, (win_rate_pct - 50.0) / 30.0)             # 20% (only the portion above 50% win rate contributes)
sample_size_score   = min(total_trades / 30, 1.0)                        # 30%
signal_quality_score = (
    0.30 * sharpe_score
    + 0.20 * profit_factor_score
    + 0.20 * win_rate_score
    + 0.30 * sample_size_score
)
```

| Score range | Interpretation | CLI hint |
|-------------|----------------|----------|
| `≥ 0.70` | Reliable | "≥0.7 is reliable" |
| `0.40 – 0.69` | Caution. Further validation (WFT / cross-symbol) recommended | "0.4–0.7: caution, more validation suggested" |
| `< 0.40` | Low reliability, treat as reference only | "<0.4: low reliability, treat as reference only" |

!!! warning "Detecting all-winning-trades backtest artifacts (issue #791)"
    When `profit_factor` is returned as `null` and `StrategyDiagnostics` emits an `ALL_WINNING_TRADES` warning, you are looking at an **all-winning-trades backtest artifact**. Likely causes include a too-loose trailing stop, exit conditions that almost never fire right after entry, or entry evaluation that has degenerated into a state-based predicate firing every bar. Cross-validate with another engine such as the TradingView Strategy Tester. `null` is treated as "unmeasurable" by `signal_quality_score`, `anomaly_score`, `check_criteria.pf`, and `target_metrics.profit_factor`, all of which fall back to the safe side (score = 0, criterion fails).

#### Why a minimum of 30 trades

- Rough threshold for statistical significance: **n ≥ 30** (where the Central Limit Theorem starts to apply)
- Below that, the `total_trades < 30` flag is raised and the `sample_size_score` term is linearly penalized
- If `total_trades < 10`, the result is also marked as "statistically meaningless" with `is_valid=false`

#### What happens if not met

- `alpha-forge optimize run --goal <name>` / `alpha-forge optimize walk-forward --goal <name>` will fail the `pre_filter.min_trades` check (default 30), set `pre_filter_pass=false`, and exclude the strategy from the `/explore-strategies` shortlist
- A single backtest run is not aborted, but the result is low-confidence — extend the data window (`--start` further into the past) or rework the indicator mix toward higher signal frequency

### Sample output (`--json`)

```json
{
  "total_return_pct": 52.30,
  "cagr_pct": 5.40,
  "sharpe_ratio": 0.92,
  "max_drawdown_pct": -16.80,
  "win_rate_pct": 50.0,
  "profit_factor": 1.74,
  "total_trades": 14,
  "pre_filter_pass": false,
  "pre_filter": { "sharpe_min": 1.0, "max_dd_max": 25.0 },
  "next_step": [
    "Next: alpha-forge optimize run SPY --strategy sma_crossover_v1 --save",
    "  or: alpha-forge pine generate --strategy sma_crossover_v1"
  ],
  "warnings": []
}
```

`next_step` (issue #1234) returns the recommended next commands as a string array on a successful backtest, so an agent can follow the scaffold → save → backtest → optimize / pine order without inferring it. The text output prints an equivalent guidance line at the end.

### Lightweight JSON with `--summary` (issue #1224) {#json-summary}

`backtest run --json --summary` **excludes heavy arrays** (`trades` / `monthly_returns` / `annual_returns` / `equity_curve`) and returns a lightweight JSON of scalar metrics + verdict (`pre_filter_pass` / `pre_filter`) + `next_step` only. Use it to cut token usage over agents / MCP. Only the array fields are dropped; the meta-field contract above is unchanged.

```bash
alpha-forge backtest run SPY --strategy sma_crossover_v1 --json --summary
```

See also the top-level field contract in the [`--json` output reference](../ai-agents/json-output-reference.md#backtest-run-json).

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Specify either --strategy or --strategy-file` | Neither given | Provide one of them |
| `--strategy and --strategy-file are mutually exclusive` | Both given | Use only one |
| `Error: Invalid start date format (YYYY-MM-DD)` | Date format invalid | Use `2024-01-15` style |
| `⚠️  {interval} data not found. Falling back to 1d data.` | Strategy `timeframe` data missing | Run `alpha-forge data fetch` for the interval |

---

## alpha-forge backtest batch

Run parallel backtests for many strategy JSON files. Strategies passing the filter (Sharpe / MaxDD) are marked as "passed".

### Synopsis

```bash
alpha-forge backtest batch <SYMBOL> (--strategy-file <FILE> ... | --strategy-dir <DIR>) [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `SYMBOL` | argument (required) | - | Symbol |
| `--strategy-file` | repeatable | - | Path to a strategy JSON file |
| `--strategy-dir` | option | - | Directory containing strategy JSON files |
| `--pattern` | option | `*.json` | Glob pattern for `--strategy-dir` |
| `--workers` | int | `3` | Number of parallel workers |
| `--sharpe-min` | float | `1.0` | Sharpe lower bound for `pre_filter_pass` |
| `--max-dd` | float | `25.0` | MaxDD upper bound for `pre_filter_pass` |
| `--json` | flag | false | Output results as a JSON array to stdout |

### Sample output

```text
Starting batch backtest: SPY × 5 strategies (workers=3)
  ✅ spy_sma_v1: Sharpe=1.32  MaxDD=-12.4%  CAGR=8.2%  trades=18
  ❌ spy_rsi_v1: Sharpe=0.61  MaxDD=-22.1%  CAGR=4.1%  trades=24
  ✅ spy_macd_v1: Sharpe=1.18  MaxDD=-15.6%  CAGR=7.0%  trades=15
  🔴 spy_broken_v1: ERROR - failed to load strategy JSON

Passed strategies: 2/4
  ✅ spy_sma_v1: Sharpe=1.32  MaxDD=-12.4%
  ✅ spy_macd_v1: Sharpe=1.18  MaxDD=-15.6%
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Specify either --strategy-file or --strategy-dir` | Neither given | Provide one of them |
| `🔴 <id>: ERROR - <reason>` | Per-strategy load/run failure | Address the message |

---

## alpha-forge backtest timeframes

Backtest the same strategy across multiple timeframes and print a comparison table (timeframe sweep). The strategy's `timeframe` field is overridden per run, using the stored per-interval data (`<SYMBOL>_<interval>.parquet`).

### Syntax

```bash
alpha-forge backtest timeframes <SYMBOL> (--strategy <name> | --strategy-file <path>) [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `SYMBOL` | Argument (required) | - | Ticker symbol |
| `--strategy` | One of the two required | - | Saved strategy name |
| `--strategy-file` | One of the two required | - | Path to a strategy JSON file |
| `--timeframes` | Option | `1h,4h,1d` | Comma-separated list of timeframes (duplicates are de-duplicated) |
| `--start` / `--end` | Option | - | Backtest period (YYYY-MM-DD) |
| `--json` | Flag | false | Emit results as JSON |

### Example output

```text
=== Timeframe Comparison: AAPL × sma_crossover_v1 ===
TF       Sharpe   Return%     MDD%      PF    Win%  Trades    Bars
──────────────────────────────────────────────────────────────────
1h     (no data)
4h         1.12    +38.40    12.10    1.62    54.2      48    4380
1d   ★     1.45    +52.30    16.80    1.74    50.0      14     730

Best: 1d (Sharpe=1.45)
No data: 1h (run `data fetch --interval <tf>` to populate)
```

When data for an interval is missing, the command does **not** fall back to 1d data; the row and the trailing summary both report it explicitly. `--json` returns a `{"symbol", "strategy_id", "timeframes": [...], "count", "best_timeframe", "missing_timeframes"}` envelope (each entry has `timeframe` / `status` / `bars` / `metrics`).

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| Specify either `--strategy` or `--strategy-file` | Neither or both given | Provide exactly one |
| All timeframes report `no_data` | Per-interval data not fetched | Run `alpha-forge data fetch <SYMBOL> --interval <tf>` (exit code 1) |
| Invalid date format | `--start`/`--end` not YYYY-MM-DD | Fix the format (exit code 2) |

---

## alpha-forge backtest diagnose

Automatically diagnose performance issues in a strategy (overfitting, low trade count, extreme win/loss balance, etc.).

### Synopsis

```bash
alpha-forge backtest diagnose <SYMBOL> --strategy <ID> [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `SYMBOL` | argument (required) | - | Symbol |
| `--strategy` | required | - | Strategy ID |
| `--start` | option | - | Start date `YYYY-MM-DD` |
| `--end` | option | - | End date `YYYY-MM-DD` |
| `--split` | flag | true | Split into in-sample / out-of-sample (default ON) |
| `--json` | flag | false | Output as JSON |

### Output

The diagnostic result lists the inferred problems and recommended actions. See `alpha-forge backtest diagnose --help` and the internal `StrategyDiagnostics` logic for details.

---

## alpha-forge backtest list

Show saved backtest results from the DB.

### Synopsis

```bash
alpha-forge backtest list [OPTIONS]
```

### Options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--strategy` | option | - | Filter by strategy ID |
| `--symbol` | option | - | Filter by symbol |
| `--sort` | option | `run_at` | Sort key (`sharpe_ratio` / `total_return_pct` / `cagr_pct` / `max_drawdown_pct` / `win_rate_pct` / `profit_factor` / `run_at`) |
| `--limit` | int | `20` | Number of rows to display |
| `--best` | flag | false | Show only the best record per group |
| `--by` | choice | `strategy` | Group key for `--best` (`strategy` / `symbol`) |

### Sample output

```text
Backtest Results (5 records)
run_id                               strategy_id                   symbol         Return  Sharpe      MDD  Trades
──────────────────────────────────────────────────────────────────────────────────────────────────────────────
spy_sma_v1_20260415_103021           spy_sma_v1                    SPY            +52.3%    0.92   -16.8%      14
spy_macd_v1_20260414_181522          spy_macd_v1                   SPY            +38.1%    1.18   -15.6%      12
...
```

### Common messages

| Message | Cause |
|---------|-------|
| `No saved backtest results found.` | DB empty |

---

## alpha-forge backtest report

Display a saved backtest result in detail.

### Synopsis

```bash
alpha-forge backtest report <RESULT_ID> [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `RESULT_ID` | argument (required) | - | DB mode: `strategy_id` or `run_id`. File mode: `result_id` |
| `--json` | flag | false | Output the full JSON |
| `--symbol` | option | - | DB mode: filter by symbol |

If `RESULT_ID` does not match a `run_id`, the latest run for that `strategy_id` is used.

### Sample output

```text
=== spy_sma_v1 / SPY (2026-04-15T10:30:21) ===
Total Return: 52.30%  CAGR: 5.40%
SR: 0.92  Sortino: 1.15  Calmar: 0.32
MDD: -16.80%  PF: 1.74  Win%: 50.0%
Trades: 14  Avg hold: 28.5d(28bar)  Max: 65.0d(65bar)
Trade log: 14 records (use --json to view all)
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: Result not found - <id>` | Neither `run_id` nor `strategy_id` matches | Verify with `alpha-forge backtest list` |

---

## alpha-forge backtest migrate

Import existing `*_report.json` files into the DB.

### Synopsis

```bash
alpha-forge backtest migrate [--dry-run] [--force]
```

### Options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--dry-run` | flag | false | Preview without writing to the DB |
| `--force` | flag | false | Overwrite on `run_id` conflict |

`run_id` values are generated as `migrated_<file_stem>`.

### Sample output

```text
  ✅ migrated_spy_sma_v1
  ♻️  migrated_spy_macd_v1 (overwritten)
  Skipping (duplicate): migrated_spy_rsi_v1

Done: 2 imported, 1 skipped
```

### Common messages

| Message | Cause |
|---------|-------|
| `Report directory does not exist.` | `config.report.output_path` not created |
| `No JSON files found to import.` | No `*_report.json` files |

---

## alpha-forge backtest compare

Compare multiple strategies on the same symbol and period.

!!! warning "The two meanings of `compare`: this one runs new backtests (heavy)"
    `backtest compare` **runs fresh backtests** of the given strategies on the spot and compares them (a **heavy operation** with side effects). In contrast, [`journal compare`](journal.md#alpha-forge-journal-compare) / [`live compare`](live.md#alpha-forge-live-compare) are read-only and merely reference **saved** runs / summaries. Despite the shared verb, the cost and side effects differ — be careful not to let an agent generalize "compare is a safe reference" and unintentionally launch long-running backtests.

### Synopsis

```bash
alpha-forge backtest compare <STRATEGY1> [STRATEGY2 ...] --symbol <SYM> [--symbol <SYM> ...] [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGIES` | arguments (required, repeatable) | - | Strategies to compare (space-separated) |
| `--symbol` / `-s` | repeatable (required) | - | Symbols to compare |
| `--start` | option | - | Start date `YYYY-MM-DD` |
| `--end` | option | - | End date `YYYY-MM-DD` |
| `--benchmark` | option | config | Benchmark symbol |
| `--json` | flag | false | Output as JSON |

### Sample output (text table)

The output uses a **one-row-per-metric** transposed layout. The first strategy you pass is the "baseline" (`基準:`); for each subsequent strategy the difference from the baseline is shown in the `Delta` column (`✅` = improvement / `❌` = regression). The final line shows the `Winner` (most improvements; ties broken by Sharpe Ratio). The header column labels are emitted in Japanese (`指標` = metric, `基準:` = baseline) regardless of locale.

The period (e.g. `(2020-01-01 to present)`) is only added to the header when `--start` / `--end` are supplied; otherwise only the strategy count is shown.

```text
=== Strategy Comparison: SPY (2 strategies) ===

────────────────────────────────────────────────────────────
指標                     基準: sma_crossover_v1    sma_cross_qs           Delta
────────────────────────────────────────────────────────────
Sharpe Ratio                       0.92            1.18          +0.26 ✅
Total Return %                    52.30%          38.10%         -14.2% ❌
CAGR %                             5.40%           4.20%          -1.2% ❌
Max Drawdown %                   -16.80%         -15.60%          +1.2% ✅
Win Rate %                        50.00%          58.00%          +8.0% ✅
Profit Factor                      1.74            1.92          +0.18 ✅
────────────────────────────────────────────────────────────
Winner: sma_cross_qs (4/6 metrics)
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: Data for <SYM> not found.` | Data missing | `alpha-forge data fetch <SYM>` |
| `Warning: Failed to load strategy '<id>'` | Invalid strategy ID / JSON | `alpha-forge strategy list`, `alpha-forge strategy validate` |

---

## alpha-forge backtest combine

Run a combined portfolio backtest across two or more strategies. Phase 1 supports equal allocation; Phase 2 supports custom weights.

### Synopsis

```bash
alpha-forge backtest combine <STRATEGY_ID1> <STRATEGY_ID2> [...] [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_IDS` | arguments (required, 2 or more) | - | Strategy IDs to combine (e.g. `iwm_sma200_bho_v1 qqq_ema_macd_v2`) |
| `--allocation` | choice | `equal` | Allocation method (`equal` / `custom` / `risk_parity` / `vol_target`) |
| `--weights` | option | - | Weights when `--allocation custom`, e.g. `sid1=0.4,sid2=0.6`. Sum must be within 1.0 ± 0.01. Required with `--allocation custom` |
| `--wft` | int | - | Number of windows for a walk-forward test (>= 2). Returns a `wft` section when set |
| `--rebalance` | choice | `monthly` | Rebalance frequency for dynamic allocation (`risk_parity` / `vol_target`): `monthly` / `weekly` / `quarterly` (#1287) |
| `--vol-lookback` | int | `63` | Lookback bars (trading days) used for the realized-vol calculation in dynamic allocation (#1287) |
| `--target-vol` | float | - | Target annualized volatility for `--allocation vol_target` (e.g. `0.15` = 15%). Required for `vol_target` (#1287) |
| `--max-leverage` | float | `1.0` | Exposure cap for `vol_target` scaling (default `1.0` = no leverage) (#1287) |
| `--max-pillar-weight` | float | - | Per-pillar weight cap for dynamic allocation (`risk_parity` / `vol_target`), e.g. `0.3`. Omitting it leaves weights uncapped. Exits with an error when combined with `equal` / `custom` |
| `--wft-warmup-bars` | int | `0` | Warmup bars per WFT window. Feeds data starting N bars before the window for indicator computation, while evaluation (metrics) covers only the window itself (#1287) |
| `--dividend-reinvest` | flag | false | Include dividend-reinvest metrics. Loads saved dividend data for each strategy's symbol and reflects it in the combined result |
| `--json` | flag | false | Output results as JSON to stdout |

`--allocation risk_parity` / `vol_target` replace fixed weights with a periodically rebalanced allocation driven by realized volatility (#1287). `risk_parity` allocates weight inversely proportional to each strategy's realized volatility over the trailing `--vol-lookback` window (inverse-vol). `vol_target` builds on `risk_parity` weights and additionally scales the combined portfolio's total exposure so its realized volatility tracks `--target-vol`; unused exposure is treated as cash (zero return), capped by `--max-leverage`. To prevent **look-ahead**, weights (and the `vol_target` scale) are computed from returns up to and including rebalance date t and applied starting the next trading day after t. Periods with insufficient lookback data fall back to equal weight (scale `1.0` for `vol_target`). The `combined` block in JSON output includes only the final applied weights; the daily weight history (`weights_history`) is not included.

Dynamic allocation can concentrate weight in a single strategy. Passing `--max-pillar-weight <cap>` (e.g. `0.3`) clips each strategy's weight to the cap and redistributes the excess proportionally to the strategies still under the cap, iterating until none remain over (water-filling; the total stays at 1.0). If `n_strategies * cap < 1.0` the cap is infeasible and the command exits with an error. Passing this option with `--allocation equal` / `custom` also exits with an error (fail-loud). Omitting it (default `None`) preserves the uncapped behavior.

When combining `--wft` with dynamic allocation, short windows may not accumulate enough bars for `--vol-lookback` within the window, causing the allocation to fall back to equal weight for most of the window. Use `--wft-warmup-bars` to feed each window's **data** starting N bars before the window boundary while still **evaluating only the window itself**.

Strategies that reference external symbols (e.g. VIX) via the `symbol` field are now correctly included in `backtest combine` as well. Previously, the external-symbol merge step was not invoked on this path, silently disabling those indicators; `backtest combine` now runs the same merge step as `backtest run` (#1287).

```bash
# risk_parity allocation + monthly rebalance + 5-window WFT with warmup prepend
alpha-forge backtest combine schd_v1 vym_v1 tlt_v1 \
    --allocation risk_parity --rebalance monthly --vol-lookback 63 \
    --wft 5 --wft-warmup-bars 63 --json

# vol_target allocation (target 15% annualized vol, 1.5x leverage cap)
alpha-forge backtest combine schd_v1 vym_v1 tlt_v1 \
    --allocation vol_target --target-vol 0.15 --max-leverage 1.5 --json

# risk_parity allocation with a 30% per-pillar weight cap
alpha-forge backtest combine schd_v1 vym_v1 tlt_v1 \
    --allocation risk_parity --max-pillar-weight 0.3 --json
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: --allocation custom requires --weights` | `--allocation custom` given without `--weights` | Provide `--weights` |
| `Error: invalid --weights token (expected sid=val): <token>` | Malformed `--weights` entry | Use `sid1=0.4,sid2=0.6` style |
| `Error: --allocation vol_target requires --target-vol` | `--allocation vol_target` given without `--target-vol` | Provide `--target-vol` |
| `Error: max_pillar_weight is only valid with allocation='risk_parity'/'vol_target'` | `--max-pillar-weight` combined with `--allocation equal` / `custom` | Use `--allocation risk_parity` / `vol_target`, or drop `--max-pillar-weight` |
| `Error: per-pillar cap is infeasible: n=..., cap=... (n*cap < 1.0, cannot preserve total 1.0)` | `n_strategies * --max-pillar-weight` is below 1.0 | Raise the cap or add more strategies |

---

## alpha-forge backtest portfolio

Run a portfolio backtest across multiple symbols.

### Synopsis

```bash
alpha-forge backtest portfolio <SYM1> [SYM2 ...] --strategy <ID> [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `SYMBOLS` | arguments (required, repeatable) | - | Space-separated list of symbols |
| `--strategy` | required | - | Strategy ID |
| `--allocation` | choice | `equal` | Allocation method (`equal` / `risk_parity` / `custom`) |
| `--weights` | option | - | Custom weights `AAPL=0.4,MSFT=0.6` (used with `--allocation custom`) |
| `--json` | flag | false | Output as JSON |
| `--save` | flag | false | Save results to a file |

### Sample output

```text
Running portfolio backtest: ['AAPL', 'MSFT', 'GOOGL'] (equal allocation)

=== Portfolio Results: tech_basket_v1 (equal) ===
Symbols: AAPL, MSFT, GOOGL
Weights: AAPL=33.3%, MSFT=33.3%, GOOGL=33.3%
Total Return: 78.40%  CAGR: 12.30%
SR: 1.45  Sortino: 1.85  Calmar: 0.62
MDD: -19.80%  CVaR(95%): -3.20%
Diversification ratio: 1.085

Symbol     Weight    Return     SR      MDD
──────────────────────────────────────────────────
AAPL          33.3%   +85.2%   1.52  -22.1%
MSFT          33.3%   +72.0%   1.41  -18.4%
GOOGL         33.3%   +78.0%   1.38  -19.5%
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: Invalid --weights format.` | Format violation | Use `AAPL=0.4,MSFT=0.6` style |
| `Error: Data for <SYM> not found.` | Data missing | `alpha-forge data fetch` |
| `Error: Backtest failed - <reason>` | Engine exception | Address the message |

---

## alpha-forge backtest chart

Show the dashboard chart URL and optionally open it.

### Synopsis

```bash
alpha-forge backtest chart [RESULT_ID] [--open] [--compare <ID> ...]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `RESULT_ID` | argument (optional) | - | `run_id` or `strategy_id` |
| `--open` | flag | false | Open the URL in a browser |
| `--compare` | repeatable | - | Strategy to compare. Use `strategy_id:run_id` to target a specific run |

### Sample output

```text
📊 To view charts, start `alpha-vis serve`:
   http://localhost:8000/?run_id=spy_sma_v1
```

`?run_id=` contains the `RESULT_ID` you passed verbatim (pass a `strategy_id` and you get that `strategy_id`; pass a specific `run_id` and you get that `run_id`).

When comparing strategies:

```text
📊 To view charts, start `alpha-vis serve`:
   http://localhost:8000/?ids=sma_crossover,rsi_reversion
```

The command itself only prints a URL. To view charts, start `alpha-vis serve` ([alpha-visualizer](https://github.com/ysakae/alpha-visualizer)).

---

## alpha-forge backtest signal-count

Skip vectorbt and just count entry-condition signal occurrences. Useful for sanity-checking condition expressions.

### Synopsis

```bash
alpha-forge backtest signal-count <SYMBOL> --strategy <ID> [--period 5y] [--estimate-trades] [--json]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `SYMBOL` | argument (required) | - | Symbol |
| `--strategy` | required | - | Strategy ID |
| `--period` | option | `5y` | Data period (e.g. `5y`, `1y`, `6m`, `30d`) |
| `--estimate-trades` | flag | false | Estimate expected trades from signal blocks (for trend-following strategies) |
| `--json` | flag | false | Output as JSON |

### Sample output

```text
Signal count check: spy_sma_v1 × SPY (5y)
Total bars: 1258 days

Entry conditions (long AND):
  sma_fast > sma_slow              :   687 days ( 54.6%)
  ──────────────────────────────────
  All conditions AND               :   687 days ( 54.6%)

Signal days per regime:
  state=0    :   312 days ( 24.8%)
  state=1    :   375 days ( 29.8%)
```

If 0 signals, `⚠️  No signals generated` is printed.

!!! note "Strategies that reference external symbols"
    For strategies that reference external symbols (e.g. `^VIX`, `USDJPY=X`), `signal-count` now applies the same `merge_external_symbols()` step used by `alpha-forge backtest run` / `alpha-forge optimize run` before counting signals. The bug (#266) where `entry_signal_days` would always be `0` for external-symbol strategies has been fixed.

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Invalid period format: <value>` | Bad `--period` | Use `5y`, `6m`, `30d` style |
| `Error: No data for <SYM> (period: <p>).` | Data exists but no rows fall within the period | Widen `--period`, or re-fetch with `alpha-forge data fetch <SYM>` |
| `⚠️  1d data not found. Falling back to 1d data.` + `❌ データが見つかりません: <SYM> (1d)` + a data-fetch hint | The parquet file itself was never fetched | `alpha-forge data fetch <SYM>` |

---

## alpha-forge backtest monte-carlo

Resample trade history from a saved backtest result and run a Monte Carlo simulation to evaluate ruin probability and worst-case scenarios.

### Synopsis

```bash
alpha-forge backtest monte-carlo <RESULT_ID> [--simulations 1000] [--json]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `RESULT_ID` | argument (required) | - | `run_id` or `strategy_id` |
| `--simulations` | int | `1000` | Number of simulation runs |
| `--json` | flag | false | Output as JSON |

### Sample output

```text
Running Monte Carlo simulation: spy_sma_v1_20260415_103021 (1000 runs)
✅ Simulation complete
Initial capital: 10000
Mean final equity: 14820
Median final equity: 14250
Worst final equity: 7340
Best final equity: 23150
Mean max MDD: 18.40%
95% max MDD:  31.20%
Ruin probability: 0.40%
```

### Sample output (`--json`) {#monte-carlo-json}

With `--json`, in addition to the statistics, a default verdict (`pre_filter_pass` / `pre_filter`) is **always included even without `--goal`**, with naming and contract aligned with `backtest run` / `optimize walk-forward` (issue #1237). The verdict checks whether the ruin probability (`ruin_probability_pct`) is at or below the default threshold of `5.0%`.

```json
{
  "initial_capital": 10000,
  "simulations_run": 1000,
  "mean_final_equity": 14820,
  "worst_final_equity": 7340,
  "best_final_equity": 23150,
  "mean_max_drawdown_pct": 18.40,
  "max_drawdown_95pct": 31.20,
  "ruin_probability_pct": 0.40,
  "pre_filter_pass": true,
  "pre_filter": { "max_ruin_pct": 5.0 }
}
```

See also the top-level field contract in the [`--json` output reference](../ai-agents/json-output-reference.md#backtest-monte-carlo-json).

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: Result not found - <id>` | Not in DB | Check `alpha-forge backtest list` |
| `Error: No valid trade history found (minimum 10 trades required).` | Trade count < 10 | Use a longer period or a different strategy |
| `Error: Simulation failed - <reason>` | Exception during simulation | Address the message |

---

## alpha-forge backtest prune-orphans

Deletes backtest and optimization results whose strategy definition no longer exists (destructive: removes rows from the DB). Use it when results linger in `backtest_results.db` after deleting scaffolded or throwaway strategies.

!!! warning "Orphans are not necessarily junk"
    `strategy delete` **intentionally keeps results** unless you pass `--with-results`. Orphans are also created by "delete the definition but keep the run history". Always inspect with `--dry-run` before deleting. Deletion cannot be undone.

### Synopsis

```bash
alpha-forge backtest prune-orphans [OPTIONS]
```

### Options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--dry-run` | flag | false | Show targets and exit without deleting |
| `--strategy` | repeatable | - | `strategy_id` to delete. Repeatable. All orphans when omitted |
| `-y`, `--yes` | flag | false | Delete without a confirmation prompt |
| `--vacuum` | flag | false | Run `VACUUM` after deleting to shrink the file (needs an exclusive lock and temp space; off by default) |
| `--json` | flag | false | Output results as JSON to stdout |

Being a destructive operation, it exits with code `2` when `--yes` is missing in a non-interactive environment (`FORGE_NONINTERACTIVE` / `CI` / non-TTY). The same applies to `--json` without `--yes` (exit code `2`), so the confirmation prompt cannot pollute the JSON on stdout. Passing a non-orphan `strategy_id` to `--strategy` exits with code `1`.

`--vacuum` is off by default because `VACUUM` takes an exclusive lock on the whole database and temporarily needs free space comparable to the original file. It can fail while `alpha-vis serve` is running or on a nearly full disk. The deletion itself still completes — free up space and re-run with `--vacuum`.

```bash
# Inspect targets without deleting
alpha-forge backtest prune-orphans --dry-run

# Delete every orphan
alpha-forge backtest prune-orphans -y

# Delete only some of them
alpha-forge backtest prune-orphans -y --strategy old_a --strategy old_b

# Delete and shrink the file
alpha-forge backtest prune-orphans -y --vacuum
```

### Sample output

```text
[dry-run] Prune targets:

  old_scaffold_v1  backtest=3  optimize=1  0.8MB  2026-05-01T09:12:00..2026-05-03T14:02:11
  old_scaffold_v2  backtest=1  optimize=0  0.2MB  2026-05-02T10:00:00..2026-05-02T10:00:00

Total 2 IDs / 5 rows / 1.0 MB
```

```text
Deleted: 2 IDs / 4 backtest rows / 1 optimization rows
Reclaimed: 0.7 MB
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `No orphan runs found` | Zero orphans | No action needed (the DB is already clean) |
| `Error: not orphan or unknown strategy_id(s): <id>` | `--strategy` names a live or unknown ID | Check the orphan list with `--dry-run` first, then re-run |
| `--json requires an explicit --yes (to avoid blocking on a destructive-action confirmation).` | `--json` used without `-y`/`--yes` | Add `-y`/`--yes` |
| `Warning: rows were deleted but VACUUM failed (<reason>). Free up disk space and run with --vacuum again` | `VACUUM` failed to get its exclusive lock or ran out of space | Free up disk space and re-run with `--vacuum` (the deletion itself already completed) |

---

## Common behavior

- **DB / file mode**: `list`, `report`, `migrate`, `monte-carlo` use `config.report.output_path / config.report.db_filename` (SQLite) as the primary store.
- **`FORGE_CONFIG`**: The strategy / data / results locations are determined by the `forge.yaml` referenced by the `FORGE_CONFIG` environment variable.
- **Exit codes**: `0` on success, `1` when `--min-trades` is below threshold, `click.UsageError` for argument errors, fatal errors print to stderr and exit.
- **Trial plan limit**: On the Trial plan, the maximum input data date is capped at `2023-12-31`. See [Trial Limits](../guides/trial-limits.md) for details.

---

<!-- Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/backtest.py`. This page must be kept in sync when CLI arguments change. -->
