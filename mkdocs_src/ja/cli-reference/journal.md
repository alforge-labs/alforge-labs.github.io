# alpha-forge journal

戦略の実行履歴・スナップショット・タグ・メモ・判定（pass/fail/review）を管理するコマンドグループ。`config.journal.auto_record` が true なら、`alpha-forge strategy save` や `alpha-forge optimize run` などの実行が自動的にジャーナルへ記録されます。

!!! info "サンプル出力について"
    本ページの出力例は `alpha-forge` のソースから読み取ったフォーマットを元にしたサンプルです。実際の数値や整形は `journal/formatter.py` の `format_*` 関数の挙動に依存します。

## サブコマンド一覧

| コマンド | 説明 |
|---------|------|
| [`alpha-forge journal list`](#alpha-forge-journal-list) | ジャーナルが存在する戦略の一覧を表示する |
| [`alpha-forge journal show`](#alpha-forge-journal-show) | 戦略の全履歴（スナップショット＋実行履歴）を表示する |
| [`alpha-forge journal runs`](#alpha-forge-journal-runs) | 実行結果をテーブル形式で一覧表示する |
| [`alpha-forge journal compare`](#alpha-forge-journal-compare) | 2 つの実行結果を比較表示する |
| [`alpha-forge journal tag`](#alpha-forge-journal-tag) | タグを追加・削除する |
| [`alpha-forge journal note`](#alpha-forge-journal-note) | メモを追記する |
| [`alpha-forge journal verdict`](#alpha-forge-journal-verdict) | 実行結果に判定（pass / fail / review）を記録する |
| [`alpha-forge journal report`](#alpha-forge-journal-report) | 戦略履歴を Markdown レポートとして出力する（TV チャート埋込対応） |

---

## alpha-forge journal list

ジャーナルが存在する戦略の一覧を表示します。`config.strategies.path` 配下の SQLite DB（`strategies.db`）の `journal_entries` テーブルを走査します。

### 構文

```bash
alpha-forge journal list [--json]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--json` | フラグ | false | 結果を JSON で出力（`{journals: [...], count}`） |

### サンプル出力

```text
戦略ID                                  最終実行   実行数   スナップ  タグ
────────────────────────────────────────────────────────────────────────────────
spy_sma_v1                   2026-04-15 10:30   14      2  production, validated
qqq_hmm_macd_ema_rsi_v1      2026-04-12 18:05    8      1  experimental
gc_hmm_macd_ema_v1           2026-04-01 09:20    5      1  -
```

整形は `journal/formatter.py` の `format_journal_list` に依存します。各行は `戦略ID` / `最終実行`（最新 run の日時。run がなければ `-`）/ `実行数` / `スナップ`（スナップショット数）/ `タグ` で構成されます。ジャーナルが 1 件もない場合は「ジャーナルが登録されている戦略はありません。」と表示されます。

---

## alpha-forge journal show

戦略の全履歴を表示します：戦略定義スナップショット + 実行履歴（バックテスト・最適化など）+ タグ + メモ + ライブサマリ（live trading records があれば）。

### 構文

```bash
alpha-forge journal show <STRATEGY_ID> [--json]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 表示する戦略 ID |
| `--json` | フラグ | false | 結果を JSON で出力（`JournalEntry` を dump + `live_summary`。不在時は stdout に `{error, code, id}` + 終了コード `1`） |

### サンプル出力

```text
=== Strategy: spy_sma_v1 ===
Tags: production, validated
Notes:
  - 2026-04-15: OOS 検証通過
  - 2026-04-10: ベースライン確定

[Snapshots]
  v1.0.0 (2026-04-01) saved via 'save'
  v1.1.0 (2026-04-15) saved via 'save'

[Runs]
  run_20260415103021 (optimization)  metric=sharpe_ratio  best=1.45  verdict=pass
  run_20260410181522 (backtest)      sharpe=0.92  cagr=5.4%          verdict=-
  ...

[Live Summary]
  trades=42  win_rate=53.5%  pnl_pct=+8.2%
```

整形は `format_journal_show` に依存。詳細フィールドはバージョンにより変動します。

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `ジャーナルがありません: <id>` | 該当ジャーナルファイル不存在、または空 | `alpha-forge journal list` で確認、戦略を実行してジャーナルを作成 |

---

## alpha-forge journal runs

実行結果をテーブル形式で一覧表示します。

### 構文

```bash
alpha-forge journal runs <STRATEGY_ID> [--best <KEY>] [--json]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 戦略 ID |
| `--best` | choice | `date` 相当（未指定時） | ソート基準。`sharpe_ratio` / `total_return_pct` / `max_drawdown_pct` / `win_rate_pct` / `date` |
| `--json` | フラグ | false | 結果を JSON で出力（`{strategy_id, runs: [...], count}`。並び順はテキスト表示と一致） |

### サンプル出力

```text
=== spy_sma_v1 実行一覧 (3件) ===
run_id                                   日時           種別 symbol    Return   CAGR    SR Sortino    MDD  Win%    PF   取引  verdict
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────
run_20260410181522           2026-04-10 18:15     backtest    SPY    +38.1%  +12.4%  0.92    1.31  -15.6% 58.3% 1.85   24  ✅ pass
run_20260401092030           2026-04-01 09:20     backtest    SPY    +28.0%   +9.7%  0.78    1.04  -18.2% 45.7% 1.42   31  🔍 review
run_20260415103021           2026-04-15 10:30 optimization    SPY         -       -     -       -       -     -    -    -  -
```

整形は `format_runs_table(j, sort_by)` に依存します。列は `run_id` / `日時` / `種別` / `symbol` / `Return` / `CAGR` / `SR` / `Sortino` / `MDD` / `Win%` / `PF` / `取引` / `verdict`。`verdict` は `✅ pass` / `❌ fail` / `🔍 review` / `-`（未判定）の絵文字付きで表示されます。`backtest` 以外の種別（`optimization` など）はメトリクス各列が `-` になります。

---

## alpha-forge journal compare

同一戦略の **2 つの実行結果** を並べて比較表示します。

!!! note "`compare` の 2 義"
    `journal compare` は**保存済み**の 2 つの run を参照するだけの **read-only** コマンドです（新規バックテストは実行しません）。新規にバックテストを実行して比較するのは別概念の重い処理 [`backtest compare`](backtest.md#alpha-forge-backtest-compare) です。

### 構文

```bash
alpha-forge journal compare <STRATEGY_ID> --run <RUN_ID1> --run <RUN_ID2> [--json]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 戦略 ID |
| `--run` | 複数指定可（必須、**ちょうど 2 個**） | - | 比較する `run_id`（2 つ指定） |
| `--json` | フラグ | false | 結果を JSON で出力（`{strategy_id, run_a: {...}, run_b: {...}}`） |

### サンプル出力

```text
=== spy_sma_v1: 実行比較 ===
  A: run_20260415103021  (2026-04-15 10:30  SPY)
  B: run_20260410181522  (2026-04-10 18:15  SPY)

指標                                  A            B  差分
─────────────────────────────────────────────────────────────────
  総リターン (%)                    52.30        38.10  -14.20
  CAGR (%)                          16.80        12.40  -4.40
  シャープレシオ                     1.45         0.92  -0.53
  ソルティノレシオ                   2.01         1.31  -0.70
  最大ドローダウン (%)             -16.80       -15.60  +1.20
  勝率 (%)                          50.00        58.30  +8.30
  プロフィットファクター             2.10         1.85  -0.25
  取引数                            18.00        24.00  +6.00
  平均保有日数                       3.20         2.80  -0.40
  露出率 (%)                        62.00        58.00  -4.00
```

整形は `format_compare(j, run1, run2)` に依存します。列は `指標`（日本語ラベル）/ `A`（1 つ目の run）/ `B`（2 つ目の run）/ `差分`（B − A、最大ドローダウンのみ小さいほど良いとして色付け）。`type` 行・`verdict` 行は表示されません。比較対象の run_id・日時・symbol はヘッダー直下の `A:` / `B:` 行に表示されます。

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: --run を2つ指定してください。` | `--run` の数が 2 でない | 必ず 2 個指定 |
| `エラー: run_id が見つかりません - <id>` | 指定 `run_id` 不存在 | `alpha-forge journal runs <id>` で実在する `run_id` を確認 |

---

## alpha-forge journal tag

戦略に **タグ** を追加・削除します。`--add` と `--remove` は **同時指定可** で、追加と削除を一度に実行できます（両方未指定はエラー）。

### 構文

```bash
alpha-forge journal tag <STRATEGY_ID> [--add <TAG>] [--remove <TAG>]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 戦略 ID |
| `--add` | オプション | - | 追加するタグ |
| `--remove` | オプション | - | 削除するタグ |

### サンプル出力

```text
✅ タグ 'production' を追加しました: spy_sma_v1
```

`--add` と `--remove` を同時指定した場合、**追加 → 削除の順** で処理・出力されます：

```text
✅ タグ 'production' を追加しました: spy_sma_v1
✅ タグ 'experimental' を削除しました: spy_sma_v1
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: --add または --remove を指定してください。` | 両方未指定 | `--add` または `--remove` を渡す |

---

## alpha-forge journal note

戦略にメモを追記します（既存メモへの追加。上書きではない）。

### 構文

```bash
alpha-forge journal note <STRATEGY_ID> <TEXT>
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 戦略 ID |
| `TEXT` | 引数（必須） | - | メモ本文（スペースを含む場合はクォートで囲む） |

### サンプル出力

```text
✅ メモを追記しました: spy_sma_v1
```

実行例：

```bash
alpha-forge journal note spy_sma_v1 "OOS 検証で sharpe=0.95、本番投入候補に格上げ"
```

---

## alpha-forge journal verdict

特定の実行結果（`run_id`）に **判定** を記録します。

### 構文

```bash
alpha-forge journal verdict <STRATEGY_ID> <RUN_ID> <pass|fail|review>
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 戦略 ID |
| `RUN_ID` | 引数（必須） | - | 判定する `run_id` |
| `VERDICT` | 引数（必須、choice） | - | `pass` / `fail` / `review` のいずれか |

### ステータス値（pass / fail / review）の使い分け

| 値 | 意味 | 使い所 |
|----|------|--------|
| `pass` | この実行結果は **採用 / 合格** | OOS 検証通過、ライブ運用候補化、ベンチマーク超え |
| `fail` | **不合格 / 採用しない** | 過学習疑い、ベンチマーク以下、リスクが許容外 |
| `review` | **要レビュー（保留）** | 判定保留中、追加検証待ち、議論中 |

判定は `alpha-forge journal show` や `alpha-forge journal runs` の表示にも反映されます。

### サンプル出力

```text
✅ 判定を記録しました: run_20260415103021 → pass
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: run_id が見つかりません - <id>` | 指定 `run_id` がジャーナルに存在しない | `alpha-forge journal runs <strategy_id>` で確認 |
| Click: `Invalid value for 'VERDICT'` | `pass` / `fail` / `review` 以外を指定 | choice の値を使用 |

!!! note "not found は終了コード `1`（epic #1083 D）"
    存在しない `run_id` を渡した場合、以前は終了コード `0`（成功扱い）を返していましたが、Fail Loud 規約に合わせて **not found = 終了コード `1`** に統一されました。無人ループはこの終了コードで判定できます。

---

## alpha-forge journal report

ジャーナルの全履歴（スナップショット・実行履歴・タグ・メモ・判定）を **Markdown レポート** として出力します（issue #523 Phase 1.5d-γ）。`--with-chart` を併用すると、TradingView から取得した最新チャートの PNG をレポート末尾に埋め込めます。

### 構文

```bash
alpha-forge journal report <STRATEGY_ID> [--output <FILE>] [--with-chart --output <FILE> --symbol <SYM> --interval <TF>]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 戦略 ID |
| `--output` | ファイルパス | - | Markdown 出力先。省略時は標準出力 |
| `--with-chart` | フラグ | false | TradingView チャート PNG をレポート末尾に埋め込む（`--output` / `--symbol` / `--interval` も必須。チャート PNG は Markdown と同ディレクトリに保存されるため標準出力との併用は不可） |
| `--symbol` | オプション | - | チャート用 TV シンボル（`--with-chart` 必須） |
| `--interval` | オプション | - | チャート用 TV インターバル（例: `D`, `60`） |
| `--mock` | フラグ | false | チャート取得を Mock MCP で行う（CI 用） |
| `--mcp-server` | オプション | - | チャート取得用 MCP サーバー（省略時 `forge.yaml` の `tv_mcp.chart_snapshot.endpoint`） |
| `--json` | フラグ | false | 本文ではなく**メタ情報**を JSON で出力（`{strategy_id, output_path, saved, with_chart, chart_path, markdown}`。`--output` 省略時のみ `markdown` を payload に同梱） |

### 実行例

```bash
# 標準出力
alpha-forge journal report spy_sma_v1

# ファイル出力 + TV チャート埋込
alpha-forge journal report spy_sma_v1 --output reports/spy.md \
  --with-chart --symbol SPY --interval D
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `ジャーナルがありません: <id>` | ジャーナル不存在 | `alpha-forge journal list` で確認 |
| `--with-chart には --symbol / --interval を指定してください。` | チャート埋込時の引数不足 | `--symbol` と `--interval` を追加 |
| `--with-chart には --output を指定してください。` | `--with-chart` 指定時に `--output` 未指定（チャート PNG は Markdown と同ディレクトリに保存するため標準出力併用不可） | `--output <FILE>` を追加 |

---

## 共通の挙動

- **保存先**: `config.strategies.path` 配下の SQLite DB（`strategies.db`）。ジャーナルは `journal_entries` / `journal_runs` / `journal_snapshots` テーブルに保存される（v0.12.0 で旧 `<strategy_id>.journal.json` から SQLite へ移行済み）
- **自動記録**: `config.journal.auto_record` が true なら、`alpha-forge strategy save` のスナップショット、`alpha-forge optimize run` の実行記録などが自動でジャーナルへ追加される
- **ライブ連携**: `journal_path` の親ディレクトリ配下の `live/` から `LiveStore` を読み、`show` の表示に反映される
- **`FORGE_CONFIG`**: 上記すべてのパスは環境変数 `FORGE_CONFIG` が指す `forge.yaml` で決まる
- **終了コード**: 通常 `0`、引数エラーは Click が `2` を返す。`run_id` 不存在時は通常 `1`（標準エラーに出力して return）
- **`--json` の出力規約**: `list` / `runs` / `compare` / `show` / `report` は `--json` に対応します。`--json` 指定時、stdout は純 JSON のみ（装飾・保存メッセージは標準エラーへ）。一覧系は `{<plural>: [...], "count": n}`、`show` などの not found は stdout に `{error, code, id}` を出して終了コード `1`。

---

<!-- 同期元: `alpha-forge/src/alpha_forge/commands/journal.py` の Click decorator と `alpha-forge/src/alpha_forge/journal/formatter.py` の `format_*` 関数。alpha-forge 側で引数追加・整形ロジック変更があった場合、本ページも追従更新が必要。 -->
