# alpha-forge live

Live trading event ingestion (VPS → local), raw event → trade record conversion, performance analysis, and backtest comparison. Integrates with `alpha-forge journal` to surface live results.

!!! info "About sample output"
    Sample outputs in this page are based on the formats read from the `alpha-forge` source. Actual values and formatting depend on the `format_*` functions in `live/formatter.py`.

## Typical operation flow

```text
1. alpha-forge live sync-events       Pull raw events from VPS
2. alpha-forge live convert-check     Verify conversion readiness
3. alpha-forge live import-events     Generate trades from fill / close events
4. alpha-forge live summary           Show live performance summary
5. alpha-forge live compare           Compare with the latest backtest run
```

## Subcommands

| Command | Description |
|---------|-------------|
| [`alpha-forge live list`](#alpha-forge-live-list) | List strategies that have live trading records |
| [`alpha-forge live events`](#alpha-forge-live-events) | List raw trading events |
| [`alpha-forge live convert-check`](#alpha-forge-live-convert-check) | Check readiness to convert raw events to trade records |
| [`alpha-forge live import-events`](#alpha-forge-live-import-events) | Generate and save trade records from fill / close events |
| [`alpha-forge live trades`](#alpha-forge-live-trades) | List individual trade records for a strategy |
| [`alpha-forge live summary`](#alpha-forge-live-summary) | Show live performance summary for a strategy |
| [`alpha-forge live compare`](#alpha-forge-live-compare) | Compare the latest backtest run with live summary |
| [`alpha-forge live doctor`](#alpha-forge-live-doctor) | Check the setup status of live trading analysis |
| [`alpha-forge live sync-events`](#alpha-forge-live-sync-events) | Sync event logs from VPS to local via rsync |
| [`alpha-forge live replay`](#alpha-forge-live-replay) | Reconstruct position-based live metrics from a combine portfolio's alert log |
| [`alpha-forge live refresh`](#alpha-forge-live-refresh) | Run sync-events → data update → replay in one shot (used by the visualizer's Live refresh button) |

---

## alpha-forge live list

Walk `<journal_path>/../live/` to find strategies that have live records (trade records or event logs).

### Synopsis

```bash
alpha-forge live list
```

### Arguments and options

None.

### Sample output

```text
spy_sma_v1
qqq_hmm_macd_ema_rsi_v1
gc_hmm_macd_ema_v1
```

Formatting is delegated to `format_live_list`.

---

## alpha-forge live events

List raw events emitted by brokers (e.g., `fill`, `close`). Without filters, the latest `--limit` records are shown.

### Synopsis

```bash
alpha-forge live events [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--strategy` | option | - | Filter by `strategy_id` (renamed from `--strategy-id` in epic #1083 D) |
| `--event-type` | option | - | Filter by `event_type` (e.g., `fill`, `close`) |
| `--broker` | option | - | Filter by `broker` |
| `--limit` | int | `20` | Number of records to display |
| `--json` | flag | false | Emit the result as JSON (`{events: [...], count}`) |

### Sample output

```text
=== live events ===
2026-04-15T09:31:00+00:00 | fill | spy_sma_v1 | SPY | buy | filled | sig_0042
2026-04-15T14:02:00+00:00 | trade_closed | spy_sma_v1 | SPY | sell | closed | sig_0042
```

Formatting is delegated to `format_live_events`. Each row is pipe (`|`) delimited in the order `timestamp` (ISO format) / `event_type` / `strategy_id` / `symbol` (`ticker`) / `side` (`action`) / `status` / `signal_id`. There are no `broker` / `qty` / `price` columns. You can still filter with `--broker`, but the `broker` value itself is not shown in the rows.

---

## alpha-forge live convert-check

Check whether raw events can be converted to trade records (whether `fill` and `close` pairs are matched, etc.). Recommended as a pre-step to `import-events`.

### Synopsis

```bash
alpha-forge live convert-check [--strategy <ID>]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--strategy` | option | - | Filter by `strategy_id` (renamed from `--strategy-id` in epic #1083 D) |

### Sample output

```text
=== event conversion report ===
strategy_id                     : spy_sma_v1
total_events                    : 96
total_signals                   : 20
total_orders                    : 18
total_fills                     : 16
total_trade_closed              : 16
accepted_orders                 : 18
failed_orders                   : 0
live_events                     : 80
paper_events                    : 16
signals_without_orders          : 2
accepted_missing_strategy_meta  : 0
accepted_missing_snapshot_id    : 0
accepted_missing_fill_data      : 2
accepted_missing_close_data     : 2
fill_events_missing_trade_id    : 0
trade_closed_missing_pnl        : 0
conversion_ready                : yes
```

Formatting is delegated to `format_event_conversion_report` (the `EventConversionReport` model). The header is `=== event conversion report ===` and each field is printed as `key : value`. `conversion_ready` is `yes` / `no`. When there are conversion blockers, a `blockers :` section and the list follow at the end. There are no `matched` / `pending` / `status` (ready/partial/missing) columns.

---

## alpha-forge live import-events

Generate trade records from `fill` / `close` events and save them to a SQLite DB (`backtest_results.db` under `config.report.output_path`). Trades and summaries were migrated from JSON files to SQLite in v0.12.0; no JSON is written to `<live_path>/trades/` or `<live_path>/summaries/`.

### Synopsis

```bash
alpha-forge live import-events <STRATEGY_ID>
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Target strategy ID |

### Prerequisites for raw event → trade records conversion

- Event logs for the `strategy_id` must exist under `<live_path>/events/` (fetched via `alpha-forge live sync-events`, or placed manually)
- Each entry must have a **paired `fill` event and `close` event**
- Verify with [`alpha-forge live convert-check`](#alpha-forge-live-convert-check) first that `conversion_ready : yes`
- Running once per `strategy_id` persists the trade records to SQLite (re-runs overwrite)

### Sample output

```text
imported_trades   : 16
strategy_id       : spy_sma_v1
db_path           : data/results/backtest_results.db
```

Only three fields are printed: `imported_trades` / `strategy_id` / `db_path` (no `trades_file` / `summary_file`). The trade records are stored in the SQLite DB referenced by `db_path`.

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Failed to generate trade records: <id>` | Unmatched `fill` / `close` pairs or missing events | Diagnose with `alpha-forge live convert-check --strategy <id>` |

---

## alpha-forge live trades

List individual trade records for a strategy.

### Synopsis

```bash
alpha-forge live trades <STRATEGY_ID> [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID |
| `--limit` | int | `50` | Number of records. `0` = show all |
| `--side` | choice | - | Filter by `long` / `short` |
| `--exit-reason` | option | - | Filter by `exit_reason` |
| `--json` | flag | false | Emit the result as JSON (`{strategy_id, trades: [...], count}`) |

Trades are sorted newest-first (`entry_at` descending). When the strategy exists but has zero trades, `--json` returns `status: "no_trades_yet"` plus an empty envelope (exit code `0`), treating it as a normal case.

### Sample output

```text
=== live trades ===
entry_at             symbol     side        qty        entry         exit    net_pnl     ret%   hold_m exit_reason
──────────────────────────────────────────────────────────────────────────────────────────────────────────────
2026-04-15 09:31     SPY        long     100.00     452.3000     458.1200    +582.00   +1.29%      271 take_profit
2026-04-12 10:05     SPY        long     100.00     451.0000     449.1000    -190.00   -0.42%      343 stop_loss
```

Formatting is delegated to `format_live_trades`. Columns are `entry_at` / `symbol` / `side` / `qty` / `entry` / `exit` / `net_pnl` / `ret%` / `hold_m` (holding minutes) / `exit_reason`. There are no `trade_id` or `exit_at` columns.

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `No live trade records found: <id>` | No trade records for the strategy in SQLite | Generate via `alpha-forge live import-events <id>` |

---

## alpha-forge live summary

Show the live performance summary. If the summary has not yet been built, it is constructed from trade records on the fly.

### Synopsis

```bash
alpha-forge live summary <STRATEGY_ID> [--json]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID |
| `--json` | flag | false | Emit the result as JSON (dumps `StrategyLiveSummary`; zero trades returns `summary: null` + `status: "no_trades_yet"` with exit code `0`) |

### Sample output

```text
=== spy_sma_v1 live summary ===
version          : v1.1.0
snapshot_id      : snap_20260415
broker           : ibkr
symbols          : SPY
total_trades     : 16
win_rate_pct     : 56.25
gross_pnl        : 1280.00
net_pnl          : 1184.50
profit_factor    : 1.92
avg_win          : 185.30
avg_loss         : -112.40
avg_slippage_bps : 1.80
total_commission : 95.50
max_drawdown_pct : -4.20
```

Formatting is delegated to `format_live_summary` (the `StrategyLiveSummary` model). Fields are `version` / `snapshot_id` / `broker` / `symbols` / `total_trades` / `win_rate_pct` / `gross_pnl` / `net_pnl` / `profit_factor` / `avg_win` / `avg_loss` / `avg_slippage_bps` / `total_commission` / `max_drawdown_pct`. There is no `total_pnl_pct`, `sharpe_ratio`, or `period`. `avg_win` / `avg_loss` are absolute amounts (P/L in the position currency), not percentages.

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `No live summary found: <id>` | Cannot build (no trade records) | Run `alpha-forge live import-events <id>` first |

---

## alpha-forge live compare

Compare the latest backtest run with the live summary side by side to evaluate whether live behavior matches expectations.

### Synopsis

```bash
alpha-forge live compare <STRATEGY_ID> [--json]
```

!!! note "The two meanings of `compare`"
    `live compare` is a **read-only** command that merely references the **saved** latest backtest run and live summary (it does not run a new backtest). Running a fresh backtest for comparison is the distinct, heavyweight [`backtest compare`](backtest.md#alpha-forge-backtest-compare).

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID |
| `--json` | flag | false | Emit the result as JSON (`{strategy_id, backtest_run, backtest: {...}, live: {...}}`) |

### Sample output

```text
=== spy_sma_v1 live vs backtest ===
backtest_run     : run_20260410181522
backtest_symbol  : SPY
live_symbols     : SPY
snapshot_id      : snap_20260415

metric                 backtest         live         delta
──────────────────────────────────────────────────────────────
total_trades                 18           16           -2
win_rate_pct              58.30%       56.25%       -2.05%
profit_factor              2.10         1.92        -0.18
total_return_pct         +12.40%            -            -
max_drawdown_pct          -3.80%       -4.20%       -0.40%
net_pnl                       -      1184.50            -
avg_slippage_bps              -         1.80            -
```

Formatting is delegated to `format_live_compare`. The header is `=== <id> live vs backtest ===`, followed by `backtest_run` / `backtest_symbol` / `live_symbols` / `snapshot_id` metadata lines and then a `metric` / `backtest` / `live` / `delta` table. The rows are `total_trades` / `win_rate_pct` / `profit_factor` / `total_return_pct` / `max_drawdown_pct` / `net_pnl` / `avg_slippage_bps`. There is no `sharpe_ratio` row. Metrics available only on the backtest side (`total_return_pct`) or only on the live side (`net_pnl` / `avg_slippage_bps`) render `-` on the missing side.

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `No live summary found: <id>` | Live summary missing | Run `alpha-forge live import-events <id>` |
| `No backtest run found: <id>` | No backtest run in journal | Run `alpha-forge backtest run` and let it record |

---

## alpha-forge live doctor

Diagnose the setup status of live trading analysis. With `STRATEGY_ID`, also checks trade and summary readiness for that strategy.

### Synopsis

```bash
alpha-forge live doctor [STRATEGY_ID] [--json]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (optional) | - | Strategy ID (enables detailed checks) |
| `--json` | flag | false | Emit the diagnostics as JSON (same data as the text output) |

### Sample output (no strategy ID)

```text
=== live trading doctor ===
live_path       : data/live
events_path     : data/live/events
db_path         : data/results/backtest_results.db
events_exists   : yes
event_files     : 24
hint            : pass a strategy_id to validate trades/summary readiness
```

There are no `trades_path` / `summaries_path` lines. Because trades and summaries are stored in SQLite (the `backtest_results.db` referenced by `db_path`), `db_path` is shown instead.

### Sample output (with strategy ID)

```text
=== live trading doctor ===
live_path       : data/live
events_path     : data/live/events
db_path         : data/results/backtest_results.db
events_exists   : yes
event_files     : 24
strategy_id     : spy_sma_v1
trades_exists   : yes
summary_exists  : yes
rollout_status  : ready
```

When trades exist but the summary has not been built, it is constructed on the spot and a `summary_built : yes` line is added. `rollout_status` is `ready` when `events_exists` is true, `event_files > 0`, and either `trades_exists` or `summary_exists` is true; otherwise `incomplete`.

---

## alpha-forge live sync-events

Sync event logs from VPS to local via rsync.

### Synopsis

```bash
alpha-forge live sync-events [--dry-run]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--dry-run` | flag | false | Show file list only without actual transfer |

### rsync configuration (`forge.yaml`)

`forge.yaml` requires a `remote` section like:

```yaml
remote:
  enabled: true
  user: <SSH_USER>
  host: <VPS_HOST>
  events_path: /var/log/alpha-strike/events    # VPS-side event log directory
  local_events_path: ./data/live/events        # Local destination (optional, default ./data/live/events)
  ssh_key_path: ~/.ssh/id_ed25519              # SSH key (optional, falls back to default)
```

| Key | Required | Description |
|-----|----------|-------------|
| `remote.enabled` | ✓ | Set to `true` |
| `remote.host` | ✓ | VPS hostname or IP |
| `remote.user` | ✓ | SSH login user |
| `remote.events_path` | ✓ | Event log directory on VPS (absolute path recommended) |
| `remote.local_events_path` | - | Local destination (defaults to `./data/live/events`) |
| `remote.ssh_key_path` | - | SSH key path (uses default key when omitted) |

### rsync command executed

```bash
rsync -avz --progress -e "ssh -i <ssh_key_path>" \
  <user>@<host>:<events_path>/ <local_events_path>/
```

With `--dry-run`, `rsync --dry-run -avz ...` runs without actually transferring. **The timeout is 300 seconds.**

### Sample output

```text
Syncing: ubuntu@vps.example.com:/var/log/alpha-strike/events/ → ./data/live/events/
sending incremental file list
events_20260415_093021.json
        2,318 100%   12.45MB/s    0:00:00
events_20260415_140215.json
        1,842 100%   15.20MB/s    0:00:00
sent 4,312 bytes  received 78 bytes  total size 4,160
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: remote is disabled. Set remote.enabled to true in forge.yaml.` | `remote.enabled` is false | Set `enabled: true` in `forge.yaml` |
| `Error: Set remote.host, remote.user, and remote.events_path.` | Required key missing | Complete the `remote` section |
| `Error: rsync timed out (300s). Check your VPS connection.` | Network or SSH issue | Verify connectivity, key, and firewall |

### Exit codes

- Success: `0`
- Missing config: `1`
- rsync timeout: `1`
- rsync own error: propagates rsync's exit code as is

---

## alpha-forge live replay

Reconstruct position-based live metrics from a combine portfolio's alert log. Intended for always-in-market combine overlays: it rebuilds position transitions from synced `alpha-strike` events (`alpha-forge live sync-events`) and computes Sharpe / CAGR / MaxDD from the portfolio equity curve. `order_reconciled` receipts are preferred as the authoritative source.

### Synopsis

```bash
alpha-forge live replay [PORTFOLIO_ID] [--combine-strategies <ID1,ID2,...>] [--since <ISO>] [--compare] [--initial-capital <FLOAT>] [--benchmark <SYMBOL>]
```

`PORTFOLIO_ID` and `--combine-strategies` are now optional. See [Config fallback for omitted arguments](#config-fallback-for-omitted-arguments-livereplay) below.

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `PORTFOLIO_ID` | argument (optional) | - | Combine portfolio ID; falls back to `live.replay.portfolio_id` in `forge.yaml` when omitted |
| `--combine-strategies` | option (optional) | - | Comma-separated combine strategy IDs (**2 or more required**); falls back to `live.replay.combine_strategies` when omitted |
| `--since` | option | - | Lower bound of the period (ISO format; UTC assumed when no timezone) |
| `--compare` | flag | false | Also run the backtest combine and show it side by side. When `live.replay.compare: true` is set, comparison is always on even without this flag (it's an OR, so config `true` cannot be turned off by omitting `--compare`) |
| `--initial-capital` | option | `live.replay.initial_capital`, then `backtest.initial_capital` (default 100,000) | Capital base of the live account |
| `--benchmark` | option | `live.benchmark` in `forge.yaml` (unset by default) | Index symbol for a buy-and-hold comparison line; leaving both this flag and `live.benchmark` unset means no comparison line is produced |

### Config fallback for omitted arguments (`live.replay`)

`PORTFOLIO_ID`, `--combine-strategies`, `--initial-capital`, and `--compare` are all optional — whatever you omit is filled in from the `live.replay` section of `forge.yaml`. [`alpha-forge live refresh`](#alpha-forge-live-refresh) uses the same resolution logic, so running it from the visualizer's Live page "Refresh" button requires this section to be configured beforehand.

```yaml
live:
  benchmark: ""            # existing (buy-and-hold comparison symbol)
  replay:
    portfolio_id: ""         # combine portfolio ID (e.g. my_hedged_pf_v1)
    combine_strategies: []   # combine target strategy IDs (2 or more)
    initial_capital: null    # capital base of the live account (null = use backtest.initial_capital)
    compare: false            # compare against the backtest combine
```

| Key | Description |
|-----|--------------|
| `live.replay.portfolio_id` | Default used when the `PORTFOLIO_ID` argument is omitted |
| `live.replay.combine_strategies` | Default used when `--combine-strategies` is omitted (set 2 or more strategy IDs) |
| `live.replay.initial_capital` | Default used when `--initial-capital` is omitted. When `null`, falls back further to `backtest.initial_capital` (default 100,000) |
| `live.replay.compare` | When `true`, always compares against the backtest combine even without passing `--compare` |

Resolution order is "flag (e.g. `--combine-strategies`) > `live.replay` config value > `backtest.initial_capital` (the final fallback, for `initial_capital` only)". Existing usage that always passes flags explicitly continues to work unchanged (backward compatible).

!!! warning "Always match `initial_capital` to the real account's capital"
    As described in [How equity is computed](#how-equity-is-computed-issue-1332) below, equity is computed as `initial_capital + cash delta + position market value`. If `--initial-capital` (or `live.replay.initial_capital`) doesn't match the real account's capital base, the return percentages skew by that ratio. Leaving it at the backtest default (100,000) while the live account holds 1,000,000 skews the return percentages by 10x.

If `portfolio_id` or `combine_strategies` (2 or more) cannot be resolved in the end, `live replay` exits with Click's argument-error exit code `2`.

### How equity is computed (issue #1332)

Equity is computed as:

```text
equity = initial_capital + cash delta + Σ(position × close)
```

Buying a position lowers cash and raises market value by the same amount, so the purchase itself does not move equity — **P&L only appears once prices move**.

Because of this, `--initial-capital` must match the capital base of the real live account. Leaving it at the backtest default (100,000) while the live account holds 1,000,000 skews the return percentages by that same ratio.

```bash
# When the live account holds $1,000,000
alpha-forge live replay beat_qqq_hedged_v1 \
  --combine-strategies tqqq_v1,gld_v1,tlt_v1 \
  --initial-capital 1000000
```

Equity and metrics are restricted to the period **from the first receipt onward**. Price history spans well over a decade, so computing across the full index would yield meaningless full-history CAGR / Sharpe values for a live track record that is only a few months old.

The date axis is the **union** of the price indexes of every constituent symbol. If a trading day is missing from one symbol's price data but present in another's, that day still appears in the equity curve (the symbol with the gap is forward-filled from its previous close). The order of symbols passed to `--combine-strategies` does not affect the result.

!!! note "Upgrading from before v1.1.0"
    Through v1.1.0 the date axis was pinned to the first symbol's price index, so trading days present only in other symbols could be dropped. Re-running may therefore shift Sharpe and volatility slightly. Total return, CAGR, and max drawdown are unchanged, since they depend on the endpoints and extremes rather than the intermediate path.

`--benchmark <SYMBOL>` adds a third line to the comparison: a buy-and-hold of that index over the same live period. Omitting `--benchmark` falls back to `live.benchmark` in `forge.yaml`; leaving both unset simply means no comparison line is produced (this is not an error). Like the `--compare` backtest line, the benchmark line is normalized so its first point equals `--initial-capital`, so the gap between the live, benchmark, and backtest lines reads directly as excess return.

If price data for the benchmark symbol has not been fetched (`alpha-forge data fetch <SYMBOL>`), `live replay` logs a warning and drops only the benchmark line — the live equity curve (and the `--compare` backtest line, if requested) are still computed and the command still exits successfully.

### Warnings about reconstruction accuracy

`live replay` warns when the reconstructed positions may have drifted from the real account. The command still exits successfully in both cases, but **the reported amounts are off**, so read the warning before trusting the numbers.

| Warning | What it means | What to do |
|---|---|---|
| A position is held but its closing price is missing | The price history is shorter than the alert log, so a held position is valued at $0. Equity, max drawdown, and cumulative P&L are all understated | Re-fetch with a longer window: `alpha-forge data fetch <SYMBOL> --period <longer>`, covering the date trading started |
| A sell exceeds the held quantity | The reconstructed position has drifted from the real account (missing or duplicated alert log entries, open-loop desync on the Pine side). The position is clamped to 0, and the average cost, unrealized P&L, and weights that follow are computed on a wrong basis | Inspect the order history for that symbol via `live events`. If it recurs, verify that the Pine-side quantity calculation is closed-loop |

### Sample output

```text
=== live replay (position-based) — combo_spy_qqq ===
receipts: 128

| Metric           | Live      | Backtest  |
|------------------|-----------|-----------|
| sharpe_ratio     |      1.21 |      1.38 |
| cagr_pct         |     14.30 |     16.80 |
| max_drawdown_pct |     -5.40 |     -4.90 |
| total_return_pct |     +9.85 |    +11.20 |
```

The `Backtest` column appears only when `--compare` is passed. When no receipts match the `portfolio_id`, a warning is shown prompting you to confirm `alpha-forge live sync-events` has been run.

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `--combine-strategies must list 2 or more strategies (comma-separated)` | Fewer than 2 strategy IDs provided | Pass at least two IDs, e.g. `--combine-strategies spy_sma_v1,qqq_hmm_v1` |
| `Failed to parse --since as ISO: ...` | Invalid ISO datetime | Use an ISO 8601 value, e.g. `2026-03-01` or `2026-03-01T00:00:00Z` |

---

## alpha-forge live refresh

A composite command that runs [`alpha-forge live sync-events`](#alpha-forge-live-sync-events) → `alpha-forge data update` → [`alpha-forge live replay`](#alpha-forge-live-replay) in sequence to bring a combine portfolio's live track record fully up to date in one shot. The "Refresh" button on the alpha-visualizer Live page calls this command.

### Synopsis

```bash
alpha-forge live refresh [--json]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--json` | flag | false | Emit the result as JSON (`{"steps": [...], "replay": {...}}`) |

### The 3 steps it runs

```text
1. alpha-forge live sync-events   Sync event logs from the VPS
2. alpha-forge data update        Update stored historical data
3. alpha-forge live replay        Rebuild the combine portfolio's live track record
```

Each step's parameters come from the `remote` / `live.replay` sections of `forge.yaml` — the command itself takes no CLI arguments for them.

When `remote.enabled` is `false`, step 1 (sync-events) is **skipped and the command continues** (this is not an error). When `true`, it requires the same [`remote` configuration](#alpha-forge-live-sync-events) as a standalone `sync-events` run.

If any step fails, the command **aborts immediately** with exit code `1` (subsequent steps do not run). Which step failed is reported to stderr as `Error: step <name> failed: <reason>`.

If `live.replay.portfolio_id` or `combine_strategies` (2 or more strategies) is not configured, the command exits with code `2` before running any step. Configure `live.replay` in `forge.yaml` first (see [`alpha-forge live replay`](#alpha-forge-live-replay) for the config keys).

### `--json` output contract

All progress (`[1/3] sync-events: ...`, etc.) is sent to stderr. With `--json`, stdout contains pure JSON of the following shape only:

```json
{
  "steps": [
    {"name": "sync_events", "status": "done"},
    {"name": "data_update", "status": "done", "updated_count": 3},
    {"name": "replay", "status": "done"}
  ],
  "replay": {
    "portfolio_id": "pf_1",
    "receipts_count": 128,
    "live_metrics": {"...": "..."},
    "backtest_metrics": null,
    "sub_strategies": ["..."]
  }
}
```

When sync-events is skipped because `remote.enabled: false`, that step reads `{"name": "sync_events", "status": "skipped", "reason": "remote_disabled"}`. If any step fails and the command aborts, nothing is written to stdout (the entire JSON payload, including `replay`, is omitted — the error is reported to stderr only).

### Exit codes

- Success: `0`
- Missing config (`live.replay.portfolio_id` / `combine_strategies` not set): `2`
- Any step failed: `1`

---

## Common behavior

- **Storage location**:
    - raw event logs: `<journal_path>/../live/events/` (JSON on the filesystem)
    - trade records / summary: a SQLite DB (`backtest_results.db` under `config.report.output_path`). Migrated from JSON files in `trades/` / `summaries/` to SQLite in v0.12.0
- **`forge.yaml`**: All paths above are determined by the `forge.yaml` referenced by the `FORGE_CONFIG` environment variable
- **VPS integration**: `sync-events` reads the `remote.*` section of `forge.yaml`
- **Exit codes**: `0` on success; argument errors return Click's `2`; missing config or records typically `1`
- **`--json` output rules**: `list` / `events` / `trades` / `summary` / `compare` / `doctor` support `--json`. When `--json` is set, stdout contains pure JSON only; decoration, progress, and save messages go to stderr. List commands return `{<plural>: [...], "count": n}` (empty array + exit code `0` when absent), while single-record commands return a `{error, code, id}` JSON to stdout with exit code `1` on not-found.

---

<!-- Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/live.py`, `LiveStore` in `alpha-forge/src/alpha_forge/live/store.py`, and `format_*` functions in `alpha-forge/src/alpha_forge/live/formatter.py`. This page must be kept in sync when CLI arguments or configuration keys change. -->
