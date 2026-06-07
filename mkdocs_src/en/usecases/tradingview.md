# TradingView Users

For Pine Script writers who want to take their backtesting to the next level with AlphaForge.

## Division of Roles

| TradingView | AlphaForge |
|-------------|------------|
| Charts and indicator visualization | Statistical backtesting and optimization |
| Rapid idea validation with Pine Script | Parameter optimization (Optuna/Bayesian) |
| Alert triggering | Walk-forward validation |
| Visual entry confirmation | Quantitative strategy evaluation (Sharpe, max DD) |

## Typical Workflow

```
1. Prototype your idea in Pine Script on TradingView
      ↓
2. Port to an AlphaForge JSON strategy
      ↓
3. Run full backtest with alpha-forge backtest run
      ↓
4. Optimize parameters with alpha-forge optimize run
      ↓
5. Re-export to Pine Script with alpha-forge pine generate
      ↓
6. TradingView alert → Alpha Strike auto-execution (optional)
```

## Getting Started

```bash
# Create a strategy from template
alpha-forge strategy create --template hmm_bb_pipeline_v1 --out my_strategy.json

# Fetch daily data (e.g. QQQ)
alpha-forge data fetch QQQ --period 5y

# Run backtest
alpha-forge backtest run QQQ --strategy my_strategy
```

## Related Docs

- [TradingView × Pine Script Integration (Part 1)](../guides/tradingview-pine-integration.md) — Porting Pine Script logic to AlphaForge JSON
- [TradingView × Alpha Strike Integration (Part 2)](../guides/tradingview-alpha-strike.md) — Connecting alerts to automated order execution
- [End-to-End Strategy Development Workflow](../guides/end-to-end-workflow.md) — From data fetch to execution
- [Strategy Templates](../templates.md) — Copy-paste ready JSON templates
