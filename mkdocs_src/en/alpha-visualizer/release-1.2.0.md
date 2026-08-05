---
title: alpha-visualizer v1.2.0 — richer Live view, recipe-folded Browse, and the Maintenance screen
description: alpha-visualizer v1.2.0 redesigns the Live portfolio view into a four-tier layout (KPIs, benchmark comparison, positions table), folds the Browse list into recipes with a symbol-coverage table, and adds a Maintenance screen for cleaning up orphaned backtest results.
---

# alpha-visualizer v1.2.0 — richer Live view, recipe-folded Browse, and the Maintenance screen

> **Released**: July 27, 2026 / **Version**: v1.2.0 (this note also covers the v1.2.1 / v1.2.2 patches) / **Distribution**: [PyPI](https://pypi.org/project/alpha-visualizer/) · [CHANGELOG](https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md)

[alpha-visualizer](index.md) is a standalone OSS package that visualizes AlphaForge backtest results in a web browser. The center of v1.2.0 is a **substantially richer Live (paper-trading) view** and a **restructured Browse screen that stays readable as your strategy library grows**.

## Highlights

### 1. Richer Live portfolio view

The combine-portfolio view was redesigned into four tiers answering, in order: how much is it worth → am I beating the market → how did it get here → what am I holding.

- **KPI row**: current value (with day-over-day change), cumulative P&L, current drawdown, excess return vs index / vs backtest
- **Equity + drawdown chart**: overlays the index (buy & hold) and the backtest combine when `alpha-forge live replay` ran with `--benchmark` / `--compare`
- **Positions table**: symbol, quantity, average cost, value, weight, unrealized P&L, with subtotal rows

See [Live in Features](features.md#live) for details.

### 2. Recipe folding and the symbol-coverage table in Browse

Strategies sharing a name, symbol, and timeframe are folded into a single "recipe" row (expand to see the parameter variants). A new **symbol-coverage table** shows recipe counts and run/not-run skew per symbol at a glance (sorted by most-unrun by default; click a row to filter).

### 3. The Maintenance screen

A new `/maintenance` screen lists backtest results whose strategy definition no longer exists ("orphans") and deletes the ones you select. Listing and deletion are delegated to `alpha-forge backtest prune-orphans`. Because orphans can include results you deliberately kept, a confirmation dialog guards the deletion.

### 4. Fixes (v1.2.0–v1.2.2)

- Compare no longer loads forever when no strategy is selected (v1.2.0)
- Browse no longer loops sparkline fetches infinitely when selecting a strategy (v1.2.2)
- Dependency security alerts resolved and layout glitches fixed (v1.2.1)

## How to upgrade

```bash
# pip
pip install -U alpha-visualizer

# uv
uv tool upgrade alpha-visualizer
```

The Maintenance screen and the Live comparison overlays rely on an AlphaForge CLI (v1.2+ recommended) installed on the same machine as the server. View-only usage keeps working without the CLI.

## Links

- **PyPI**: <https://pypi.org/project/alpha-visualizer/>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **Features**: [alpha-visualizer / Features](features.md)

Bug reports and feature requests are welcome on [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues).
