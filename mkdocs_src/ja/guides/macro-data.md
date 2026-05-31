# FRED マクロデータ活用ガイド（金利・VIX・CPI）

[FRED](https://fred.stlouisfed.org/)（Federal Reserve Economic Data）のマクロ経済系列を AlphaForge に取り込み、**レジーム判定・ML 特徴量・イベントブラックアウト**に活用するガイドです。

!!! info "前提"
    - **対象読者**: 価格指標ベースの戦略を一通り作れる中級者。マクロ regime / クロスアセット情報で期待値・Sharpe を底上げしたい方。
    - **前提**: AlphaForge バイナリ版、または `alpha-trade` モノレポ開発環境。
    - **look-ahead 厳密**: すべて vintage（公表日ベース）で処理され、改定値の先取りは起きません。

## なぜマクロデータか

価格指標だけの戦略は「相場の地合い（regime）」を捉えにくく、**不利な局面でも機械的にエントリー**しがちです。イールドカーブ・VIX・実質金利などのマクロ系列を併用すると、

- yield curve（10年−3ヶ月）が陰転 → トレンドフォローを停止／縮小
- VIX 高位 → 株式ロングを停止
- 実質金利・DXY を ML 特徴量に投入してエントリー確率分類器を補強
- FOMC/NFP/CPI 発表前後はエントリーを停止（ブラックアウト）

といった「**不利な局面でのトレード停止**」「**ML 特徴量の補強**」が可能になります（勝率より期待値・Sharpe の改善が主目的）。

## 1. API キーの設定

FRED の無料 API キーを [API key ページ](https://fred.stlouisfed.org/docs/api/api_key.html) で取得し、環境変数に設定します。

```bash
export FRED_API_KEY="your_fred_api_key"
```

`forge.yaml` の `data.providers.fred.api_key` でも設定できます。

## 2. データ取得（vintage / look-ahead 厳密）

```bash
# マクロ系列（全改定履歴を公表日 realtime_start で保存）
alpha-forge data alt fetch FRED:T10Y3M --start 2000-01-01 --end 2024-12-31   # 10年-3ヶ月スプレッド
alpha-forge data alt fetch FRED:VIXCLS --start 2000-01-01 --end 2024-12-31   # VIX
# イベント公表日カレンダー（CPI / NFP の初回公表日）
alpha-forge data alt fetch FRED_RELEASE_DATES --start 2000-01-01 --end 2024-12-31
```

!!! tip "vintage（改定）の扱い"
    各観測値の全改定を、その値が公表された日（`realtime_start`）で保持します。バックテストではバー時刻 `t` に対し `realtime_start <= t` を満たす **最新の公表値のみ** 参照され、`t` より後に公表された改定値は先取りされません。これが「マクロデータでのバックテストは未来を覗いてしまう」典型的な罠を構造的に防ぎます。

## 3. 戦略でマクロ系列を使う（ALTDATA）

`ALTDATA` 指標で `source_key="FRED:<series_id>"` を参照します。例: イールドカーブ陰転（`< 0`）局面ではエントリーを停止する。

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
  "states": {"1": {"entry_conditions": {"long": {"conditions": [ /* 通常のロング条件 */ ]}}}}
}
```

## 4. マクロ regime 分析

メトリクスをマクロレジーム別に分解できます（`backtest_config.regime_analysis` の `method="macro"`、しきい値 + 持続 N 日）。

```json
"regime_analysis": {
  "method": "macro",
  "macro_rules": [
    {"series_column": "yield_curve_10y_3m", "op": "<", "threshold": 0.0, "persist_n": 5, "label_on": 0, "label_off": 1}
  ],
  "label_names": {"0": "risk_off", "1": "risk_on"}
}
```

利用可能な論理列名: `yield_curve_10y_3m` / `yield_curve_10y_2y` / `vix_close` / `dxy_broad` / `real_rate_10y` / `fed_funds` / `unemployment` / `cpi_index`。

## 5. ML 特徴量（EXTERNAL_SERIES / macro_v1）

`ML_SIGNAL_WFT` の `features` に `EXTERNAL_SERIES` を指定すると、マクロ列を ML 特徴量に投入できます。組み込みセット `macro_v1` も利用できます。

```json
"features": [
  {"type": "EXTERNAL_SERIES", "column": "yield_curve_10y_3m", "transform": "level"},
  {"type": "EXTERNAL_SERIES", "column": "vix_close", "transform": "zscore", "window": 60},
  {"type": "LAG", "source": "close", "periods": [1, 5]}
]
```

`transform` は `level` / `diff` / `pct_change` / `zscore`（いずれも過去窓のみで未来参照なし）。ウォークフォワード（WFT）では先頭 `train_ratio` のみで学習し、学習区間の予測は除外されるため leak が混入しません。

## 6. イベントブラックアウト

マクロ統計の公表前後 N 時間はエントリーを停止できます（日足/4h 以上が対象）。

```json
"risk_management": {
  "event_blackout": ["CPI", "NFP"],
  "event_blackout_hours_before": 24,
  "event_blackout_hours_after": 24
}
```

事前に `alpha-forge data alt fetch FRED_RELEASE_DATES` が必要です。

!!! note "look-ahead ではない / FOMC について"
    リリース**日時はスケジュール情報**（事前に分かる）であり、公表される**数値そのものは使わない**ため look-ahead bias には当たりません。CPI・NFP は FRED 系列の初回公表日から導出、**FOMC は同梱の静的スケジュール**（Fed 公表の確定日程）から提供されます。FOMC スケジュールは年次更新が必要です。

!!! tip "VIX ゲートだけなら FRED 不要"
    「VIX < 20 でのみエントリー」のような単純なゲートは、外部シンボル（`symbol: "^VIX"`、yfinance）だけで完結します。FRED は金利・実質金利・CPI など、yfinance に無いマクロ系列で威力を発揮します。
