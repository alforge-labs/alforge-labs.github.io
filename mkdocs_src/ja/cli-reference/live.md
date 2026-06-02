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
| `--strategy-id` | オプション | - | `strategy_id` で絞り込む |
| `--event-type` | オプション | - | `event_type` で絞り込む（例: `fill`、`close`） |
| `--broker` | オプション | - | `broker` で絞り込む |
| `--limit` | int | `20` | 表示件数 |

### サンプル出力

```text
timestamp           strategy_id     broker      event_type   symbol   side   qty   price
2026-04-15 09:31    spy_sma_v1      ibkr        fill         SPY      long   100   452.30
2026-04-15 14:02    spy_sma_v1      ibkr        close        SPY      long   100   458.12
...
```

整形は `format_live_events` に依存します。

---

## alpha-forge live convert-check

raw event を trade records に変換できる状態か（`fill` と `close` のペアが揃っているか等）を確認します。`import-events` の前段で実行することを推奨。

### 構文

```bash
alpha-forge live convert-check [--strategy-id <ID>]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--strategy-id` | オプション | - | `strategy_id` で絞り込む |

### サンプル出力

```text
=== Conversion readiness ===
strategy_id              fill_events   close_events   matched   pending   status
spy_sma_v1                        18             16        16         2   partial
qqq_hmm_macd_ema_rsi_v1            8              8         8         0   ready
broken_v1                          5              0         0         5   missing close events
```

整形は `format_event_conversion_report` に依存します。

---

## alpha-forge live import-events

`fill` / `close` event から trade records を生成し、`<live_path>/trades/<strategy_id>.json` および `<live_path>/summaries/<strategy_id>.json` に保存します。

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
- 事前に [`alpha-forge live convert-check`](#alpha-forge-live-convert-check) で `status: ready`（または `partial` で許容範囲）を確認しておくこと
- 1 戦略 ID に対して 1 回実行すれば `<strategy_id>.json` が生成される（再実行で上書き）

### サンプル出力

```text
imported_trades   : 16
strategy_id       : spy_sma_v1
trades_file       : data/live/trades/spy_sma_v1.json
summary_file      : data/live/summaries/spy_sma_v1.json
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `trade records を生成できませんでした: <id>` | `fill` / `close` ペアが揃わない、event 不存在 | `alpha-forge live convert-check --strategy-id <id>` で原因確認 |

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

新しい取引から順に表示されます（`entry_at` 降順）。

### サンプル出力

```text
trade_id  side    entry_at              exit_at               qty   pnl_pct   exit_reason
t_0042    long    2026-04-15 09:31      2026-04-15 14:02      100   +1.29%    take_profit
t_0041    long    2026-04-12 10:05      2026-04-12 15:48      100   -0.42%    stop_loss
...
```

整形は `format_live_trades` に依存します。

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `live trade records がありません: <id>` | `<live_path>/trades/<id>.json` 不存在 | `alpha-forge live import-events <id>` で生成 |

---

## alpha-forge live summary

戦略の live performance summary を表示します。サマリーが未生成の場合は trade records から自動構築します。

### 構文

```bash
alpha-forge live summary <STRATEGY_ID>
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 戦略 ID |

### サンプル出力

```text
=== spy_sma_v1 / Live Summary ===
trades            : 16
win_rate          : 56.3%
total_pnl_pct     : +8.42%
avg_win_pct       : +1.85%
avg_loss_pct      : -1.12%
max_drawdown_pct  : -4.20%
sharpe_ratio      : 1.32
period            : 2026-03-01 → 2026-04-15
```

整形は `format_live_summary` に依存します。

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `live summary がありません: <id>` | trade records 不存在で構築不能 | `alpha-forge live import-events <id>` を先に実行 |

---

## alpha-forge live compare

最新 backtest run と live summary を比較表示し、ライブが想定通りに機能しているかを評価します。

### 構文

```bash
alpha-forge live compare <STRATEGY_ID>
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 戦略 ID |

### サンプル出力

```text
=== spy_sma_v1: Backtest vs Live ===

Metric             Backtest (run_20260410)    Live (2026-03-01 → 2026-04-15)    Diff
trades             18                          16                                 -2
win_rate_pct       58.3                        56.3                              -2.0
total_return_pct   +12.4                       +8.42                             -3.98
sharpe_ratio       1.45                        1.32                              -0.13
max_drawdown_pct   -3.80                       -4.20                             -0.40
```

整形は `format_live_compare` に依存します。

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
alpha-forge live doctor [STRATEGY_ID]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（任意） | - | 戦略 ID（指定で詳細チェック） |

### サンプル出力（戦略 ID なし）

```text
=== live trading doctor ===
live_path       : data/live
events_path     : data/live/events
trades_path     : data/live/trades
summaries_path  : data/live/summaries
events_exists   : yes
event_files     : 24
hint            : pass a strategy_id to validate trades/summary readiness
```

### サンプル出力（戦略 ID 指定）

```text
=== live trading doctor ===
live_path       : data/live
...
event_files     : 24
strategy_id     : spy_sma_v1
trades_exists   : yes
summary_exists  : yes
rollout_status  : ready
```

`rollout_status` は `events_exists` かつ `event_files > 0` かつ（`trades_exists` か `summary_exists`）が満たされれば `ready`、それ以外は `incomplete`。

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

---

## 共通の挙動

- **保存先**: `<journal_path>/../live/` 配下（`events/`、`trades/`、`summaries/` のサブディレクトリ）
- **`forge.yaml`**: 上記すべてのパスは `FORGE_CONFIG` が指す `forge.yaml` で決まる
- **VPS 連携**: `sync-events` は `forge.yaml` の `remote.*` セクションを参照
- **詳細仕様**: データモデルとロールアウト手順は alpha-forge リポジトリ内の以下を参照
    - `alpha-forge/docs/live-trading-data-model.md`
    - `alpha-forge/docs/live-trading-rollout.md`
- **終了コード**: 通常 `0`、引数エラーは Click が `2`、設定不足や record 不存在は通常 `1`

---

<!-- 同期元: `alpha-forge/src/alpha_forge/commands/live.py` の Click decorator、`alpha-forge/src/alpha_forge/live/store.py` の LiveStore、`alpha-forge/src/alpha_forge/live/formatter.py` の `format_*` 関数。alpha-forge 側で引数追加・設定キー変更があった場合、本ページも追従更新が必要。 -->
