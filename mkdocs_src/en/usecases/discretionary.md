# Discretionary → Systematic

For traders who have built up a discretionary playbook over years and want to **codify those rules as declarative JSON and validate them with backtests**, rather than leaving them at the level of "gut feel" or "market sense."

## Three Problems Discretionary Trading Carries

| Problem | What Happens in Discretionary Trading | How AlphaForge Solves It |
|---------|---------------------------------------|--------------------------|
| **Reproducibility** | "Market sense" and "intuition" are hard to verbalize, so the source of edge is opaque | Express the strategy as JSON so anyone can reproduce the exact same signals |
| **Emotional Bias** | Aggressive on winning days, timid on losing days — decisions swing with P&L | Apply one fixed ruleset across the full history to quantify the bias |
| **Hindsight Bias** | "I should have cut here" is always obvious *after* the fact | Walk-forward validation evaluates using only information available *before* the trade |

## Translate Discretionary Rules Into Declarative JSON

If your discretionary rule is "buy when the 20-day MA crosses up and RSI(14) < 30, stop out at 2× ATR," you can declare this directly in an AlphaForge strategy JSON.

```bash
# Start from a template
alpha-forge strategy create my_playbook --template ma_rsi_atr

# Edit the strategy JSON to match your discretionary rules:
#   - Entry conditions (MA period, RSI threshold)
#   - Exit conditions (ATR multiple, take-profit width)
#   - Sizing (fraction of account balance)
```

For logic beyond what plain JSON expresses (composite conditions, regime detection), see the HMM and multi-timeframe examples in Strategy Templates.

## Quantify Discretionary Skill vs. Emotional Drag

Apply the *same* rule mechanically across `2018–2025` and the gap between this systematic result and your actual discretionary P&L is the size of your emotional bias.

```bash
# 1. Backtest the codified rule
alpha-forge backtest run QQQ --strategy my_playbook

# 2. Walk-forward to evaluate only with information available beforehand
alpha-forge optimize walk-forward QQQ --strategy my_playbook --folds 5

# 3. Compare against your actual discretionary record
#    - Systematic backtest Sharpe: 1.10
#    - Personal discretionary Sharpe : 0.40
#    → Emotional bias was eroding 0.70 Sharpe points
```

The point isn't to disown discretion — it's to **quantify the edge you took discretionarily, and carve out the reproducible parts**.

## Bridge to Hybrid Execution

If you're not ready to commit to full automation, AlphaForge supports a hybrid intermediate stage: **mechanize the signal, keep execution discretionary.**

```
Backtest → Optimize → Generate Pine Script
                                  ↓
                       TradingView alerts (notification only)
                                  ↓
                       Confirm and execute manually
```

You can let AlphaForge raise alerts for the patterns you "always miss," while keeping the execution decision in your own hands. There's no full-automation prerequisite, so the psychological migration cost stays low.

## First Steps

```bash
# 1. Start from a simple MA + RSI template
alpha-forge strategy create my_playbook --template ma_rsi_atr

# 2. Fetch 5 years of historical data
alpha-forge data fetch QQQ --period 5y

# 3. Backtest the codified ruleset
alpha-forge backtest run QQQ --strategy my_playbook --json

# 4. Capture the baseline for emotional-bias comparison
alpha-forge journal note my_playbook "Baseline vs. discretionary record"
```

## Related Docs

- [Strategy Templates](../templates.md) — JSON-declarative templates (MA, RSI, HMM, regime-switching)
- [Strategy Gallery](../strategy-gallery.md) — Cross-symbol strategy examples and metric interpretation
- [End-to-End Strategy Development Workflow](../guides/end-to-end-workflow.md) — From backtest to alerts
- [TradingView × Alpha Strike Integration](../guides/tradingview-alpha-strike.md) — Hybrid config: mechanized signals + manual execution
