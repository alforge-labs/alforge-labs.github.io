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
| `--strategy-id` | option | - | Filter by `strategy_id` |
| `--event-type` | option | - | Filter by `event_type` (e.g., `fill`, `close`) |
| `--broker` | option | - | Filter by `broker` |
| `--limit` | int | `20` | Number of records to display |

### Sample output

```text
timestamp           strategy_id     broker      event_type   symbol   side   qty   price
2026-04-15 09:31    spy_sma_v1      ibkr        fill         SPY      long   100   452.30
2026-04-15 14:02    spy_sma_v1      ibkr        close        SPY      long   100   458.12
...
```

Formatting is delegated to `format_live_events`.

---

## alpha-forge live convert-check

Check whether raw events can be converted to trade records (whether `fill` and `close` pairs are matched, etc.). Recommended as a pre-step to `import-events`.

### Synopsis

```bash
alpha-forge live convert-check [--strategy-id <ID>]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--strategy-id` | option | - | Filter by `strategy_id` |

### Sample output

```text
=== Conversion readiness ===
strategy_id              fill_events   close_events   matched   pending   status
spy_sma_v1                        18             16        16         2   partial
qqq_hmm_macd_ema_rsi_v1            8              8         8         0   ready
broken_v1                          5              0         0         5   missing close events
```

Formatting is delegated to `format_event_conversion_report`.

---

## alpha-forge live import-events

Generate trade records from `fill` / `close` events and save them as `<live_path>/trades/<strategy_id>.json` and `<live_path>/summaries/<strategy_id>.json`.

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
- Verify with [`alpha-forge live convert-check`](#alpha-forge-live-convert-check) first that the status is `ready` (or `partial` within tolerance)
- Running once per `strategy_id` produces `<strategy_id>.json` (re-runs overwrite)

### Sample output

```text
imported_trades   : 16
strategy_id       : spy_sma_v1
trades_file       : data/live/trades/spy_sma_v1.json
summary_file      : data/live/summaries/spy_sma_v1.json
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Failed to generate trade records: <id>` | Unmatched `fill` / `close` pairs or missing events | Diagnose with `alpha-forge live convert-check --strategy-id <id>` |

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

Trades are sorted newest-first (`entry_at` descending).

### Sample output

```text
trade_id  side    entry_at              exit_at               qty   pnl_pct   exit_reason
t_0042    long    2026-04-15 09:31      2026-04-15 14:02      100   +1.29%    take_profit
t_0041    long    2026-04-12 10:05      2026-04-12 15:48      100   -0.42%    stop_loss
...
```

Formatting is delegated to `format_live_trades`.

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `No live trade records found: <id>` | `<live_path>/trades/<id>.json` does not exist | Generate via `alpha-forge live import-events <id>` |

---

## alpha-forge live summary

Show the live performance summary. If the summary has not yet been built, it is constructed from trade records on the fly.

### Synopsis

```bash
alpha-forge live summary <STRATEGY_ID>
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID |

### Sample output

```text
=== spy_sma_v1 / Live Summary ===
trades            : 16
win_rate          : 56.3%
total_pnl_pct     : +8.42%
avg_win_pct       : +1.85%
avg_loss_pct      : -1.12%
max_drawdown_pct  : -4.20%
sharpe_ratio      : 1.32
period            : 2026-03-01 → 2026-04-15
```

Formatting is delegated to `format_live_summary`.

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `No live summary found: <id>` | Cannot build (no trade records) | Run `alpha-forge live import-events <id>` first |

---

## alpha-forge live compare

Compare the latest backtest run with the live summary side by side to evaluate whether live behavior matches expectations.

### Synopsis

```bash
alpha-forge live compare <STRATEGY_ID>
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID |

### Sample output

```text
=== spy_sma_v1: Backtest vs Live ===

Metric             Backtest (run_20260410)    Live (2026-03-01 → 2026-04-15)    Diff
trades             18                          16                                 -2
win_rate_pct       58.3                        56.3                              -2.0
total_return_pct   +12.4                       +8.42                             -3.98
sharpe_ratio       1.45                        1.32                              -0.13
max_drawdown_pct   -3.80                       -4.20                             -0.40
```

Formatting is delegated to `format_live_compare`.

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
alpha-forge live doctor [STRATEGY_ID]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (optional) | - | Strategy ID (enables detailed checks) |

### Sample output (no strategy ID)

```text
=== live trading doctor ===
live_path       : data/live
events_path     : data/live/events
trades_path     : data/live/trades
summaries_path  : data/live/summaries
events_exists   : yes
event_files     : 24
hint            : pass a strategy_id to validate trades/summary readiness
```

### Sample output (with strategy ID)

```text
=== live trading doctor ===
live_path       : data/live
...
event_files     : 24
strategy_id     : spy_sma_v1
trades_exists   : yes
summary_exists  : yes
rollout_status  : ready
```

`rollout_status` is `ready` when `events_exists` is true, `event_files > 0`, and either `trades_exists` or `summary_exists` is true; otherwise `incomplete`.

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
alpha-forge live replay <PORTFOLIO_ID> --combine-strategies <ID1,ID2,...> [--since <ISO>] [--compare]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `PORTFOLIO_ID` | argument (required) | - | Combine portfolio ID |
| `--combine-strategies` | option (required) | - | Comma-separated combine strategy IDs (**2 or more required**) |
| `--since` | option | - | Lower bound of the period (ISO format; UTC assumed when no timezone) |
| `--compare` | flag | false | Also run the backtest combine and show it side by side |

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

## Common behavior

- **Storage location**: under `<journal_path>/../live/` (subdirectories `events/`, `trades/`, `summaries/`)
- **`forge.yaml`**: All paths above are determined by the `forge.yaml` referenced by the `FORGE_CONFIG` environment variable
- **VPS integration**: `sync-events` reads the `remote.*` section of `forge.yaml`
- **Detailed specs**: For data model and rollout procedure, see the alpha-forge repo
    - `alpha-forge/docs/live-trading-data-model.md`
    - `alpha-forge/docs/live-trading-rollout.md`
- **Exit codes**: `0` on success; argument errors return Click's `2`; missing config or records typically `1`

---

<!-- Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/live.py`, `LiveStore` in `alpha-forge/src/alpha_forge/live/store.py`, and `format_*` functions in `alpha-forge/src/alpha_forge/live/formatter.py`. This page must be kept in sync when CLI arguments or configuration keys change. -->
