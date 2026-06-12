# alpha-forge analyze

戦略分析の補助ツール群。テクニカル指標カタログ（`indicator`）、ML データセット・モデル学習・WFT 検証（`ml`）、ペアトレード用コインテグレーション検定（`pairs`）の 3 サブグループを含みます。

## alpha-forge analyze indicator

`alpha-forge` がサポートするテクニカル指標 50+ のカタログ・詳細を参照します。

## alpha-forge analyze indicator list

対応指標の一覧を表示します。`FILTER_NAME` 指定で部分一致絞り込み（大文字小文字を区別しない）。

```bash
alpha-forge analyze indicator list [FILTER_NAME] [--detail] [--json]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `FILTER_NAME` | 引数（任意） | - | 指標名のフィルタ |
| `--detail` | フラグ | false | 各指標のパラメータ・デフォルト値・説明を表示 |
| `--json` | フラグ | false | 結果を JSON で出力（`{indicators: [...], count}`。`--detail` 併用で各要素に `params` を同梱） |

サンプル出力：

```text
利用可能なインジケーター一覧（60件）:

  [移動平均]  ALMA  DEMA  EMA  HMA  KAMA  RMA  SMA  TEMA  VWMA  WMA
  [トレンド]  ADX  ICHIMOKU  MACD  RANGE_FILTER  SAR  SUPERTREND  SUPERTREND_DIR
  [モメンタム]  AROON  TSI
  [オシレーター]  CCI  CMO  MFI  MOM  PERCENTRANK  ROC  RSI  STOCH  TRIX  UP_RATIO  WILLR
  [ボラティリティ]  ATR  BBANDS  KC  STDDEV
  [出来高]  CMF  OBV  PV_CORR  VWAP  WVMA
  [ピボット/チャネル]  CHANDELIER  DONCHIAN  PIVOTHIGH  PIVOTLOW  ROLLING_QUANTILE
  [統計/ML]  CORRELATION  HALFLIFE  HMM  LINEAR_REG  OU_HALFLIFE  OU_ZSCORE  REGIME_RULE  SEASONAL  ZSCORE
  [高度な機能]  ALTDATA  EXPR  FFILL  GRID_SIGNAL  ML_SIGNAL  ML_SIGNAL_WFT  PRICE

詳細: alpha-forge analyze indicator show <TYPE>
```

## alpha-forge analyze indicator show

指定指標の詳細（説明・パラメータ・出力・使用例）を表示します。

```bash
alpha-forge analyze indicator show <INDICATOR_TYPE> [--json]
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `INDICATOR_TYPE` | 引数（必須） | 指標名（大文字小文字を区別しない） |
| `--json` | フラグ | 指標定義を JSON で出力（`name` / `category` / `desc` / `params` / `available_features` / `output` / `notes` / `example`）。不在時は stdout に `{error, code: "indicator_not_found", id}` + 終了コード `1` |

サンプル出力：

```text
SMA — Simple Moving Average

カテゴリー: 移動平均

パラメーター:
  名前                 型       デフォルト              説明
  length              int      20                    期間

出力: スカラー時系列

使用例 (JSON):
  {"id": "sma_20", "type": "SMA", "params": {"length": 20}}
```

未知の指標名を指定すると `エラー: '<TYPE>' は認識されないインジケーターです。` を出して終了コード `1`。

---

## alpha-forge analyze pairs

ペアトレード戦略のためのコインテグレーション検定とスプレッド構築。`statsmodels` ベースの Engle–Granger 検定を使用。

## alpha-forge analyze pairs scan

2 銘柄のコインテグレーション検定を実行します。

```bash
alpha-forge analyze pairs scan <SYM_A> <SYM_B> [OPTIONS]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `SYM_A`, `SYM_B` | 引数（必須） | - | 検定対象の 2 銘柄 |
| `--method` | choice | `engle_granger` | コインテグレーション検定手法 |
| `--pvalue` | float | `0.05` | コインテグレーションと判定する p 値閾値 |
| `--interval` | オプション | `1d` | 時間足 |
| `--json` | フラグ | false | 検定結果を JSON で出力（`{sym_a, sym_b, method, interval, pvalue_threshold, is_cointegrated, p_value, test_statistic, critical_values}`） |

サンプル出力：

```text
✅ コインテグレーションあり
  ペア      : SPY / QQQ
  p_value    : 0.012345
  閾値      : 0.05
  検定統計量: -3.5421
  臨界値 5%: -2.8623
```

## alpha-forge analyze pairs scan-all

ウォッチリスト内の全ペアをスキャンします（テキスト表示は最大 20 件まで）。

```bash
alpha-forge analyze pairs scan-all --symbols-file <FILE> [--pvalue 0.05] [--interval 1d] [--json]
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `--symbols-file` | 必須（ファイル） | 銘柄リスト（行ごと 1 銘柄、`#` コメント可） |
| `--pvalue` | float | p 値閾値（デフォルト 0.05） |
| `--json` | フラグ | 結果を JSON で出力（`{interval, pvalue_threshold, pairs: [...], count, cointegrated_count}`）。テキスト表示の 20 件上限は `--json` では適用されず**全件**返します。進捗メッセージは `--json` の有無に関わらず標準エラーへ出力されます |

## alpha-forge analyze pairs build

スプレッド系列を計算し、`alt_data` ストアに保存します（戦略 JSON から `ALTDATA` で参照可能）。

```bash
alpha-forge analyze pairs build --sym-a <SYM> --sym-b <SYM> [OPTIONS]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--sym-a` | 必須 | - | 銘柄 A（従属変数） |
| `--sym-b` | 必須 | - | 銘柄 B（独立変数） |
| `--interval` | オプション | `1d` | 時間足 |
| `--log-prices` / `--no-log-prices` | フラグ | `--log-prices` | 対数価格でスプレッドを計算 |
| `--output-id` | オプション | `<A>_<B>_spread` | 保存する `source_key` |
| `--json` | フラグ | false | 結果を JSON で出力（`{sym_a, sym_b, interval, log_prices, source_key, hedge_ratio, half_life, n_rows}`）。進捗メッセージ（「ヘッジ比率を推定中...」等）は `--json` の有無に関わらず標準エラーへ出力 |

サンプル出力：

```text
ヘッジ比率を推定中... (SPY / QQQ)
  ヘッジ比率: 0.823145
  OU 半減期 : 12.4 日
  データ点数: 1530

✅ スプレッドを保存しました: source_key='SPY_QQQ_spread'
   戦略 JSON での参照方法:
   {"id": "spread", "type": "ALTDATA", "params": {"source_key": "SPY_QQQ_spread", "column": "spread"}}
```

平均回帰がない場合、半減期は `N/A (平均回帰なし)` と表示されます。

---

## alpha-forge analyze ml

機械学習モデル用のデータセット作成・モデル学習・walk-forward 検証コマンド群です（issue #512 Phase 1-2, 4）。学習済み joblib モデルは既存の `ML_SIGNAL` 指標から `model_path` 指定で推論に利用できます。

## alpha-forge analyze ml dataset build

保存済み OHLCV から特徴量行列と将来リターンラベルを結合した parquet データセットを生成します。

```bash
alpha-forge analyze ml dataset build EURUSD=X --feature-set default_v1 --label binary:24:0.005 --interval 1h
alpha-forge analyze ml dataset build EURUSD=X --label ternary:24:0.005
alpha-forge analyze ml dataset build EURUSD=X --label regression:5
alpha-forge analyze ml dataset build EURUSD=X --label binary:24:0.005 --json
```

**主なオプション**

| オプション | 説明 | 既定値 |
|-----------|------|-------|
| `--feature-set` | 組み込み feature set 名（`alpha-forge analyze ml dataset feature-sets` で一覧） | `default_v1` |
| `--label` | ラベル仕様文字列（必須） | — |
| `--interval` | 時間足（OHLCV ロード時に使用） | `1d` |
| `--out` | 出力 parquet パス | `<storage_path>/../ml_datasets/<symbol>_<feature_set>_<label_type>_<interval>.parquet` |
| `--keep-nan` | NaN を含む行を残す | False（除外） |
| `--json` | サマリを JSON 出力 | False |

**ラベル仕様文字列**

- `binary:<forward_n>:<threshold_pct>` … forward_n バー後リターンが閾値を超えると 1
- `ternary:<forward_n>:<threshold_pct>` … +閾値超 → 1、−閾値未満 → −1、それ以外 → 0
- `regression:<forward_n>` … forward_n バー後の単純リターンをそのままラベル化
- `triple_barrier:<max_holding>:<atr_mult_up>:<atr_mult_down>:<atr_window>` … López de Prado triple-barrier（issue #520、3 値）。各バーで ATR ベースの上下バリアを設置し、max_holding バーまでの間で先に当たったものでラベル付け（上 → 1、下 → −1、timeout → 0）。ボラティリティ適応的で固定閾値より regime ロバスト
- `triple_barrier_sym:<max_holding>:<atr_mult>:<atr_window>` … triple_barrier の対称版 shorthand（up=down=`atr_mult`）。**新規 dataset の既定推奨**は `triple_barrier_sym:24:1.5:14`（issue #538）
- `triple_barrier_vol:<max_holding>:<vol_mult>:<atr_window>` … barrier scale を ATR の代わりに `rolling_std(returns, atr_window) × close` で計算する volatility-adaptive 版（issue #538）。低ボラ局面で barrier も自動的に縮む
- `triple_barrier_balanced:<max_holding>:<target_long_share>:<atr_window>` … 二分探索で対称 atr_mult を調整して long クラス比率を target に合わせる rebalance mode（issue #538）。例: `target_long_share=0.33` で 3 クラスをほぼ均等にしたい場合

> **issue #538 の背景**: 非対称比 `2.0:1.0` だと SL ヒット側（−1）が分布の半数以上を占める偏向が起きやすい（issue #520 検証で −1 が 64% に集中）。新規 dataset は `triple_barrier_sym:24:1.5:14` を出発点にすると、proba dispersion（issue #537）の screening を通りやすくなります。

parquet ファイルにはシンボル・タイムフレーム・特徴量列名・ラベル設定がメタデータとして同梱されるため、Phase 2 の学習側はファイル単独で再現可能な学習が行えます。

## alpha-forge analyze ml dataset feature-sets

利用可能な組み込み feature set を一覧表示します。

```bash
alpha-forge analyze ml dataset feature-sets [--json]
```

`--json` 指定時は `{feature_sets: [{name, n_specs, specs: [...]}], count}` を純 JSON で出力します。

**組み込み feature set**

| 名前 | 用途 | 内容 |
|---|---|---|
| `default_v1` | 株式・先物等 Volume が有効な銘柄 | LAG(close 1/2/5/10) + PCT_CHANGE(close 1/5) + ROLLING_MEAN/STD/MIN/MAX(20) + PCT_CHANGE(volume 1) |
| `default_v1_fx` | **FX 銘柄**（issue #518） | `default_v1` から `PCT_CHANGE(volume)` を除いたもの。yfinance 系 FX は Volume が常に 0 のため、`default_v1` を使うと `dropna` で全行が消えるバグを回避 |
| `mtf_v1` | **複数タイムフレーム表現**（issue #520） | 短期 lag (1, 6, 24, 48, 120) + 複数 window の rolling 統計 (5, 20, 120, 480) + ボラレジーム + 高安レンジ。Volume を含まないので FX でも使える。`triple_barrier` ラベルとの組合せ推奨 |

## alpha-forge analyze ml train

Phase 1 で生成したデータセット parquet からモデルを学習し、joblib + metrics.json を保存します（issue #512 Phase 2）。

```bash
alpha-forge analyze ml train <DATASET.parquet> [OPTIONS]
```

**主なオプション**

| オプション | 説明 | 既定値 |
|-----------|------|-------|
| `--model` | モデル種別（`alpha-forge analyze ml models` で一覧） | `logistic_regression` |
| `--test-ratio` | 末尾から test に回す比率（時系列順保持） | `0.2` |
| `--random-state` | 乱数シード | `42` |
| `--params` | モデル追加パラメータの JSON 文字列 | — |
| `--out` | 出力 joblib パス | `<storage_path>/../ml_models/<dataset_stem>_<model>.joblib` |
| `--json` | サマリを JSON 出力 | False |

**サポートモデル**

| モデル名 | タスク | 備考 |
|----------|-------|------|
| `logistic_regression` | 分類 | StandardScaler + LogisticRegression パイプライン |
| `random_forest_classifier` | 分類 | sklearn |
| `gradient_boosting_classifier` | 分類 | sklearn |
| `xgboost_classifier` | 分類 | optional（`uv add xgboost` が必要） |
| `linear_regression` | 回帰 | StandardScaler + LinearRegression |
| `random_forest_regressor` | 回帰 | sklearn |
| `gradient_boosting_regressor` | 回帰 | sklearn |
| `xgboost_regressor` | 回帰 | optional（`uv add xgboost` が必要） |

**評価メトリクス**

- 分類: accuracy / precision / recall / f1 / auc（二値分類時のみ）。weighted 平均を採用。
- 回帰: mse / mae / rmse / r2

**確率校正（`--calibration`、issue #519）**

`gradient_boosting_classifier` 等の確率出力は素のままだと特定領域に偏ることがあり、`ml_long_prob >= 0.6` のような閾値が機能しなくなることがあります（issue #512 検証で確認）。`--calibration` オプションで分類モデルの `predict_proba` 出力を校正できます。

| 値 | 説明 |
|---|---|
| `none`（既定） | 校正なし |
| `sigmoid` | Platt scaling（少サンプル向け） |
| `isotonic` | 等浸透回帰（多サンプル向け） |

```bash
alpha-forge analyze ml train ds.parquet --model random_forest_classifier --calibration isotonic
```

回帰モデルに指定した場合は warning 出力 + 無視（base model のまま）。校正された joblib も `ML_SIGNAL` / `ML_SIGNAL_WFT` 指標からそのまま推論可能（scikit-learn 互換 API）。

**保存形式**

- モデル本体: joblib（scikit-learn 互換 API。`predict` / `predict_proba` をそのまま `ML_SIGNAL` 指標から呼べる）
- メトリクス: `<model>.joblib.metrics.json`（`model_type` / `task` / `feature_columns` / `n_train` / `n_test` / `train_metrics` / `test_metrics` / `config`（`calibration` 含む）/ `trained_at` を格納）

## alpha-forge analyze ml models

利用可能なモデル種別（分類 + 回帰）を一覧表示します。

```bash
alpha-forge analyze ml models [--json]
```

`--json` 指定時は `{classification: [...], regression: [...], count}` を純 JSON で出力します。

## alpha-forge analyze ml walk-forward

ML データセット parquet を N ウィンドウに分割し、各ウィンドウで独立に学習・評価して時系列安定性を検証します（issue #512 Phase 4）。モデル本体は保存しません（最終モデルは `alpha-forge analyze ml train` で別途学習）。

```bash
alpha-forge analyze ml walk-forward <DATASET.parquet> [OPTIONS]
```

**主なオプション**

| オプション | 説明 | 既定値 |
|-----------|------|-------|
| `--model` | モデル種別（`alpha-forge analyze ml models` で一覧） | `logistic_regression` |
| `--n-splits` | ウィンドウ数 | `5` |
| `--train-ratio` | 各ウィンドウ内の学習比率 | `0.7` |
| `--random-state` | 乱数シード | `42` |
| `--params` | モデル追加パラメータの JSON 文字列 | — |
| `--out` | レポート JSON 出力先 | `<storage_path>/../ml_models/<dataset_stem>_<model>.walkforward.json` |
| `--json` | サマリを JSON 出力 | False |

**レポート JSON の主要フィールド**

- `model_type` / `task` / `n_splits` / `train_ratio`
- `windows[]`: 各ウィンドウの `fold` / `train_start` / `train_end` / `test_start` / `test_end` / `n_train` / `n_test` / `train_metrics` / `test_metrics`
- `aggregate_train_metrics` / `aggregate_test_metrics`: 各ウィンドウの単純平均
- `dataset`: 元データセットの symbol / interval / feature_set / label_type

**proba dispersion メトリクス（分類タスクのみ、issue #537）**

`aggregate_test_metrics` および各 `windows[].test_metrics` には、accuracy/precision/recall/f1 に加えて `predict_proba` の分布メトリクスが含まれます。これは「accuracy/spread は基準を満たすが proba 値が低位レンジに集中して entry 閾値で実質ほぼ False になる」モデルを screening 段階で検出するためのものです。

| キー | 内容 |
|---|---|
| `proba_max` | 各 fold の正クラス確率の最大値（fold 平均） |
| `proba_p90` / `proba_p95` | 90 / 95 パーセンタイル（fold 平均） |
| `proba_above_055` | 正クラス確率 >= 0.55 の比率（fold 平均、0.0–1.0） |
| `proba_above_060` | 同 >= 0.60 の比率 |

テキスト出力でも集計直下に 1 行表示されます:

```text
proba_dispersion: max=0.568 p90=0.412 p95=0.456 share>=0.55=0.54% share>=0.60=0.12%
```

**読み方の目安**: `share>=0.55` が極小（数 % 以下）の場合、entry 条件で `ml_long_prob >= 0.55` を使うとフィルタが事実上機能しません。閾値を 0.45–0.50 に下げる、`--calibration` で校正する、ラベル仕様を変える（例: `triple_barrier` の barrier 比対称化）などを検討してください。回帰タスクではこれらのキーは出力されません。

**screening 判定と推奨アクション（issue #565）**

`alpha-forge analyze ml walk-forward` は分類タスクの場合、上記メトリクスを使って **3 軸の自動判定** と **推奨アクション** を出力します（出力末尾の SCREENING RESULT / RECOMMENDATION ブロック）。

| 軸 | 既定閾値 | 上書き CLI オプション |
|---|---|---|
| `accuracy`（test 集計平均） | `>= 0.55` | `--screen-accuracy-min` |
| `fold_spread`（各 fold accuracy の最大-最小） | `<= 0.15` | `--screen-spread-max` |
| `proba_dispersion`（`proba_above_055`） | `>= 0.05` | `--screen-proba055-min` |

不合格パターン別の推奨アクション:

| パターン | 推奨 |
|---|---|
| accuracy NG | データ量・特徴量を増やす / モデル種別を変える（`accuracy_low`） |
| accuracy OK / spread NG | データ非定常性が強い → ラベル期間短縮 / regime 別学習（`fold_spread_high`） |
| accuracy/spread OK / proba NG | 閾値下げる / calibration 変える / ラベル比対称化（`proba_low_dispersion`） |
| すべて NG | 学習可能なシグナルではない → 特徴量設計から見直す（`no_learnable_signal`） |

JSON 出力では `screening` フィールドに `criteria` / `recommendations` / `overall_pass` がそのまま入ります。回帰タスクは現状 screening 対象外で、このフィールドは出力されません。

**戦略 JSON の WFT との関係**

- `alpha-forge analyze ml walk-forward`: **ML モデル単体** の時系列安定性検証
- `alpha-forge optimize walk-forward`: **戦略 JSON 全体**（ML_SIGNAL 指標を含む場合もあり）の WFT
- ML 補強戦略の真価は最終的に `alpha-forge optimize walk-forward` で計測。本コマンドはその前段で「学習可能なシグナルか」を選別するために使用する。

## `ML_SIGNAL_WFT` 指標 — leak 安全な ML 補強（issue #517）

`alpha-forge analyze ml train` で保存した joblib モデルを `ML_SIGNAL` 指標から参照すると、`alpha-forge optimize walk-forward` の OOS が学習期間と重複した場合に **look-ahead leak** が発生します（issue #512 Phase 4 検証で確認済み）。これを構造的に解消する新指標が `ML_SIGNAL_WFT` です。

`ML_SIGNAL_WFT` は **指標計算関数自体が「渡された df の先頭 train_ratio で自己学習 → 全体に対して predict」** を行う自己完結型の指標で、WFT エンジン側の変更は不要です。学習区間の予測値は NaN にされ、取引判断には test 区間の予測値のみが使われます。

**戦略 JSON の例**

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

**主要パラメータ**

| パラメータ | 型 | 既定 | 説明 |
|---|---|---|---|
| `model_type` | str | — | `alpha-forge analyze ml models` で表示されるモデル種別 |
| `model_params` | dict | `{}` | モデル追加パラメータ |
| `features` | list | — | `build_feature_matrix` 互換のスペック |
| `label` | str | — | `binary:N:thr` / `ternary:N:thr` / `regression:N` |
| `train_ratio` | float | 0.7 | 先頭の何割を学習に使うか |
| `min_train_rows` | int | 100 | 学習行数がこれ未満なら全 NaN（leak 防止優先） |
| `output` | str | "proba" | "proba"（確率）または "predict"（クラス） |
| `proba_class` | int | 1 | predict_proba のクラスインデックス |
| `threshold` | float \| null | null | 指定があれば proba >= threshold を 1 化 |
| `calibration` | str | "none" | 確率校正（issue #519）。"none" / "sigmoid" / "isotonic" |

**`ML_SIGNAL` との使い分け**

| 指標 | 用途 | leak 耐性 |
|---|---|---|
| `ML_SIGNAL` | 事前学習済みの joblib モデルを参照 | OOS が学習期間外なら安全、重複あれば leak |
| `ML_SIGNAL_WFT` | **WFT 整合の本番運用** — 評価コンテキスト内で自己学習 | **構造的に leak 不可能** |

**学習結果のキャッシュ**

WFT は各ウィンドウで Optuna を N 回試行するため、同じ IS データに対して `_calc_ml_signal_wft` が N 回呼ばれます。再学習を避けるため本指標は **コンテンツアドレス指定型のディスクキャッシュ**（既定: `<storage_path>/../ml_models/wft_cache/`）を持ち、SHA-256 で `(feature_columns, label values, model_type, model_params, random_state)` をキー化して joblib を再利用します。同じ入力なら 2 回目以降はキャッシュヒットで即座に推論可能です。

**Pine Script との関係**

`ML_SIGNAL` と同様、`ML_SIGNAL_WFT` も Pine Script には変換できません。`alpha-forge pine generate` 時には警告コメント付きで `<id> = true` として扱われます。

---

## `--json` の出力規約

`analyze` 配下の参照系コマンド（`indicator list` / `indicator show` / `ml models` / `ml dataset feature-sets` / `pairs scan` / `pairs scan-all` / `pairs build`）は `--json` に対応します（MCP / パイプ用途・装飾なし）。

- `--json` 指定時、stdout は**純 JSON のみ**で、装飾・ヘッダ・進捗・保存メッセージは標準エラーへ分離されます。
- 一覧系は `{<plural>: [...], "count": n}` の envelope（データ不在でも空配列 + 終了コード `0`）。
- `indicator show` の不在は **終了コード `1` を維持**しつつ、`--json` 時は stdout に `{error, code: "indicator_not_found", id}` を返します。
- `pairs build` / `pairs scan-all` の進捗メッセージ（「ヘッジ比率を推定中...」「スキャン中...」等）は `--json` の有無に関わらず**標準エラー**へ出力され、stdout の純度を確保します。
- `pairs scan-all` のテキスト表示にある 20 件上限は、`--json` では**適用されず全件**返されます。

---
