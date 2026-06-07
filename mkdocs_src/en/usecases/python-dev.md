# Python Developers

For Python developers who want to manage strategy experiments with a CLI/JSON-first workflow.

## Why AlphaForge Fits Python Developers

- **Strategies are JSON** — declaratively manage parameters without writing boilerplate code
- **CLI supports structured output** — use `--json` flag to pipe results into your own scripts
- **Optuna-based optimization** — integrates naturally with the Python ecosystem
- **uv project structure** — coexists with your existing Python code in a monorepo

## Basic Usage

```bash
# Get backtest results as JSON and pipe to custom script
alpha-forge backtest run QQQ --strategy my_strategy --json | python analyze.py

# Optuna optimization (maximize Sharpe ratio)
alpha-forge optimize run QQQ --strategy my_strategy --trials 200 --metric sharpe_ratio

# Walk-forward validation
alpha-forge optimize walk-forward QQQ --strategy my_strategy --windows 5
```

## Managing Strategies as JSON

AlphaForge strategies are defined in JSON files — easy to version-control and diff.

```json
{
  "strategy_id": "my_strategy",
  "name": "My Strategy",
  "target_symbols": ["QQQ"],
  "indicators": [
    { "id": "rsi", "type": "RSI", "params": { "length": 14 } },
    { "id": "bb_lower", "type": "BBANDS", "params": { "length": 20, "std": 2.0, "line": "lower" } }
  ],
  "entry_conditions": {
    "long": { "logic": "AND", "conditions": [
      { "left": "rsi", "op": "<", "right": 30 },
      { "left": "close", "op": "<", "right": "bb_lower" }
    ] }
  },
  "exit_conditions": {
    "long": { "logic": "OR", "conditions": [
      { "left": "rsi", "op": ">", "right": 70 }
    ] }
  },
  "risk_management": { "position_size_pct": 100.0 }
}
```

## Related Docs

- [End-to-End Strategy Development Workflow](../guides/end-to-end-workflow.md) — Full development cycle
- [Strategy Templates](../templates.md) — Complete JSON samples (copy-paste ready)
- [Strategy Gallery](../strategy-gallery.md) — Browse strategies by market and objective
- [CLI Reference](../cli-reference/index.md) — All commands in detail
