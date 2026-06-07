# alpha-forge explore

Manage exploration pipeline state and run the full pipeline in one command. These commands are used internally by the AI agent skill `/explore-strategies`.

| Subcommand | Description |
|-----------|-------------|
| `run` | Run backtest → optimize → WFT → DB registration end-to-end (**main command**) |
| `import` | Bulk-import a Markdown log into the exploration DB |
| `log` | Manually record an exploration trial to the DB |
| `status` | Show coverage map against a goal |
| `result` | Show details of the latest trial saved in the exploration DB |
| `diagnose` | Estimate whether a longer backtest period would let a WFT-failed strategy pass, via linear extrapolation of the trade rate (issue #685) |
| `health` | Detect consecutive failures and scaffold fixation from recent trials (quality gate for unattended runs) |
| `recommend` | Write next-exploration candidates to `recommendations.yaml` |
| `coverage` | Update or view parameter coverage YAML |

## alpha-forge explore run

Runs validation → auto data fetch → backtest → optimize → walk-forward test (WFT) → coverage update → DB registration in a single command. Returns exit code 1 on failure (except `--dry-run` / `--pre-check`).  
Called internally by the `/explore-strategies` agent skill.

```bash
alpha-forge explore run <SYMBOL> --strategy <NAME> --goal <GOAL> [--no-cleanup] [--dry-run] [--pre-check] [--json] [--db <PATH>]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--strategy` | Strategy name (required) | — |
| `--goal` | Goal name — applies `pre_filter` / `target_metrics` from `goals.yaml` | `default` |
| `--no-cleanup` | Skip file / DB cleanup on failure (for debugging) | off |
| `--dry-run` | Print planned steps and exit without running | off |
| `--pre-check` | Run backtest only (default params), skip optimization and WFT (#321) | off |
| `--json` | Output result as JSON to stdout (**deprecated**: use `alpha-forge explore result show <id> --json` instead) | off |
| `--db` | Path to exploration DB (defaults to path from `forge.yaml`) | — |

### Using `--pre-check`

Use for rapid screening during strategy design. Optimization and WFT are not executed.

```bash
alpha-forge explore run SPY --strategy my_rsi_v1 --pre-check
alpha-forge explore run SPY --strategy my_rsi_v1 --pre-check --json
```

Sample text output with `--pre-check`:

```
📊 Pre-check (backtest, default params)
  Sharpe:     0.821
  MaxDD:      19.9%
  Trades:     24 ⚠️ low (may be insufficient for WFT windows)
  Signals:    31
  Pre-filter: FAIL ❌

→ Optimization and WFT are skipped.
```

### Output JSON example

```json
{
  "symbol": "SPY",
  "strategy_id": "spy_hmm_rsi_v3",
  "passed": false,
  "backtest": {
    "sharpe": 0.82,
    "max_dd": 19.9,
    "trades": 42
  },
  "pre_filter_pass": true,
  "wft_avg_sharpe": 1.12,
  "wft_target": 1.5,
  "skip_reason": "wft_failed",
  "cleanup_done": true,
  "entry_signals": 31
}
```

| Field | Description |
|-------|-------------|
| `passed` | `true` when WFT meets `target_metrics` |
| `skip_reason` | Reason for skip/failure: `validation_failed` / `no_signals` / `pre_filter_failed` / `wft_failed` / `pre_check_only` / `dry_run` / `null` |
| `cleanup_done` | `true` when strategy JSON and result JSON were automatically removed on failure |
| `entry_signals` | Number of days with long entry signal (set during `--pre-check`; may be `null` for backward compatibility) |

## alpha-forge explore result show

Display the latest exploration result for a strategy from the DB. Use this to inspect failure details after `alpha-forge explore run` exits with code 1.

```bash
alpha-forge explore result show <STRATEGY_ID> [--goal <GOAL>] [--json] [--db <PATH>]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--goal` | Filter by goal name | — |
| `--json` | Output result as JSON to stdout | off |
| `--db` | Path to exploration DB (defaults to path from `forge.yaml`) | — |

### Examples

```bash
# Display latest result in human-readable format
alpha-forge explore result show gc_bb_hmm_rsi_v1

# Filter by goal and output as JSON (includes wft_diagnostics and more)
alpha-forge explore result show gc_bb_hmm_rsi_v1 --goal commodities --json
```

Typical failure investigation flow after `alpha-forge explore run` returns exit code 1:

```bash
FORGE_CONFIG=forge.yaml alpha-forge explore run GC=F --strategy gc_bb_hmm_rsi_v1 --goal commodities
# exit code 1 → retrieve details from DB
FORGE_CONFIG=forge.yaml alpha-forge explore result show gc_bb_hmm_rsi_v1 --goal commodities --json
```

The `--json` output includes `wft_diagnostics`, `pre_filter_diagnostics`, and `opt_metrics` fields.

### pre_filter_diagnostics structure (issue #409)

When `skip_reason: "pre_filter_failed"`, the `pre_filter_diagnostics` field contains a
structured `{value, threshold, passed, gap}` object for each criterion so autonomous
exploration agents can decide programmatically which criterion failed and by how much.

```json
{
  "pre_filter_diagnostics": {
    "sharpe_ratio":      {"value": 0.716, "threshold": 1.0,  "passed": false, "gap": -0.284},
    "max_drawdown":      {"value": 1.66,  "threshold": 25.0, "passed": true,  "gap": 23.34},
    "trades":            {"value": 16,    "threshold": 30,   "passed": false, "gap": -14},
    "monthly_volume_usd":{"value": 10606.43, "threshold": 0.0, "passed": null, "note": "未チェック（monthly_volume_usd_min が 0 以下です）"},
    "verdict": "failed",
    "failed_criteria": ["sharpe_ratio", "trades"]
  }
}
```

| Field | Description |
|-------|-------------|
| `value` | Observed metric from the backtest. `monthly_volume_usd` is also computed, but when its threshold (`monthly_volume_usd_min`) is 0 or below it is treated as "not evaluated" — `passed` becomes `null` and a `note` is attached, while `value` itself is still computed. The `note` text is emitted in Japanese regardless of locale |
| `threshold` | Threshold resolved from the `pre_filter` section of goals.yaml |
| `passed` | Whether the criterion is met (`null` means not evaluated) |
| `gap` | "value − threshold" (for `max_drawdown` it is "threshold − value"). Negative = shortfall, positive = headroom |
| `verdict` | `"passed"` if all criteria pass, otherwise `"failed"` |
| `failed_criteria` | Names of failed criteria in stable order: `sharpe_ratio` → `max_drawdown` → `trades` |

### wft_diagnostics structure (issue #684)

When `skip_reason` is `"wft_insufficient_oos_data"` or `"wft_no_valid_oos_windows"`, the `wft_diagnostics` field contains structured per-window verdicts and an aggregate summary, mirroring the style of `pre_filter_diagnostics`. Agents can determine which windows failed and why.

```json
{
  "wft_diagnostics": {
    "total_oos_trades": 17,
    "oos_trades_by_window": [3, 3, 0, 6, 5],
    "valid_windows": 4,
    "required_valid_windows": 3,
    "min_oos_trades_per_window": 3,
    "windows": [
      {
        "window_index": 1,
        "oos_trades": 3,
        "oos_metric": -0.01,
        "valid": true,
        "skip_reason": null,
        "failed_criteria": [],
        "criteria": {
          "min_trades":     {"value": 3, "threshold": 3, "passed": true, "gap": 0},
          "metric_finite":  {"value": -0.01, "passed": true}
        }
      },
      {
        "window_index": 3,
        "oos_trades": 0,
        "oos_metric": null,
        "valid": false,
        "skip_reason": null,
        "failed_criteria": ["min_trades", "metric_finite"],
        "criteria": {
          "min_trades":     {"value": 0, "threshold": 3, "passed": false, "gap": -3},
          "metric_finite":  {"value": null, "passed": false}
        }
      }
    ],
    "summary": {
      "total_windows": 5,
      "valid_windows": 4,
      "required_valid_windows": 3,
      "min_required_trades": 3,
      "min_valid_windows_ratio": 0.6,
      "min_trades_violated_windows": [3],
      "metric_invalid_windows": [3],
      "skipped_windows": []
    }
  }
}
```

| Field | Description |
|-------|-------------|
| `windows[].window_index` | 1-based window index |
| `windows[].oos_trades` | Number of trades during the OOS period |
| `windows[].oos_metric` | OOS optimization metric (NaN/inf normalized to `null`) |
| `windows[].valid` | True iff both `min_trades` and `metric_finite` pass |
| `windows[].failed_criteria` | List of failed criteria (`min_trades`, `metric_finite`, `window_skip:<reason>`) |
| `windows[].criteria` | Per-criterion `{value, threshold, passed, gap}` |
| `summary.min_trades_violated_windows` | 1-based indices where `min_trades` failed |
| `summary.metric_invalid_windows` | 1-based indices where the metric was NaN/inf/None |
| `summary.skipped_windows` | 1-based indices where the engine itself skipped the window |
| `summary.required_valid_windows` | Required valid windows = `ceil(total × min_valid_windows_ratio)` |

The legacy fields (`total_oos_trades`, `oos_trades_by_window`, `valid_windows`, `required_valid_windows`, `min_oos_trades_per_window`) are kept alongside the new fields for backward compatibility.

## alpha-forge explore diagnose

Estimate whether a longer backtest period would let a WFT-failed strategy pass, using linear extrapolation of the trade rate (issue #685). Designed as a follow-up to `alpha-forge explore result show` when you see `wft_failed`.

```bash
alpha-forge explore diagnose <STRATEGY_ID> [--goal <GOAL>] [--periods 10y,20y,30y] \
                                    [--windows 5] [--min-oos-trades 3] \
                                    [--db <PATH>] [--json]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--goal` | Filter records by goal | DB-attached goal |
| `--periods` | Comma-separated periods to evaluate (e.g. `10y,20y,30y`) | `10y,20y,30y` |
| `--windows` | WFT window count | `goals.yaml` wft config or `5` |
| `--min-oos-trades` | Required OOS trades per window | `goals.yaml` wft config or `3` |
| `--json` | JSON output | off |

### Extrapolation logic

- `trade_rate = total_trades / current_period_years`
- For each scenario: `expected = trade_rate × (period / windows)`
- `ratio = expected / min_oos_trades_per_window`
- `pass_probability`: ratio>=3 → 90%, >=2 → 70%, >=1.5 → 50%, >=1 → 30%, <1 → 0%
- `recommendation` is the **shortest period** that meets ≥0.7. Falls back to ≥0.5, then highest. Returns `null` if all scenarios are 0.

### Sample output

```
WFT diagnose: nvda_ema_macd_supertrend_lt_v1 (symbol=NVDA, goal=long-term-stocks, skip_reason=wft_failed)

Current observation:
  backtest_period: 20.0y  total_trades: 1167  trade_rate: 58.35/y
  wft_windows: 5  min_oos_trades_per_window: 3

Extrapolation by period:
  ✓ 10.0y / 2.0y/window → ~116.7 trades/window (req 3, ratio 38.9, pass_prob ≈ 90%)
  ✓ 20.0y / 4.0y/window → ~233.4 trades/window (req 3, ratio 77.8, pass_prob ≈ 90%)
  ✓ 30.0y / 6.0y/window → ~350.1 trades/window (req 3, ratio 116.7, pass_prob ≈ 90%)

Recommendation:
  goals.yaml: exploration.backtest_period: "10y"
  alpha-forge data fetch NVDA --provider yfinance --period 10y --interval 1d
  Estimated pass probability: ~90% (tier: high)
```

## alpha-forge explore health

Aggregate the most recent N trials and detect consecutive failures or scaffold fixation (issue #408). Designed to be invoked at the start of every iteration of the unattended `/explore-strategies --runs 0` loop, so structural failures (scaffold bugs, goals.yaml drift) can be caught early instead of burning runs forever.

```bash
alpha-forge explore health --goal <GOAL> [--last N] [--strict] [--json] [--db <PATH>]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--goal` | Goal name to aggregate | `default` |
| `--last` | Number of recent trials to analyze | `5` |
| `--strict` | Exit with code `1` when `escalation: true` (used to break the unattended loop). Returns `0` when only `warning: true` (issue #467) | off |
| `--json` | Output result as JSON to stdout | off |
| `--db` | Path to exploration DB (defaults to path from `forge.yaml`) | — |

### Output JSON example

```json
{
  "goal": "default",
  "last_n": 5,
  "pass_rate": 0.0,
  "failure_breakdown": {"pre_filter_failed": 3, "no_signals": 2},
  "scaffold_transformation_rate": 1.0,
  "most_common_combo": "ATR+BB+RSI",
  "same_combo_streak": 5,
  "escalation": true,
  "warning": false,
  "escalation_type": "scaffold_degradation",
  "major_indicator_concentration": {"EMA": 0.8, "SUPERTREND": 0.4, "BB": 0.2},
  "recommended_actions": [
    "Pass rate over the last 5 trials is 0%. Check pre_filter thresholds, target symbols, and candidate indicators in goals.yaml.",
    "All recent trials had their indicators transformed by the scaffold. Inspect the indicator filters in `alpha_forge.strategy.scaffold` (see alpha-forge issues #399 and #400)."
  ]
}
```

| Field | Description |
|-------|-------------|
| `last_n` | Actual number of trials analyzed (capped by DB row count when fewer than `--last` exist) |
| `pass_rate` | Ratio of trials with `passed=True` (0.0–1.0) |
| `failure_breakdown` | Failure counts grouped by `skip_reason` |
| `scaffold_transformation_rate` | Ratio of trials whose scaffold transformed the requested indicators (excluding the auto-added ATR-only case) |
| `same_combo_streak` | How many of the most recent trials share the same `indicator_combo` |
| `escalation` | `true` when `pass_rate==0` AND scaffold-related root cause (`scaffold_transformation_rate>=0.5` or mid-range). Hard-stop signal (issue #467) |
| `warning` | `true` when `pass_rate==0` AND `same_combo_streak==last_n` AND `scaffold_transformation_rate<=0.1` (only `agent_selection_bias`). Loop continues (exit 0) and the agent is expected to switch to a different indicator combo on the next run (issue #467) |
| `escalation_type` | Cause classification (issues #436 / #467): `"scaffold_degradation"` (escalation) / `"agent_selection_bias"` (warning) / `null` |
| `major_indicator_concentration` | **Indicator-level concentration** over the recent N scaffold trials (issue #858). Maps `{indicator: containment_ratio (0–1)}` — `dominant_combo` aggregates full-string combos, so `ATR+EMA+SUPERTREND` and `ATR+EMA+HMM+SMA` are distinct, but this field aggregates per indicator and exposes dominant indicators like `EMA`. `ATR` is excluded (auto-added by scaffold) |
| `recommended_actions` | Human-facing remediation hints derived from the detected pattern |

### Escalation rules

If the DB contains fewer than `--last` rows for the goal, the report stays observational (`escalation: false` and `warning: false` are both forced) and never blocks the loop. Once enough history accumulates, the report takes one of the following shapes:

- 0% pass rate and scaffold transformation rate `>= 50%` → `escalation: true` / `escalation_type: "scaffold_degradation"` (hard stop)
- 0% pass rate and all of the most recent N trials share the same `indicator_combo`:
  - scaffold transformation rate `<= 10%` → `warning: true` / `escalation: false` / `escalation_type: "agent_selection_bias"` (loop continues; downgraded to warning by issue #467 because the agent can resolve it by picking a different combo)
  - mid-range (10% < rate < 50%) → conservatively classified as `escalation: true` / `"scaffold_degradation"`

### Use inside the unattended skill

```bash
# Run at the start of every iteration of /explore-strategies
FORGE_CONFIG=forge.yaml alpha-forge explore health \
  --goal default --last 5 --strict --json
# exit code 1 → surface recommended_actions to a human and break the loop
```

---

## alpha-forge explore recommend show

Displays the next exploration candidates from `recommendations.yaml` (produced by auto-relax / analyze-exploration).

```bash
alpha-forge explore recommend show [--recs <path>] [--json] [--validated-only]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--recs <path>` | Path to `recommendations.yaml` | `data/explorer/recommendations.yaml` |
| `--json` | Emit JSON | off |
| `--validated-only` | **Strict mode: only show candidates whose consumable `strategy_id` exists in the DB** (intended for agent consumption, issue #831) | off |

### Agent consumption notes (issue #831)

Each candidate carries two fields: `strategy_id` (the consumable identifier) and `variant_of` (a reference to the base strategy it was derived from). When passing a candidate to `explore run` / `backtest run`, **always use `strategy_id`**. Using `variant_of` often fails with `ValueError: Unknown template name` because the base is no longer registered in the DB / template registry.

Example output (post issue #831):

```text
Recommendations (auto-relax / 2026-05-19T13:10:59+00:00)
  #1 NVDA ATR+EMA+SUPERTREND (score=1.083) [strategy_id: nvda_ema_supertrend_v2_optimized] [variant of nvda_ema_supertrend_v2 (missing)]
     auto-relax variant
```

- `[strategy_id: ...]` is what agents / users should pass to `--strategy`.
- `[variant of <id> (missing)]` — the `(missing)` marker indicates the base is no longer in the DB (informational only — do not consume it).
- Candidates with `strategy_id=None` AND a DB-missing `variant_of` are automatically removed from the file.
- With `--validated-only`, only candidates whose `strategy_id` exists in the DB are shown, so agents can safely forward the value to `--strategy`.

---
