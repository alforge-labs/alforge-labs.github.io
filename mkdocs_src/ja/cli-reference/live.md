# alpha-forge live

ライブトレードのイベントログ取得（VPS→ローカル）、raw event → trade records 変換、パフォーマンス分析、バックテストとの比較を行うコマンドグループ。`alpha-forge journal` と連携してライブ実績を可視化します。

!!! info "サンプル出力について"
    本ページの出力例は `alpha-forge` のソースから読み取ったフォーマットを元にしたサンプルです。実際の数値や整形は `live/formatter.py` の `format_*` 関数の挙動に依存します。

## ライブ運用までの典型フロー

```text
1. alpha-forge live sync-events       VPS から raw event を取得
2. alpha-forge live convert-check     変換 readiness を確認
3. alpha-forge live import-events     fill/close event から trades を生成
4. alpha-forge live summary           ライブパフォーマンスを表示
5. alpha-forge live compare           最新 backtest run と比較
```

## サブコマンド一覧

| コマンド | 説明 |
|---------|------|
| [`alpha-forge live list`](#alpha-forge-live-list) | live trading records が存在する戦略一覧 |
| [`alpha-forge live events`](#alpha-forge-live-events) | raw event を一覧表示 |
| [`alpha-forge live convert-check`](#alpha-forge-live-convert-check) | raw event から trades 変換 readiness を確認 |
| [`alpha-forge live import-events`](#alpha-forge-live-import-events) | fill / close event から trade records を生成して保存 |
| [`alpha-forge live trades`](#alpha-forge-live-trades) | 戦略の個別取引レコードを一覧 |
| [`alpha-forge live summary`](#alpha-forge-live-summary) | 戦略の live performance summary を表示 |
| [`alpha-forge live compare`](#alpha-forge-live-compare) | 最新 backtest run と live summary を比較 |
| [`alpha-forge live doctor`](#alpha-forge-live-doctor) | live trading analysis の導入状態を確認 |
| [`alpha-forge live sync-events`](#alpha-forge-live-sync-events) | VPS 上のイベントログをローカルに rsync で同期 |
| [`alpha-forge live replay`](#alpha-forge-live-replay) | combine portfolio の alert log から position ベースで live メトリクスを再構築 |

---

## alpha-forge live list

`<journal_path>/../live/` 配下の trade records と event ログを走査し、ライブ記録が存在する戦略 ID を表示します。

### 構文

```bash
alpha-forge live list
```

### 引数とオプション

なし。

### サンプル出力

```text
spy_sma_v1
qqq_hmm_macd_ema_rsi_v1
gc_hmm_macd_ema_v1
```

整形は `format_live_list` に依存します。

---

## alpha-forge live events

raw event（broker から出力される `fill`、`close` 等）を一覧表示します。フィルタなしの場合は最新から `--limit` 件を表示。

### 構文

```bash
alpha-forge live events [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--strategy` | オプション | - | `strategy_id` で絞り込む（epic #1083 D で `--strategy-id` から改名） |
| `--event-type` | オプション | - | `event_type` で絞り込む（例: `fill`、`close`） |
| `--broker` | オプション | - | `broker` で絞り込む |
| `--limit` | int | `20` | 表示件数 |
| `--json` | フラグ | false | 結果を JSON で出力（`{events: [...], count}`） |

### サンプル出力

```text
=== live events ===
2026-04-15T09:31:00+00:00 | fill | spy_sma_v1 | SPY | buy | filled | sig_0042
2026-04-15T14:02:00+00:00 | trade_closed | spy_sma_v1 | SPY | sell | closed | sig_0042
```

整形は `format_live_events` に依存します。各行はパイプ（`|`）区切りで、`timestamp`（ISO 形式）/ `event_type` / `strategy_id` / `symbol`（`ticker`）/ `side`（`action`）/ `status` / `signal_id` の順に出力されます。`broker` / `qty` / `price` 列はありません。`--broker` オプションで絞り込みは可能ですが、`broker` 値そのものは行に表示されません。

---

## alpha-forge live convert-check

raw event を trade records に変換できる状態か（`fill` と `close` のペアが揃っているか等）を確認します。`import-events` の前段で実行することを推奨。

### 構文

```bash
alpha-forge live convert-check [--strategy <ID>]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--strategy` | オプション | - | `strategy_id` で絞り込む（epic #1083 D で `--strategy-id` から改名） |

### サンプル出力

```text
=== event conversion report ===
strategy_id                     : spy_sma_v1
total_events                    : 96
total_signals                   : 20
total_orders                    : 18
total_fills                     : 16
total_trade_closed              : 16
accepted_orders                 : 18
failed_orders                   : 0
live_events                     : 80
paper_events                    : 16
signals_without_orders          : 2
accepted_missing_strategy_meta  : 0
accepted_missing_snapshot_id    : 0
accepted_missing_fill_data      : 2
accepted_missing_close_data     : 2
fill_events_missing_trade_id    : 0
trade_closed_missing_pnl        : 0
conversion_ready                : yes
```

整形は `format_event_conversion_report`（`EventConversionReport` モデル）に依存します。ヘッダは `=== event conversion report ===` で、各フィールドは `key : value` 形式で出力されます。`conversion_ready` は `yes` / `no`。変換を妨げる要因がある場合は末尾に `blockers :` とその一覧が表示されます。`matched` / `pending` / `status`（ready/partial/missing）といった列はありません。

---

## alpha-forge live import-events

`fill` / `close` event から trade records を生成し、SQLite DB（`config.report.output_path` 配下の `backtest_results.db`）に保存します。trades / summaries は v0.12.0 で JSON ファイルから SQLite へ移行済みで、`<live_path>/trades/` や `<live_path>/summaries/` に JSON は作られません。

### 構文

```bash
alpha-forge live import-events <STRATEGY_ID>
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 対象戦略 ID |

### raw event → trade records 変換の前提条件

- `<live_path>/events/` に該当 `strategy_id` の event ログが存在すること（`alpha-forge live sync-events` で取得済み、または手動配置）
- 各エントリーに対して **`fill` event と `close` event のペア** が揃っていること
- 事前に [`alpha-forge live convert-check`](#alpha-forge-live-convert-check) で `conversion_ready : yes` を確認しておくこと
- 1 戦略 ID に対して 1 回実行すれば trade records が SQLite に保存される（再実行で上書き）

### サンプル出力

```text
imported_trades   : 16
strategy_id       : spy_sma_v1
db_path           : data/results/backtest_results.db
```

出力されるのは `imported_trades` / `strategy_id` / `db_path` の 3 項目のみです（`trades_file` / `summary_file` は出力されません）。trade records は `db_path` が指す SQLite DB に保存されます。

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `trade records を生成できませんでした: <id>` | `fill` / `close` ペアが揃わない、event 不存在 | `alpha-forge live convert-check --strategy <id>` で原因確認 |

---

## alpha-forge live trades

戦略の個別取引レコードを一覧します。

### 構文

```bash
alpha-forge live trades <STRATEGY_ID> [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 戦略 ID |
| `--limit` | int | `50` | 表示件数。`0` で全件 |
| `--side` | choice | - | `long` / `short` で絞り込む |
| `--exit-reason` | オプション | - | `exit_reason` で絞り込む |
| `--json` | フラグ | false | 結果を JSON で出力（`{strategy_id, trades: [...], count}`） |

新しい取引から順に表示されます（`entry_at` 降順）。取引が 0 件でも戦略が存在すれば正常系として `--json` では `status: "no_trades_yet"` + 空 envelope（終了コード `0`）を返します。

### サンプル出力

```text
=== live trades ===
entry_at             symbol     side        qty        entry         exit    net_pnl     ret%   hold_m exit_reason
──────────────────────────────────────────────────────────────────────────────────────────────────────────────
2026-04-15 09:31     SPY        long     100.00     452.3000     458.1200    +582.00   +1.29%      271 take_profit
2026-04-12 10:05     SPY        long     100.00     451.0000     449.1000    -190.00   -0.42%      343 stop_loss
```

整形は `format_live_trades` に依存します。列は `entry_at` / `symbol` / `side` / `qty` / `entry` / `exit` / `net_pnl` / `ret%` / `hold_m`（保有分数）/ `exit_reason`。`trade_id` 列・`exit_at` 列はありません。

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `live trade records がありません: <id>` | 該当戦略の trade records が SQLite に存在しない | `alpha-forge live import-events <id>` で生成 |

---

## alpha-forge live summary

戦略の live performance summary を表示します。サマリーが未生成の場合は trade records から自動構築します。

### 構文

```bash
alpha-forge live summary <STRATEGY_ID> [--json]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 戦略 ID |
| `--json` | フラグ | false | 結果を JSON で出力（`StrategyLiveSummary` を dump。取引 0 件は `summary: null` + `status: "no_trades_yet"` で終了コード `0`） |

### サンプル出力

```text
=== spy_sma_v1 live summary ===
version          : v1.1.0
snapshot_id      : snap_20260415
broker           : ibkr
symbols          : SPY
total_trades     : 16
win_rate_pct     : 56.25
gross_pnl        : 1280.00
net_pnl          : 1184.50
profit_factor    : 1.92
avg_win          : 185.30
avg_loss         : -112.40
avg_slippage_bps : 1.80
total_commission : 95.50
max_drawdown_pct : -4.20
```

整形は `format_live_summary`（`StrategyLiveSummary` モデル）に依存します。フィールドは `version` / `snapshot_id` / `broker` / `symbols` / `total_trades` / `win_rate_pct` / `gross_pnl` / `net_pnl` / `profit_factor` / `avg_win` / `avg_loss` / `avg_slippage_bps` / `total_commission` / `max_drawdown_pct`。`total_pnl_pct` / `sharpe_ratio` / `period` は出力されません。`avg_win` / `avg_loss` は % ではなく絶対額（建玉通貨の損益）です。

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `live summary がありません: <id>` | trade records 不存在で構築不能 | `alpha-forge live import-events <id>` を先に実行 |

---

## alpha-forge live compare

最新 backtest run と live summary を比較表示し、ライブが想定通りに機能しているかを評価します。

### 構文

```bash
alpha-forge live compare <STRATEGY_ID> [--json]
```

!!! note "`compare` の 2 義"
    `live compare` は**保存済み**の最新 backtest run と live summary を参照するだけの **read-only** コマンドです（新規バックテストは実行しません）。新規にバックテストを実行して比較するのは別概念の重い処理 [`backtest compare`](backtest.md#alpha-forge-backtest-compare) です。

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 戦略 ID |
| `--json` | フラグ | false | 結果を JSON で出力（`{strategy_id, backtest_run, backtest: {...}, live: {...}}`） |

### サンプル出力

```text
=== spy_sma_v1 live vs backtest ===
backtest_run     : run_20260410181522
backtest_symbol  : SPY
live_symbols     : SPY
snapshot_id      : snap_20260415

metric                 backtest         live         delta
──────────────────────────────────────────────────────────────
total_trades                 18           16           -2
win_rate_pct              58.30%       56.25%       -2.05%
profit_factor              2.10         1.92        -0.18
total_return_pct         +12.40%            -            -
max_drawdown_pct          -3.80%       -4.20%       -0.40%
net_pnl                       -      1184.50            -
avg_slippage_bps              -         1.80            -
```

整形は `format_live_compare` に依存します。ヘッダは `=== <id> live vs backtest ===` で、`backtest_run` / `backtest_symbol` / `live_symbols` / `snapshot_id` のメタ行に続いて `metric` / `backtest` / `live` / `delta` の表が出力されます。行は `total_trades` / `win_rate_pct` / `profit_factor` / `total_return_pct` / `max_drawdown_pct` / `net_pnl` / `avg_slippage_bps`。`sharpe_ratio` 行はありません。backtest 側にしか無い指標（`total_return_pct`）や live 側にしか無い指標（`net_pnl` / `avg_slippage_bps`）は片側が `-` になります。

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `live summary がありません: <id>` | live summary 不存在 | `alpha-forge live import-events <id>` で生成 |
| `backtest run がありません: <id>` | ジャーナルに backtest run 不存在 | `alpha-forge backtest run` で実行・記録 |

---

## alpha-forge live doctor

live trading analysis の導入状態を診断します。`STRATEGY_ID` を渡すと、その戦略について trades / summary の有無まで確認します。

### 構文

```bash
alpha-forge live doctor [STRATEGY_ID] [--json]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（任意） | - | 戦略 ID（指定で詳細チェック） |
| `--json` | フラグ | false | 診断結果を JSON で出力（テキストと同一データ） |

### サンプル出力（戦略 ID なし）

```text
=== live trading doctor ===
live_path       : data/live
events_path     : data/live/events
db_path         : data/results/backtest_results.db
events_exists   : yes
event_files     : 24
hint            : pass a strategy_id to validate trades/summary readiness
```

`trades_path` / `summaries_path` は出力されません。trades / summaries は SQLite（`db_path` が指す `backtest_results.db`）に保存されるため、代わりに `db_path` が表示されます。

### サンプル出力（戦略 ID 指定）

```text
=== live trading doctor ===
live_path       : data/live
events_path     : data/live/events
db_path         : data/results/backtest_results.db
events_exists   : yes
event_files     : 24
strategy_id     : spy_sma_v1
trades_exists   : yes
summary_exists  : yes
rollout_status  : ready
```

trades はあるが summary が未生成の場合、その場で summary を構築し `summary_built : yes` 行が追加されます。`rollout_status` は `events_exists` かつ `event_files > 0` かつ（`trades_exists` か `summary_exists`）が満たされれば `ready`、それ以外は `incomplete`。

---

## alpha-forge live sync-events

VPS 上のイベントログを rsync でローカルに同期します。

### 構文

```bash
alpha-forge live sync-events [--dry-run]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--dry-run` | フラグ | false | 実際の転送を行わず、ファイル一覧のみ表示 |

### rsync 設定要件（`forge.yaml`）

`forge.yaml` に以下のような `remote` 設定が必要：

```yaml
remote:
  enabled: true
  user: <SSH_USER>
  host: <VPS_HOST>
  events_path: /var/log/alpha-strike/events    # VPS 側のイベントログディレクトリ
  local_events_path: ./data/live/events        # ローカル保存先（任意、デフォルト ./data/live/events）
  ssh_key_path: ~/.ssh/id_ed25519              # SSH 鍵（任意、未指定なら ssh デフォルト鍵）
```

| キー | 必須 | 説明 |
|------|------|------|
| `remote.enabled` | ✓ | `true` に設定 |
| `remote.host` | ✓ | VPS のホスト名または IP |
| `remote.user` | ✓ | SSH ログインユーザー名 |
| `remote.events_path` | ✓ | VPS 側のイベントログディレクトリ（絶対パス推奨） |
| `remote.local_events_path` | - | ローカル保存先（省略時 `./data/live/events`） |
| `remote.ssh_key_path` | - | SSH 鍵パス（省略時 SSH デフォルト鍵） |

### 実行される rsync コマンド

```bash
rsync -avz --progress -e "ssh -i <ssh_key_path>" \
  <user>@<host>:<events_path>/ <local_events_path>/
```

`--dry-run` 指定時は `rsync --dry-run -avz ...` で実際の転送を行わずファイル一覧のみ確認できます。**タイムアウトは 300 秒**。

### サンプル出力

```text
同期中: ubuntu@vps.example.com:/var/log/alpha-strike/events/ → ./data/live/events/
sending incremental file list
events_20260415_093021.json
        2,318 100%   12.45MB/s    0:00:00
events_20260415_140215.json
        1,842 100%   15.20MB/s    0:00:00
sent 4,312 bytes  received 78 bytes  total size 4,160
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: remote が無効です。forge.yaml の remote.enabled を true に設定してください。` | `remote.enabled` が false | `forge.yaml` で `enabled: true` |
| `エラー: remote.host, remote.user, remote.events_path を設定してください。` | 必須キー欠如 | `forge.yaml` の `remote` を完全設定 |
| `エラー: rsync タイムアウト（300秒）。VPS への接続を確認してください。` | ネットワーク・SSH 障害 | SSH 接続性、鍵設定、ファイアウォールを確認 |

### 終了コード

- 成功: `0`
- 設定不足: `1`
- rsync タイムアウト: `1`
- rsync 自体のエラー: rsync の終了コードをそのまま伝播

---

## alpha-forge live replay

always-in-market の combine overlay 向けに、同期済み alpha-strike イベント（[`alpha-forge live sync-events`](#alpha-forge-live-sync-events) で取得）から position 推移を再構築し、portfolio equity curve から Sharpe / CAGR / MaxDD を算出します（issue #57）。`order_reconciled` イベントを権威ソースとして優先します。

### 構文

```bash
alpha-forge live replay <PORTFOLIO_ID> --combine-strategies <ID1>,<ID2>[,...] [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `PORTFOLIO_ID` | 引数（必須） | - | combine portfolio 識別子 |
| `--combine-strategies` | オプション（必須） | - | combine 対象戦略 ID（カンマ区切り、2 戦略以上） |
| `--since` | オプション | - | 期間下限（ISO 形式） |
| `--compare` | フラグ | false | `backtest combine` の結果と並べて比較表示する |
| `--initial-capital` | オプション | `backtest.initial_capital`（既定 100,000） | ライブ口座の基準資本 |
| `--benchmark` | オプション | `forge.yaml` の `live.benchmark`（既定は未設定） | 比較用の指数銘柄（buy&hold）。本フラグと `live.benchmark` の両方が未設定の場合、比較線は表示されません |

### equity の計算方法（issue #1332）

equity は次式で求めます。

```text
equity = initial_capital + cash 増減 + Σ(建玉 × 終値)
```

建玉の買い付けは cash 減少と評価額増加が相殺されるため equity を動かさず、**価格が動いて初めて損益が出ます**。

このため `--initial-capital` は実際のライブ口座の資本と一致させてください。バックテストの既定（100,000）のまま実口座が 1,000,000 だと、リターン率がその比率でずれます。

```bash
# 実口座が $1,000,000 の場合
alpha-forge live replay beat_qqq_hedged_v1 \
  --combine-strategies tqqq_v1,gld_v1,tlt_v1 \
  --initial-capital 1000000
```

equity / メトリクスは**最初の receipt 以降**に限定されます。価格データは十数年分あるため、全期間で算出すると運用実績が数ヶ月でも CAGR / Sharpe が全期間ベースの無意味な値になるためです。

equity を並べる日付軸は、構成銘柄すべての価格インデックスの**和集合**です。ある銘柄の価格データにだけ欠けている営業日があっても、他の銘柄が取引していればその日は equity に現れます（欠けている銘柄の価格は直前値で前方補完されます）。`--combine-strategies` に渡す銘柄の並び順は結果に影響しません。

!!! note "v1.1.0 より前からの移行"
    v1.1.0 までは日付軸が「最初の銘柄の価格インデックス」固定でした。そのため他の銘柄にしか無い営業日が欠落することがあり、再実行すると Sharpe / ボラティリティがわずかに変わる場合があります（累計リターン・CAGR・最大DD は日付軸の端点と極値で決まるため変わりません）。

`--benchmark <SYMBOL>` を指定すると、同じライブ期間について指数の buy&hold を第三の比較線として追加します。`--benchmark` を省略した場合は `forge.yaml` の `live.benchmark` にフォールバックし、両方とも未設定であれば単に比較線が出ないだけです（エラーにはなりません）。`--compare` の backtest 線と同様、ベンチマーク線も先頭値が `--initial-capital` と一致するよう正規化されるため、live・ベンチマーク・backtest の各線の差がそのまま超過リターンとして読み取れます。

ベンチマーク銘柄の価格データが未取得（`alpha-forge data fetch <SYMBOL>` 未実行）の場合、`live replay` は警告を出してベンチマーク線のみを省略します。live のエクイティカーブ（および `--compare` 指定時の backtest 線）は引き続き計算され、コマンドは正常終了します。

### 再構築の精度に関する警告

`live replay` は、再構築した建玉が実口座とずれている可能性を検知すると警告を出します。いずれもコマンド自体は正常終了しますが、**表示される金額が実態とずれている**ため内容を確認してください。

| 警告 | 意味 | 対処 |
|---|---|---|
| 建玉があるのに終値が欠測している | 価格データの期間がアラートログより短く、保有中の建玉が時価 $0 として評価されている。equity・最大DD・累計損益がいずれも過小に出る | `alpha-forge data fetch <SYMBOL> --period <長め>` で運用開始日以前まで価格データを取得し直す |
| 保有数量を超える売却を検出した | 再構築した建玉と実口座がずれている（アラートログの欠落・重複、Pine 側の open-loop desync など）。建玉は 0 にクランプされ、以降の平均取得単価・含み損益・構成比は誤った前提で計算される | イベントログ（`live events`）で該当銘柄の発注履歴を確認する。恒常的に出る場合は Pine 側の数量計算が closed-loop になっているか確認する |

---

## 共通の挙動

- **保存先**:
    - raw event ログ: `<journal_path>/../live/events/`（ファイルシステム上の JSON）
    - trade records / summary: SQLite DB（`config.report.output_path` 配下の `backtest_results.db`）。v0.12.0 で `trades/` / `summaries/` の JSON ファイルから SQLite へ移行済み
- **`forge.yaml`**: 上記すべてのパスは `FORGE_CONFIG` が指す `forge.yaml` で決まる
- **VPS 連携**: `sync-events` は `forge.yaml` の `remote.*` セクションを参照
- **終了コード**: 通常 `0`、引数エラーは Click が `2`、設定不足や record 不存在は通常 `1`
- **`--json` の出力規約**: `list` / `events` / `trades` / `summary` / `compare` / `doctor` は `--json` に対応します。`--json` 指定時、stdout は純 JSON のみで、装飾・進捗・保存メッセージは標準エラーへ分離されます。一覧系は `{<plural>: [...], "count": n}`（不在でも空配列 + 終了コード `0`）、単体参照系の not found は stdout に `{error, code, id}` の JSON を出して終了コード `1` を返します。

---

<!-- 同期元: `alpha-forge/src/alpha_forge/commands/live.py` の Click decorator、`alpha-forge/src/alpha_forge/live/store.py` の LiveStore、`alpha-forge/src/alpha_forge/live/formatter.py` の `format_*` 関数。alpha-forge 側で引数追加・設定キー変更があった場合、本ページも追従更新が必要。 -->
