# FRED Macro Data Guide (rates, VIX, CPI)

A guide to pulling [FRED](https://fred.stlouisfed.org/) (Federal Reserve Economic Data) macroeconomic series into AlphaForge for **regime detection, ML features, and event blackouts**.

!!! info "Prerequisites"
    - **Audience**: intermediate users who can already build price-indicator strategies and want to lift expectancy / Sharpe with macro-regime and cross-asset information.
    - **Setup**: AlphaForge binary build, or the `alpha-trade` monorepo development environment.
    - **Look-ahead strict**: everything is processed vintage (by publication date), so revised values are never used early.

## Why macro data

Price-only strategies struggle to read the market "regime" and tend to **enter mechanically even in unfavorable conditions**. Adding macro series — yield curve, VIX, real rates — enables:

- yield curve (10y − 3m) inverts → halt/shrink trend following
- VIX elevated → halt equity longs
- feed real rates / DXY into an ML entry-probability classifier
- halt entries around FOMC/NFP/CPI releases (blackout)

i.e. **stop trading in unfavorable regimes** and **augment ML features** (the goal is improved expectancy/Sharpe rather than raw win rate).

## 1. Set the API key

Get a free FRED API key from the [API key page](https://fred.stlouisfed.org/docs/api/api_key.html) and set the environment variable.

```bash
export FRED_API_KEY="your_fred_api_key"
```

You can also set `data.providers.fred.api_key` in `forge.yaml`.

## 2. Fetch data (vintage / look-ahead strict)

```bash
# Macro series (full revision history stored by publication date realtime_start)
alpha-forge data alt fetch FRED:T10Y3M --start 2000-01-01 --end 2024-12-31   # 10y-3m spread
alpha-forge data alt fetch FRED:VIXCLS --start 2000-01-01 --end 2024-12-31   # VIX
# Event release-date calendar (first-release dates for CPI / NFP)
alpha-forge data alt fetch FRED_RELEASE_DATES --start 2000-01-01 --end 2024-12-31
```

!!! tip "How vintage (revisions) work"
    Every revision of an observation is stored by the date it was published (`realtime_start`). During a backtest, at bar time `t` only the **latest value with `realtime_start <= t`** is used; revisions published after `t` are never peeked at. This structurally avoids the classic "backtesting with macro data peeks into the future" trap.

## 3. Use a macro series in a strategy (ALTDATA)

Reference `source_key="FRED:<series_id>"` via the `ALTDATA` indicator. Example: halt entries while the yield curve is inverted (`< 0`).

```json
"indicators": [
  {"id": "yc", "type": "ALTDATA", "params": {"source_key": "FRED:T10Y3M", "column": "value"}},
  {"id": "yc_regime", "type": "REGIME_RULE", "params": {
    "states": [
      {"label": 1, "condition": {"left": "yc", "op": ">=", "right": 0}},
      {"label": 0, "condition": {"left": "yc", "op": "<", "right": 0}}
    ], "default_label": 1}}
],
"regime_config": {
  "indicator_id": "yc_regime",
  "default_action": "skip",
  "states": {"1": {"entry_conditions": {"long": {"conditions": [ /* your long conditions */ ]}}}}
}
```

## 4. Macro regime analysis

Break metrics down by macro regime (`backtest_config.regime_analysis` with `method="macro"`, threshold + persist-N days).

```json
"regime_analysis": {
  "method": "macro",
  "macro_rules": [
    {"series_column": "yield_curve_10y_3m", "op": "<", "threshold": 0.0, "persist_n": 5, "label_on": 0, "label_off": 1}
  ],
  "label_names": {"0": "risk_off", "1": "risk_on"}
}
```

Available logical columns: `yield_curve_10y_3m` / `yield_curve_10y_2y` / `vix_close` / `dxy_broad` / `real_rate_10y` / `fed_funds` / `unemployment` / `cpi_index`.

## 5. ML features (EXTERNAL_SERIES / macro_v1)

Add `EXTERNAL_SERIES` to `ML_SIGNAL_WFT.features` to feed macro columns into the model. The built-in `macro_v1` set is also available.

```json
"features": [
  {"type": "EXTERNAL_SERIES", "column": "yield_curve_10y_3m", "transform": "level"},
  {"type": "EXTERNAL_SERIES", "column": "vix_close", "transform": "zscore", "window": 60},
  {"type": "LAG", "source": "close", "periods": [1, 5]}
]
```

`transform` is one of `level` / `diff` / `pct_change` / `zscore` (all backward-window only, no look-ahead). Walk-forward (WFT) trains only on the leading `train_ratio` and excludes the training region from predictions, so no leakage is introduced.

## 6. Event blackout

Halt entries N hours around macro releases (daily/4h+ timeframes only).

```json
"risk_management": {
  "event_blackout": ["CPI", "NFP"],
  "event_blackout_hours_before": 24,
  "event_blackout_hours_after": 24
}
```

Requires `alpha-forge data alt fetch FRED_RELEASE_DATES` beforehand.

!!! note "Not look-ahead / about FOMC"
    Release **dates are schedule information** (known in advance), and the **published values themselves are not used**, so this is not look-ahead bias. CPI and NFP are derived from FRED series first-release dates; **FOMC comes from a bundled static schedule** (the Fed's published calendar). The FOMC schedule needs annual updates.

!!! tip "A VIX gate needs no FRED"
    A simple gate like "enter only when VIX < 20" is fully achievable with an external symbol (`symbol: "^VIX"`, yfinance). FRED shines for series not on yfinance — rates, real rates, CPI, etc.
