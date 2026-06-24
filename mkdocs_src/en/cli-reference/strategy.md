# alpha-forge strategy

Create, register, validate, and manage strategy JSON definitions. Covers scaffolding from built-in templates, local registration, viewing, JSON → DB migration, deletion, and logical consistency checks (static + dynamic).

!!! info "About sample output"
    Sample outputs in this page are based on the formats read from the `alpha-forge` source. Actual numbers depend on the data and environment.

## Subcommands

| Command | Description |
|---------|-------------|
| [`alpha-forge strategy list`](#alpha-forge-strategy-list) | List all registered strategies |
| [`alpha-forge strategy create`](#alpha-forge-strategy-create) | Create a JSON file from a built-in template |
| [`alpha-forge strategy scaffold`](#alpha-forge-strategy-scaffold) | Scaffold a strategy from a symbol, indicators, and a strategy type |
| [`alpha-forge strategy save`](#alpha-forge-strategy-save) | Register a custom strategy from a JSON file |
| [`alpha-forge strategy show`](#alpha-forge-strategy-show) | Display the definition (JSON) of a registered strategy |
| [`alpha-forge strategy migrate`](#alpha-forge-strategy-migrate) | Import existing JSON files into the DB |
| [`alpha-forge strategy delete`](#alpha-forge-strategy-delete) | Delete a registered strategy from the DB |
| [`alpha-forge strategy purge`](#alpha-forge-strategy-purge) | Purge the strategy JSON, related results, and DB entry in a single command |
| [`alpha-forge strategy validate`](#alpha-forge-strategy-validate) | Validate strategy logical consistency |
| [`alpha-forge strategy cost-presets`](#alpha-forge-strategy-cost-presets) | List built-in cost presets |
| [`alpha-forge strategy signals`](#alpha-forge-strategy-signals) | Count entry signals for a strategy |

---

## alpha-forge strategy list

List all registered strategies. When `config.strategies.use_db` is true, reads from the DB; otherwise from the file-based store.

### Synopsis

```bash
alpha-forge strategy list [--json]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--json` | flag | false | Output as JSON (machine-readable, for MCP / pipe use) |

### Sample output

```text
ID                                       Name                           Version    Timeframe
------------------------------------------------------------------------------------------
spy_sma_crossover_v1                     SMA Golden/Death Cross SPY v1  1.0.0      1d
qqq_hmm_macd_ema_rsi_v1                  QQQ HMM × MACD × EMA × RSI v1  1.0.0      1d
gc_hmm_macd_ema_v1                       GC HMM × MACD × EMA v1         1.0.0      1d
```

When no strategies are registered:

```text
No registered strategies found.
```

---

## alpha-forge strategy create

Create a strategy JSON file from a built-in template. **Does not register the strategy** — edit the file and then call [`alpha-forge strategy save`](#alpha-forge-strategy-save).

### Synopsis

```bash
alpha-forge strategy create --template <NAME> --out <FILE> [--strategy-id <ID>]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--template` | required | - | Built-in template name to use as base |
| `--out` | required | - | Output JSON file path |
| `--strategy-id` | optional | auto-derived from `--out` basename (without extension) | Override `strategy_id` in the generated JSON |

!!! info "Auto-derived `strategy_id` (v0.5.4+)"
    With `--out my_usdjpy_v1.json`, the generated JSON's `strategy_id` is
    automatically set to `my_usdjpy_v1`. This addresses F-301: before v0.5.4,
    `strategy_id` was left as the template name (e.g., `sma_crossover_v1`),
    which collided with the built-in template on `alpha-forge strategy save`.

    - **Explicit override**: pass `--strategy-id usdjpy_sma_v1`
    - **Filename equals template name** (e.g., `--out sma_crossover_v1.json`):
      a warning is printed and the template ID is preserved as-is for backward
      compatibility. Manual edit is required before `save`.
    - **`--strategy-id ""` (empty)**: exits with code 2.

### Available templates

Built-in templates from `alpha-forge/src/alpha_forge/strategy/templates.py` (`_TEMPLATE_REGISTRY`):

AlphaForge ships a curated set of templates so users can focus on building their own strategies. The distributed binary includes **4 basic templates + 1 range strategy + 2 advanced-indicator references = 7 templates total**. The 27 specialized templates that shipped through v0.3.5 (KAMA + RSI trailing variants, FX 1h ports, Connors / TSI / OU stat-arb, etc.) were removed in v0.4.0 and archived under `alpha-strategies/legacy_templates/` for internal reference.

| Name | Category | Description |
|------|----------|-------------|
| `sma_crossover_v1` | Basic | Short/long SMA crossover (the most basic trend follower) |
| `rsi_reversion_v1` | Basic | Mean reversion using RSI overbought / oversold |
| `macd_crossover_v1` | Basic | MACD line / signal line crossover |
| `bbands_breakout_v1` | Basic | Bollinger Bands upper-band breakout |
| `grid_bot_template` | Range | Grid bot strategy (representative choppy-market template) |
| `hmm_bb_pipeline_v1` | Reference | Two-stage pipeline that classifies regimes via HMM (Bull/Range/Bear, 3 states) and switches BB-based signals per regime |
| `donchian_turtle_v1` | Reference | Donchian Channel Breakout + ATR stop. Richard Dennis "Turtle Trading Rules" style classic trend follower |


### Sample output

```text
✅ Created JSON file from template 'sma_crossover_v1': my_strategy.json

📝 Before `alpha-forge strategy save`, edit at least:
   - name              human-readable name (e.g. "USDJPY SMA cross v1")
   - target_symbols    target symbols (e.g. ["USDJPY=X"])
   - (if optimizing)   define optimizer_config.param_ranges

   Next: alpha-forge strategy save my_strategy.json
      →  alpha-forge backtest run <SYMBOL> --strategy my_strategy
```

### Fields you must edit in the generated JSON (F-300)

The JSON produced by built-in templates is **not directly ready to `alpha-forge strategy save`**. At minimum, edit:

| Field | Template default | Why edit |
|-------|-----------------|----------|
| `name` | The template name | Used by `alpha-forge strategy list` for human identification |
| `target_symbols` | `[]` (empty) | Leaving it empty causes a symbol-missing error in `backtest run` |
| `optimizer_config.param_ranges` | `null` or minimal | Required if you want to optimize. With `null` the built-in default ranges are used (see [`alpha-forge optimize run`](optimize.md#alpha-forge-optimize-run)) |

`strategy_id` is auto-derived from the `--out` filename and normally needs no editing.

For a complete walkthrough see the *Strategy JSON Editing* section in [end-to-end-workflow](../guides/end-to-end-workflow.md).

### Common errors

| Situation | Behavior |
|-----------|----------|
| Unknown template name | Prints `❌ Unknown template name: <name>. Available: ...` to stderr along with a guidance block (save / specify JSON), then exits with code `1` (no raw `ValueError:` traceback) |

---

## alpha-forge strategy save

Register a custom strategy in the **strategy registry** from a JSON file. When `config.journal.auto_record` is true, a Journal snapshot is also recorded.

### Synopsis

```bash
alpha-forge strategy save <FILE_PATH> [--force]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `FILE_PATH` | argument (required) | - | Strategy JSON file path |
| `--force` | flag | false | Overwrite if a strategy with the same ID already exists |

### Sample output

```text
✅ Strategy 'my_strategy_v1' registered
```

When overwritten with `--force`:

```text
✅ Strategy 'my_strategy_v1' overwritten
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: file not found - <path>` | File missing | Verify the path |
| `Error: <DuplicateStrategyError>` | Same ID already registered | Use `--force`, or change `strategy_id` in the JSON |

---

## alpha-forge strategy show

Pretty-print a registered strategy JSON to stdout.

### Synopsis

```bash
alpha-forge strategy show <STRATEGY_ID> [--json] [--with-silence-stats]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID to display |
| `--json` | flag | false | Output as pure JSON (for piping) |
| `--with-silence-stats` | flag | false | Compute and display historical `hedge_trigger` firing stats for buy-hold-overlay (#966 Phase 3). For composite `REGIME_RULE`, per-condition and aggregated counts are shown. Requires OHLC data fetch. |

### Sample output

```text
=== spy_sma_crossover_v1 ===
{
  "strategy_id": "spy_sma_crossover_v1",
  "name": "SMA Golden/Death Cross SPY v1",
  "version": "1.0.0",
  ...
}
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: strategy '<id>' not found` | Invalid ID | Verify with `alpha-forge strategy list` |

---

## alpha-forge strategy migrate

Import existing JSON files under `config.strategies.path` into the **DB (SQLite)**. Use this when switching to the `use_db: true` operation mode.

### Synopsis

```bash
alpha-forge strategy migrate [--dry-run] [--force]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--dry-run` | flag | false | Preview only, no writes |
| `--force` | flag | false | Overwrite duplicate IDs with the last file |

### Prerequisite

`config.strategies.use_db` must be **true**. In `forge.yaml` (`FORGE_CONFIG`):

```yaml
strategies:
  use_db: true
```

### Sample output

```text
⚠️  Duplicate strategy_id detected:
  spy_sma_crossover_v1:
    - spy_sma_crossover_v1.json
    - spy_sma_crossover_v1_optimized.json

Re-run with --force to overwrite with the last file.
```

With `--force --dry-run`:

```text
[dry-run] 12 strategies would be registered (no writes performed)
```

Normal run:

```text
  Skip (broken_v1.json): parse error - <details>
  Skip (legacy_v1): duplicate, not registered

✅ Done: 10 registered, 2 skipped
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: strategies.use_db is false. Set use_db: true in forge.yaml` | DB disabled | Update `forge.yaml` and retry |
| `No JSON files found for migration.` | `strategies.path` is empty | Verify path / file placement |

---

## alpha-forge strategy delete

Delete a registered strategy from the DB / registry. With `--with-results`, also deletes related files (optimized strategy, backtest results, optimization results). Journal files are always kept.

### Synopsis

```bash
alpha-forge strategy delete <STRATEGY_ID> [--dry-run] [--yes] [--with-results]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID to delete |
| `--dry-run` | flag | false | Show what would be deleted and exit without deleting anything (closes the destructive-guard asymmetry, issue #1178) |
| `--yes` / `-y` | flag | false | Skip confirmation prompt (renamed from `--force` in epic #1083 D) |
| `--with-results` | flag | false | Also delete related files (`<id>_optimized.json`, `<id>_report.json`, `optimize_<id>_*.json`) |

Because this is a destructive operation, in non-interactive environments (`FORGE_NONINTERACTIVE` / `CI` / non-TTY) it stops with exit code `2` unless `--yes` is given. Not-found returns exit code `1`.

With `--dry-run`, the command lists what would be deleted (including related files when `--with-results` is set) and exits with code `0` without deleting anything. Useful for verifying the target before a real deletion.

### Files removed by `--with-results`

- `strategies.path / <id>_optimized.json`
- `report.output_path / <id>_report.json`
- `report.output_path / optimize_<id>_*.json` (all matching files)

`<id>.journal.json` is **kept**.

### Automatic cleanup of recommendations.yaml (issue #454)

When a strategy is deleted, any matching entry in `data/explorer/recommendations.yaml` is automatically removed (ranks are renumbered). Deleting an auto-relax recommendation will not leave a stale entry that causes `alpha-forge explore run` to fail with `StrategyNotFoundError`.

In addition, `alpha-forge explore recommend show` performs a DB existence check at display time and auto-prunes any stale entries left over from previous runs.

### Sample output

```text
To delete: my_strategy_v1

  ✓ data/strategies/my_strategy_v1_optimized.json
  ✓ data/results/my_strategy_v1_report.json
  ✓ data/results/optimize_my_strategy_v1_20260415_103021.json
  - data/journal/my_strategy_v1.journal.json (kept)

Continue? [y/N]: y
✅ Strategy 'my_strategy_v1' deleted
Files deleted: 3
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: strategy '<id>' not found` | Invalid ID | Verify with `alpha-forge strategy list` |
| `Cancelled` | Declined the prompt | Use `--yes` or re-confirm |

---

## alpha-forge strategy purge

Purge the strategy JSON, related files (`_optimized.json`, `_report.json`, `optimize_<id>_*.json`), and DB entry **in a single command**. Replaces the previous three-step `rm <strategy>.json && rm <strategy>_report.json && alpha-forge strategy delete <id> --yes` workflow. Journal files (`<id>.journal.json`) are preserved.

### Synopsis

```bash
alpha-forge strategy purge <STRATEGY_ID> [--dry-run] [--yes]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID to purge completely |
| `--dry-run` | flag | false | Only list the files that would be deleted; do not actually delete them |
| `--yes` / `-y` | flag | false | Skip the confirmation prompt and purge (newly added in epic #1083 A; previously the command only had a confirmation prompt and could hang) |

Because this is a destructive operation, in non-interactive environments (`FORGE_NONINTERACTIVE` / `CI` / non-TTY) it stops with exit code `2` unless `--yes` is given. Not-found returns exit code `1`.

### Sample output

`--dry-run`:

```text
[dry-run] Targets:
  - data/strategies/my_strategy_v1.json
  - data/strategies/my_strategy_v1_optimized.json
  - data/results/my_strategy_v1_report.json
  - data/results/optimize_my_strategy_v1_20260415_103021.json
  - DB entry: my_strategy_v1
  Note: data/journal/my_strategy_v1.journal.json is preserved
```

Normal run:

```text
Targets: my_strategy_v1

  ✓ data/strategies/my_strategy_v1.json
  ✓ data/strategies/my_strategy_v1_optimized.json
  ✓ data/results/my_strategy_v1_report.json
  ✓ data/results/optimize_my_strategy_v1_20260415_103021.json
  - data/journal/my_strategy_v1.journal.json (preserved)

Continue? [y/N]: y
✅ Strategy 'my_strategy_v1' has been purged
```

Missing files are reported as warnings only and do not abort the command.

### Differences vs. `delete --with-results`

| Aspect | `delete --with-results` | `purge` |
|--------|-------------------------|---------|
| Strategy JSON | Kept | Deleted |
| `<id>_optimized.json` | Deleted | Deleted |
| `<id>_report.json` | Deleted | Deleted |
| `optimize_<id>_*.json` | Deleted | Deleted |
| Journal | Preserved | Preserved |
| DB entry | Deleted | Deleted |

Use `purge` to wipe a strategy completely; use `delete --with-results` when you want to keep the strategy JSON but clean up related result files.

---

## alpha-forge strategy scaffold

Generate a ready-to-use strategy JSON from a symbol, a set of indicators, and a strategy type. Unlike `create` (which copies a built-in template you must edit), `scaffold` builds the indicators, entry/exit conditions, and risk-management block for you. You must specify **one of** `--output` (write to a file) or `--save` (register in the strategy registry) as the destination; if neither is given the command prints `Error: specify --output and/or --save` and exits with code `1` (it does not print JSON to stdout). This is the primary strategy-generation entrypoint used by the `/explore-strategies` workflow.

!!! tip "Indicator catalog (machine-readable)"
    The indicators accepted by `--indicators`, along with each one's `params` (name / default / type), example, and Pine-conversion support, are queryable via [`alpha-forge analyze indicator list --json`](analyze.md#alpha-forge-analyze-indicator-list) / [`alpha-forge analyze indicator show <NAME> --json`](analyze.md#alpha-forge-analyze-indicator-show). This is the authoritative source for `type` names, parameter names, and defaults when hand-writing a strategy JSON.

### Synopsis

```bash
alpha-forge strategy scaffold --symbol <SYMBOL> --indicators <CSV> --type <TYPE> [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--symbol` | required | - | Target symbol (e.g. `GC=F`, `AAPL`) |
| `--indicators` | required | - | Comma-separated indicators: `BB,SMA,HMM,RSI,EMA,ADX,MACD,ATR,SUPERTREND,STOCH,AROON,LINEAR_REG,PV_CORR,UP_RATIO,CMO,ROLLING_QUANTILE`. Alpha158-derived indicators are type-restricted (AROON/LINEAR_REG/PV_CORR/UP_RATIO: trend-following only; CMO/ROLLING_QUANTILE: mean-reversion only; incompatible types raise ValueError) (a mean-reversion + single EMA/SMA trend filter on FX/commodity tends to signal-starve; alternatives are emitted as a stderr `WARNING`, issue #830) |
| `--type` | required | - | `mean-reversion` \| `trend-following` \| `buy-hold-overlay` |
| `--strategy-id` | optional | auto-generated | `strategy_id` for the generated JSON |
| `--output` | optional | - | Output JSON file path |
| `--save` | flag | false | Save directly to the DB |
| `--no-atr` | flag | false | Skip auto-adding ATR (added by default) |
| `--goal` | optional | - | Goal name auto-applying `scaffold_defaults` from `goals.yaml` (issue #461) |
| `--position-size-pct` | float | type-specific (`mean-reversion`=15.0 / `trend-following`=10.0) | Position size % of equity (issue #461) |
| `--leverage` | float | `1.0` | Leverage multiplier (0=no position, >1=leveraged; issue #461) |
| `--stop-loss-pct` | float | null | Stop-loss % from entry price (issue #461) |
| `--take-profit-pct` | float | null | Take-profit % from entry price (issue #461) |
| `--trailing-stop-pct` | float | null | Trailing-stop % drawdown from peak close (issue #765) |
| `--target-exposure-pct` | float (0<x<=100) | `70.0` | (`buy-hold-overlay` only) Target exposure % during hedge regime (#922 Phase 3) |
| `--hedge-trigger-mode` | `or` \| `and` | `or` | (`buy-hold-overlay` only) Aggregation mode for composite hedge triggers (#964/#965); ignored for single-indicator setups |
| `--commission-pct` | float | inherits `backtest.commission_pct` | Strategy-specific one-way commission % (issue #766) |
| `--slippage-pct` | float | inherits `backtest.slippage_pct` | Strategy-specific one-way slippage % (issue #766) |
| `--cost-preset` | option | - | Cost preset name (issue #785; e.g. `moomoo-crypto-spot`, `binance-spot-vip0`, `oanda-fx-major`, `ibkr-us-stock-fixed`) — explicit `--commission-pct`/`--slippage-pct` win. See [`alpha-forge strategy cost-presets`](#alpha-forge-strategy-cost-presets) |
| `--timeframe` | option | `1d` | Strategy timeframe (e.g. `1d`, `4h`; issue #463/#758) |
| `--confirm-bars` | int | - | Reversal confirmation bars (`mean-reversion` only; issue #470/#473) |
| `--wick-ratio` | float | - | Pin-bar wick-length threshold for reversals (issue #473; effective only when `confirm_bars>=1`) |
| `--vol-tier` | `auto` \| `low` \| `mid` \| `high` | `auto` | Volatility tier controlling mean-reversion SL/TP defaults (issue #886): `low`=0.8%/1.6%, `mid`=1.5%/3.0%, `high`=3.5%/7.0%; `auto` infers from trailing-252d ATR%; explicit SL/TP win |
| `--allow-extreme` | flag | false | Allow 5+ indicators (issue #888); normally aborted to avoid `no_signals`/`pre_filter_failed` |
| `--reject-on-warning` | flag | false | Exit with code `2` (without saving) on any scaffold warning (issue #903) |

### Exit codes

- `0` on success
- `2` when `--reject-on-warning` is set and a scaffold warning is detected
- `1` when generation is aborted (e.g. 5+ indicators without `--allow-extreme`)

---

## alpha-forge strategy validate

Run **logical consistency checks** on a strategy. With `--symbol`, also runs **dynamic checks** (signal counts and condition correlation on real data). Pass a `.json` path as `STRATEGY_ID` to validate an unregistered file directly.

### Synopsis

```bash
alpha-forge strategy validate <STRATEGY_ID|FILE.json> [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `STRATEGY_ID` | argument (required) | - | Strategy ID, or a `.json` file path |
| `--symbol` | option | - | Symbol for dynamic checks (enables dynamic phase) |
| `--period` | option | `1y` | Data period |
| `--min-signals` | int | `30` | Min signal count threshold (warning if below) |
| `--corr-threshold` | float | `0.9` | Correlation warning threshold |
| `--json` | flag | false | Output as JSON |

### Static checks

What `StrategyValidator` checks when `--symbol` is not given (implementation-based):

- Required fields: `strategy_id` / `name` / `version` / `timeframe`
- `indicators[]`: ID uniqueness, reference resolution
- `entry_conditions` / `exit_conditions`: referenced IDs exist
- Condition expressions (`left` / `op` / `right`): syntax and type integrity
- `risk_management`: value ranges (percentages, leverage)
- `regime_config.indicator_id` resolves to a real indicator
- `optimizer_config.param_ranges` keys map to either `parameters` or an indicator `params`

### Dynamic checks (with `--symbol`)

Loads real data and runs a lightweight backtest to gather signal statistics:

- Entry signal count over the period (warns if below `min_signals`)
- True-day count and percentage of each leaf condition
- Pairwise correlation of conditions (warns above `corr_threshold`)

### Sample output (text)

```text
Strategy: spy_sma_crossover_v1  [OK]

[DYNAMIC CHECKS]
  Symbol: SPY  Period: 1y  Total days: 252
  Entry signals: 87 days
  Condition True days:
    sma_fast > sma_slow: 142 days (56.3%)
    rsi < 70: 198 days (78.6%)

✓ No issues detected
```

When errors are detected:

```text
Strategy: my_v1  [NG]

[ERRORS]
  ✗ [E_INDICATOR_REF] Reference 'sma_fast' in condition does not exist in indicators
    → Add { "id": "sma_fast", "type": "SMA", ... } to the indicators array

[WARNINGS]
  ⚠ [W_LOW_SIGNALS] Too few entry signals: 12 days (threshold 30)
    → Loosen the conditions or extend the data period

  [CORRELATION]
    ⚠ rsi < 70 × close > sma_fast: 0.94
      → Drop one of the highly correlated conditions, or replace with an independent one
```

### Sample output (`--json`)

Static checks are returned under `static_checks`; dynamic checks (only when `--symbol` is given) are returned as a nested `dynamic_checks` object (without `--symbol`, `dynamic_checks` is omitted entirely).

```json
{
  "ok": false,
  "strategy_id": "my_v1",
  "static_checks": {
    "errors": [
      {"code": "E_INDICATOR_REF", "severity": "error", "message": "...", "suggestion": "..."}
    ],
    "warnings": []
  },
  "dynamic_checks": {
    "symbol": "SPY",
    "period": "1y",
    "total_days": 252,
    "entry_signal_days": 12,
    "signal_rate_pct": 4.8,
    "leaf_conditions": [
      {"description": "rsi < 30", "true_days": 18, "total_days": 252, "true_pct": 7.1}
    ],
    "hmm_regime_days": null,
    "warnings": [
      {"code": "W_LOW_SIGNALS", "severity": "warning", "message": "...", "suggestion": "..."}
    ],
    "correlations": []
  }
}
```

### Exit codes

- `result.ok = true` → `0`
- `result.ok = false` (errors detected) → `1`

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: file not found - <path>` | `.json` path not found | Verify the path |

---

## alpha-forge strategy cost-presets

List the built-in cost presets (broker/exchange fee + slippage + spread profiles). Use a preset name with `alpha-forge strategy scaffold --cost-preset <NAME>` or `alpha-forge backtest run ... --cost-preset <NAME>` to bake `commission_pct` / `slippage_pct` / `spread_pct` into the strategy (issue #785).

### Synopsis

```bash
alpha-forge strategy cost-presets [--json]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--json` | flag | false | Output as JSON |

---

## alpha-forge strategy signals

Count entry signals, estimated trades, and WFT window coverage without running optimization or WFT (#321).

```bash
alpha-forge strategy signals <SYMBOL> --strategy <NAME> [--period <PERIOD>] [--json]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--strategy` | Strategy name (required) | — |
| `--period` | Historical data period | `5y` |
| `--json` | Output as JSON | off |

#### Text output example

```
📊 Signal Summary: my_rsi_v1 / SPY (5y)
  Long signals:      45 days
  Estimated trades:  38
  Avg trades/year:   7.6
  WFT coverage:      low (5-10 trades/window)
```

#### JSON output example

```json
{
  "strategy_id": "my_rsi_v1",
  "symbol": "SPY",
  "period": "5y",
  "total_days": 1260,
  "long_signals": 45,
  "short_signals": 0,
  "estimated_trades": 38,
  "avg_per_year": 7.6,
  "wft_window_coverage": "low (5-10 trades/window)"
}
```

| Field | Description |
|-------|-------------|
| `long_signals` | Number of days with long entry signal |
| `estimated_trades` | Estimated trades (counted as signal blocks) |
| `avg_per_year` | Average trades per year |
| `wft_window_coverage` | Coverage assessment based on trades per WFT window |

---

## Common behavior

- **Storage**: When `config.strategies.use_db` is true, uses `SQLiteStrategyRepository`; otherwise file-based. Switch via `forge.yaml`.
- **Locations**: `config.strategies.path` (strategy JSON), `config.report.output_path` (backtest / optimization results), `config.journal.journal_path` (journal).
- **Journal integration**: When `config.journal.auto_record` is true, `save` automatically records a journal snapshot.
- **`FORGE_CONFIG`**: All paths above are determined by the `forge.yaml` referenced by the `FORGE_CONFIG` environment variable.
- **Exit codes**: `0` on success; `validate` returns `1` when errors are detected; argument errors return Click's `2`; runtime errors typically `1`. Note that missing-resource cases (e.g. `strategy show <nonexistent_id>`) intentionally exit with code `2` so that scripts piping `--json` output do not break on `json.load(stdout)` (issue #782).

---

<!-- Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/strategy.py` and `_TEMPLATE_REGISTRY` in `alpha-forge/src/alpha_forge/strategy/templates.py`. This page must be kept in sync when CLI arguments or templates change. -->
