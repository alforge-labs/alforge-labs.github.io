---
title: alpha-visualizer v0.9.0 — Run optimization and WFT from the GUI, plus a parameter tuning loop (cumulative update since v0.7.1)
description: alpha-visualizer v0.9.0 adds asynchronous optimization / Walk-Forward Test jobs and a parameter tuning loop, closing the whole strategy-development loop inside the GUI. Highlights since v0.7.1 include FX carry-adjusted metrics, X share cards, and accessibility upgrades.
---

# alpha-visualizer v0.9.0 — cumulative update since v0.7.1

> **Published**: July 19, 2026 / **Version**: v0.9.0 / **Distribution**: [PyPI](https://pypi.org/project/alpha-visualizer/0.9.0/) · [GitHub Release](https://github.com/alforge-labs/alpha-visualizer/releases/tag/v0.9.0)

[alpha-visualizer](index.md) is a standalone OSS package that visualizes `alpha-forge` backtest results in the browser. The headline change in v0.9.0: **asynchronous optimization / WFT jobs and a parameter tuning loop close the whole strategy-development loop inside the GUI**. This note summarizes the cumulative highlights since v0.7.1 (v0.7.3, v0.8.0, and v0.9.0).

## Highlights

### 1. Run optimization / WFT from the GUI (v0.9.0)

Optimization (Optuna) and Walk-Forward Tests now launch from the browser as **asynchronous jobs**, with real-time log / progress streaming over SSE and cancellation. WFT jobs run with recording enabled (`--save`), so finished runs automatically appear in the WFO tab. The Detail screen's backtest re-run — available since earlier releases — was also hardened with direct run retrieval, timeouts, and execution-log display.

This requires the AlphaForge CLI on the same machine as the server (without it, the dashboard keeps working as a read-only viewer). Tune concurrency and timeout via `ALPHA_VIS_JOB_CONCURRENCY` / `ALPHA_VIS_JOB_TIMEOUT`.

### 2. Parameter tuning loop (v0.9.0)

The tuning panel on the Strategy tab supports an **edit → trial run → compare → explicit save** loop entirely in the GUI. Trial runs never touch the original strategy definition; parameters are written back only via the explicit "Save" action. Tuning trials are visually distinguished from regular runs in Browse, Run History, and the Backtest tab, so exploration footprints never mix with adopted results. **Duplicate-based strategy creation** (clone under a new ID) is also supported.

### 3. FX carry-adjusted metrics (v0.9.0)

Integrates with AlphaForge v0.18.0's `backtest run --carry` (FX carry / swap accrual): carry-adjusted metrics are shown as a dedicated card on the Detail screen's Backtest tab. See the [AlphaForge changelog](../changelog.md) for details.

### 4. Share cards and X sharing (v0.9.0)

Export an OGP-sized (1200×630) PNG share card — equity curve plus headline metrics — from the Detail, Compare, and Live screens. The "Share on X" button saves the card and opens the X composer with a pre-filled performance summary (with a 280-character guard) in one click.

### 5. Accessibility and UI quality (v0.8.0)

Keyboard navigation, ARIA landmarks, screen-reader support, and WCAG AA contrast adjustments. Candlestick charts gained an OHLC data-table alternative. Shared loading skeletons, `Intl` digit grouping, and OS theme following are also included.

### 6. Charts and the Optimize view (v0.7.3 / v0.8.0)

TradingView lightweight-charts became the default renderer for the main charts (v0.7.3). Optimization results gained a **two-parameter × metric heatmap view**, switchable with the scatter plot via tabs (v0.8.0).

## Upgrading

```bash
# pip
pip install -U alpha-visualizer

# uv
uv add alpha-visualizer@latest        # add to a project
uv tool install alpha-visualizer       # install as a CLI
```

Quick check with the bundled samples:

```bash
alpha-vis serve --use-bundled-samples --no-open
# open http://127.0.0.1:8000
```

Pointing at your `alpha-forge` project data:

```bash
alpha-vis serve --forge-dir /path/to/your/alpha-strategies
```

No configuration (`forge.yaml`) changes are required. If you do not use the GUI execution features, everything works exactly as before.

## Links

- **PyPI**: <https://pypi.org/project/alpha-visualizer/0.9.0/>
- **GitHub Release (tag)**: <https://github.com/alforge-labs/alpha-visualizer/releases/tag/v0.9.0>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **Installation**: [alpha-visualizer / Installation](installation.md)
- **Features**: [alpha-visualizer / Features](features.md)
- **Configuration**: [alpha-visualizer / Configuration](configuration.md)

Bug reports and feature requests are welcome on [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues).
