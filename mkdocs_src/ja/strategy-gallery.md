# 戦略実例ギャラリー

このページは、市場・目的別に戦略候補を選ぶための短い実例カタログです。既存の [戦略テンプレート](templates.md) は代表テンプレートの深い解説と全文JSONを扱い、このギャラリーは「どの戦略を、どの市場で、どう試すか」を素早く比較するために使います。

!!! info "JSON例について"
    各JSONは要点スニペットです。実際に保存する場合は、必要な `risk_management` や `optimizer_config` を補ってから `alpha-forge strategy validate` で確認してください。過去データの検証結果は将来の成果を保証しません。

## 一覧

| 実例 | 主な目的 | 想定シンボル | Pine Script生成可否 |
|---|---|---|---|
| HMM + BB + RSI | レジーム適応型の平均回帰 | `QQQ` | 可 |
| MACD + RSI | モメンタムと過熱感の併用 | `SPY` | 可 |
| トレンドフォロー | 明確な上昇トレンドへの追随 | `AAPL` | 可 |
| 平均回帰 | レンジ内の行き過ぎから反発を狙う | `MSFT` | 可 |
| FXペア向け | 主要通貨ペアの短中期検証 | `EURUSD=X` | 可 |
| インデックスETF向け | ETF横断で頑健な設定を探す | `SPY` | 可 |
| 商品先物向け | 商品特有のトレンド/レンジを扱う | `CL=F` | 条件付き可 |

## HMM + BB + RSI

| 項目 | 内容 |
|---|---|
| 目的 | HMMで相場レジームを分け、BB下限とRSI過売で平均回帰エントリーを試す |
| 向いている市場 | トレンドとレンジが入れ替わる大型ETFや高流動性銘柄 |
| 戦略タイプ | レジーム適応 + 平均回帰 |
| 主要指標 | HMM, BBANDS, RSI, ATR |
| 想定シンボル | `QQQ`, `SPY` |
| Pine Script生成可否 | 可。HMMを使う場合は `--with-training-data` の併用を検討 |

### JSON要点スニペット

```json
{
  "strategy_id": "gallery_hmm_bb_rsi_v1",
  "target_symbols": ["QQQ"],
  "indicators": [
    { "id": "regime", "type": "HMM", "params": { "n_components": 3, "features": ["return", "volatility"] } },
    { "id": "bb_lower", "type": "BBANDS", "params": { "length": 20, "std": 2.0, "line": "lower" } },
    { "id": "rsi", "type": "RSI", "params": { "length": 7 } }
  ],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [
    { "left": "close", "op": "<", "right": "bb_lower" },
    { "left": "rsi", "op": "<", "right": "35" }
  ]}}
}
```

### 実行コマンド

```bash
alpha-forge strategy save data/strategies/gallery_hmm_bb_rsi_v1.json
alpha-forge strategy validate gallery_hmm_bb_rsi_v1
alpha-forge backtest run QQQ --strategy gallery_hmm_bb_rsi_v1 --json
alpha-forge optimize run QQQ --strategy gallery_hmm_bb_rsi_v1 --metric sharpe_ratio --save
alpha-forge pine generate --strategy gallery_hmm_bb_rsi_v1 --with-training-data
```

### 結果の読み方

Sharpeだけでなく、レジーム別の取引数とMax Drawdownを確認します。Bear相当の局面で取引が残りすぎる場合は、HMM状態ごとの条件分岐を強めます。

### 改良ポイント

`rsi` 期間、BBの標準偏差、HMMの状態数を最適化対象にします。詳細な全文JSONは [戦略テンプレート](templates.md) を参照してください。

## MACD + RSI

| 項目 | 内容 |
|---|---|
| 目的 | MACDの方向感にRSIの過熱/過冷却フィルタを加え、だましを減らす |
| 向いている市場 | 中期モメンタムが出やすい株式・ETF |
| 戦略タイプ | モメンタム + フィルタ |
| 主要指標 | MACD, RSI, EMA |
| 想定シンボル | `SPY`, `NVDA` |
| Pine Script生成可否 | 可 |

### JSON要点スニペット

```json
{
  "strategy_id": "gallery_macd_rsi_v1",
  "target_symbols": ["SPY"],
  "indicators": [
    { "id": "macd", "type": "MACD", "params": { "fast": 12, "slow": 26, "signal": 9, "line": "macd" } },
    { "id": "macd_signal", "type": "MACD", "params": { "fast": 12, "slow": 26, "signal": 9, "line": "signal" } },
    { "id": "rsi", "type": "RSI", "params": { "length": 14 } }
  ],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [
    { "left": "macd", "op": "crosses_above", "right": "macd_signal" },
    { "left": "rsi", "op": "<", "right": "70" }
  ]}}
}
```

### 実行コマンド

```bash
alpha-forge strategy save data/strategies/gallery_macd_rsi_v1.json
alpha-forge strategy validate gallery_macd_rsi_v1
alpha-forge backtest run SPY --strategy gallery_macd_rsi_v1 --json
alpha-forge optimize run SPY --strategy gallery_macd_rsi_v1 --metric sharpe_ratio --save
alpha-forge pine generate --strategy gallery_macd_rsi_v1
```

### 結果の読み方

取引数が少なすぎる場合、MACDクロス条件が厳しすぎます。勝率よりもPF、平均損益、連敗時のドローダウンを合わせて確認します。

### 改良ポイント

RSI上限を60-80で試し、MACDのfast/slow期間を最適化します。トレンドが弱い銘柄ではEMAフィルタを追加します。

## トレンドフォロー

| 項目 | 内容 |
|---|---|
| 目的 | 上昇トレンドの継続局面だけに乗る |
| 向いている市場 | 個別株、株式ETF、商品先物の強いトレンド局面 |
| 戦略タイプ | トレンドフォロー |
| 主要指標 | EMA, ADX, ATR |
| 想定シンボル | `AAPL`, `NVDA` |
| Pine Script生成可否 | 可 |

### JSON要点スニペット

```json
{
  "strategy_id": "gallery_trend_follow_v1",
  "target_symbols": ["AAPL"],
  "indicators": [
    { "id": "ema_fast", "type": "EMA", "params": { "length": 20 } },
    { "id": "ema_slow", "type": "EMA", "params": { "length": 100 } },
    { "id": "adx", "type": "ADX", "params": { "length": 14 } }
  ],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [
    { "left": "ema_fast", "op": ">", "right": "ema_slow" },
    { "left": "adx", "op": ">", "right": "20" }
  ]}}
}
```

### 実行コマンド

```bash
alpha-forge strategy save data/strategies/gallery_trend_follow_v1.json
alpha-forge strategy validate gallery_trend_follow_v1
alpha-forge backtest run AAPL --strategy gallery_trend_follow_v1 --json
alpha-forge optimize run AAPL --strategy gallery_trend_follow_v1 --metric sharpe_ratio --save
alpha-forge pine generate --strategy gallery_trend_follow_v1
```

### 結果の読み方

トレンドフォローは勝率が低くてもPFや平均勝ち幅が高ければ成立します。Max Drawdownが大きい場合はATRベースの損切りを見直します。

### 改良ポイント

ADX閾値とEMA期間を最適化し、週足SMAなど上位足フィルタを追加します。

## 平均回帰

| 項目 | 内容 |
|---|---|
| 目的 | レンジ相場で売られすぎからの反発を狙う |
| 向いている市場 | 大型株、ETF、ボラティリティが極端でない銘柄 |
| 戦略タイプ | 平均回帰 |
| 主要指標 | BBANDS, RSI, ATR |
| 想定シンボル | `MSFT`, `SPY` |
| Pine Script生成可否 | 可 |

### JSON要点スニペット

```json
{
  "strategy_id": "gallery_mean_reversion_v1",
  "target_symbols": ["MSFT"],
  "indicators": [
    { "id": "bb_lower", "type": "BBANDS", "params": { "length": 20, "std": 2.0, "line": "lower" } },
    { "id": "bb_mid", "type": "BBANDS", "params": { "length": 20, "std": 2.0, "line": "mid" } },
    { "id": "rsi", "type": "RSI", "params": { "length": 10 } }
  ],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [
    { "left": "close", "op": "<", "right": "bb_lower" },
    { "left": "rsi", "op": "<", "right": "35" }
  ]}}
}
```

### 実行コマンド

```bash
alpha-forge strategy save data/strategies/gallery_mean_reversion_v1.json
alpha-forge strategy validate gallery_mean_reversion_v1
alpha-forge backtest run MSFT --strategy gallery_mean_reversion_v1 --json
alpha-forge optimize run MSFT --strategy gallery_mean_reversion_v1 --metric sharpe_ratio --save
alpha-forge pine generate --strategy gallery_mean_reversion_v1
```

### 結果の読み方

平均回帰は急落相場で損失が連続しやすいため、連敗数と最大保有期間を確認します。反発までの保有が長すぎる場合は時間切れ決済を検討します。

### 改良ポイント

上位足のトレンドフィルタやボラティリティフィルタを追加し、強い下落トレンドでは取引を止めます。

## FXペア向け

| 項目 | 内容 |
|---|---|
| 目的 | 主要通貨ペアで短中期のトレンドと過熱感を検証する |
| 向いている市場 | EURUSD=X, USDJPY=X など流動性の高いFXペア |
| 戦略タイプ | トレンド + オシレーター |
| 主要指標 | SMA, RSI, ATR |
| 想定シンボル | `EURUSD=X`, `USDJPY=X` |
| Pine Script生成可否 | 可 |

### JSON要点スニペット

```json
{
  "strategy_id": "gallery_fx_pair_v1",
  "target_symbols": ["EURUSD=X"],
  "asset_type": "fx",
  "indicators": [
    { "id": "sma_fast", "type": "SMA", "params": { "length": 20 } },
    { "id": "sma_slow", "type": "SMA", "params": { "length": 80 } },
    { "id": "rsi", "type": "RSI", "params": { "length": 14 } }
  ],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [
    { "left": "sma_fast", "op": ">", "right": "sma_slow" },
    { "left": "rsi", "op": "<", "right": "65" }
  ]}}
}
```

### 実行コマンド

```bash
alpha-forge strategy save data/strategies/gallery_fx_pair_v1.json
alpha-forge strategy validate gallery_fx_pair_v1
alpha-forge backtest run EURUSD=X --strategy gallery_fx_pair_v1 --json
alpha-forge optimize run EURUSD=X --strategy gallery_fx_pair_v1 --metric sharpe_ratio --save
alpha-forge pine generate --strategy gallery_fx_pair_v1
```

### 結果の読み方

FXはトレンドが短く反転しやすいため、平均保有期間とPFを重視します。通貨ペアごとのボラティリティ差でATR設定が効きすぎていないか確認します。

### 改良ポイント

USDJPY=XやGBPUSD=Xでも同じ戦略を検証し、`alpha-forge optimize cross-symbol` でペア横断の頑健性を確認します。

## インデックスETF向け

| 項目 | 内容 |
|---|---|
| 目的 | SPY/QQQ/IWMなど複数ETFで過剰最適化に強い設定を探す |
| 向いている市場 | 米国インデックスETF |
| 戦略タイプ | クロスシンボル検証 |
| 主要指標 | SMA, RSI, ATR |
| 想定シンボル | `SPY`, `QQQ`, `IWM` |
| Pine Script生成可否 | 可 |

### JSON要点スニペット

```json
{
  "strategy_id": "gallery_index_etf_v1",
  "target_symbols": ["SPY", "QQQ", "IWM"],
  "indicators": [
    { "id": "sma_50", "type": "SMA", "params": { "length": 50 } },
    { "id": "sma_200", "type": "SMA", "params": { "length": 200 } },
    { "id": "rsi", "type": "RSI", "params": { "length": 14 } }
  ],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [
    { "left": "sma_50", "op": ">", "right": "sma_200" },
    { "left": "rsi", "op": "<", "right": "70" }
  ]}}
}
```

### 実行コマンド

```bash
alpha-forge strategy save data/strategies/gallery_index_etf_v1.json
alpha-forge strategy validate gallery_index_etf_v1
alpha-forge backtest run SPY --strategy gallery_index_etf_v1 --json
alpha-forge optimize run SPY --strategy gallery_index_etf_v1 --metric sharpe_ratio --save
alpha-forge pine generate --strategy gallery_index_etf_v1
```

### 結果の読み方

単一ETFだけで良い結果が出ても、QQQやIWMで崩れる場合は過剰最適化の可能性があります。銘柄横断でSharpeとMax Drawdownを比較します。

### 改良ポイント

`alpha-forge optimize cross-symbol SPY QQQ IWM --strategy gallery_index_etf_v1 --aggregation min --save` で最悪ケースを底上げします。

## 商品先物向け

| 項目 | 内容 |
|---|---|
| 目的 | 商品先物のトレンドと急反転を同時に扱う |
| 向いている市場 | 原油、金、天然ガスなどボラティリティが高い商品 |
| 戦略タイプ | レジーム切り替え |
| 主要指標 | HMM, SUPERTREND, RSI, ATR |
| 想定シンボル | `CL=F`, `GC=F` |
| Pine Script生成可否 | 条件付き可。HMMを含む場合は学習済みパラメータの扱いを確認 |

### JSON要点スニペット

```json
{
  "strategy_id": "gallery_commodity_futures_v1",
  "target_symbols": ["CL=F"],
  "indicators": [
    { "id": "regime", "type": "HMM", "params": { "n_components": 2, "features": ["return", "volatility"] } },
    { "id": "supertrend", "type": "SUPERTREND", "params": { "length": 10, "multiplier": 3.0 } },
    { "id": "rsi", "type": "RSI", "params": { "length": 14 } }
  ],
  "entry_conditions": { "long": { "logic": "AND", "conditions": [
    { "left": "close", "op": "crosses_above", "right": "supertrend" },
    { "left": "rsi", "op": "<", "right": "70" }
  ]}}
}
```

### 実行コマンド

```bash
alpha-forge strategy save data/strategies/gallery_commodity_futures_v1.json
alpha-forge strategy validate gallery_commodity_futures_v1
alpha-forge backtest run CL=F --strategy gallery_commodity_futures_v1 --json
alpha-forge optimize run CL=F --strategy gallery_commodity_futures_v1 --metric sharpe_ratio --save
alpha-forge pine generate --strategy gallery_commodity_futures_v1 --with-training-data
```

### 結果の読み方

商品先物はギャップや急変が大きいため、Max Drawdown、平均負け幅、連敗時の資金曲線を重視します。取引数が少ない場合は期間を広げて確認します。

### 改良ポイント

CL=FだけでなくGC=FやNG=Fでも試し、ATR損切り倍率とSuperTrend倍率を横断的に最適化します。全文に近いレジーム切り替え例は [レジーム切り替え](templates.md#regime-switching) を参照してください。
