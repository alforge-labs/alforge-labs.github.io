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
