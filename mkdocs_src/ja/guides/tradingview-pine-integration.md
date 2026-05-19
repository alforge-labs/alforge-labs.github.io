# TradingView への Pine Script 反映

`alpha-forge pine generate` で生成した `.pine` ファイルを TradingView に貼り付けてアラートを設定します。

## 1. Pine エディタを開く

TradingView でチャートを開き、画面下部の「Pine エディタ」タブをクリックします。

## 2. スクリプトを貼り付ける

生成した `.pine` ファイルの内容をエディタに貼り付け、「スクリプトを追加」（▶ ボタン）をクリックします。

## 3. アラートを設定する

チャート右上のベルアイコン（アラート）→「アラートを追加」をクリック。

- **条件**: 追加したスクリプト名を選択
- **Webhook URL**: チェックを入れ、alpha-strike のエンドポイントを入力
- **メッセージ**: 後述の JSON ペイロードを入力（[alpha-strike 連携ガイド](tradingview-alpha-strike.md) 参照）

## 4. アラートメッセージのヒント

Pine Script 内でシグナル変数（例: `longSignal`）を定義しておくと、アラートの条件設定が簡単になります。

```pinescript
// Pine Script 内でのアラート定義例
longSignal = ta.crossover(ema_fast, ema_slow)
shortSignal = ta.crossunder(ema_fast, ema_slow)
alertcondition(longSignal, title="Long Entry", message="long")
```

!!! tip "次のステップ"
    Webhook 受信側の設定は [TradingView と alpha-strike の連携](tradingview-alpha-strike.md) を参照してください。

---

## 4.5 Pine v6 出力の自動検証（issue #786）

`alpha-forge pine generate` / `pine preview` は、出力した Pine スクリプトに対して内部の **Pine v6 シグネチャ DB** と照合する post-generate validator を自動で走らせます。Pine v6 で廃止された引数（例: `strategy.exit(trail_percent=...)` / `strategy.entry(allow_short=...)`）や typo を検出し、TradingView Pine Editor に貼り付ける前に CLI 段階で停止します。

- **エラー**（exit code `2`）: 廃止引数 / 未知引数を検出した場合。問題箇所が行番号付きで stderr に表示されます。
- **警告のみ**: DB 未登録の v6 関数を検出した場合は warning にとどまり、コマンドは正常終了します（false positive 抑止のため）。
- 緊急バイパスが必要な場合は `--no-validate` フラグでスキップ可能ですが、TradingView 上で syntax error になる可能性が高いため、原則として戦略 JSON や生成器側の修正を優先してください。

```bash
# 通常の生成（validator 自動実行）
alpha-forge pine generate --strategy sma_crossover_v1_optimized

# 緊急時のバイパス
alpha-forge pine generate --strategy sma_crossover_v1_optimized --no-validate
```

シグネチャ DB (`alpha_forge/pinescript/v6_signatures.yaml`) は `strategy.*` / `ta.*` / `input.*` / `request.security` の主要 API をカバーしています。Pine v6 の API 変更や生成器の新規対応に応じて更新されます。

---

## 4.6 Pine 出力に期間フィルタを焼き込む（issue #823）

`--backtest-period 'YYYY-MM-DD:YYYY-MM-DD'` を指定すると、Pine 出力の冒頭に `in_backtest_period = time >= timestamp("from") and time <= timestamp("to")` 変数を宣言し、すべての entry condition に `and in_backtest_period` を AND します（exit には付与しない）。

```bash
alpha-forge pine generate --strategy sma_crossover_v1_optimized \
  --backtest-period 2022-01-01:2024-12-31
```

**用途**: TradingView の Strategy Tester は **Date Range UI が有料プラン（Premium 以上）依存**で、Essential プランでは Custom date range の自動変更が動かないケースがあります。Pine 側に期間ガードを焼き込めばこの問題を完全に回避でき、`scripts/tv_cross_validate.py update --from/--to` 経由でも自動的にこの方式が使われます。

実機検証 (TradingView Essential プラン、SPY 2022-01-01～2024-12-31):

| 戦略 | alpha-forge trades | TV trades (修正前) | TV trades (本機能適用後) |
|---|---:|---:|---:|
| sma_crossover_v1 | 17 | 207 | **17 (完全一致)** |
| bollinger_mr_v1 | 69 | 1317 | 128 (90% 縮減) |

**設計**: exit にはガードを入れないため、period 終了時に open している position は通常 exit ロジックでクローズします。

---

## 4.7 SL/TP 戦略の intra-bar fill 差（issue #827）

`risk_management.stop_loss_pct` / `take_profit_pct` を持つ戦略では、**alpha-forge と TV で trade 数の解釈が異なります**。これは backtest engine の仕様差で、利用者として事前に知っておく必要がある制約です。

- **alpha-forge (vectorbt)** は SL/TP を **次バー close fill** で約定
- **TV** の `strategy.exit(stop=..., limit=...)` は **毎バー intra-bar fill** で約定（high/low が水準に触れた瞬間に同バー内で約定）

同じ Pine スクリプトでも TV の trade 数が alpha-forge より大幅に増える傾向があります。

| 戦略 | SL/TP | alpha-forge | TV | 差 |
|------|:-----:|---:|---:|---:|
| sma_crossover_v1 | なし | 17 | 17 | **0% (完全一致)** |
| bollinger_mr_v1 | あり (2%/4%) | 69 | 128 | 86% |

**比較指標の信頼度**:

| 指標 | intra-bar fill 影響 | 解釈 |
|------|:-----:|------|
| `win_rate_pct` | 低 | **高信頼** |
| `profit_factor` | 低 | **高信頼** |
| `total_trades` | 高 | 要注意 |
| `total_return_pct` | 高 | 要注意 |

bollinger_mr_v1 の win_rate は 41.18% (alpha) vs 41.41% (TV) と 0.23pp 差で **signal 品質は同一**、trade 数だけがペアの数え方差で 1.86x ズレることが確認できます。

### 自動切替: `--tolerance-profile auto` (alpha-forge issue #828)

SL/TP 戦略を cross-validation する際は、`scripts/tv_cross_validate.py check` の `--tolerance-profile auto`（既定）で許容差分プロファイルが自動切替されます。

```bash
alpha-forge ディレクトリで実行
uv run python scripts/tv_cross_validate.py check \
  --strategy bollinger_mr_v1 --symbol SPY \
  --golden tests/fixtures/tv_golden/bollinger_mr_v1__SPY__1d.json
# auto (既定): 戦略 JSON の risk_management から SL/TP / trailing 有無を判定
#   → sl_tp profile が自動で適用される
```

| profile | total_trades | win_rate | total_return | profit_factor | 用途 |
|---------|---:|---:|---:|---:|---|
| `default` | ±20% | ±5pp | ±15pp | ±0.30 | event-based (SL/TP 無し) 戦略 |
| `sl_tp` | ±100% | ±5pp | ±20pp | ±0.50 | SL/TP / trailing 戦略 (intra-bar fill 差を吸収) |
| `auto` (既定) | — | — | — | — | 戦略 JSON から判定 |

!!! note "total_return の単位 (alpha-forge #828 follow-up)"
    `total_return_pct` は当初 **相対 % 差** で判定していましたが、`alpha=-4.22 / tv=2.15` のような **sign 反転 + 小さい分母** で相対差が暴騰する問題が判明し、**絶対 pp 差**に変更されました（PR #834）。これにより bollinger_mr_v1 (alpha 69 vs TV 128 trades) が 4/4 PASS で overall_pass=True になります。

`auto` の判定は `risk_management.stop_loss_pct` / `take_profit_pct` / `trailing_stop_pct` のいずれかが設定されていれば `sl_tp` profile、無しなら `default` profile。明示指定 (`--tolerance-profile sl_tp` 等) と個別フラグ (`--total-trades-rel-pct 200.0` 等) で override も可能です。

---

## 5. Pine Script を MCP server で検証する（issue #523）

`alpha-forge pine verify` を使うと、生成した Pine Script を **TradingView Desktop + サードパーティ MCP server** に投げて検証できます。コンパイル可否だけでなく、Strategy Tester のメトリクスや個別トレードを alpha-forge のバックテストと比較し、Pine 変換の正確性を機械的に確認できます。

### 5.1 前提セットアップ

1. TradingView Desktop を `--remote-debugging-port=9222` で起動
2. サードパーティ MCP server を別プロセスで起動：
   - `tradesdontlie/tradingview-mcp` — コンパイル検証・チャート操作向け
   - `oviniciusramosp/tradingview-mcp`（vinicius fork）— Strategy Tester 集計に強い。`metrics` / `signal` モードでは **こちら推奨**
3. `forge.yaml` でエンドポイントと flavor を設定：

```yaml
tv_mcp:
  pine_verify:
    enabled: true
    endpoint: "node /opt/tv-mcp/server.js"
    runtime: node
    flavor: vinicius     # metrics/signal を使うなら vinicius
    timeout_seconds: 60
```

### 5.2 verify モード一覧

| モード | 検証内容 | 推奨 flavor |
|--------|---------|-------------|
| `compile_only` | Pine Script の構文・コンパイルだけ | `tradesdontlie` で十分 |
| `metrics` | TV Strategy Tester の集計（PF・勝率・トレード数等）と alpha-forge のメトリクスを比較 | **`vinicius`**（`tradesdontlie` には `data_get_strategy_results` バグあり） |
| `signal` | tradesdontlie: TV のトレードリストを alpha-forge `trades` と時刻ベースで突合し一致率を算出。<br>vinicius: 時刻情報を返さないため **count-based 比較**（件数のみ）に自動切替（issue #580） | `tradesdontlie`（時刻照合が必要なら） / `vinicius`（件数だけで十分なら） |
| `regime` | **未実装（保留中）** — upstream MCP server に時系列 study tool が無いため、HMM 状態列を bar 単位で取り出せない（[issue #581](https://github.com/ysakae/alpha-forge/issues/581)）。指定すると明示的エラーで停止する | — |

### 5.3 ワークフロー

```bash
# 1. コンパイル可否のみ確認（最速）
alpha-forge pine verify --strategy spy_sma_v1 \
  --mcp-server "node /opt/tv-mcp/server.js"

# 2. Strategy Tester メトリクス比較（vinicius 推奨）
alpha-forge pine verify --strategy spy_sma_v1 \
  --check-mode metrics \
  --symbol SPY --interval D \
  --mcp-server-flavor vinicius \
  --auto-backtest \
  --output reports/verify_spy.md

# 3. トレード単位で時刻一致を見る（誤差±60 秒、95% 一致を要求）
alpha-forge pine verify --strategy spy_sma_v1 \
  --check-mode signal \
  --symbol SPY --interval D \
  --mcp-server-flavor vinicius \
  --auto-backtest \
  --match-tolerance-seconds 60 \
  --min-match-rate 0.95
```

### 5.4 期間ミスマッチを避けるヒント

`metrics` モードで `total_trades` の差が大きいときは、データ期間のミスマッチ（yfinance ~5 年 vs TradingView 数十年）が原因のことが多いです。長期バックテストを TV 側に揃えたい場合は、データ取得を TradingView MCP に切り替えてください：

```bash
alpha-forge data fetch SPY --provider tv_mcp \
  --mcp-server "node /opt/tv-mcp/server.js" --period max
```

詳細は [`alpha-forge data` コマンドリファレンス](../cli-reference/data.md#tradingview-mcp-tv_mcpissue-576) を参照してください。

### 5.5 出力レポート

`--output reports/xxx.md` を指定すると、Markdown レポートに以下が含まれます：

- 戦略 ID と検証モード
- 比較メトリクス表（alpha-forge ↔ TradingView）
- 不一致の検出（許容誤差を超えた項目）
- 判定（PASS / FAIL）と推奨アクション

`alpha-forge journal report --with-chart --symbol SPY --interval D` と組み合わせると、戦略履歴 + 検証結果 + TV チャート画像を 1 ページで確認できます。
