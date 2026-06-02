---
title: alpha-visualizer v0.7.1 — TradingView charts, live SQLite reads, and Apache-2.0 (cumulative update since v0.2.0)
description: alpha-visualizer has moved from v0.2.0 to v0.7.1. Highlights include renaming the CLI from vis to alpha-vis, migrating the core charts to TradingView lightweight-charts, a new signal time-series chart, reading live performance directly from SQLite, relicensing to Apache-2.0, and continuous dependency updates — raising both visualization quality and production readiness.
---

# alpha-visualizer v0.7.1 — Cumulative update since v0.2.0

> **Released**: June 2, 2026 / **Version**: v0.7.1 / **Distribution**: [PyPI](https://pypi.org/project/alpha-visualizer/0.7.1/) · [GitHub Release](https://github.com/alforge-labs/alpha-visualizer/releases/tag/v0.7.1)

[alpha-visualizer](index.md) is a standalone OSS package that renders backtest results produced by `alpha-forge` in a web browser. Since v0.2.0 (instant exploration with bundled samples), releases v0.3.0 through v0.7.1 have centered on **revamping chart rendering and improving production readiness**. This note summarizes the cumulative highlights since v0.2.0.

> **Two breaking changes**: the CLI command was renamed (v0.3.0) and the license changed (v0.6.0). See the relevant sections below.

## Highlights

### 1. CLI renamed from `vis` to `alpha-vis` (v0.3.0, breaking)

The command name now is **`alpha-vis`**, resolving a clash with macOS's built-in `/usr/bin/vis` (a BSD text-visualization utility) that caused newcomers running `vis serve` to hit errors like `vis: serve: No such file or directory`.

```bash
# v0.3.0 and later
alpha-vis serve --use-bundled-samples --no-open
```

The old `vis` command no longer works — update your scripts and shell aliases to `alpha-vis`.

### 2. Core charts migrated to TradingView lightweight-charts (v0.3.0, v0.4.0)

The primary charts — equity/drawdown, rolling metrics, WFO synthetic equity, and Compare equity — now build on the industry-standard **TradingView lightweight-charts**. Zoom, pan, and crosshair interactions are improved, giving the familiar feel of a financial charting tool.

### 3. Signal time-series chart (v0.4.0)

The Strategy structure tab in the Detail view gained `StrategySignalChartTV`, overlaying **candlesticks + trade markers + price lines**. You can read entry/exit timing directly on the price chart, with regime-change markers supported as well. A backend OHLC endpoint, a frontend OHLC API client, and a `useStrategyHistorical` hook were added.

### 4. Live performance read directly from SQLite (v0.7.0)

The live-performance view now reads directly from **`backtest_results.db` (SQLite)** instead of going through JSON files. Reconciliation against `alpha-forge` production data is more robust, and when `use_db=true` but the DB is missing, the app no longer silently falls back to JSON — it **fails loud** with an explicit error.

### 5. Relicensed to Apache-2.0 (v0.6.0)

From v0.6.0 onward, the license changed from **MIT to Apache-2.0**, a more explicit license (including patent provisions) that clarifies usage terms for both commercial and OSS use. Releases at or before v0.5.0 remain MIT-licensed.

### 6. Ongoing security and dependency updates (v0.5.0, v0.7.1)

- Resolved security alerts reported by **CodeQL** (v0.5.0).
- Switched the **Dependabot** Python ecosystem from `pip` to `uv`, so transitive dependencies in `uv.lock` are picked up by scheduled updates (v0.7.1).
- Updated dependencies — idna, SQLAlchemy, FastAPI, pandas, ruff, hypothesis, @vitejs/plugin-react — to their latest versions (v0.7.1).

## How to upgrade

```bash
# pip
pip install -U alpha-visualizer

# uv
uv add alpha-visualizer@latest        # add to a project
uv tool install alpha-visualizer       # use as a CLI
```

The easiest smoke test is the bundled samples (note the command is now `alpha-vis`):

```bash
alpha-vis serve --use-bundled-samples --no-open
# open http://127.0.0.1:8000
```

To view data from your own `alpha-forge` project:

```bash
alpha-vis serve --forge-dir /path/to/your/alpha-strategies
```

There are no changes to the config file (`forge.yaml`); existing alpha-forge projects keep working as-is.

## Related links

- **PyPI**: <https://pypi.org/project/alpha-visualizer/0.7.1/>
- **GitHub Release (tag)**: <https://github.com/alforge-labs/alpha-visualizer/releases/tag/v0.7.1>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **Installation**: [alpha-visualizer / Installation](installation.md)
- **Features**: [alpha-visualizer / Features](features.md)
- **Configuration**: [alpha-visualizer / Configuration](configuration.md)

Please file bugs and feature requests at [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues).
