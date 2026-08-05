---
title: alpha-visualizer v1.5.0 — the GUI wave (data management, Pine export, AI development upgrades, Get Started)
description: alpha-visualizer v1.5.0 is a major release that closes the loop from data fetching to strategy creation, backtesting, optimization, and Pine export — all in the GUI. It adds a Data screen, TradingView Pine Script export, AI development upgrades (goal builder, derived development), and a setup checklist with a first-strategy guide.
---

# alpha-visualizer v1.5.0 — the GUI wave

> **Released**: August 5, 2026 / **Version**: v1.5.0 / **Distribution**: [PyPI](https://pypi.org/project/alpha-visualizer/) · [GitHub Release](https://github.com/alforge-labs/alpha-visualizer/releases/tag/v1.5.0)

[alpha-visualizer](index.md) is a standalone OSS package that visualizes AlphaForge backtest results in a web browser. v1.5.0 is a major release that lets beginner-to-intermediate investors complete the whole loop — **fetch data → create a strategy → backtest → optimize → export Pine** — almost entirely in the GUI.

## Highlights

### 1. The Data screen

A new "Data" screen lists stored historical datasets with freshness (datasets older than 24 hours get a "Stale" badge) and lets you fetch symbols or incrementally update everything from the GUI, as asynchronous jobs with SSE progress and cancellation. Screens that hit missing data and the AI develop view link here with the symbol pre-filled. See [Data in Features](features.md#data).

### 2. Pine Script export to TradingView

The "Export to TradingView" card on the Detail screen (Strategy tab) copies or downloads the strategy as Pine Script (v6). Unsupported indicators are flagged before generating, and the card walks you through pasting into the TradingView Pine editor. Pine export is a paid-plan AlphaForge feature (Trial shows an upgrade prompt).

### 3. AI strategy development (Agent Develop) upgrades

- **Goal builder**: pick a strategy type (trend following / mean reversion / breakout) and indicators to auto-draft a goal text. Indicator choices are limited to Pine-convertible ones, keeping a later TradingView export safe
- **Next actions on completion**: jump straight from the completion panel to the new strategy's backtest, optimization, or a comparison with existing strategies
- **Derived development from an existing strategy**: the "Improve with AI" card on Detail sends an improvement instruction (e.g. trade less often) and creates a **derived version under a new id** — the original strategy is never modified

### 4. Get Started (setup checklist + first-strategy guide)

A new "Get Started" screen aggregates first-run setup state (forge CLI / EULA / workspace / authentication / data) with a concrete next step per incomplete item — copyable commands or in-GUI links. Below it, a five-step first-strategy guide marks progress based on actual data. While setup is incomplete, the "Start" nav item carries an attention dot. See [Get Started in Features](features.md#get-started).

### 5. Everything else

- Dev-dependency security updates (undici 7.29.0 / postcss 8.5.25; no impact on the production bundle)

## How to upgrade

```bash
# pip
pip install -U alpha-visualizer

# uv
uv tool upgrade alpha-visualizer
```

GUI execution features (data fetching, Pine export, etc.) require an AlphaForge CLI (v1.3+ recommended) on the same machine as the server. View-only usage keeps working without the CLI. Write-type features such as data-fetch jobs are enabled only on localhost binds.

## Links

- **PyPI**: <https://pypi.org/project/alpha-visualizer/>
- **GitHub Release**: <https://github.com/alforge-labs/alpha-visualizer/releases/tag/v1.5.0>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **Features**: [alpha-visualizer / Features](features.md)
- **Installation**: [alpha-visualizer / Installation](installation.md)

Bug reports and feature requests are welcome on [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues).
