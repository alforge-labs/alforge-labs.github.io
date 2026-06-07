# alpha-forge pine

戦略 JSON と TradingView Pine Script v6 を相互変換します。

!!! warning "[有料プラン限定] Pine Script エクスポート"
    `alpha-forge pine generate`・`alpha-forge pine preview`・`alpha-forge pine verify` は **有料プラン（Lifetime / Annual / Monthly）でのみ利用できます**。Trial プランで実行すると赤枠 Panel と購入ページ URL（[https://alforgelabs.com/en/index.html#pricing](https://alforgelabs.com/en/index.html#pricing)）が表示され、終了コード `1` で完全停止します。ファイル出力も標準出力もされません。`alpha-forge pine import`（インポート機能）は対象外で、Trial プランでも継続利用できます。詳しくは [Trial 制限](../guides/trial-limits.md) を参照してください。

## alpha-forge pine generate `[有料プラン限定]`

戦略定義から Pine Script を生成し、`config.pinescript.output_path / <strategy_id>.pine` に保存します。**有料プラン（Lifetime / Annual / Monthly）限定**。

```bash
alpha-forge pine generate --strategy <ID> [--with-training-data]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--strategy` | オプション | - | 戦略名（`--combine-strategies` と排他） |
| `--combine-strategies` | オプション | - | 複数の buy-hold-overlay 戦略をカンマ区切りで指定し単一 Pine v6 Indicator として combine portfolio を生成（`--strategy` と排他、issue #970） |
| `--allocation` | choice(`equal`/`custom`) | `equal` | `--combine-strategies` 用の配分モード（`custom` は `--weights` 必須） |
| `--weights` | オプション | - | `--allocation custom` 時の weights（例 `tqqq_phase2=0.5,gld_bh=0.25,tlt_bh=0.25`、合計 1.0±0.01） |
| `--portfolio-id` | オプション | - | `--combine-strategies` 時の portfolio 識別子（生成 Pine indicator 名と webhook payload に書き込む） |
| `--rebalance-freq` | choice(`none`/`weekly`/`monthly`/`quarterly`/`yearly`) | `none` | `--combine-strategies` 用の定期 rebalance 頻度（issue #971 Phase 2） |
| `--rebalance-threshold` | float(0.001–0.5) | - | threshold-based rebalance。各 ticker の current_weight が target から ±X 乖離で発火（`--rebalance-freq` と OR 併用可、issue #971） |
| `--allow-non-buy-hold` | フラグ | false | `--combine-strategies` で mean-reversion / trend-following 戦略を許可（各 sub-strategy が独立 position、issue #971 experimental） |
| `--combine-mode` | choice(`indicator`/`hybrid-strategy`) | `indicator` | combine 出力モード。`hybrid-strategy` はメイン symbol を strategy() で出力し TradingView Strategy Tester に対応（`--main-strategy` 必須、issue #985） |
| `--main-strategy` | オプション | - | `--combine-mode hybrid-strategy` で strategy() 化するメイン戦略 ID（`--combine-strategies` 内の buy-hold-overlay 戦略、issue #985） |
| `--with-training-data` | フラグ | false | HMM インジケータがある場合、学習済みパラメータを Pine Script に埋め込む（データを自動フェッチ。`--combine-strategies` 併用時は combine 内 HMM を並列フェッチ、issue #974） |
| `--with-webhook` | フラグ | false | alpha-strike Webhook 連携用 input + make_payload + alert() を Pine Script に付与（issue #770） |
| `--webhook-broker` | choice(`moomoo`/`oanda`) | - | `--with-webhook` の発注先 broker（省略時 asset_type から推論） |
| `--webhook-asset-class` | オプション | - | `--with-webhook` の asset_class（CRYPTO / FX / US_STOCK 等。省略時 asset_type から推論） |
| `--webhook-ticker` | オプション | - | `--with-webhook` の broker 側ティッカー（moomoo crypto は CC.BTC 等。省略時 target_symbols[0] から推論） |
| `--webhook-quantity` | float | - | `--with-webhook` の 1 注文あたり数量（TradingView 側で input から調整可能） |
| `--webhook-run-mode` | choice(`paper`/`live`) | `paper` | `--with-webhook` の run_mode（記録のみ／実発注を alpha-strike 側で切替） |
| `--no-validate` | フラグ | false | Pine v6 シグネチャ DB ベースの post-generate validator をスキップ（緊急避難用、issue #786） |
| `--backtest-period` | オプション | - | Pine 出力に期間フィルタを焼き込む（形式 `YYYY-MM-DD:YYYY-MM-DD`、issue #823） |

サンプル出力（有料プラン）：

```text
✅ Pine Script が保存されました: output/pinescript/spy_sma_v1.pine
```

サンプル出力（Trial プラン・ハードブロック）：

```text
╭─────────────── 🔒 有料プラン限定機能 ───────────────╮
│ Pine Script エクスポートは有料プラン（Lifetime /    │
│ Annual / Monthly）のみ利用できます。                │
│ TradingView でのシームレスな運用を行うには…         │
│ アップグレード: https://alforgelabs.com/en/...      │
╰─────────────────────────────────────────────────────╯
```

## alpha-forge pine preview `[有料プラン限定]`

戦略定義から生成される Pine Script を標準出力でプレビューします（ファイル保存しない）。**有料プラン（Lifetime / Annual / Monthly）限定**。

```bash
alpha-forge pine preview --strategy <ID> [--with-webhook] [--backtest-period <YYYY-MM-DD:YYYY-MM-DD>]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--strategy` | 必須 | - | 戦略名 |
| `--with-webhook` | フラグ | false | alpha-strike Webhook 連携用の input + make_payload + alert() を付与（issue #770） |
| `--webhook-broker` | choice(`moomoo`/`oanda`) | - | `--with-webhook` 用 broker（省略時は asset_type から推論） |
| `--webhook-asset-class` | オプション | - | `--with-webhook` 用 asset_class |
| `--webhook-ticker` | オプション | - | `--with-webhook` 用 broker ティッカー |
| `--webhook-quantity` | float | `1.0` | `--with-webhook` 用 数量 |
| `--webhook-run-mode` | choice(`paper`/`live`) | `paper` | `--with-webhook` 用 run_mode |
| `--no-validate` | フラグ | false | Pine v6 シグネチャ DB に基づく post-generate validator をスキップ（緊急避難用、issue #786） |
| `--backtest-period` | オプション | - | Pine 出力に期間フィルタを焼き込む（`YYYY-MM-DD:YYYY-MM-DD`、issue #823） |

## alpha-forge pine import

Pine Script (`.pine`) をパースして戦略定義として取り込みます。

```bash
alpha-forge pine import <PINE_FILE> --id <STRATEGY_ID>
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `PINE_FILE` | 引数（必須、ファイル必須） | `.pine` ファイルパス |
| `--id` | 必須 | 保存する戦略 ID |

パース失敗時は `エラー: Pine Script のパースに失敗しました - <details>` を出して標準エラーへ。

## alpha-forge pine verify `[有料プラン限定]`

戦略から生成した Pine Script を **TradingView MCP server** で検証します（issue #523）。コンパイルチェックに加えて、Strategy Tester の集計値や個別トレードを alpha-forge のバックテスト結果と突き合わせて差異を検出できます。**有料プラン（Lifetime / Annual / Monthly）限定**で、内部で Pine Script を生成するため Trial プランで実行すると generate / preview と同じ赤枠 Panel が表示され、終了コード `1` で停止します（`--check-mode` の判定に到達する前に paywall が発火します）。

```bash
alpha-forge pine verify --strategy <ID> [--check-mode <MODE>] [--mcp-server <CMD>] [--mcp-server-flavor <tradesdontlie|vinicius>] [OPTIONS]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--strategy` | 必須 | - | 戦略名 |
| `--check-mode` | choice | `compile_only` | `compile_only` / `metrics` / `signal` / `regime` |
| `--mcp-server` | オプション | - | MCP サーバーコマンド（省略時 `forge.yaml` の `tv_mcp.pine_verify.endpoint`） |
| `--mcp-server-flavor` | choice | `tradesdontlie` | `vinicius` は `oviniciusramosp/tradingview-mcp` フォーク。metrics/signal モードでは推奨 |
| `--mock` | フラグ | false | Mock MCP クライアント（PoC・CI 用） |
| `--symbol` / `--interval` | オプション | - | TV シンボル / インターバル（metrics / signal モードで必須） |
| `--auto-backtest` | フラグ | false | alpha-forge バックテストを内部で実行して比較する |
| `--backtest-result` | オプション | - | 比較対象 alpha-forge バックテスト結果（JSON パスまたは `run_id`） |
| `--metric-tolerance` | float | `0.10` | metrics モードの相対差許容（10%） |
| `--match-tolerance-seconds` | int | `60` | signal モードのトレード時刻許容差（秒） |
| `--min-match-rate` | float | `0.95` | signal モードの最低トレード一致率 |
| `--output` | ファイル | - | レポート Markdown 出力先 |
| `--combine-strategies` | オプション | - | combine portfolio Pine を symbolic / alert-log / Strategy Tester で検証（`--strategy` と排他、issue #975）。例: `tqqq_phase2,gld_bh,tlt_bh` |
| `--combine-allocation` | choice | `equal` | `equal` / `custom`。`--combine-strategies` 用 allocation |
| `--combine-weights` | オプション | - | `--combine-allocation custom` 時の重み（例: `tqqq=0.5,gld=0.5`） |
| `--combine-portfolio-id` | オプション | - | `--combine-strategies` 用 portfolio_id（省略時は自動生成） |
| `--combine-rebalance-freq` | choice | `none` | `none` / `weekly` / `monthly` / `quarterly` / `yearly`。`--combine-strategies` 用 rebalance 頻度 |
| `--combine-rebalance-threshold` | float | - | `--combine-strategies` 用の threshold-based rebalance（例: `0.05`） |
| `--verify-mode` | choice | `symbolic` | `--combine-strategies --check-mode metrics` 経路の検証モード（#975/#980/#986）。`symbolic`=backtest combine と Pine 設定を symbolic 比較／`alert-log`=alpha-strike JSONL から position 再構築して metrics 計算（`--receipts-source` 必須）／`tradingview-strategy-tester`=hybrid-strategy Pine を Strategy Tester で比較（`--combine-mode hybrid-strategy` + `--main-strategy` + `--symbol` + `--interval` 必須） |
| `--combine-mode` | choice | `indicator` | `indicator` / `hybrid-strategy`。combine の Pine 出力モード。`tradingview-strategy-tester` verify では `hybrid-strategy` を指定（#986） |
| `--main-strategy` | オプション | - | hybrid-strategy verify で `strategy()` 化するメイン戦略 ID（#986） |
| `--receipts-source` | パス | - | `--verify-mode alert-log` 用の alpha-strike JSONL ファイル or ディレクトリ |
| `--receipts-since` | オプション | - | `--verify-mode alert-log` の対象期間下限（ISO 形式 `YYYY-MM-DD` 等）。省略時は全期間 |

**check-mode**

| モード | 用途 |
|--------|------|
| `compile_only` | Pine Script の構文・コンパイルだけを検証（`tradesdontlie` で十分） |
| `metrics` | TV Strategy Tester の総合メトリクス（PF・勝率・トレード数等）と alpha-forge のメトリクスを比較。**`vinicius` 推奨**（`tradesdontlie` の `data_get_strategy_results` バグ回避） |
| `signal` | tradesdontlie: TV のトレードリストと alpha-forge の `trades` を時刻ベースで突合し一致率を算出。<br>vinicius: 時刻情報を返さないため **count-based 比較**（トレード件数のみで合否判定）に自動切替（issue #580） |
| `regime` | **未実装（保留中、issue #581）**。upstream MCP server に時系列 study tool が追加されたら着手予定。指定すると明示的エラーで停止 |

**実行例**

```bash
# コンパイル検証のみ（最速）
alpha-forge pine verify --strategy spy_sma_v1 --mcp-server "node /opt/tv-mcp/server.js"

# Strategy Tester 集計の比較（vinicius 推奨）
alpha-forge pine verify --strategy spy_sma_v1 \
  --check-mode metrics \
  --symbol SPY --interval D \
  --mcp-server-flavor vinicius \
  --auto-backtest \
  --output reports/verify_spy.md
```

検証ガイドの詳細は [TradingView との Pine Script 連携](../guides/tradingview-pine-integration.md) を参照してください。

---
