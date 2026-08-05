---
title: alpha-visualizer v1.3.0 — the UX-audit wave (Runs page, full report, portfolio blending, and more)
description: alpha-visualizer v1.3.0 addresses 57 findings from a full UX audit in one release — a cross-strategy Runs page, a print-friendly full report, portfolio blending in Compare, a major expansion of metrics and analysis views, exact IS/OOS splitting, and accessibility/robustness improvements.
---

# alpha-visualizer v1.3.0 — the UX-audit wave

> **Released**: August 1, 2026 / **Version**: v1.3.0 (this note also covers the v1.3.1–v1.3.5 patches) / **Distribution**: [PyPI](https://pypi.org/project/alpha-visualizer/) · [GitHub Release](https://github.com/alforge-labs/alpha-visualizer/releases/tag/v1.3.0)

[alpha-visualizer](index.md) is a standalone OSS package that visualizes AlphaForge backtest results in a web browser. v1.3.0 is a **single-release response to 57 findings from a full UX audit** — the largest release to date, spanning new screens, richer metrics, plainer wording, and accessibility.

## Highlights

### 1. New screens and views

- **Runs page**: search, filter (symbol, period, minimum Sharpe), and sort backtest runs across all strategies
- **Full report**: a print-friendly view reachable from Detail (save as PDF via the browser's print dialog)
- **Portfolio blending**: assign weights in Compare to draw a weighted composite equity curve and check diversification effects
- **Run History comparison**: pick two runs to compare metric deltas with overlaid equity curves

### 2. Richer metrics and analysis

- Metrics forge already computed but the UI never showed (realized costs, Kelly criterion, expectancy, win-rate confidence intervals, and more)
- Holding-period histogram (win/loss colored), yearly summary table, sub-period recalculation presets (YTD/1Y/3Y/5Y)
- Arbitrary benchmark overlay with benchmark-relative metrics (β / α / IR / excess return)
- Log-scale toggle for equity charts, rolling annualized volatility, parameter importance (Spearman rank correlation) in Optimize
- Strategy favorites (star + Starred lens)
- **IS/OOS metrics switched from prorated pseudo-values to exact equity splitting** (more accurate displayed values)

### 3. Clarity and accessibility

- Metric tooltips extended to every metric (with guideline values, touch/keyboard support), in-app help links (IS/OOS and WFO concepts)
- Plainer, consistent UI wording (no internal jargon or CLI-centric phrasing), bilingual CLI help and startup messages
- Dialog focus traps, keyboard-operable scroll regions, and mobile-width layout fixes

### 4. Robustness and performance

- 404 pages for unknown strategy ids, a shared error screen for render exceptions, no more infinite polling on job 404s
- GZip compression, lighter list APIs, a lightweight sparkline API
- An explicit warning plus TrustedHostMiddleware for non-loopback binds
- Coverage thresholds and mypy introduced in CI (existing type errors driven to zero)

### 5. Patches (v1.3.1–v1.3.5)

- **v1.3.1**: fixed the forge CLI executable name to `alpha-forge`, restoring GUI execution features (**use v1.3.1+ if you run the v1.3 line**)
- **v1.3.2**: when forge aborts due to an unaccepted EULA, the UI now explains how to accept it
- **v1.3.3–v1.3.5**: chart series legend, better Live series colors, and a chart-wheel scrolling fix

## How to upgrade

```bash
# pip
pip install -U alpha-visualizer

# uv
uv tool upgrade alpha-visualizer
```

Paired with `alpha-forge` v1.3.0, run-time parameters are shown on the Detail screen (params_json integration).

## Links

- **PyPI**: <https://pypi.org/project/alpha-visualizer/>
- **GitHub Release**: <https://github.com/alforge-labs/alpha-visualizer/releases/tag/v1.3.0>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **Features**: [alpha-visualizer / Features](features.md)

Bug reports and feature requests are welcome on [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues).
