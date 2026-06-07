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

List all strategies that have a journal. Walks the `journal_entries` table in the SQLite DB (`strategies.db`) under `config.strategies.path`.

### Synopsis

```bash
alpha-forge journal list [--json]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--json` | flag | false | Emit the result as JSON (`{journals: [...], count}`) |

### Sample output

```text
戦略ID                                  最終実行   実行数   スナップ  タグ
────────────────────────────────────────────────────────────────────────────────
spy_sma_v1                   2026-04-15 10:30   14      2  production, validated
qqq_hmm_macd_ema_rsi_v1      2026-04-12 18:05    8      1  experimental
gc_hmm_macd_ema_v1           2026-04-01 09:20    5      1  -
```

Formatting is delegated to `format_journal_list` in `journal/formatter.py`. The header labels are emitted in Japanese; columns are strategy ID, last run (timestamp of the most recent run, `-` when none), run count, snapshot count, and tags. When no journals exist, the message "ジャーナルが登録されている戦略はありません。" is shown.

---

## alpha-forge journal show

Show a strategy's full history: definition snapshots, run history (backtests / optimizations / ...), tags, notes, and a live summary (when live trading records exist).

### Synopsis

```bash
alpha-forge journal show <STRATEGY_ID> [--json]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID to display |
| `--json` | flag | false | Emit the result as JSON (dumps `JournalEntry` + `live_summary`; not-found returns `{error, code, id}` to stdout with exit code `1`) |

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
alpha-forge journal runs <STRATEGY_ID> [--best <KEY>] [--json]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID |
| `--best` | choice | (date-equivalent when omitted) | Sort key. `sharpe_ratio` / `total_return_pct` / `max_drawdown_pct` / `win_rate_pct` / `date` |
| `--json` | flag | false | Emit the result as JSON (`{strategy_id, runs: [...], count}`; sort order matches the text output) |

### Sample output

```text
=== spy_sma_v1 実行一覧 (3件) ===
run_id                                   日時           種別 symbol    Return   CAGR    SR Sortino    MDD  Win%    PF   取引  verdict
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────
run_20260410181522           2026-04-10 18:15     backtest    SPY    +38.1%  +12.4%  0.92    1.31  -15.6% 58.3% 1.85   24  ✅ pass
run_20260401092030           2026-04-01 09:20     backtest    SPY    +28.0%   +9.7%  0.78    1.04  -18.2% 45.7% 1.42   31  🔍 review
run_20260415103021           2026-04-15 10:30 optimization    SPY         -       -     -       -       -     -    -    -  -
```

Formatting is delegated to `format_runs_table(j, sort_by)`. The title line and the `日時` (date) / `種別` (type) / `取引` (trades) header labels are emitted in Japanese. Columns are `run_id` / `日時` / `種別` / `symbol` / `Return` / `CAGR` / `SR` / `Sortino` / `MDD` / `Win%` / `PF` / `取引` / `verdict`. The `verdict` is shown with an emoji (`✅ pass` / `❌ fail` / `🔍 review` / `-` when none). For non-`backtest` types (e.g. `optimization`), the metric columns render as `-`.

---

## alpha-forge journal compare

Compare **two run results** of the same strategy side by side.

!!! note "The two meanings of `compare`"
    `journal compare` is a **read-only** command that merely references **saved** runs (it does not run a new backtest). Running a fresh backtest for comparison is the distinct, heavyweight [`backtest compare`](backtest.md#alpha-forge-backtest-compare).

### Synopsis

```bash
alpha-forge journal compare <STRATEGY_ID> --run <RUN_ID1> --run <RUN_ID2> [--json]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID |
| `--run` | repeatable (required, **exactly 2**) | - | `run_id` to compare |
| `--json` | flag | false | Emit the result as JSON (`{strategy_id, run_a: {...}, run_b: {...}}`) |

### Sample output

```text
=== spy_sma_v1: 実行比較 ===
  A: run_20260415103021  (2026-04-15 10:30  SPY)
  B: run_20260410181522  (2026-04-10 18:15  SPY)

指標                                  A            B  差分
─────────────────────────────────────────────────────────────────
  総リターン (%)                    52.30        38.10  -14.20
  CAGR (%)                          16.80        12.40  -4.40
  シャープレシオ                     1.45         0.92  -0.53
  ソルティノレシオ                   2.01         1.31  -0.70
  最大ドローダウン (%)             -16.80       -15.60  +1.20
  勝率 (%)                          50.00        58.30  +8.30
  プロフィットファクター             2.10         1.85  -0.25
  取引数                            18.00        24.00  +6.00
  平均保有日数                       3.20         2.80  -0.40
  露出率 (%)                        62.00        58.00  -4.00
```

Formatting is delegated to `format_compare(j, run1, run2)`. The metric labels (`指標` column) are emitted in Japanese. Columns are `指標` (metric) / `A` (first run) / `B` (second run) / `差分` (delta = B − A; colored, with max drawdown treated as lower-is-better). There are no `type` or `verdict` rows. The compared run IDs, timestamps, and symbols appear in the `A:` / `B:` lines right under the header.

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

When both flags are given, they are processed and printed in **add-then-remove order**:

```text
✅ Tag 'production' added: spy_sma_v1
✅ Tag 'experimental' removed: spy_sma_v1
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

!!! note "Not-found returns exit code `1` (epic #1083 D)"
    Previously, passing a non-existent `run_id` returned exit code `0` (treated as success). To honor the Fail Loud convention, this is now unified to **not found = exit code `1`**, so unattended loops can detect it via the exit code.

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
| `--json` | flag | false | Emit **metadata** as JSON instead of the body (`{strategy_id, output_path, saved, with_chart, chart_path, markdown}`; `markdown` is included in the payload only when `--output` is omitted) |

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

- **Storage location**: a SQLite DB (`strategies.db`) under `config.strategies.path`. Journals are stored in the `journal_entries` / `journal_runs` / `journal_snapshots` tables (migrated from the legacy `<strategy_id>.journal.json` files to SQLite in v0.12.0)
- **Auto-recording**: With `config.journal.auto_record` true, `alpha-forge strategy save` snapshots and `alpha-forge optimize run` records are added automatically
- **Live integration**: `LiveStore` reads from `<journal_path>/../live/` and feeds into `show`
- **`FORGE_CONFIG`**: All paths above are determined by the `forge.yaml` referenced by the `FORGE_CONFIG` environment variable
- **Exit codes**: `0` on success; argument errors return Click's `2`; `run_id` not found typically returns `1` (writes to stderr and returns)
- **`--json` output rules**: `list` / `runs` / `compare` / `show` / `report` support `--json`. When `--json` is set, stdout contains pure JSON only (decoration and save messages go to stderr). List commands return `{<plural>: [...], "count": n}`, and single-record commands like `show` return `{error, code, id}` to stdout with exit code `1` on not-found.

---

<!-- Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/journal.py` and `format_*` functions in `alpha-forge/src/alpha_forge/journal/formatter.py`. This page must be kept in sync when CLI arguments or formatting logic change. -->
