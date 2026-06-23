# Strategy Design Patterns

AlphaForge is a **development and validation platform built for users to grow their own strategies**. The distributed binary ships a curated set of 7 strategies (4 basic + 1 range + 2 advanced-indicator references), and this page is a **collection of design patterns for assembling your own strategy JSON** on top of them.

!!! info "How to read this page"
    - The IDs of the 7 built-in strategies are listed in the [CLI reference: alpha-forge strategy](cli-reference/strategy.md).
    - The JSON examples on this page are written as templates for **building your own custom strategy**; the `strategy_id` values use placeholder `my_*` names. Replace them with meaningful names of your own and register via `alpha-forge strategy save`.
    - Backtest result numbers are illustrative. Actual values depend on data and environment (fetch period, provider, settings).

## Three design patterns on this page

| Pattern | Strategy type | Key indicators | Learning focus |
|---------|---------------|----------------|----------------|
| [HMM × BB × RSI](#hmm-bb-rsi) | Regime-adaptive mean reversion | HMM / BBANDS / RSI | HMM regime detection + intermediate `variables` design |
| [Regime switching](#regime-switching) | Per-regime strategy switching | HMM / SUPERTREND / BBANDS / RSI | Switching entry / exit / risk per regime via `regime_config` |
| [Multi-timeframe](#multi-timeframe) | Higher-TF trend × daily entry | Weekly SMA / RSI / ATR | MTF confluence with `indicators[].timeframe` |

These go one step beyond the built-in `hmm_bb_pipeline_v1` (HMM example) and `donchian_turtle_v1` (classic Turtle trend follower) shipped with the binary, and serve as design guidance when you "start from the 7 built-ins and customize."

## Strategy JSON basics

Every strategy follows the same Pydantic schema. Indicator details are available via [`alpha-forge analyze indicator list`](cli-reference/analyze.md#alpha-forge-analyze-indicator-list).

```text
{
  "strategy_id": "...",
  "name": "...",
  "target_symbols": [...],
  "asset_type": "stock",
  "timeframe": "1d",
  "parameters": {...},          // Top-level parameters subject to optimization
  "indicators": [...],          // Computed indicators (30+ types)
  "variables": [...],           // Intermediate boolean variables (optional)
  "entry_conditions": {...},    // Entry conditions
  "exit_conditions": {...},     // Exit conditions
  "risk_management": {...},     // Position size, SL/TP
  "regime_config": {...},       // Regime adaptation (optional)
  "optimizer_config": {...}     // Optimization parameter ranges
}
```

![Strategy JSON Schema Structure](assets/illustrations/templates/strategy-json-schema-tree.png)

!!! note "About `schema_version` (schema generation, issue #1175)"
    A strategy JSON may carry an integer `schema_version` that denotes the schema generation for product management (distinct from the free-form user `version` field). It is checked on load, and **JSON with a `schema_version` newer than the current CLI is rejected with an explicit error**, prompting you to update the CLI. Older versions or no version at all (including existing JSON without a `schema_version` key) are read with backward compatibility, so you do not need to add it manually.

Key concepts:

- **`indicators[].lock_on_entry: true`** — Freeze the value at the entry bar (used for SL/TP prices)
- **`indicators[].timeframe: "1w"`** — Pull values from a higher timeframe (multi-timeframe)
- **`EXPR` indicator** — Arbitrary pandas expression (e.g., `"close * 0.98"`)
- **`HMM` indicator** — Hidden Markov Model regime detection
- **`regime_config`** — Switch `entry/exit/risk_override` per regime, keyed on the HMM output

![Indicator Calculation Flow (HMM × BB × RSI)](assets/illustrations/templates/indicator-calculation-dag.png)

---

## HMM × BB × RSI

### Overview

Mean-reversion entries triggered by **Bollinger Band lower break + RSI oversold**, filtered through a **3-state HMM regime detector**. Bull/Neutral/Bear regimes are distinguished, with aggressive leverage in Bull (5x), conservative in Neutral (3x), and skip in Bear.

The strength of this template is **managing three regimes within a single strategy JSON**. A mean-reversion strategy that works in range markets is automatically muted (or fully paused) when trends are too strong or too weak — keeping drawdowns under control.

![HMM 3-State Regime Transition](assets/illustrations/templates/hmm-state-transition-diagram.png)

### Suitable scenarios

- **Symbols**: US large-cap ETFs (QQQ, SPY), growth stocks (NVDA), instruments with low long-horizon transaction costs
- **Market environment**: Mid-to-long-term regimes alternating between trend and range (like 2018-2025)
- **Holding period**: Days to ~2 weeks
- **Risk profile**: Leverage-friendly (up to 5x); HMM mis-detection can amplify drawdowns

### Strategy JSON (full)

```json
{
  "strategy_id": "my_hmm_bb_rsi_v1",
  "name": "Multi-Asset HMM×BB+RSI v1 (QQQ)",
  "version": "1.0.0",
  "description": "HMM 3-state regime filter × BB+RSI mean reversion. Bull(state=0): long on BB-lower + RSI oversold (leverage=5). Neutral(state=1): same condition (leverage=3). Bear(state=2): skip. Daily.",
  "target_symbols": ["QQQ"],
  "asset_type": "stock",
  "timeframe": "1d",
  "parameters": {
    "rsi_oversold_th": 35,
    "atr_mult": 2.0
  },
  "indicators": [
    { "id": "regime",   "type": "HMM",     "params": { "n_components": 3, "features": ["return", "volatility"] } },
    { "id": "bb_lower", "type": "BBANDS",  "params": { "length": 20, "std": 2.0, "line": "lower" } },
    { "id": "bb_mid",   "type": "BBANDS",  "params": { "length": 20, "std": 2.0, "line": "mid" } },
    { "id": "rsi",      "type": "RSI",     "params": { "length": 7 } },
    { "id": "atr",      "type": "ATR",     "params": { "length": 14 } },
    { "id": "sl_dist",  "type": "EXPR",    "params": { "expr": "atr * atr_mult" }, "lock_on_entry": true }
  ],
  "variables": [],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [] } },
  "exit_conditions":  { "long": { "logic": "OR",  "conditions": [] } },
  "risk_management": {
    "leverage": 5.0,
    "position_sizing_method": "fixed",
    "position_size_pct": 100.0,
    "stop_loss_indicator": "sl_dist",
    "max_positions": 1
  },
  "regime_config": {
    "indicator_id": "regime",
    "default_action": "skip",
    "states": {
      "0": {
        "entry_conditions": { "long": { "logic": "AND", "conditions": [
          { "left": "close", "op": "<", "right": "bb_lower" },
          { "left": "rsi",   "op": "<", "right": "rsi_oversold_th" }
        ]}},
        "exit_conditions":  { "long": { "logic": "OR",  "conditions": [
          { "left": "close", "op": ">", "right": "bb_mid" }
        ]}},
        "risk_override": { "leverage": 5.0, "position_sizing_method": "fixed", "position_size_pct": 100.0 }
      },
      "1": {
        "entry_conditions": { "long": { "logic": "AND", "conditions": [
          { "left": "close", "op": "<", "right": "bb_lower" },
          { "left": "rsi",   "op": "<", "right": "rsi_oversold_th" }
        ]}},
        "exit_conditions":  { "long": { "logic": "OR",  "conditions": [
          { "left": "close", "op": ">", "right": "bb_mid" }
        ]}},
        "risk_override": { "leverage": 3.0, "position_sizing_method": "fixed", "position_size_pct": 100.0 }
      },
      "2": {}
    }
  },
  "backtest_config": {
    "regime_analysis": {
      "method": "hmm",
      "hmm_indicator_id": "regime",
      "label_names": { "0": "Bull", "1": "Neutral", "2": "Bear" }
    }
  },
  "optimizer_config": {
    "param_ranges": {
      "bb_lower.length": { "min": 15,  "max": 25,  "step": 1 },
      "bb_lower.std":    { "min": 1.8, "max": 2.5, "step": 0.1 },
      "rsi.length":      { "min": 5,   "max": 14,  "step": 1 },
      "rsi_oversold_th": { "min": 25,  "max": 45,  "step": 5 },
      "atr_mult":        { "min": 1.5, "max": 3.0, "step": 0.5 }
    },
    "constraints": { "min_trades": 20 },
    "metric": "sharpe_ratio"
  },
  "tags": ["hmm", "bb", "rsi", "mean-reversion", "leverage", "nas100"]
}
```

### Key parameters

| Parameter | Role | Recommended range |
|-----------|------|-------------------|
| `regime.n_components` | HMM state count | `3` (Bull/Neutral/Bear) |
| `regime.features` | HMM input features | `["return", "volatility"]` |
| `bb_lower.length` / `std` | BB period and std multiplier | period `15-25`, std `1.8-2.5` |
| `rsi.length` | RSI period | `5-14` (shorter = more responsive) |
| `rsi_oversold_th` | Entry threshold | `25-45` (lower = stricter) |
| `atr_mult` | ATR-based SL multiplier | `1.5-3.0` |
| `risk_override.leverage` | Per-regime leverage | Bull `5.0` / Neutral `3.0` / Bear `0` (skip) |

### Sample backtest output

!!! warning "Sample output"
    Numbers depend on data and environment.

```text
==> QQQ 2018-01-01 → 2025-12-31 (1d)
   trades: 38   win_rate: 65.8%   profit_factor: 2.15
   total_return: +124.5%   cagr: +10.7%   sharpe: 1.42
   max_drawdown: -18.4%   exposure: 24.3%
   final_equity: $22,450  (initial: $10,000)
```

### Customization tips

- **Change the symbol**: Replace `target_symbols` with `["SPY"]`, `["NVDA"]`, `["GC=F"]`, etc.
- **Change state count**: `regime.n_components: 2` (Bull/Bear) simplifies the decision; `4` adds nuance (requires more data)
- **Strengthen entry**: Add `volume > sma_volume_20` or similar conditions in `regime_config.states["0"].entry_conditions`
- **Optimize**: `alpha-forge optimize run QQQ --strategy my_hmm_bb_rsi_v1 --metric sharpe_ratio --save`

---

## Regime switching

### Overview

A pattern that **applies different strategies per regime**, keyed on HMM output. Within a single strategy JSON, the Bull regime runs trend-following and the Bear/Range regime runs mean reversion — **swapping the strategy itself** rather than just parameters.

The defining feature versus HMM × BB × RSI: `regime_config.states` lets you define `entry_conditions` and `exit_conditions` **completely independently per regime**.

### Suitable scenarios

- **Symbols**: Commodity futures (CL=F, GC=F, NG=F) — high-volatility instruments with clear trend/range alternation
- **Market environment**: Capture both trend and counter-trend behavior typical of commodity markets
- **Holding period**: Days to a month
- **Risk profile**: High leverage (10x) + ATR-based SL; assumes margin-based commodity trading

### Strategy JSON (full)

```json
{
  "strategy_id": "my_regime_switching_v1",
  "name": "Commodity HMM Regime v1",
  "version": "1.0.0",
  "description": "Regime-adaptive for commodity CFDs: HMM 2-state Bull/Bear. Bull = SuperTrend long, Bear = BB+RSI mean reversion. leverage=10.",
  "target_symbols": ["GC=F", "SI=F", "CL=F", "BZ=F", "NG=F", "ZC=F", "ZS=F", "ZW=F", "HG=F"],
  "asset_type": "stock",
  "timeframe": "1d",
  "parameters": {
    "adx_threshold": 20,
    "rsi_threshold": 35,
    "atr_mult": 2.0
  },
  "indicators": [
    { "id": "regime",         "type": "HMM",        "params": { "n_components": 2, "features": ["return", "volatility"], "volatility_window": 10 } },
    { "id": "supertrend_val", "type": "SUPERTREND", "params": { "length": 9, "multiplier": 3.0 } },
    { "id": "adx_val",        "type": "ADX",        "params": { "length": 14 } },
    { "id": "bb_lower",       "type": "BBANDS",     "params": { "length": 20, "std": 2.0, "line": "lower" } },
    { "id": "bb_mid",         "type": "BBANDS",     "params": { "length": 20, "std": 2.0, "line": "mid" } },
    { "id": "rsi",            "type": "RSI",        "params": { "length": 14 } },
    { "id": "atr",            "type": "ATR",        "params": { "length": 14 } },
    { "id": "sl_dist",        "type": "EXPR",       "params": { "expr": "atr * atr_mult" }, "lock_on_entry": true }
  ],
  "variables": [],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [] } },
  "exit_conditions":  { "long": { "logic": "OR",  "conditions": [] } },
  "risk_management": {
    "leverage": 10.0,
    "position_sizing_method": "risk_based",
    "risk_per_trade_pct": 1.5,
    "stop_loss_indicator": "sl_dist",
    "max_positions": 1
  },
  "regime_config": {
    "indicator_id": "regime",
    "states": {
      "0": {
        "entry_conditions": { "long": { "logic": "AND", "conditions": [
          { "left": "close",   "op": "crosses_above", "right": "supertrend_val" },
          { "left": "adx_val", "op": ">",             "right": "adx_threshold" }
        ]}},
        "exit_conditions":  { "long": { "logic": "OR",  "conditions": [
          { "left": "close", "op": "crosses_below", "right": "supertrend_val" }
        ]}}
      },
      "1": {
        "entry_conditions": { "long": { "logic": "AND", "conditions": [
          { "left": "close", "op": "<", "right": "bb_lower" },
          { "left": "rsi",   "op": "<", "right": "rsi_threshold" }
        ]}},
        "exit_conditions":  { "long": { "logic": "OR",  "conditions": [
          { "left": "close", "op": ">", "right": "bb_mid" }
        ]}}
      }
    }
  },
  "backtest_config": {
    "regime_analysis": {
      "method": "hmm",
      "hmm_indicator_id": "regime",
      "label_names": { "0": "Bull", "1": "Bear" }
    }
  },
  "optimizer_config": {
    "param_ranges": {
      "supertrend_val.multiplier": { "min": 2.0, "max": 4.0, "step": 0.5 },
      "adx_threshold":             { "min": 15,  "max": 30,  "step": 5 },
      "rsi_threshold":             { "min": 25,  "max": 45,  "step": 5 },
      "atr_mult":                  { "min": 1.5, "max": 3.0, "step": 0.5 }
    },
    "constraints": { "min_trades": 15 },
    "metric": "sharpe_ratio"
  },
  "tags": ["hmm", "regime", "adaptive", "commodity", "leverage-10"]
}
```

### Key parameters

| Parameter | Role | Recommended range |
|-----------|------|-------------------|
| `regime.n_components` | HMM state count | `2` (simple Bull/Bear switch) |
| `regime.volatility_window` | Volatility computation window | `10` (short) to `30` (mid) |
| `supertrend_val.multiplier` | SuperTrend channel width | `2.0-4.0` (smaller = more responsive) |
| `adx_threshold` | Trend strength threshold | `15-30` (≥25 = strong trend) |
| `rsi_threshold` | Mean-reversion oversold threshold | `25-45` |
| `risk_per_trade_pct` | % risk per trade | `1.5` (conservative) |
| `leverage` | Commodity futures leverage | `10` (margin trading assumed) |

### Sample backtest output

!!! warning "Sample output"

```text
==> CL=F 2018-01-01 → 2025-12-31 (1d)
   trades: 27   win_rate: 51.9%   profit_factor: 1.82
   total_return: +88.3%   cagr: +8.4%   sharpe: 1.21
   max_drawdown: -22.1%   exposure: 31.5%
```

Running a strategy that sets `backtest_config.regime_analysis` with `--regime` adds a per-regime performance block (numbers are illustrative):

```text
=== Per-Regime Performance ===
  Bull      : Trades= 14 | Sharpe=  1.45 | WinRate= 57.1% | MDD=  12.30%
  Bear      : Trades= 13 | Sharpe=  0.92 | WinRate= 46.2% | MDD=  22.10%
```

!!! note "Output structure"
    With `--json`, the `regime_breakdown` key is returned as `{ "method", "description", "periods": [...], "aggregates": {...} }`. Each entry in `periods` holds fields such as `label / start / end / sharpe / total_trades` for a contiguous regime segment, and `aggregates` holds per-label averages (such as `sharpe_avg`).

### Customization tips

- **Add more states**: `n_components: 3` for Bull/Range/Bear; add `states["2"]`
- **Switch to equities**: Replace `target_symbols` with stocks and lower `risk_management.leverage` to `1.0-2.0`
- **More entries**: Loosen each regime's `entry_conditions` (e.g., `adx_threshold: 15`, `rsi_threshold: 45`)
- **Cross-symbol optimize**: `alpha-forge optimize cross-symbol GC=F SI=F CL=F --strategy my_regime_switching_v1 --aggregation min --save`

---

## Multi-timeframe

### Overview

Use the `indicators[].timeframe` field to **pull higher-timeframe values** while entering on the lower timeframe. Judge a long-term trend on the weekly SMA and time pullback entries on the daily RSI.

!!! info "Educational example"
    The strategy JSON in this section is written as an example of the `indicators[].timeframe` feature. Validate behavior with [`alpha-forge strategy validate`](cli-reference/strategy.md#alpha-forge-strategy-validate) and [`alpha-forge backtest run`](cli-reference/backtest.md#alpha-forge-backtest-run) before live use.

### Suitable scenarios

- **Symbols**: US large-cap stocks / ETFs (SPY, QQQ, AAPL)
- **Market environment**: Long-term uptrend with short-term pullbacks
- **Holding period**: 1 day to 2 weeks
- **Risk profile**: Trend-following design — watch for **drawdowns at trend reversals**. Skips entries entirely when the weekly trend turns down.

### Strategy JSON (full)

```json
{
  "strategy_id": "my_mtf_pullback_v1",
  "name": "SPY Multi-Timeframe Trend Pullback v1",
  "version": "1.0.0",
  "description": "Multi-timeframe strategy: judge trend with weekly SMA, time pullback entries on daily RSI oversold.",
  "target_symbols": ["SPY"],
  "asset_type": "stock",
  "timeframe": "1d",
  "parameters": {
    "rsi_oversold_th": 35,
    "atr_mult": 2.0
  },
  "indicators": [
    {
      "id": "weekly_sma",
      "type": "SMA",
      "params": { "length": 20 },
      "source": "close",
      "timeframe": "1w"
    },
    {
      "id": "weekly_close",
      "type": "EXPR",
      "params": { "expr": "close" },
      "timeframe": "1w"
    },
    { "id": "rsi", "type": "RSI", "params": { "length": 7 } },
    { "id": "sma_50", "type": "SMA", "params": { "length": 50 } },
    { "id": "atr", "type": "ATR", "params": { "length": 14 } },
    { "id": "sl_dist", "type": "EXPR", "params": { "expr": "atr * atr_mult" }, "lock_on_entry": true }
  ],
  "variables": [
    {
      "id": "weekly_uptrend",
      "logic": "AND",
      "conditions": [
        { "left": "weekly_close", "op": ">", "right": "weekly_sma" }
      ]
    }
  ],
  "entry_conditions": {
    "long": {
      "logic": "AND",
      "conditions": [
        { "left": "weekly_uptrend", "op": "==", "right": true },
        { "left": "close", "op": ">", "right": "sma_50" },
        { "left": "rsi",   "op": "<", "right": "rsi_oversold_th" }
      ]
    }
  },
  "exit_conditions": {
    "long": {
      "logic": "OR",
      "conditions": [
        { "left": "rsi", "op": ">", "right": 60 },
        { "left": "close", "op": "<", "right": "sma_50" }
      ]
    }
  },
  "risk_management": {
    "leverage": 1.0,
    "position_sizing_method": "fixed",
    "position_size_pct": 25.0,
    "stop_loss_indicator": "sl_dist",
    "max_positions": 1
  },
  "regime_config": null,
  "optimizer_config": {
    "param_ranges": {
      "weekly_sma.length": { "min": 10, "max": 30, "step": 5 },
      "rsi.length":        { "min": 5,  "max": 14, "step": 1 },
      "rsi_oversold_th":   { "min": 25, "max": 45, "step": 5 },
      "atr_mult":          { "min": 1.5, "max": 3.0, "step": 0.5 }
    },
    "constraints": { "min_trades": 20 },
    "metric": "sharpe_ratio"
  },
  "tags": ["multi-timeframe", "trend-following", "pullback", "weekly", "spy"]
}
```

### Key parameters

| Parameter | Role | Recommended range |
|-----------|------|-------------------|
| `weekly_sma.timeframe: "1w"` | Higher timeframe for the SMA | `"1w"` (also `"4h"`, `"1mo"`) |
| `weekly_sma.length` | Weekly SMA period | `10-30` (mid-to-long trend) |
| `rsi.length` | Daily RSI period | `5-14` |
| `rsi_oversold_th` | Pullback threshold | `25-45` |
| `sma_50` | Daily mid-trend filter | fixed `50` |
| `position_size_pct` | Per-position size | `25%` (conservative) |

The `indicators[].timeframe` field computes only that indicator on a different timeframe. When a daily-base strategy (`timeframe: "1d"`) references a weekly indicator, the matching weekly value is automatically forward-filled (ffill) to align with each daily row.

### Sample backtest output

!!! warning "Sample output"

```text
==> SPY 2018-01-01 → 2025-12-31 (1d)
   trades: 32   win_rate: 62.5%   profit_factor: 1.95
   total_return: +68.2%   cagr: +6.7%   sharpe: 1.18
   max_drawdown: -14.3%   exposure: 28.7%
```

### Customization tips

- **Change the higher timeframe**: `weekly_sma.timeframe: "4h"` for intraday MTF; `"1mo"` for monthly-led strategies
- **Combine multiple higher timeframes**: Require both weekly and monthly SMAs to be cleared before entering
- **Expand symbols**: `target_symbols: ["SPY", "QQQ", "DIA"]` and use `alpha-forge optimize cross-symbol` for robust parameters
- **Add shorts**: Define `entry_conditions.short` for "weekly downtrend + daily RSI overbought"

---

## Customization and derivations

### Parameter optimization

Each template includes `optimizer_config.param_ranges`, so Optuna Bayesian optimization runs with:

```bash
alpha-forge optimize run <SYMBOL> --strategy <STRATEGY_ID> --metric sharpe_ratio --save
```

See [`alpha-forge optimize run`](cli-reference/optimize.md#alpha-forge-optimize-run) for details.

### Walk-forward to guard against overfitting

```bash
alpha-forge optimize walk-forward <SYMBOL> --strategy <STRATEGY_ID> --windows 5
```

Each window runs IS optimization → OOS evaluation; check `overfitting_score` afterwards.

### Sensitivity analysis to measure robustness

```bash
alpha-forge optimize sensitivity <RESULT_FILE>
```

Sweep around optimized parameters and measure how much the metric moves. If `overall_robustness_score` ≤ 0.7, suspect overfitting.

### Compare with live results

Once trade records accumulate, compare against backtest:

```bash
alpha-forge live compare <STRATEGY_ID>
```

See [`alpha-forge live compare`](cli-reference/live.md#alpha-forge-live-compare).

---

## Related documentation

- [Getting Started](getting-started.md) — Start with a simple SMA crossover
- [CLI Reference](cli-reference/index.md) — All `alpha-forge` command parameters
- [AI-Driven Strategy Exploration Workflow](ai-agents/exploration-workflow.md) — Generate strategies with Claude Code / Codex

---

