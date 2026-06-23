# alpha-forge analyze

Strategy-analysis utilities. Three nested subgroups: technical indicators (`indicator`), ML dataset / training / walk-forward (`ml`), and pairs-trading cointegration (`pairs`).

## alpha-forge analyze indicator

Browse the catalog of 50+ technical indicators supported by `alpha-forge`.

## alpha-forge analyze indicator list

List supported indicators. With `FILTER_NAME`, filter by case-insensitive substring.

```bash
alpha-forge analyze indicator list [FILTER_NAME] [--detail] [--json]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `FILTER_NAME` | argument (optional) | - | Filter substring |
| `--detail` | flag | false | Show parameter names, defaults, and descriptions |
| `--json` | flag | false | Emit the result as JSON (`{indicators: [...], count}`; with `--detail`, each element includes `params`) |

Sample output (the category labels such as `移動平均` = moving average are emitted in Japanese regardless of locale; each indicator now carries a Pine-conversion legend, issue #1165):

```text
利用可能なインジケーター一覧（60件）:
凡例: ✓=Pine 変換対応 / ✗=Pine 非対応（pine generate で na・エントリーしない）

  [移動平均]  ALMA✓  DEMA✓  EMA✓  HMA✓  KAMA✗  RMA✓  SMA✓  TEMA✓  VWMA✓  WMA✓
  [トレンド]  ADX✓  ICHIMOKU✗  MACD✓  RANGE_FILTER✗  SAR✓  SUPERTREND✓  SUPERTREND_DIR✗
  [モメンタム]  AROON✓  TSI✓
  [オシレーター]  CCI✓  CMO✓  MFI✓  MOM✓  PERCENTRANK✓  ROC✓  RSI✓  STOCH✓  TRIX✗  UP_RATIO✓  WILLR✓
  [ボラティリティ]  ATR✓  BBANDS✓  KC✗  STDDEV✓
  [出来高]  CMF✗  OBV✓  PV_CORR✓  VWAP✓  WVMA✓
  [ピボット/チャネル]  CHANDELIER✗  DONCHIAN✓  PIVOTHIGH✗  PIVOTLOW✗  ROLLING_QUANTILE✓
  [統計/ML]  CORRELATION✗  HALFLIFE✗  HMM✗  LINEAR_REG✓  OU_HALFLIFE✗  OU_ZSCORE✗  REGIME_RULE✗  SEASONAL✓  ZSCORE✓
  [高度な機能]  ALTDATA✗  EXPR✓  FFILL✗  GRID_SIGNAL✗  ML_SIGNAL✗  ML_SIGNAL_WFT✗  PRICE✓

Details: alpha-forge analyze indicator show <TYPE>
```

!!! tip "Expanded native Pine conversion (issue #1165)"
    GA added native Pine v6 (`ta.*`) conversion for 10 indicators — **CCI / OBV / HMA / VWMA / RMA / ALMA / TSI / DEMA / TEMA / ZSCORE** — and introduced the `pine_supported` flag (`✓` / `✗`) shown above. When a strategy containing a `✗` indicator is passed to `alpha-forge pine generate`, that indicator is treated as `na` (no entry) and a warning comment is inserted into the Pine output. The `--json` output adds a boolean `pine_supported` field to each indicator.

## alpha-forge analyze indicator show

Show detailed information for a specific indicator (description, parameters, output, example).

```bash
alpha-forge analyze indicator show <INDICATOR_TYPE> [--json]
```

| Name | Kind | Description |
|------|------|-------------|
| `INDICATOR_TYPE` | argument (required) | Indicator name (case-insensitive) |
| `--json` | flag | Emit the indicator definition as JSON (`name` / `category` / `desc` / `params` / `available_features` / `output` / `notes` / `example` / `pine_supported`); not-found returns `{error, code: "indicator_not_found", id}` to stdout with exit code `1` |

The detail view also reports **Pine conversion support** (`Pine 変換: 対応 / 非対応`), available as the boolean `pine_supported` in `--json` (issue #1165).

Sample output:

```text
RSI — Relative Strength Index

Category: オシレーター

Parameters:
  Name                 Type     Default                Description
  length              int      14                    Period

Output: float — RSI value (0–100)
Pine 変換: 対応（ta.* へネイティブ変換）

Example (JSON):
  {"id": "rsi_14", "type": "RSI", "params": {"length": 14}}
```

Unknown indicator names print `Error: '<TYPE>' is not a recognized indicator.` and exit with code `1`.

---

## alpha-forge analyze pairs

Cointegration tests and spread series for pair trading. Uses the Engle–Granger test from `statsmodels`.

!!! info "Positioned as a research tool (issue #1177)"
    `analyze pairs` is a **research tool for discovering and validating** pair-trading candidates. The workflow is: find statistically cointegrated pairs with `scan` / `scan-all`, then `build` their spread series into the `alt_data` store, and reference that spread from a strategy JSON via the `ALTDATA` indicator. `pairs` itself neither places orders nor runs backtests — it is a preprocessing / feature-generation stage for building strategies.

    **Typical workflow (combined with ALTDATA)**:

    ```bash
    # 1) Discover candidate pairs via statistical tests
    alpha-forge analyze pairs scan-all --symbols-file watchlist.txt --pvalue 0.05

    # 2) Build the spread series for a promising pair and store it in alt_data
    alpha-forge analyze pairs build --sym-a SPY --sym-b QQQ --output-id SPY_QQQ_spread

    # 3) Reference the spread as an ALTDATA indicator in a strategy JSON (mean-reversion)
    #    e.g. {"id": "spread", "type": "ALTDATA",
    #          "params": {"source_key": "SPY_QQQ_spread", "column": "spread"}}
    alpha-forge backtest run SPY --strategy spy_qqq_spread_meanrev_v1
    ```

## alpha-forge analyze pairs scan

Run a cointegration test on two symbols.

```bash
alpha-forge analyze pairs scan <SYM_A> <SYM_B> [OPTIONS]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `SYM_A`, `SYM_B` | arguments (required) | - | Two symbols to test |
| `--method` | choice | `engle_granger` | Cointegration test method |
| `--pvalue` | float | `0.05` | p-value threshold for cointegration |
| `--interval` | option | `1d` | Timeframe |
| `--json` | flag | false | Emit the test result as JSON (`{sym_a, sym_b, method, interval, pvalue_threshold, is_cointegrated, p_value, test_statistic, critical_values}`) |

Sample output:

```text
✅ Cointegrated
  Pair       : SPY / QQQ
  p_value    : 0.012345
  Threshold  : 0.05
  Test stat  : -3.5421
  Critical 5%: -2.8623
```

## alpha-forge analyze pairs scan-all

Scan all pairs in a watchlist (text output shows the top 20).

```bash
alpha-forge analyze pairs scan-all --symbols-file <FILE> [--pvalue 0.05] [--interval 1d] [--json]
```

| Name | Kind | Description |
|------|------|-------------|
| `--symbols-file` | required (file) | Symbol list (one per line; `#` comments allowed) |
| `--pvalue` | float | p-value threshold (default 0.05) |
| `--json` | flag | Emit the result as JSON (`{interval, pvalue_threshold, pairs: [...], count, cointegrated_count}`). The 20-item cap of the text output does **not** apply to `--json`, which returns **all** pairs. Progress messages go to stderr regardless of `--json` |

## alpha-forge analyze pairs build

Compute spread series and save to the `alt_data` store (referenceable from strategy JSON via `ALTDATA`).

```bash
alpha-forge analyze pairs build --sym-a <SYM> --sym-b <SYM> [OPTIONS]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--sym-a` | required | - | Symbol A (dependent variable) |
| `--sym-b` | required | - | Symbol B (independent variable) |
| `--interval` | option | `1d` | Timeframe |
| `--log-prices` / `--no-log-prices` | flag | `--log-prices` | Use log prices for the spread |
| `--output-id` | option | `<A>_<B>_spread` | `source_key` to save |
| `--json` | flag | false | Emit the result as JSON (`{sym_a, sym_b, interval, log_prices, source_key, hedge_ratio, half_life, n_rows}`). Progress messages (e.g. "Estimating hedge ratio...") go to stderr regardless of `--json` |

Sample output:

```text
Estimating hedge ratio... (SPY / QQQ)
  Hedge ratio: 0.823145
  OU half-life: 12.4 days
  Data points: 1530

✅ Spread saved: source_key='SPY_QQQ_spread'
   How to reference in strategy JSON:
   {"id": "spread", "type": "ALTDATA", "params": {"source_key": "SPY_QQQ_spread", "column": "spread"}}
```

When there is no mean reversion, the half-life is shown as `N/A (no mean reversion)`.

---

## alpha-forge analyze ml

Machine-learning dataset, model training, and walk-forward validation commands (issue #512 Phase 1-2, 4). Trained joblib models can be referenced from the existing `ML_SIGNAL` indicator via `model_path` for inference.

!!! warning "`ML_SIGNAL` leak caveat — prefer `ML_SIGNAL_WFT` for production (issue #1186)"
    Referencing a pretrained joblib model from the `ML_SIGNAL` indicator causes a **look-ahead leak** when the OOS period of `alpha-forge optimize walk-forward` overlaps the training period, which inflates backtest results. For WFT-consistent production use, use the **`ML_SIGNAL_WFT` indicator** (see the dedicated section lower on this page), which self-trains inside the evaluation context and structurally eliminates the leak. Keep `ML_SIGNAL` for research / validation where you can guarantee the OOS never overlaps the training window.

## alpha-forge analyze ml dataset build

Build a feature+forward-return-label parquet dataset from stored OHLCV.

```bash
alpha-forge analyze ml dataset build EURUSD=X --feature-set default_v1 --label binary:24:0.005 --interval 1h
alpha-forge analyze ml dataset build EURUSD=X --label ternary:24:0.005
alpha-forge analyze ml dataset build EURUSD=X --label regression:5
alpha-forge analyze ml dataset build EURUSD=X --label binary:24:0.005 --json
```

**Key options**

| Option | Description | Default |
|--------|-------------|---------|
| `--feature-set` | Built-in feature set name (see `alpha-forge analyze ml dataset feature-sets`) | `default_v1` |
| `--label` | Label spec string (required) | — |
| `--interval` | Bar interval used to load OHLCV | `1d` |
| `--out` | Output parquet path | `<storage_path>/../ml_datasets/<symbol>_<feature_set>_<label_type>_<interval>.parquet` |
| `--keep-nan` | Keep rows containing NaN | False (drops them) |
| `--json` | Print summary as JSON | False |

**Label spec strings**

- `binary:<forward_n>:<threshold_pct>` — 1 if forward_return > threshold, else 0
- `ternary:<forward_n>:<threshold_pct>` — +1 above threshold, −1 below −threshold, 0 in between
- `regression:<forward_n>` — raw forward return as the label
- `triple_barrier:<max_holding>:<atr_mult_up>:<atr_mult_down>:<atr_window>` — López de Prado triple-barrier (issue #520, 3-value). For each bar set ATR-based upper / lower barriers; whichever is hit first within `max_holding` determines the label (up → 1, down → −1, timeout → 0). Volatility-adaptive — more regime-robust than fixed-threshold binary/ternary.
- `triple_barrier_sym:<max_holding>:<atr_mult>:<atr_window>` — symmetric shorthand for triple_barrier (up = down = `atr_mult`). **Recommended default for new datasets**: `triple_barrier_sym:24:1.5:14` (issue #538).
- `triple_barrier_vol:<max_holding>:<vol_mult>:<atr_window>` — volatility-adaptive variant that uses `rolling_std(returns, atr_window) × close` instead of ATR (issue #538). Barriers shrink automatically in low-vol regimes.
- `triple_barrier_balanced:<max_holding>:<target_long_share>:<atr_window>` — rebalance mode that bisects symmetric `atr_mult` until the long-class share matches `target_long_share` (issue #538). Use `target_long_share=0.33` to roughly balance the three classes.

> **Why issue #538**: An asymmetric ratio like `2.0:1.0` tends to bias the label distribution heavily toward the SL side (−1) — issue #520 verification observed −1 ≈ 64% of all labels. Starting new datasets from `triple_barrier_sym:24:1.5:14` makes them far more likely to pass the proba-dispersion screening (issue #537).

The parquet file embeds symbol / interval / feature columns / label config as metadata so Phase 2 training can reproduce the exact pipeline from the file alone.

## alpha-forge analyze ml dataset feature-sets

List available built-in feature sets.

```bash
alpha-forge analyze ml dataset feature-sets [--json]
```

With `--json`, emits `{feature_sets: [{name, n_specs, specs: [...]}], count}` as pure JSON.

**Built-in feature sets**

| Name | Use case | Contents |
|---|---|---|
| `default_v1` | Equities, futures, etc. with non-zero Volume | LAG(close 1/2/5/10) + PCT_CHANGE(close 1/5) + ROLLING_MEAN/STD/MIN/MAX(20) + PCT_CHANGE(volume 1) |
| `default_v1_fx` | **FX symbols** (issue #518) | `default_v1` minus `PCT_CHANGE(volume)`. yfinance FX has Volume always 0 — using `default_v1` would cause `dropna` to wipe out every row. |
| `mtf_v1` | **Multi-timeframe representation** (issue #520) | Multi-scale lags (1, 6, 24, 48, 120) + multi-window rolling stats (5, 20, 120, 480) + volatility regime + high/low ranges. Volume-free so it works on FX. Recommended pairing with `triple_barrier` labels. |

## alpha-forge analyze ml train

Train a model from a Phase 1 dataset parquet and save joblib + metrics.json (issue #512 Phase 2).

```bash
alpha-forge analyze ml train <DATASET.parquet> [OPTIONS]
```

**Key options**

| Option | Description | Default |
|--------|-------------|---------|
| `--model` | Model type (see `alpha-forge analyze ml models`) | `logistic_regression` |
| `--test-ratio` | Tail fraction used as the test split (time-series order preserved) | `0.2` |
| `--random-state` | Random seed | `42` |
| `--params` | Extra model parameters as a JSON string | — |
| `--out` | Output joblib path | `<storage_path>/../ml_models/<dataset_stem>_<model>.joblib` |
| `--json` | Print summary as JSON | False |

**Supported models**

| Model | Task | Notes |
|-------|------|-------|
| `logistic_regression` | Classification | StandardScaler + LogisticRegression pipeline |
| `random_forest_classifier` | Classification | sklearn |
| `gradient_boosting_classifier` | Classification | sklearn |
| `xgboost_classifier` | Classification | optional (`uv add xgboost`) |
| `linear_regression` | Regression | StandardScaler + LinearRegression |
| `random_forest_regressor` | Regression | sklearn |
| `gradient_boosting_regressor` | Regression | sklearn |
| `xgboost_regressor` | Regression | optional (`uv add xgboost`) |

**Evaluation metrics**

- Classification: accuracy / precision / recall / f1 / auc (binary only). Weighted averages.
- Regression: mse / mae / rmse / r2

**Probability calibration (`--calibration`, issue #519)**

Raw probabilities from models like `gradient_boosting_classifier` can cluster in narrow ranges, causing thresholds like `ml_long_prob >= 0.6` to become no-ops (confirmed in issue #512 verification). The `--calibration` option scales `predict_proba` output for classification models.

| Value | Description |
|---|---|
| `none` (default) | No calibration |
| `sigmoid` | Platt scaling (suitable for small samples) |
| `isotonic` | Isotonic regression (more flexible, larger samples) |

```bash
alpha-forge analyze ml train ds.parquet --model random_forest_classifier --calibration isotonic
```

Specifying `--calibration` on a regression model emits a warning and is ignored (base model is used). Calibrated joblib models work as is from the `ML_SIGNAL` / `ML_SIGNAL_WFT` indicators (sklearn-compatible API).

**Storage format**

- Model: joblib (sklearn-compatible API; `predict` / `predict_proba` callable from `ML_SIGNAL` indicator as is)
- Metrics: `<model>.joblib.metrics.json` (model_type / task / feature_columns / n_train / n_test / train_metrics / test_metrics / config (including `calibration`) / trained_at)

## alpha-forge analyze ml models

List available model types (classification + regression).

```bash
alpha-forge analyze ml models [--json]
```

With `--json`, emits `{classification: [...], regression: [...], count}` as pure JSON.

## alpha-forge analyze ml walk-forward

Split a dataset into N windows and train + evaluate a fresh model in each window for time-series stability checks (issue #512 Phase 4). The model is **not** persisted — use `alpha-forge analyze ml train` to produce the final model.

```bash
alpha-forge analyze ml walk-forward <DATASET.parquet> [OPTIONS]
```

**Key options**

| Option | Description | Default |
|--------|-------------|---------|
| `--model` | Model type (see `alpha-forge analyze ml models`) | `logistic_regression` |
| `--n-splits` | Number of windows | `5` |
| `--train-ratio` | Train fraction within each window | `0.7` |
| `--random-state` | Random seed | `42` |
| `--params` | Extra model params as JSON string | — |
| `--out` | Report JSON output path | `<storage_path>/../ml_models/<dataset_stem>_<model>.walkforward.json` |
| `--json` | Print summary as JSON | False |

**Report JSON fields**

- `model_type` / `task` / `n_splits` / `train_ratio`
- `windows[]`: per-window `fold` / `train_start` / `train_end` / `test_start` / `test_end` / `n_train` / `n_test` / `train_metrics` / `test_metrics`
- `aggregate_train_metrics` / `aggregate_test_metrics`: arithmetic mean across windows
- `dataset`: symbol / interval / feature_set / label_type from the source dataset

**Proba dispersion metrics (classification only, issue #537)**

For classification tasks, `aggregate_test_metrics` and each `windows[].test_metrics` include `predict_proba` distribution metrics in addition to accuracy/precision/recall/f1. They surface "models that look learnable by accuracy/spread but whose proba output is squashed into a low range so any entry threshold filters out almost every bar":

| Key | Meaning |
|---|---|
| `proba_max` | Per-fold maximum positive-class probability (fold mean) |
| `proba_p90` / `proba_p95` | 90 / 95 percentile (fold mean) |
| `proba_above_055` | Share of bars with positive-class probability >= 0.55 (fold mean, 0.0–1.0) |
| `proba_above_060` | Share with probability >= 0.60 (fold mean, 0.0–1.0) |

The text output also prints a one-line summary right after the aggregate block:

```text
proba_dispersion: max=0.568 p90=0.412 p95=0.456 share>=0.55=0.54% share>=0.60=0.12%
```

**How to read it**: A near-zero `share>=0.55` means an `ml_long_prob >= 0.55` entry filter never fires — lower the threshold to 0.45–0.50, calibrate the model with `--calibration`, or revise the label spec (for example, symmetrize the `triple_barrier` ratio). Regression tasks have no `predict_proba`, so these keys are omitted.

**Screening verdict and recommendations (issue #565)**

For classification tasks, `alpha-forge analyze ml walk-forward` automatically prints a **three-axis verdict** and **recommendations** (the SCREENING RESULT / RECOMMENDATION block at the end of the output).

| Axis | Default threshold | CLI override |
|---|---|---|
| `accuracy` (aggregate test mean) | `>= 0.55` | `--screen-accuracy-min` |
| `fold_spread` (max - min of per-fold test accuracy) | `<= 0.15` | `--screen-spread-max` |
| `proba_dispersion` (`proba_above_055`) | `>= 0.05` | `--screen-proba055-min` |

Recommendations follow the pass/fail pattern across the three axes:

| Pattern | Recommendation |
|---|---|
| accuracy NG | More data / wider feature set / try another model (`accuracy_low`) |
| accuracy OK / spread NG | Non-stationarity → shorten label horizon / regime-split training (`fold_spread_high`) |
| accuracy/spread OK / proba NG | Lower entry threshold / change calibration / symmetrize labels (`proba_low_dispersion`) |
| All NG | Not a learnable signal → redesign features (`no_learnable_signal`) |

The JSON output carries the same data as a top-level `screening` field with `criteria` / `recommendations` / `overall_pass`. Regression tasks are out of scope and the field is omitted.

**Relation to strategy WFT**

- `alpha-forge analyze ml walk-forward`: stability of the **ML model itself** over time
- `alpha-forge optimize walk-forward`: WFT of the **whole strategy JSON** (which may include `ML_SIGNAL`)
- The end-to-end measure of an ML-augmented strategy is `alpha-forge optimize walk-forward`. This command is a screening step: is the signal even learnable?

## `ML_SIGNAL_WFT` indicator — leak-safe ML augmentation (issue #517)

Referencing a `alpha-forge analyze ml train` joblib via the `ML_SIGNAL` indicator causes **look-ahead leak** in `alpha-forge optimize walk-forward` whenever the OOS overlaps the model's training period (confirmed in issue #512 Phase 4 verification). The new `ML_SIGNAL_WFT` indicator resolves this structurally.

`ML_SIGNAL_WFT` is **a self-contained indicator that trains on the first `train_ratio` of the input df and predicts over the whole df**. The WFT engine itself is unchanged. Predictions over the training segment are forced to NaN, so only the test segment ever drives trade decisions.

**Strategy JSON example**

```json
{
  "id": "ml_long_prob",
  "type": "ML_SIGNAL_WFT",
  "params": {
    "model_type": "gradient_boosting_classifier",
    "model_params": {"n_estimators": 200, "max_depth": 5},
    "features": [
      {"type": "LAG", "source": "close", "periods": [1, 2, 5, 10]},
      {"type": "PCT_CHANGE", "source": "close", "periods": 1},
      {"type": "ROLLING_MEAN", "source": "close", "window": 20}
    ],
    "label": "binary:24:0.005",
    "train_ratio": 0.7,
    "min_train_rows": 500,
    "random_state": 42,
    "output": "proba",
    "proba_class": 1,
    "threshold": null
  }
}
```

**Key parameters**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `model_type` | str | — | Model type from `alpha-forge analyze ml models` |
| `model_params` | dict | `{}` | Extra model parameters |
| `features` | list | — | `build_feature_matrix`-compatible spec |
| `label` | str | — | `binary:N:thr` / `ternary:N:thr` / `regression:N` |
| `train_ratio` | float | 0.7 | Head fraction used for training |
| `min_train_rows` | int | 100 | All-NaN if training rows fall below (leak-prevention priority) |
| `output` | str | "proba" | "proba" (probability) or "predict" (class) |
| `proba_class` | int | 1 | Class index for `predict_proba` |
| `threshold` | float \| null | null | Binarize proba >= threshold to 1 if set |
| `calibration` | str | "none" | Probability calibration (issue #519). "none" / "sigmoid" / "isotonic" |

**`ML_SIGNAL` vs `ML_SIGNAL_WFT`**

| Indicator | Use case | Leak resilience |
|---|---|---|
| `ML_SIGNAL` | Reference a pretrained joblib | Safe only if OOS is outside the training period |
| `ML_SIGNAL_WFT` | **WFT-aligned production** — self-trains within the evaluation context | **Structurally leak-free** |

**Cache for trained artifacts**

WFT runs Optuna N trials per window, calling `_calc_ml_signal_wft` N times on identical IS data. To avoid redundant retraining, this indicator uses a **content-addressed disk cache** (default: `<storage_path>/../ml_models/wft_cache/`), keying joblib artifacts by SHA-256 over `(feature_columns, label values, model_type, model_params, random_state)`. Subsequent calls with the same input hit the cache instantly.

**Pine Script integration**

Like `ML_SIGNAL`, `ML_SIGNAL_WFT` is not Pine Script-translatable. `alpha-forge pine generate` emits a warning comment and treats the signal as `<id> = true`.

---

## `--json` output rules

The reference-style commands under `analyze` (`indicator list` / `indicator show` / `ml models` / `ml dataset feature-sets` / `pairs scan` / `pairs scan-all` / `pairs build`) support `--json` (for MCP / pipe usage, no decoration).

- When `--json` is set, stdout contains **pure JSON only**; decoration, headers, progress, and save messages go to stderr.
- List commands return a `{<plural>: [...], "count": n}` envelope (empty array + exit code `0` even when absent).
- `indicator show` keeps **exit code `1`** on not-found, and with `--json` returns `{error, code: "indicator_not_found", id}` to stdout.
- Progress messages from `pairs build` / `pairs scan-all` (e.g. "Estimating hedge ratio...", "Scanning...") go to **stderr** regardless of `--json`, keeping stdout pure.
- The 20-item cap of the `pairs scan-all` text output does **not** apply to `--json`, which returns **all** pairs.

---
