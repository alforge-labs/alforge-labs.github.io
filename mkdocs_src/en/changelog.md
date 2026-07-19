---
title: AlphaForge Changelog
description: Public release history for the AlphaForge CLI. A user-facing summary of new features, improvements, fixes, and breaking changes per version.
---

# AlphaForge Changelog

A user-facing summary of notable changes in each public AlphaForge CLI release. Distribution binaries (macOS arm64) and checksums for every version are published on [GitHub Releases](https://github.com/alforge-labs/alforge-labs.github.io/releases). See [Getting Started](getting-started.md) for install and update instructions.

!!! info "About this page"
    This page is a **user-facing summary**. Internal refactors, tests, CI, and documentation chores that do not affect usage are omitted. Update to the latest version with `alpha-forge self update`.

---

## v0.18.0 — 2026-07-19

Added the full FX carry (swap) backtesting suite and the fastest onboarding path via `alpha-forge demo`. Multi-strategy portfolios gained strategy-level dynamic allocation.

- **FX carry accrual**: `backtest run --carry` reports daily carry approximated from short-term interest-rate differentials as reference values (`carry_adjusted_*`). Major 8-currency pairs work with zero configuration via built-in FRED rate-series mappings, and importing broker swap-point CSVs with `data alt import-swap` takes precedence over the approximation. Results are persisted to the DB and shown on the alpha-visualizer v0.9.0 detail screen.
- **Fastest onboarding**: The single `alpha-forge demo` command runs everything from initialization to a backtest on the bundled DEMO data. `system init` now auto-places sample data plus a demo strategy, missing-data errors are paste-ready commands, and `system doctor` suggests concrete resolution commands (next_actions).
- **Dynamic allocation for multi-strategy portfolios**: Added strategy-level `risk_parity` / `vol_target` allocation and `--max-pillar-weight` (per-pillar weight cap). WFT warmup pre-fill removes gaps at the start of combined curves.
- **`optimize walk-forward --save`**: Records WFT results so they automatically appear in alpha-visualizer's WFO tab.
- **Run provenance**: Backtest results now record their execution source.

## v0.17.0 — 2026-06-28

Extended the hedge triggers of the buy-hold-overlay strategy scaffold and polished the CLI UX.

- **Hedge trigger extensions**: Added the fast TRAILING_DD hedge trigger and an HMM × TRAILING_DD composite trigger to buy-hold-overlay. The default lookback is now configurable.
- **REGIME_RULE optimization**: Regime-condition firing thresholds can now be optimization targets.
- **`combine --json`**: Outputs the combined portfolio equity_curve as JSON (for chart generation).
- **CLI UX**: Eight polish items including scaffold exit help, chart-path existence validation, and did-you-mean suggestions, plus consistent error display, exit codes, and `--json` / `--help` behavior.

## v0.16.0 — 2026-06-24

The second wave of AI-agent integration: a machine-readable catalog and a `--json` output contract.

- **`system describe`**: A new machine-readable catalog of every command and argument, letting agents self-discover the CLI surface.
- **`--json` contract**: `backtest run --json` now includes `run_id` / `result_id` with token-economized output. Extended `--json` to all read-only commands, unified the default WFT / MC verdicts, and uncaught exceptions now return a structured error envelope. Published a contract reference and versioning policy for the `--json` schemas.
- **Next-step guidance**: Successful commands suggest the next action. `strategy templates` lists the bundled templates.
- **Distributed skills**: Bundled forge-* skills for Codex, and `system init` now deploys a generic AGENTS.md.

## v0.15.0 — 2026-06-23

Hardened diagnostics and data fetching, and improved the first-run experience.

- **`system doctor` / `system paths`**: New environment-diagnostics command, plus a listing of all data locations with backup instructions.
- **Crash resilience**: Uncaught exceptions now fall back with a reporting path and an always-on crash log.
- **Robust data fetching**: Providers gained retries with exponential backoff, OANDA warns instead of silently truncating at its page-fetch limit, and ALTDATA sentiment sources gained retries / caching.
- **Native Pine conversion**: Ten staple indicators convert natively, with a `pine_supported` flag.
- **Maintenance**: Introduced schema versions plus a migration framework for strategy / result JSON. Added `--dry-run` to `strategy delete` / `pine delete`, and a WARNING for the silent fallback when `FORGE_CONFIG` is unset.
- **Docs / English**: `FORGE_LANG=en` fully localizes the top-level help. Added Troubleshooting, a Glossary, and a CLI-only end-to-end sample.

## v0.14.0 — 2026-06-19

Substantially expanded Alpha158-derived indicators, extended metrics, and position sizing.

- **Indicator expansion**: Added Alpha158-derived indicators such as CMO / PERCENTRANK / STDDEV / AROON / PV_CORR / ROLLING_QUANTILE / UP_RATIO / WVMA, plus LINEAR_REG pred / resid (with native Pine conversion). Bundled an EXPR preset collection of nine KBAR formulas.
- **Extended metrics**: Added seven families of extended metrics.
- **Position sizing**: Added `kelly` / `vol_target`.
- **`backtest timeframes`**: New one-shot sweep across timeframes.
- **explore**: Added the `acknowledge` command to mark escalations as read.
- **License grace period**: Extended the offline grace period to 14 days; expiry now degrades to Trial instead of disabling the CLI.
- **Security / fixes**: Resolved 15 dependency vulnerabilities (pillow / urllib3 / protobuf and more). Fixed `risk_based` Pine output size to match the engine, and invalid optimizer param_ranges are now detected before execution (exit 2).

## v0.13.0 — 2026-06-08

Substantially strengthened unattended use from AI agents / CI: eliminated confirmation-prompt hangs, broadened `--json` coverage, and unified exit codes. Many bug fixes as well.

- **AI agent / CI integration**: Added `system config` to observe the effective configuration. Extended `--json` output to the `analyze` / `live` / `journal` / `idea` groups. Unified the exit-code convention (`0`=success / `1`=not found or expected failure / `2`=argument error) across all commands so unattended loops run safely.
- **Non-interactive execution**: `FORGE_NONINTERACTIVE` / `CI` / non-TTY detection eliminates confirmation-prompt hangs. Destructive operations now stop with exit code `2` unless `--yes` is given.
- **Cleanup commands**: Added `optimize clean` / `pine list`・`delete`・`clean` / `data tv-mcp cache-clean`.
- **`self update` now supports Windows**. The combine Pine webhook payload now includes `target_qty` (alpha-strike integration).
- **Fixes**: `backtest --regime` now shows per-regime performance as a label aggregate (`--json` stays pure JSON). Fixed monte-carlo on saved results, auto journal recording, empty-overwrite protection in `data fetch`, and more.
- ⚠️ **Breaking changes**: Renamed `strategy delete`'s `--force` to `--yes`/`-y`, and `--strategy-id` to `--strategy` for `explore log` / `live events` / `live convert-check` (no compatibility aliases). Many commands that returned `exit 0` on error now exit non-zero. Review your scripts / CI branching.

## v0.12.0 — 2026-06-04

Built out the Windows distribution pipeline and improved the first-run setup experience.

- **`system init` improvements**: Added a `DIRECTORY` argument so creation and initialization complete in one command. Added a confirmation prompt against accidental expansion into unintended locations (e.g. directly under home).
- **Windows build pipeline**: Automatic builds on tag push with clcache acceleration, and clang-cl to avoid MSVC heap exhaustion.
- **Auth**: Guides users to the Whop purchase page URL when no license is present.
- Unified the CLI name to `alpha-forge` (resolved rename gaps in docs and messages).

## v0.11.0 — 2026-06-02

Added FRED macro-data integration and macro-regime support.

- **FRED macro-data integration**: Added a macro-data provider (strict vintage look-ahead merge), a macro regime classifier, and `EXTERNAL_SERIES` ML features.
- **Macro event blackout**: Halts entries around FOMC / NFP / CPI. `backtest run --regime-filter` gates entries by macro regime.
- **`FORGE_ACCEPT_EULA`**: Accept the first-run EULA non-interactively (for CI).
- Added `--json` to `strategy list` / `backtest list`. Made the walk-forward OOS aggregation method configurable.
- **Fixes**: Warn instead of silently ignoring `--leverage` in buy-hold-overlay, bundle `v6_signatures.yaml` into the distribution binary, and hardened the authentication flow.

## v0.10.0 — 2026-05-30

Strengthened live (paper-trading) integration and portfolio-level live aggregation.

- **alpha-forge live / replay**: Treats order-reconciliation events (order_reconciled) as the authoritative source and excludes phantom (unfilled) fills, so live performance is computed accurately.
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

- **Setup**: `alpha-forge system init` now scaffolds goal-configuration samples and asset-class templates. Added `--strategy-id` to `strategy create`.
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

- **Fix**: Resolved a failure where `alpha-forge system init` could not expand resources in the distributed binary.

---

For distribution assets and checksums of older versions, see [GitHub Releases](https://github.com/alforge-labs/alforge-labs.github.io/releases).
