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

ジャーナルが存在する戦略の一覧を表示します。`config.journal.journal_path` 配下の `<strategy_id>.journal.json` を走査します。

### 構文

```bash
alpha-forge journal list
```

### 引数とオプション

なし。

### サンプル出力

```text
spy_sma_v1                  runs:14   tags: production, validated   verdict: pass
qqq_hmm_macd_ema_rsi_v1     runs: 8   tags: experimental             verdict: review
gc_hmm_macd_ema_v1          runs: 5   tags: -                         verdict: -
```

整形は `journal/formatter.py` の `format_journal_list` に依存し、ジャーナルがない場合は空または案内メッセージを返します。

---

## alpha-forge journal show

戦略の全履歴を表示します：戦略定義スナップショット + 実行履歴（バックテスト・最適化など）+ タグ + メモ + ライブサマリ（live trading records があれば）。

### 構文

```bash
alpha-forge journal show <STRATEGY_ID>
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 表示する戦略 ID |

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
alpha-forge journal runs <STRATEGY_ID> [--best <KEY>]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 戦略 ID |
| `--best` | choice | `date` 相当（未指定時） | ソート基準。`sharpe_ratio` / `total_return_pct` / `max_drawdown_pct` / `win_rate_pct` / `date` |

### サンプル出力

```text
run_id                       type            sharpe   ret%    mdd%   win%   verdict
run_20260415103021           optimization      1.45    +52.3   -16.8   50.0   pass
run_20260410181522           backtest          0.92    +38.1   -15.6   58.3   review
run_20260401092030           backtest          0.78    +28.0   -18.2   45.7   -
```

整形は `format_runs_table(j, sort_by)` に依存します。

---

## alpha-forge journal compare

同一戦略の **2 つの実行結果** を並べて比較表示します。

### 構文

```bash
alpha-forge journal compare <STRATEGY_ID> --run <RUN_ID1> --run <RUN_ID2>
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 戦略 ID |
| `--run` | 複数指定可（必須、**ちょうど 2 個**） | - | 比較する `run_id`（2 つ指定） |

### サンプル出力

```text
=== Compare runs of spy_sma_v1 ===

Metric              run_20260415103021      run_20260410181522
type                optimization            backtest
sharpe_ratio        1.45                    0.92
total_return_pct    +52.3                   +38.1
max_drawdown_pct    -16.8                   -15.6
win_rate_pct        50.0                    58.3
verdict             pass                    review
```

整形は `format_compare(j, run1, run2)` に依存します。

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

`--add` と `--remove` を同時指定した場合：

```text
✅ タグ 'experimental' を削除しました: spy_sma_v1
✅ タグ 'production' を追加しました: spy_sma_v1
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

- **保存先**: `config.journal.journal_path / <strategy_id>.journal.json`
- **自動記録**: `config.journal.auto_record` が true なら、`alpha-forge strategy save` のスナップショット、`alpha-forge optimize run` の実行記録などが自動でジャーナルへ追加される
- **ライブ連携**: `journal_path` の親ディレクトリ配下の `live/` から `LiveStore` を読み、`show` の表示に反映される
- **`FORGE_CONFIG`**: 上記すべてのパスは環境変数 `FORGE_CONFIG` が指す `forge.yaml` で決まる
- **終了コード**: 通常 `0`、引数エラーは Click が `2` を返す。`run_id` 不存在時は通常 `1`（標準エラーに出力して return）

---

<!-- 同期元: `alpha-forge/src/alpha_forge/commands/journal.py` の Click decorator と `alpha-forge/src/alpha_forge/journal/formatter.py` の `format_*` 関数。alpha-forge 側で引数追加・整形ロジック変更があった場合、本ページも追従更新が必要。 -->
