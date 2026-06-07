# Strategy Gallery

This page is a short example catalog for choosing strategy ideas by market and purpose. [Strategy Templates](templates.md) provides deep explanations and full JSON for representative templates; this gallery helps you quickly compare what to test, where to test it, and which `alpha-forge` commands to run next.

!!! info "About JSON examples"
    Each JSON block is a focused snippet, not a complete production strategy. Add the required `risk_management` and `optimizer_config` fields for your workflow, then validate with `alpha-forge strategy validate`. Backtest results never guarantee future performance.

## Gallery overview

| Example | Main purpose | Example symbols | Pine Script export |
|---|---|---|---|
| HMM + BB + RSI | Regime-adaptive mean reversion | `QQQ` | Available |
| MACD + RSI | Momentum with overheat filter | `SPY` | Available |
| Trend following | Follow sustained uptrends | `AAPL` | Available |
| Mean reversion | Buy stretched downside moves in ranges | `MSFT` | Available |
| FX pairs | Test liquid major FX pairs | `EURUSD=X` | Available |
| Index ETFs | Search robust settings across ETFs | `SPY` | Available |
| Commodity futures | Handle commodity trend/range shifts | `CL=F` | Conditional |

## HMM + BB + RSI

| Field | Details |
|---|---|
| Purpose | Use HMM regimes to filter BB-lower + RSI-oversold mean reversion entries |
| Suitable markets | Liquid ETFs and large-cap instruments with alternating trend/range regimes |
| Strategy type | Regime-adaptive mean reversion |
| Key indicators | HMM, BBANDS, RSI, ATR |
| Example symbols | `QQQ`, `SPY` |
| Pine Script export | Available. For HMM strategies, consider `--with-training-data` |

### JSON snippet

```json
{
  "strategy_id": "gallery_hmm_bb_rsi_v1",
  "target_symbols": ["QQQ"],
  "indicators": [
    { "id": "regime", "type": "HMM", "params": { "n_components": 3, "features": ["return", "volatility"] } },
    { "id": "bb_lower", "type": "BBANDS", "params": { "length": 20, "std": 2.0, "line": "lower" } },
    { "id": "rsi", "type": "RSI", "params": { "length": 7 } }
  ],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [
    { "left": "close", "op": "<", "right": "bb_lower" },
    { "left": "rsi", "op": "<", "right": "35" }
  ]}}
}
```

### Run commands

```bash
alpha-forge strategy save data/strategies/gallery_hmm_bb_rsi_v1.json
alpha-forge strategy validate gallery_hmm_bb_rsi_v1
alpha-forge backtest run QQQ --strategy gallery_hmm_bb_rsi_v1 --json
alpha-forge optimize run QQQ --strategy gallery_hmm_bb_rsi_v1 --metric sharpe_ratio --save
alpha-forge pine generate --strategy gallery_hmm_bb_rsi_v1 --with-training-data
```

### How to read results

Check trade count and Max Drawdown by regime, not just Sharpe. If trades still occur in weak regimes, tighten the state-specific rules.

### Improvement ideas

Optimize RSI length, BB standard deviation, and HMM state count. For a fuller JSON example, see [Strategy Templates](templates.md).

## MACD + RSI

| Field | Details |
|---|---|
| Purpose | Combine MACD direction with an RSI overheat filter to reduce false momentum entries |
| Suitable markets | Stocks and ETFs with medium-term momentum |
| Strategy type | Momentum with filter |
| Key indicators | MACD, RSI, EMA |
| Example symbols | `SPY`, `NVDA` |
| Pine Script export | Available |

### JSON snippet

```json
{
  "strategy_id": "gallery_macd_rsi_v1",
  "target_symbols": ["SPY"],
  "indicators": [
    { "id": "macd", "type": "MACD", "params": { "fast": 12, "slow": 26, "signal": 9, "line": "macd" } },
    { "id": "macd_signal", "type": "MACD", "params": { "fast": 12, "slow": 26, "signal": 9, "line": "signal" } },
    { "id": "rsi", "type": "RSI", "params": { "length": 14 } }
  ],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [
    { "left": "macd", "op": "crosses_above", "right": "macd_signal" },
    { "left": "rsi", "op": "<", "right": "70" }
  ]}}
}
```

### Run commands

```bash
alpha-forge strategy save data/strategies/gallery_macd_rsi_v1.json
alpha-forge strategy validate gallery_macd_rsi_v1
alpha-forge backtest run SPY --strategy gallery_macd_rsi_v1 --json
alpha-forge optimize run SPY --strategy gallery_macd_rsi_v1 --metric sharpe_ratio --save
alpha-forge pine generate --strategy gallery_macd_rsi_v1
```

### How to read results

If trade count is too low, the MACD cross may be too restrictive. Compare PF, average win/loss, and drawdown during losing streaks.

### Improvement ideas

Try RSI caps from 60 to 80 and optimize MACD fast/slow periods. Add an EMA filter for weak-trend symbols.

## Trend following

| Field | Details |
|---|---|
| Purpose | Participate only when the uptrend is already established |
| Suitable markets | Stocks, equity ETFs, and commodity contracts in persistent trends |
| Strategy type | Trend following |
| Key indicators | EMA, ADX, ATR |
| Example symbols | `AAPL`, `NVDA` |
| Pine Script export | Available |

### JSON snippet

```json
{
  "strategy_id": "gallery_trend_follow_v1",
  "target_symbols": ["AAPL"],
  "indicators": [
    { "id": "ema_fast", "type": "EMA", "params": { "length": 20 } },
    { "id": "ema_slow", "type": "EMA", "params": { "length": 100 } },
    { "id": "adx", "type": "ADX", "params": { "length": 14 } }
  ],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [
    { "left": "ema_fast", "op": ">", "right": "ema_slow" },
    { "left": "adx", "op": ">", "right": "20" }
  ]}}
}
```

### Run commands

```bash
alpha-forge strategy save data/strategies/gallery_trend_follow_v1.json
alpha-forge strategy validate gallery_trend_follow_v1
alpha-forge backtest run AAPL --strategy gallery_trend_follow_v1 --json
alpha-forge optimize run AAPL --strategy gallery_trend_follow_v1 --metric sharpe_ratio --save
alpha-forge pine generate --strategy gallery_trend_follow_v1
```

### How to read results

Trend following can work with a low win rate if PF and average win size are strong. If drawdown is too large, revisit ATR-based exits.

### Improvement ideas

Optimize ADX threshold and EMA lengths. Add a weekly SMA filter for higher-timeframe confirmation.

## Mean reversion

| Field | Details |
|---|---|
| Purpose | Buy stretched downside moves in range-like markets |
| Suitable markets | Large-cap stocks and ETFs without extreme volatility |
| Strategy type | Mean reversion |
| Key indicators | BBANDS, RSI, ATR |
| Example symbols | `MSFT`, `SPY` |
| Pine Script export | Available |

### JSON snippet

```json
{
  "strategy_id": "gallery_mean_reversion_v1",
  "target_symbols": ["MSFT"],
  "indicators": [
    { "id": "bb_lower", "type": "BBANDS", "params": { "length": 20, "std": 2.0, "line": "lower" } },
    { "id": "bb_mid", "type": "BBANDS", "params": { "length": 20, "std": 2.0, "line": "mid" } },
    { "id": "rsi", "type": "RSI", "params": { "length": 10 } }
  ],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [
    { "left": "close", "op": "<", "right": "bb_lower" },
    { "left": "rsi", "op": "<", "right": "35" }
  ]}}
}
```

### Run commands

```bash
alpha-forge strategy save data/strategies/gallery_mean_reversion_v1.json
alpha-forge strategy validate gallery_mean_reversion_v1
alpha-forge backtest run MSFT --strategy gallery_mean_reversion_v1 --json
alpha-forge optimize run MSFT --strategy gallery_mean_reversion_v1 --metric sharpe_ratio --save
alpha-forge pine generate --strategy gallery_mean_reversion_v1
```

### How to read results

Mean reversion can lose repeatedly during sharp downtrends. Watch losing streaks and maximum holding period, not only win rate.

### Improvement ideas

Add higher-timeframe trend and volatility filters so the strategy stands aside during strong downtrends.

## FX pairs

| Field | Details |
|---|---|
| Purpose | Test short-to-medium-term trend and oscillator behavior on major FX pairs |
| Suitable markets | Liquid major pairs such as EURUSD=X and USDJPY=X |
| Strategy type | Trend with oscillator filter |
| Key indicators | SMA, RSI, ATR |
| Example symbols | `EURUSD=X`, `USDJPY=X` |
| Pine Script export | Available |

### JSON snippet

```json
{
  "strategy_id": "gallery_fx_pair_v1",
  "target_symbols": ["EURUSD=X"],
  "asset_type": "fx",
  "indicators": [
    { "id": "sma_fast", "type": "SMA", "params": { "length": 20 } },
    { "id": "sma_slow", "type": "SMA", "params": { "length": 80 } },
    { "id": "rsi", "type": "RSI", "params": { "length": 14 } }
  ],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [
    { "left": "sma_fast", "op": ">", "right": "sma_slow" },
    { "left": "rsi", "op": "<", "right": "65" }
  ]}}
}
```

### Run commands

```bash
alpha-forge strategy save data/strategies/gallery_fx_pair_v1.json
alpha-forge strategy validate gallery_fx_pair_v1
alpha-forge backtest run EURUSD=X --strategy gallery_fx_pair_v1 --json
alpha-forge optimize run EURUSD=X --strategy gallery_fx_pair_v1 --metric sharpe_ratio --save
alpha-forge pine generate --strategy gallery_fx_pair_v1
```

### How to read results

FX trends can reverse quickly, so average holding period and PF are important. Check whether ATR settings are too loose for each pair.

### Improvement ideas

Run the same idea on USDJPY=X and GBPUSD=X, then use `alpha-forge optimize cross-symbol` to inspect cross-pair robustness.

## Index ETFs

| Field | Details |
|---|---|
| Purpose | Search for settings that remain robust across SPY, QQQ, and IWM |
| Suitable markets | US index ETFs |
| Strategy type | Cross-symbol validation |
| Key indicators | SMA, RSI, ATR |
| Example symbols | `SPY`, `QQQ`, `IWM` |
| Pine Script export | Available |

### JSON snippet

```json
{
  "strategy_id": "gallery_index_etf_v1",
  "target_symbols": ["SPY", "QQQ", "IWM"],
  "indicators": [
    { "id": "sma_50", "type": "SMA", "params": { "length": 50 } },
    { "id": "sma_200", "type": "SMA", "params": { "length": 200 } },
    { "id": "rsi", "type": "RSI", "params": { "length": 14 } }
  ],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [
    { "left": "sma_50", "op": ">", "right": "sma_200" },
    { "left": "rsi", "op": "<", "right": "70" }
  ]}}
}
```

### Run commands

```bash
alpha-forge strategy save data/strategies/gallery_index_etf_v1.json
alpha-forge strategy validate gallery_index_etf_v1
alpha-forge backtest run SPY --strategy gallery_index_etf_v1 --json
alpha-forge optimize run SPY --strategy gallery_index_etf_v1 --metric sharpe_ratio --save
alpha-forge pine generate --strategy gallery_index_etf_v1
```

### How to read results

A strong SPY-only result may still be overfit if QQQ or IWM collapses. Compare Sharpe and Max Drawdown across symbols.

### Improvement ideas

Use `alpha-forge optimize cross-symbol SPY QQQ IWM --strategy gallery_index_etf_v1 --aggregation min --save` to improve the worst-case score.

## Commodity futures

| Field | Details |
|---|---|
| Purpose | Combine trend and reversal behavior for volatile commodity contracts |
| Suitable markets | Crude oil, gold, natural gas, and other high-volatility commodities |
| Strategy type | Regime switching |
| Key indicators | HMM, SUPERTREND, RSI, ATR |
| Example symbols | `CL=F`, `GC=F` |
| Pine Script export | Conditional. Confirm trained-parameter handling when HMM is included |

### JSON snippet

```json
{
  "strategy_id": "gallery_commodity_futures_v1",
  "target_symbols": ["CL=F"],
  "indicators": [
    { "id": "regime", "type": "HMM", "params": { "n_components": 2, "features": ["return", "volatility"] } },
    { "id": "supertrend", "type": "SUPERTREND", "params": { "length": 10, "multiplier": 3.0 } },
    { "id": "rsi", "type": "RSI", "params": { "length": 14 } }
  ],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [
    { "left": "close", "op": "crosses_above", "right": "supertrend" },
    { "left": "rsi", "op": "<", "right": "70" }
  ]}}
}
```

### Run commands

```bash
alpha-forge strategy save data/strategies/gallery_commodity_futures_v1.json
alpha-forge strategy validate gallery_commodity_futures_v1
alpha-forge backtest run CL=F --strategy gallery_commodity_futures_v1 --json
alpha-forge optimize run CL=F --strategy gallery_commodity_futures_v1 --metric sharpe_ratio --save
alpha-forge pine generate --strategy gallery_commodity_futures_v1 --with-training-data
```

### How to read results

Commodity futures can gap and reverse sharply, so inspect Max Drawdown, average loss, and the equity curve during losing streaks. If trade count is too low, expand the test period.

### Improvement ideas

Test CL=F, GC=F, and NG=F, then optimize ATR and SuperTrend multipliers across symbols. For a fuller regime-switching example, see [Regime switching](templates.md#regime-switching).
