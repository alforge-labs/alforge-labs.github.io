# alpha-forge journal

Manage strategy execution history, snapshots, tags, notes, and verdicts (pass / fail / review). When `config.journal.auto_record` is true, runs of `alpha-forge strategy save`, `alpha-forge optimize run`, and similar are recorded automatically.

!!! info "About sample output"
    Sample outputs in this page are based on the formats read from the `alpha-forge` source. Actual values and formatting depend on the `format_*` functions in `journal/formatter.py`.

## Subcommands

| Command | Description |
|---------|-------------|
| [`alpha-forge journal list`](#alpha-forge-journal-list) | Show list of strategies that have a journal |
| [`alpha-forge journal show`](#alpha-forge-journal-show) | Show full history (snapshots and runs) for a strategy |
| [`alpha-forge journal runs`](#alpha-forge-journal-runs) | Show run results in table format |
| [`alpha-forge journal compare`](#alpha-forge-journal-compare) | Compare two run results side by side |
| [`alpha-forge journal tag`](#alpha-forge-journal-tag) | Add or remove tags |
| [`alpha-forge journal note`](#alpha-forge-journal-note) | Append a note |
| [`alpha-forge journal verdict`](#alpha-forge-journal-verdict) | Record a verdict (pass / fail / review) for a run result |
| [`alpha-forge journal report`](#alpha-forge-journal-report) | Render the strategy history as a Markdown report (with optional TV chart embedding) |

---

## alpha-forge journal list

List all strategies that have a journal. Walks `<strategy_id>.journal.json` files under `config.journal.journal_path`.

### Synopsis

```bash
alpha-forge journal list
```

### Arguments and options

None.

### Sample output

```text
spy_sma_v1                  runs:14   tags: production, validated   verdict: pass
qqq_hmm_macd_ema_rsi_v1     runs: 8   tags: experimental             verdict: review
gc_hmm_macd_ema_v1          runs: 5   tags: -                         verdict: -
```

Formatting is delegated to `format_journal_list` in `journal/formatter.py`. When no journals exist, an empty result or guidance message is returned.

---

## alpha-forge journal show

Show a strategy's full history: definition snapshots, run history (backtests / optimizations / ...), tags, notes, and a live summary (when live trading records exist).

### Synopsis

```bash
alpha-forge journal show <STRATEGY_ID>
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID to display |

### Sample output

```text
=== Strategy: spy_sma_v1 ===
Tags: production, validated
Notes:
  - 2026-04-15: passed OOS validation
  - 2026-04-10: baseline finalized

[Snapshots]
  v1.0.0 (2026-04-01) saved via 'save'
  v1.1.0 (2026-04-15) saved via 'save'

[Runs]
  run_20260415103021 (optimization)  metric=sharpe_ratio  best=1.45  verdict=pass
  run_20260410181522 (backtest)      sharpe=0.92  cagr=5.4%          verdict=-
  ...

[Live Summary]
  trades=42  win_rate=53.5%  pnl_pct=+8.2%
```

Formatting is delegated to `format_journal_show`. Field details may vary by version.

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `No journal found: <id>` | Journal file missing or empty | Verify with `alpha-forge journal list`; run the strategy to create a journal |

---

## alpha-forge journal runs

Show run results in a table.

### Synopsis

```bash
alpha-forge journal runs <STRATEGY_ID> [--best <KEY>]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID |
| `--best` | choice | (date-equivalent when omitted) | Sort key. `sharpe_ratio` / `total_return_pct` / `max_drawdown_pct` / `win_rate_pct` / `date` |

### Sample output

```text
run_id                       type            sharpe   ret%    mdd%   win%   verdict
run_20260415103021           optimization      1.45    +52.3   -16.8   50.0   pass
run_20260410181522           backtest          0.92    +38.1   -15.6   58.3   review
run_20260401092030           backtest          0.78    +28.0   -18.2   45.7   -
```

Formatting is delegated to `format_runs_table(j, sort_by)`.

---

## alpha-forge journal compare

Compare **two run results** of the same strategy side by side.

### Synopsis

```bash
alpha-forge journal compare <STRATEGY_ID> --run <RUN_ID1> --run <RUN_ID2>
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID |
| `--run` | repeatable (required, **exactly 2**) | - | `run_id` to compare |

### Sample output

```text
=== Compare runs of spy_sma_v1 ===

Metric              run_20260415103021      run_20260410181522
type                optimization            backtest
sharpe_ratio        1.45                    0.92
total_return_pct    +52.3                   +38.1
max_drawdown_pct    -16.8                   -15.6
win_rate_pct        50.0                    58.3
verdict             pass                    review
```

Formatting is delegated to `format_compare(j, run1, run2)`.

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: specify exactly 2 --run values.` | Number of `--run` not 2 | Pass exactly 2 |
| `Error: run_id not found - <id>` | Specified `run_id` does not exist | Verify with `alpha-forge journal runs <strategy_id>` |

---

## alpha-forge journal tag

Add or remove **tags** on a strategy. `--add` and `--remove` can be **combined** in one call (one of them must be present).

### Synopsis

```bash
alpha-forge journal tag <STRATEGY_ID> [--add <TAG>] [--remove <TAG>]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID |
| `--add` | option | - | Tag to add |
| `--remove` | option | - | Tag to remove |

### Sample output

```text
✅ Tag 'production' added: spy_sma_v1
```

When both flags are given:

```text
✅ Tag 'experimental' removed: spy_sma_v1
✅ Tag 'production' added: spy_sma_v1
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: specify --add or --remove.` | Neither given | Pass `--add` or `--remove` |

---

## alpha-forge journal note

Append a note to a strategy (additive — does not overwrite existing notes).

### Synopsis

```bash
alpha-forge journal note <STRATEGY_ID> <TEXT>
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID |
| `TEXT` | argument (required) | - | Note body (quote if it contains spaces) |

### Sample output

```text
✅ Note appended: spy_sma_v1
```

Example:

```bash
alpha-forge journal note spy_sma_v1 "OOS check passed at sharpe=0.95; promoted to production candidate"
```

---

## alpha-forge journal verdict

Record a **verdict** on a specific run (`run_id`).

### Synopsis

```bash
alpha-forge journal verdict <STRATEGY_ID> <RUN_ID> <pass|fail|review>
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID |
| `RUN_ID` | argument (required) | - | `run_id` to verdict |
| `VERDICT` | argument (required, choice) | - | One of `pass` / `fail` / `review` |

### Verdict values (pass / fail / review)

| Value | Meaning | When to use |
|-------|---------|-------------|
| `pass` | **Accepted / passing** | OOS check passed, promoted to live, beats benchmark |
| `fail` | **Rejected / not accepted** | Suspected overfitting, below benchmark, unacceptable risk |
| `review` | **Pending review** | Decision deferred, awaiting more validation, under discussion |

The verdict is reflected in `alpha-forge journal show` and `alpha-forge journal runs` output.

### Sample output

```text
✅ Verdict recorded: run_20260415103021 → pass
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: run_id not found - <id>` | Specified `run_id` does not exist in the journal | Verify with `alpha-forge journal runs <strategy_id>` |
| Click: `Invalid value for 'VERDICT'` | Value other than `pass` / `fail` / `review` | Use one of the choices |

---

## alpha-forge journal report

Render the strategy's full history (snapshots, runs, tags, notes, verdicts) as a **Markdown report** (issue #523 Phase 1.5d-γ). With `--with-chart`, append a TradingView chart PNG fetched from a TV MCP server at the bottom.

### Synopsis

```bash
alpha-forge journal report <STRATEGY_ID> [--output <FILE>]
alpha-forge journal report <STRATEGY_ID> --output <FILE> --with-chart --symbol <SYM> --interval <TF>
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID |
| `--output` | file path | - | Markdown output destination. Stdout when omitted |
| `--with-chart` | flag | false | Append a TradingView chart PNG at the end of the report. Also requires `--output` (the chart PNG is written next to the Markdown file) and `--symbol`/`--interval` |
| `--symbol` | option | - | TV symbol for the chart (required when `--with-chart`) |
| `--interval` | option | - | TV interval for the chart (e.g. `D`, `60`) |
| `--mock` | flag | false | Use the mock MCP client for chart retrieval (CI) |
| `--mcp-server` | option | - | MCP server endpoint for chart retrieval (defaults to `tv_mcp.chart_snapshot.endpoint` in `forge.yaml`) |

### Examples

```bash
# Print to stdout
alpha-forge journal report spy_sma_v1

# Write to file with embedded TV chart
alpha-forge journal report spy_sma_v1 --output reports/spy.md \
  --with-chart --symbol SPY --interval D
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `No journal found: <id>` | Journal missing | Verify with `alpha-forge journal list` |
| `--with-chart requires --symbol / --interval.` | Missing chart args | Add `--symbol` and `--interval` |
| `--with-chart requires --output (chart PNG is written next to the Markdown file).` | `--with-chart` given without `--output` (cannot combine with stdout output) | Add `--output <FILE>` |

---

## Common behavior

- **Storage location**: `config.journal.journal_path / <strategy_id>.journal.json`
- **Auto-recording**: With `config.journal.auto_record` true, `alpha-forge strategy save` snapshots and `alpha-forge optimize run` records are added automatically
- **Live integration**: `LiveStore` reads from `<journal_path>/../live/` and feeds into `show`
- **`FORGE_CONFIG`**: All paths above are determined by the `forge.yaml` referenced by the `FORGE_CONFIG` environment variable
- **Exit codes**: `0` on success; argument errors return Click's `2`; `run_id` not found typically returns `1` (writes to stderr and returns)

---

<!-- Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/journal.py` and `format_*` functions in `alpha-forge/src/alpha_forge/journal/formatter.py`. This page must be kept in sync when CLI arguments or formatting logic change. -->
