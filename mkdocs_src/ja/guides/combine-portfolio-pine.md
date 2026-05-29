# Combine Portfolio Pine — 複数戦略を 1 つの Pine で運用する

`alpha-forge pine generate --combine-strategies` で、複数の buy-hold-overlay
戦略を 1 つの Pine v6 Indicator として束ねて TradingView 上で動かせます。
各戦略の発注は `alert()` 経由で alpha-strike Webhook に送信され、moomoo /
OANDA で自動約定します。

## なぜ Indicator なのか

Pine v6 の `strategy()` は **1 銘柄前提** で、複数 ticker を扱えません。
combine portfolio Pine は次の方針で複数銘柄を 1 つの Pine にまとめます:

- 各サブ戦略の価格は `request.security()` で別 ticker を取得
- 各サブ戦略の `target_qty` を bar close ごとに計算
- 数量変化または rebalance トリガーで `alert()` を発火
- 受信側 (alpha-strike) で webhook v2 payload を解析し、moomoo / OANDA に
  発注する

そのため combine Pine 単独では TradingView Strategy Tester は動きません
(Indicator なので Strategy Tester がアタッチしない仕様)。代わりに
[symbolic verify](#symbolic-verify) でロジック整合性を保証します。

## クイックスタート

### 1. combine Pine を生成する

```bash
forge pine generate \
  --combine-strategies tqqq_phase2,gld_bh,tlt_bh \
  --combine-allocation equal \
  --rebalance-freq monthly \
  --rebalance-threshold 0.05 \
  --portfolio-id beat_qqq_hedged_v1 \
  --with-webhook \
  --webhook-broker moomoo \
  --webhook-run-mode paper
```

オプション:

| オプション | 意味 |
|-----------|------|
| `--combine-strategies sid1,sid2,...` | combine 対象戦略 ID (2 件以上、カンマ区切り) |
| `--allocation equal\|custom` | 均等配分または `--weights` 指定の任意配分 |
| `--weights tqqq=0.5,gld=0.3,tlt=0.2` | custom 時の重み (合計 1.0 ± 0.01) |
| `--rebalance-freq weekly\|monthly\|quarterly\|yearly\|none` | 定期 rebalance 頻度 |
| `--rebalance-threshold 0.05` | weight 乖離 ±5% でリバランス発火 |
| `--allow-non-buy-hold` | mean-reversion / trend-following 戦略を combine に許可 (Phase 2 experimental) |
| `--with-training-data` | HMM 戦略を含む場合に学習データを並列フェッチして Forward Algorithm を Pine に埋め込む (issue [#974](https://github.com/ysakae/alpha-forge/issues/974)) |
| `--portfolio-id <id>` | 生成 Pine の indicator 名 + webhook payload に書き込む portfolio_id |

### 2. TradingView Pine Editor に貼り付ける

`output/pinescript/<portfolio_id>.pine` をそのまま Pine Editor に貼り付け、
「スクリプトを追加」をクリックします。

### 3. アラートを設定する

| 項目 | 設定値 |
|------|--------|
| **条件** | 追加した `<portfolio_id>` インジケータ → `Any alert() function call` |
| **頻度** | `Once Per Bar Close` (Pine 側で `alert.freq_once_per_bar_close` を指定済) |
| **Webhook URL** | `https://strike.alforgelabs.com/webhook` (環境ごとに置換) |
| **メッセージ** | **空欄のまま** — Pine 内の `make_payload()` がそのまま発信される |

設定保存後、最初の日足クローズで初回 3 銘柄エントリーが発火します。

## Webhook payload の構造

`make_payload()` は alpha-strike webhook v2 payload を 1 行で出力します:

```json
{
  "passphrase": "<i_passphrase 入力値>",
  "broker": "moomoo",
  "asset_class": "US",
  "action": "buy",
  "ticker": "US.TQQQ",
  "quantity": 33,
  "strategy_id": "beat_qqq_hedged_v1",
  "sub_strategy_id": "tqqq_phase2",
  "portfolio_id": "beat_qqq_hedged_v1",
  "signal_id": "20260529-135959",
  "run_mode": "paper",
  "timeframe": "1D"
}
```

`run_mode` は `paper` か `live` の二択で、TradingView 上の入力で切替可能。
ペーパー検証中は必ず `paper` を指定して moomoo SIMULATE 環境に流すこと。

## HMM Forward Algorithm の完全再現 (issue [#974](https://github.com/ysakae/alpha-forge/issues/974))

combine 内に HMM レジーム戦略を含める場合は `--with-training-data` を付与
すると、各 HMM 戦略の学習データを並列フェッチして transition matrix /
means / variances を Pine に焼き込み、Forward Algorithm を Pine 内で
逐次計算します。

- 並列フェッチ: `concurrent.futures.ThreadPoolExecutor` で I/O 並列化
- 複数 HMM の識別子は prefix で完全分離 (`s0_hmm_transmat`,
  `s1_hmm_transmat`, `s0_f_hmm_step`, `s1_f_hmm_step` 等)
- training data 未提供時は volatility regime proxy (`ta.stdev`) に
  フォールバック (後方互換)

```bash
forge pine generate \
  --combine-strategies qqq_hmm_v1,tqqq_v1,gld_v1 \
  --allocation equal \
  --with-training-data \
  --portfolio-id combine_hmm_v1
```

## symbolic verify (issue [#975](https://github.com/ysakae/alpha-forge/issues/975)) {#symbolic-verify}

`forge pine verify --combine-strategies` で、生成 Pine と alpha-forge
backtest combine が **同じ意図で動く** ことを TradingView を介さず
symbolic に検証できます。

```bash
forge pine verify \
  --combine-strategies tqqq_phase2,gld_bh,tlt_bh \
  --combine-allocation equal \
  --combine-rebalance-freq monthly \
  --combine-rebalance-threshold 0.05 \
  --combine-portfolio-id beat_qqq_hedged_v1 \
  --check-mode metrics
```

出力例:

```text
# Combine Portfolio Verify — beat_qqq_hedged_v1

**Status**: ✅ PASSED (0 violation(s) / 12 checks)

## Metrics

| Metric            | Value     |
|-------------------|-----------|
| total_return_pct  | 915.5400  |
| cagr_pct          | 15.3000   |
| sharpe_ratio      | 1.0401    |
| max_drawdown_pct  | 23.3200   |
| volatility_pct    | 14.7700   |

## Integrity Checks (抜粋)

| Key                                     | Expected | Observed | OK |
|-----------------------------------------|----------|----------|----|
| pine_syntax                             | 0 errors | 0 errors | ✅ |
| weight:tqqq_phase2                      | 0.333333 | 0.3333   | ✅ |
| hedge_exposure:tqqq_phase2              | 0.4      | 0.4      | ✅ |
| rebalance_freq                          | monthly  | monthly  | ✅ |
| rebalance_threshold                     | 0.05     | 0.05     | ✅ |
```

整合性チェックの対象:

- `pine_syntax` — Pine v6 構文 verify (PineV6Validator)
- `weight:<sid>` — Pine 内 `s{i}_weight` と backtest combine の `weight_map[sid]`
- `base_exposure:<sid>` — 通常時 exposure
- `hedge_exposure:<sid>` — hedge state の `target_exposure_pct`
- `rebalance_freq` — `ta.change(month)` 等と CLI 指定の対応
- `rebalance_threshold` — `i_rebalance_threshold` 入力値

`--check-mode compile_only` を指定すると Pine v6 構文 verify のみ実行
(backtest 不要)。

## 既知の制約

- **Strategy Tester は動かない**: combine Pine は Indicator のため、
  TradingView 内で Sharpe / CAGR / MDD を直接取得できません。
  metrics は symbolic verify か alpha-forge backtest combine から取得します。
- **`Once Per Bar Close` 必須**: intrabar 発火を避けるため Pine 側で
  `alert.freq_once_per_bar_close` を強制しています。TradingView アラート
  設定でも同じ頻度を選択してください。
- **発火日の制約**: 戦略 alert はそれぞれの bar close 後に発火するため、
  初回エントリーは「アラート保存後の最初の日足クローズ」になります。

## 関連ドキュメント

- [TradingView への Pine Script 反映](tradingview-pine-integration.md) — 単体戦略の場合
- [TradingView と alpha-strike の連携](tradingview-alpha-strike.md) — Webhook 受信側
- [alpha-strike セットアップガイド](alpha-strike-setup.md) — Webhook サーバー構築
