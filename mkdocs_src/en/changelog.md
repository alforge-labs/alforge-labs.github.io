---
title: AlphaForge Changelog
description: Public release history for the AlphaForge CLI. A user-facing summary of new features, improvements, fixes, and breaking changes per version.
---

# AlphaForge Changelog

A user-facing summary of notable changes in each public AlphaForge CLI release. Distribution binaries (macOS arm64) and checksums for every version are published on [GitHub Releases](https://github.com/alforge-labs/alforge-labs.github.io/releases). See [Getting Started](getting-started.md) for install and update instructions.

!!! info "About this page"
    This page is a **user-facing summary**. Internal refactors, tests, CI, and documentation chores that do not affect usage are omitted. Update to the latest version with `alpha-forge self update`.

---

## v0.10.0 — 2026-05-30

Strengthened live (paper-trading) integration and portfolio-level live aggregation.

- **forge live / replay**: Treats order-reconciliation events (order_reconciled) as the authoritative source and excludes phantom (unfilled) fills, so live performance is computed accurately.
- **Combine Portfolio live aggregation**: Persists position-based live performance of always-in-market overlay strategies to SQLite, laying the groundwork for visualization in [alpha-visualizer](alpha-visualizer/index.md).
- **Fix**: Corrected `signal_id` timestamp formatting in Combine Portfolio Pine output.

## v0.9.0 — 2026-05-29

Full support for a Buy & Hold benchmark with a hedge overlay, plus multi-strategy portfolios.

- **Buy & Hold + hedge overlay**: Added `always_in_market` and benchmark configuration, enabling strategies that stay invested while dynamically adjusting hedge allocation by regime. New metrics for alpha, hedge efficiency, and average exposure.
- **Combine Portfolio backtest**: Combined backtests across multiple strategies (custom weights, walk-forward validation, dividend reinvestment).
- **Combine Portfolio Pine v6 output**: A hybrid-strategy mode that exports an integrated portfolio as a TradingView Pine script, with verification against the TradingView Strategy Tester.
- **Exploration diagnostics**: Over-trading gates, validation-window shortening adaptive to data length, and per-strategy-type blocker tallies.

## v0.8.0 — 2026-05-21

Hardened the health diagnostics and quality gates of autonomous exploration.

- **Exploration health**: A selection guide with two-stage thresholds, insufficient-bars diagnostics, staged drawdown-floor relief, and a stall-detection trigger that halts the loop.
- **Strategy scaffolding gates**: Detection of mean-reversion × SuperTrend structural contradictions, asset-volatility-aware stop-loss/take-profit defaults, indicator-overload warnings (warn at 4+, abort at 5+), and an indicator-concentration guard.

## v0.7.0 — 2026-05-21

Major progress on cost realism and TradingView consistency.

- **Per-broker cost presets**: Spread, maker/taker fees, and IBKR-style per-share fees reflected in backtests.
- **TradingView cross-validation**: Reconciles generated Pine against the TradingView Strategy Tester to verify result consistency, with tolerance profiles for SL/TP strategies.
- **Pine quality**: A post-generation validator based on the Pine v6 signature database, plus an option to bake the date filter into Pine output.
- **Exploration metrics**: Leverage-adjusted CAGR, Calmar recommendations, and walk-forward dispersion metrics.

## v0.6.0 — 2026-05-18

Expanded the first-run experience and supported markets.

- **Setup**: `forge system init` now scaffolds goal-configuration samples and asset-class templates. Added `--strategy-id` to `strategy create`.
- **Crypto support**: A dedicated Binance data provider, fetching 4h/1h over 5+ years.
- **alpha-strike integration**: `pine generate --with-webhook` automatically adds order-routing inputs/alerts to Pine.
- **Benchmark**: `--no-benchmark` disables benchmark comparison.

## v0.5.1 – v0.5.3 — 2026-05-15 to 16 (hotfixes)

- **v0.5.3**: Added a Trial-plan fallback so users without Whop authentication can still run the CLI. Fixed data-fetch guidance shown on errors.
- **v0.5.2 / v0.5.1**: Fixed resource-path resolution in the distributed (Nuitka) binary, and a Trial-UX improvement that lets `system init` / `docs` run without authentication.

## v0.5.0 — 2026-05-15

Unified the product-family naming.

- **Breaking change**: Renamed the CLI command from `forge` to **`alpha-forge`** for product-family symmetry. Distribution binaries are likewise named `alpha-forge-*`.
- **Improvements**: Added a mechanism that turns known exceptions into action-oriented messages. UX improvements to optimize/backtest output.

## v0.4.0 — 2026-05-14

Dramatically improved startup speed.

- **Performance**: Lazy-loading of subcommands cut warm startup from ~2.6s to ~0.08s. Distribution-binary cold start dropped from ~97s to ~7s.
- **self-update**: Added a post-replace smoke test and a spinner display.
- **Breaking change**: Trimmed the bundled strategy templates from 34 to a curated 7.

## v0.3.5 — 2026-05-13

- **Fix**: Resolved a failure where `forge system init` could not expand resources in the distributed binary.

---

For distribution assets and checksums of older versions, see [GitHub Releases](https://github.com/alforge-labs/alforge-labs.github.io/releases).
