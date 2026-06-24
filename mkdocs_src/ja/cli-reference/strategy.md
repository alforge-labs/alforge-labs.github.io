# alpha-forge strategy

戦略 JSON の作成・登録・検証・管理を行うコマンドグループ。組み込みテンプレートからの雛形作成、ローカル登録、表示、JSON → DB 移行、削除、論理整合性チェック（静的・動的）まで一通り扱います。

!!! info "サンプル出力について"
    本ページの出力例は `alpha-forge` のソースから読み取ったフォーマットを元にしたサンプルです。実際の数値はデータと環境によって異なります。

## サブコマンド一覧

| コマンド | 説明 |
|---------|------|
| [`alpha-forge strategy list`](#alpha-forge-strategy-list) | 登録済み戦略の一覧を表示する |
| [`alpha-forge strategy create`](#alpha-forge-strategy-create) | 組み込みテンプレートから JSON ファイルを作成する |
| [`alpha-forge strategy scaffold`](#alpha-forge-strategy-scaffold) | シンボル・インジケータ・タイプから戦略をスキャフォールドする |
| [`alpha-forge strategy save`](#alpha-forge-strategy-save) | JSON ファイルからカスタム戦略を登録する |
| [`alpha-forge strategy show`](#alpha-forge-strategy-show) | 登録済みの戦略定義（JSON）を表示する |
| [`alpha-forge strategy migrate`](#alpha-forge-strategy-migrate) | 既存 JSON ファイルを DB にインポートする |
| [`alpha-forge strategy delete`](#alpha-forge-strategy-delete) | 登録済み戦略を DB から削除する |
| [`alpha-forge strategy purge`](#alpha-forge-strategy-purge) | 戦略 JSON・関連結果・DB エントリを 1 コマンドで完全削除する |
| [`alpha-forge strategy validate`](#alpha-forge-strategy-validate) | 戦略の論理整合性チェックを実行する |
| [`alpha-forge strategy signals`](#alpha-forge-strategy-signals) | エントリーシグナル数を軽量集計する |
| [`alpha-forge strategy cost-presets`](#alpha-forge-strategy-cost-presets) | ビルトインのコストプリセット一覧を表示する |

---

## alpha-forge strategy list

登録済み戦略の一覧を表示する。`config.strategies.use_db` が true なら DB から、false ならファイルベースのストアから取得します。

### 構文

```bash
alpha-forge strategy list [--json]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--json` | フラグ | false | 結果を JSON 形式で出力する（機械可読・MCP/パイプ用途） |

### サンプル出力

```text
ID                                       名前                           バージョン  タイムフレーム
------------------------------------------------------------------------------------------
spy_sma_crossover_v1                     SMA Golden/Death Cross SPY v1  1.0.0       1d
qqq_hmm_macd_ema_rsi_v1                  QQQ HMM × MACD × EMA × RSI v1  1.0.0       1d
gc_hmm_macd_ema_v1                       GC HMM × MACD × EMA v1         1.0.0       1d
```

戦略が 1 件もない場合：

```text
登録済み戦略はありません。
```

---

## alpha-forge strategy create

組み込みテンプレートから戦略 JSON ファイルを作成します。**戦略レジストリには登録されません**。編集してから [`alpha-forge strategy save`](#alpha-forge-strategy-save) で登録する流れです。

### 構文

```bash
alpha-forge strategy create --template <NAME> --out <FILE> [--strategy-id <ID>]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--template` | 必須 | - | ベースとするテンプレート名 |
| `--out` | 必須 | - | 出力先の JSON ファイルパス |
| `--strategy-id` | オプション | `--out` のファイル名（拡張子除く）から自動派生 | 生成 JSON の `strategy_id` を明示指定する |

!!! info "strategy_id の自動派生（v0.5.4+）"
    `--out my_usdjpy_v1.json` のように指定すると、生成 JSON の `strategy_id` は
    自動的に `my_usdjpy_v1` になります。これは v0.5.3 以前のように
    `strategy_id` がテンプレート名（例: `sma_crossover_v1`）のまま生成され、
    `alpha-forge strategy save` で**ビルトインテンプレートと衝突するエラー**を起こす
    問題（F-301）への対応です。

    - **明示指定したい場合**: `--strategy-id usdjpy_sma_v1` を渡す
    - **ファイル名がテンプレート名と同じ場合**（例: `--out sma_crossover_v1.json`）:
      警告を出してテンプレート ID をそのまま残します（後方互換）。`save` 前に
      手動編集が必要です。
    - **`--strategy-id ""`（空文字）**: 終了コード 2 のエラーで停止します。

### 利用可能なテンプレート

`alpha-forge` に同梱されている組み込みテンプレート（`alpha-forge/src/alpha_forge/strategy/templates.py` の `_TEMPLATE_REGISTRY` 由来）:

AlphaForge は「ユーザー自身が戦略を作って育てる」プロダクトコンセプトのため、配布バイナリには **基本テンプレート 4 個 + レンジ代表 1 個 + 高度指標リファレンス 2 個 = 計 7 個のみ** を同梱しています。v0.3.5 までに同梱されていた 27 個の特化系（KAMA + RSI トレーリング・FX 1h 派生・Connors / TSI / OU stat-arb 等）は v0.4.0 で削除し、`alpha-strategies/legacy_templates/` に社内アーカイブとして保存しています。

| 名前 | カテゴリ | 概要 |
|------|---------|------|
| `sma_crossover_v1` | 基本 | 短期 SMA × 長期 SMA のゴールデン／デッドクロス（最も基本的なトレンドフォロー） |
| `rsi_reversion_v1` | 基本 | RSI の売られ過ぎ／買われ過ぎを利用した逆張り |
| `macd_crossover_v1` | 基本 | MACD ライン × シグナルラインのクロスオーバー |
| `bbands_breakout_v1` | 基本 | ボリンジャーバンドの上限ブレイクアウト |
| `grid_bot_template` | レンジ | グリッドボット戦略（チョッピー相場の代表型） |
| `hmm_bb_pipeline_v1` | リファレンス | HMM 3 状態（Bull / Range / Bear）でレジーム判定し、状態ごとに BB ベースのシグナルを切り替える 2 段階パイプライン（HMM 利用例） |
| `donchian_turtle_v1` | リファレンス | Donchian Channel Breakout + ATR ストップ。Richard Dennis "Turtle Trading Rules" 系統の古典トレンドフォロー |


### サンプル出力

```text
✅ 戦略テンプレート 'sma_crossover_v1' から JSON ファイルを作成しました: my_strategy.json

📝 alpha-forge strategy save の前に、最低限以下を編集してください:
   - name              人が読める戦略名（例: "USDJPY SMA クロス v1"）
   - target_symbols    対象シンボル（例: ["USDJPY=X"]）
   - （最適化したい場合）optimizer_config.param_ranges を定義

   次のステップ: alpha-forge strategy save my_strategy.json
             →   alpha-forge backtest run <SYMBOL> --strategy my_strategy
```

### 生成 JSON で必ず編集すべき項目（F-300）

組み込みテンプレートが書き出す JSON は **そのまま `alpha-forge strategy save` できる形にはなっていません**。最低限以下の編集が必要です：

| 項目 | テンプレ初期値 | 編集する理由 |
|------|--------------|-------------|
| `name` | テンプレート名そのまま | 戦略一覧 (`alpha-forge strategy list`) で人が見分けるため |
| `target_symbols` | `[]`（空） | 空のまま `backtest run` するとシンボル指定エラーで停止する |
| `optimizer_config.param_ranges` | `null` または最小範囲 | 最適化を回したい場合に必須。`null` のままだと内蔵デフォルト範囲が使われる（[`alpha-forge optimize run`](optimize.md#alpha-forge-optimize-run) 参照） |

`strategy_id` は `--out` のファイル名から自動派生されるため、原則編集不要です。

詳しい編集フローは [end-to-end-workflow](../guides/end-to-end-workflow.md) の「戦略 JSON 編集」セクションを参照してください。

### 主なエラー

| 状況 | 動作 |
|------|------|
| 未知のテンプレート名 | `❌ 未知のテンプレート名です: <name>。利用可能: ...` を stderr に出力し、登録・JSON 指定の案内ブロックを添えて終了コード `1` で停止（raw な `ValueError:` トレースバックは出ません） |

---

## alpha-forge strategy scaffold

シンボル・インジケータ・タイプから戦略 JSON を **生成** します。組み込みテンプレートに依存せず、指定したインジケータ群と戦略タイプ（逆張り／順張り／buy-and-hold オーバーレイ）から条件・リスク管理を自動構築します。出力先として `--output`（ファイル書き出し）か `--save`（戦略レジストリへ登録）の **いずれかが必須** です。どちらも指定しないと `エラー: --output または --save のいずれかを指定してください` を出して終了コード `1` で停止します（標準出力への JSON 出力は行いません）。`/explore-strategies` の戦略生成主経路です。

!!! tip "指標カタログ（機械可読）"
    `--indicators` に指定できる指標と、各指標の `params`（name / default / type）・記述例・Pine 変換可否は [`alpha-forge analyze indicator list --json`](analyze.md#alpha-forge-analyze-indicator-list) / [`alpha-forge analyze indicator show <NAME> --json`](analyze.md#alpha-forge-analyze-indicator-show) で確認できます。戦略 JSON を手書きする際の `type` 名・パラメータ名・既定値の権威ソースです。

### 構文

```bash
alpha-forge strategy scaffold --symbol <SYMBOL> --indicators <CSV> --type <TYPE> [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--symbol` | 必須 | - | 対象シンボル（例: `GC=F`, `AAPL`） |
| `--indicators` | 必須 | - | 使用インジケータ（カンマ区切り）: `BB,SMA,HMM,RSI,EMA,ADX,MACD,ATR,SUPERTREND,STOCH,AROON,LINEAR_REG,PV_CORR,UP_RATIO,CMO,ROLLING_QUANTILE`。Alpha158 由来指標は type 限定（AROON/LINEAR_REG/PV_CORR/UP_RATIO=trend-following 専用、CMO/ROLLING_QUANTILE=mean-reversion 専用。不適合 type は ValueError）。mean-reversion + 単一 EMA/SMA トレンドフィルタ + FX/コモディティの組み合わせは signal-starve しやすく、生成時に stderr WARNING で代替案を案内（issue #830） |
| `--type` | 必須（`mean-reversion` / `trend-following` / `buy-hold-overlay`） | - | 戦略タイプ |
| `--strategy-id` | オプション | 自動生成 | 生成戦略の `strategy_id` |
| `--output` | オプション | - | 出力 JSON ファイルパス |
| `--save` | フラグ | false | DB（戦略レジストリ）に直接保存する |
| `--no-atr` | フラグ | false | ATR の自動追加をスキップする（デフォルト: 自動追加） |
| `--goal` | オプション | - | ゴール名（`goals.yaml` の `scaffold_defaults` を自動適用、issue #461） |
| `--position-size-pct` | float | type 別（mean-reversion=15.0 / trend-following=10.0） | ポジションサイズ%（equity 比率、issue #461） |
| `--leverage` | float | 1.0 | レバレッジ倍率（0=ノーポジ、>1=レバ、issue #461） |
| `--stop-loss-pct` | float | null（SL なし） | 損切り%（エントリー価格からの距離、issue #461） |
| `--take-profit-pct` | float | null（TP なし） | 利確%（エントリー価格からの距離、issue #461） |
| `--trailing-stop-pct` | float | null（trailing なし） | トレーリングストップ%（ピーク close からの引き下げ幅、issue #765） |
| `--target-exposure-pct` | float（0 < x ≤ 100） | 70.0 | （buy-hold-overlay 専用）hedge レジーム時の目標エクスポージャー%（#922 Phase 3） |
| `--hedge-trigger-mode` | `or` / `and` | `or` | （buy-hold-overlay 専用）複合 hedge トリガーの集約モード（#964/#965）。`or`=任意の指標で hedge、`and`=全指標一致時のみ。対応: SMA200+ATR / SMA200+RSI / SMA200+BB |
| `--commission-pct` | float | null（forge.yaml 継承） | 戦略固有の手数料%（片道、絶対 %。issue #766） |
| `--slippage-pct` | float | null（forge.yaml 継承） | 戦略固有のスリッページ%（片道、絶対 %。issue #766） |
| `--cost-preset` | オプション | - | コストプリセット名（issue #785、例: `moomoo-crypto-spot` / `binance-spot-vip0` / `oanda-fx-major` / `ibkr-us-stock-fixed`）。`--commission-pct` / `--slippage-pct` 併用時は明示値が優先。一覧は [`alpha-forge strategy cost-presets`](#alpha-forge-strategy-cost-presets) |
| `--timeframe` | オプション | `1d` | 戦略の時間足（例: `1d`, `4h`、issue #463/#758、`--goal` の `scaffold_defaults.timeframe` を上書き） |
| `--confirm-bars` | int | - | 反転確認バー数（mean-reversion のみ、issue #470/#473）。0=瞬間、1=前バー BB 抜け+現バー反転、2/3=連続反転 |
| `--wick-ratio` | float | - | ピンバー的反転の wick 長さ閾値（issue #473）。`confirm_bars≥1` のみ有効 |
| `--vol-tier` | `auto` / `low` / `mid` / `high` | - | asset ボラティリティ tier（issue #886）。mean-reversion の SL/TP デフォルトを tier 別に変える（low=0.8%/1.6%、mid=1.5%/3.0%、high=3.5%/7.0%）。`auto` は過去 252 営業日の ATR%/価格平均から自動判定。明示 SL/TP が優先 |
| `--allow-extreme` | フラグ | false | 指標数 5 以上の戦略生成を許可する（issue #888）。通常は AND 条件過剰で no_signals / pre_filter_failed を量産するため abort される |
| `--reject-on-warning` | フラグ | false | scaffold 警告を検出したら戦略を保存せず exit code 2 で終了する（issue #903）。agent (skill) が別組み合わせへ切り替える運用に使う。`--allow-extreme` による abort 突破は対象外（abort は exit 1） |

---

## alpha-forge strategy save

JSON ファイルからカスタム戦略を **戦略レジストリに登録** します。`config.journal.auto_record` が true の場合、Journal にスナップショットも記録されます。

### 構文

```bash
alpha-forge strategy save <FILE_PATH> [--force]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `FILE_PATH` | 引数（必須） | - | 戦略 JSON ファイルパス |
| `--force` | フラグ | false | 同一 ID が存在する場合に上書きする |

### サンプル出力

```text
✅ カスタム戦略 'my_strategy_v1' を登録しました
```

`--force` で上書きした場合：

```text
✅ カスタム戦略 'my_strategy_v1' を上書き登録しました
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: 指定されたファイルが見つかりません - <path>` | ファイル未存在 | パスを確認 |
| `エラー: <DuplicateStrategyError>` | 同 ID が既に登録済み | `--force` で上書きするか、JSON の `strategy_id` を変更 |

---

## alpha-forge strategy show

登録済みの戦略 JSON を整形して標準出力に表示します。

### 構文

```bash
alpha-forge strategy show <STRATEGY_ID> [--json] [--with-silence-stats]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 表示する戦略 ID |
| `--json` | フラグ | false | 純粋な JSON 形式で出力（パイプ用途向け） |
| `--with-silence-stats` | フラグ | false | buy-hold-overlay の hedge_trigger 発火統計を historical OHLC で計算して表示（#966 Phase 3）。複合 REGIME_RULE では各 condition と集約結果の発火バー数を出力する。OHLC 取得を伴うため `--json` 時のみ別途実行が必要 |

### サンプル出力

```text
=== spy_sma_crossover_v1 ===
{
  "strategy_id": "spy_sma_crossover_v1",
  "name": "SMA Golden/Death Cross SPY v1",
  "version": "1.0.0",
  ...
}
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: 戦略 '<id>' が見つかりません` | ID 不正 | `alpha-forge strategy list` で確認 |

---

## alpha-forge strategy migrate

`config.strategies.path` 配下の既存 JSON ファイルを **DB（SQLite）にインポート** します。`use_db: true` の運用に切り替える際に使用します。

### 構文

```bash
alpha-forge strategy migrate [--dry-run] [--force]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--dry-run` | フラグ | false | 実際には書き込まずに確認のみ |
| `--force` | フラグ | false | 重複 ID は最後のファイルで上書き |

### 前提条件

`config.strategies.use_db` が **true** であることが必要です。`forge.yaml`（`FORGE_CONFIG`）で：

```yaml
strategies:
  use_db: true
```

### サンプル出力

```text
⚠️  重複 strategy_id を検出:
  spy_sma_crossover_v1:
    - spy_sma_crossover_v1.json
    - spy_sma_crossover_v1_optimized.json

--force を付けて再実行すると、最後のファイルで上書きします。
```

`--force --dry-run` 指定時：

```text
[dry-run] 12 件を DB に登録予定（実際には書き込みません）
```

通常実行時：

```text
  スキップ (broken_v1.json): パースエラー - <詳細>
  スキップ (legacy_v1): 重複のため登録しませんでした

✅ 完了: 10 件登録, 2 件スキップ
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: strategies.use_db が false です。forge.yaml に use_db: true を設定してください` | DB 無効 | `forge.yaml` を更新して再実行 |
| `移行対象の JSON ファイルが見つかりません。` | `strategies.path` が空 | パス・配置を確認 |

---

## alpha-forge strategy delete

登録済み戦略を DB / レジストリから削除します。`--with-results` を付けると関連ファイル（最適化済み戦略・バックテスト結果・最適化結果 JSON）も一括削除します。Journal は保持されます。

### 構文

```bash
alpha-forge strategy delete <STRATEGY_ID> [--dry-run] [--yes] [--with-results]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 削除する戦略 ID |
| `--dry-run` | フラグ | false | 実際には削除せず、削除対象を表示して終了する（破壊系ガードの非対称解消、issue #1178） |
| `--yes` / `-y` | フラグ | false | 確認プロンプトなしで削除（epic #1083 D で `--force` から改名） |
| `--with-results` | フラグ | false | 関連ファイル（`<id>_optimized.json`、`<id>_report.json`、`optimize_<id>_*.json`）も一括削除 |

破壊的操作のため、非対話環境（`FORGE_NONINTERACTIVE` / `CI` / 非 TTY）で `--yes` が無いと終了コード `2` で停止します。not found は終了コード `1`。

`--dry-run` を付けると、何も削除せずに削除対象（`--with-results` 指定時は関連ファイルも）を一覧表示して終了コード `0` で終わります。本番削除の前に対象を確認するのに有効です。

### `--with-results` で削除対象になるファイル

- `strategies.path / <id>_optimized.json`
- `report.output_path / <id>_report.json`
- `report.output_path / optimize_<id>_*.json`（複数あれば全て）

`<id>.journal.json` は **保持** されます。

### recommendations.yaml の自動クリーンアップ（issue #454）

戦略削除時に `data/explorer/recommendations.yaml` 上の該当エントリも自動的に削除されます（rank は詰め直されます）。auto-relax で生成された推薦戦略を削除しても、stale な推薦が残って `alpha-forge explore run` が `StrategyNotFoundError` で停止することはありません。

なお、`alpha-forge explore recommend show` 実行時には DB 存在チェックが走り、過去に取り残された stale エントリも自動的に prune されます。

### サンプル出力

```text
削除対象: my_strategy_v1

  ✓ data/strategies/my_strategy_v1_optimized.json
  ✓ data/results/my_strategy_v1_report.json
  ✓ data/results/optimize_my_strategy_v1_20260415_103021.json
  - data/journal/my_strategy_v1.journal.json (保持)

続行しますか？ [y/N]: y
✅ 戦略 'my_strategy_v1' を削除しました
ファイルを削除しました: 3件
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: 戦略 '<id>' が見つかりません` | ID 不正 | `alpha-forge strategy list` で確認 |
| `キャンセルしました` | 確認プロンプトで No | `--yes` を付けるか、改めて承認 |

---

## alpha-forge strategy purge

戦略 JSON・関連ファイル（`_optimized.json`、`_report.json`、`optimize_<id>_*.json`）・DB エントリを **1 コマンドで完全削除** します。従来の `rm <strategy>.json && rm <strategy>_report.json && alpha-forge strategy delete <id> --yes` の 3 ステップが 1 コマンドになります。Journal ファイル（`<id>.journal.json`）は保持されます。

### 構文

```bash
alpha-forge strategy purge <STRATEGY_ID> [--dry-run] [--yes]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 完全削除する戦略 ID |
| `--dry-run` | フラグ | false | 削除対象ファイルの一覧表示のみ。実ファイルは削除しない |
| `--yes` / `-y` | フラグ | false | 確認プロンプトなしで完全削除（epic #1083 A で新規追加。従来は確認プロンプトのみでハングしていた） |

破壊的操作のため、非対話環境（`FORGE_NONINTERACTIVE` / `CI` / 非 TTY）で `--yes` が無いと終了コード `2` で停止します。not found は終了コード `1`。

### サンプル出力

`--dry-run`：

```text
[dry-run] 削除対象:
  - data/strategies/my_strategy_v1.json
  - data/strategies/my_strategy_v1_optimized.json
  - data/results/my_strategy_v1_report.json
  - data/results/optimize_my_strategy_v1_20260415_103021.json
  - DB エントリ: my_strategy_v1
  ※ data/journal/my_strategy_v1.journal.json は保持
```

通常実行：

```text
削除対象: my_strategy_v1

  ✓ data/strategies/my_strategy_v1.json
  ✓ data/strategies/my_strategy_v1_optimized.json
  ✓ data/results/my_strategy_v1_report.json
  ✓ data/results/optimize_my_strategy_v1_20260415_103021.json
  - data/journal/my_strategy_v1.journal.json (保持)

続行しますか？ [y/N]: y
✅ 戦略 'my_strategy_v1' を完全削除しました
```

存在しないファイルは警告のみで処理を続行します（エラーで停止しません）。

### `delete --with-results` との違い

| 観点 | `delete --with-results` | `purge` |
|------|-------------------------|---------|
| 戦略 JSON 本体 | 残す | 削除 |
| `<id>_optimized.json` | 削除 | 削除 |
| `<id>_report.json` | 削除 | 削除 |
| `optimize_<id>_*.json` | 削除 | 削除 |
| Journal | 保持 | 保持 |
| DB エントリ | 削除 | 削除 |

戦略を「完全に消したい」ときは `purge`、戦略 JSON を残して結果ファイルだけ片付けたいときは `delete --with-results` を使います。

---

## alpha-forge strategy validate

戦略の **論理整合性チェック** を実行します。`--symbol` を指定すると **動的チェック**（実データ上のシグナル件数・条件相関）も実施します。`STRATEGY_ID` に `.json` 拡張子のパスを渡すと、レジストリ未登録の JSON を直接検証できます。

### 構文

```bash
alpha-forge strategy validate <STRATEGY_ID|FILE.json> [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `STRATEGY_ID` | 引数（必須） | - | 戦略 ID または `.json` ファイルパス |
| `--symbol` | オプション | - | 動的チェック用シンボル（指定で動的チェック有効化） |
| `--period` | オプション | `1y` | データ取得期間 |
| `--min-signals` | int | `30` | 最小シグナル件数閾値（下回ると警告） |
| `--corr-threshold` | float | `0.9` | 相関係数の警告閾値 |
| `--json` | フラグ | false | JSON 形式で出力 |

### 静的チェックの内容

レジストリの `StrategyValidator` が `symbol` 未指定時に行うチェック（実装ベース）：

- `strategy_id` / `name` / `version` / `timeframe` などの必須フィールド
- `indicators[]` の `id` 重複チェック・参照解決
- `entry_conditions` / `exit_conditions` の参照先 ID が存在するか
- 条件式（`left` / `op` / `right`）の構文と型整合性
- `risk_management` の値域（パーセント、レバレッジなど）
- `regime_config` の `indicator_id` 解決
- `optimizer_config.param_ranges` のキーが `parameters` または指標 `params` に対応

### `--symbol` 指定時の動的チェック

実データを取得し、軽量バックテストでシグナル統計を取ります：

- 期間中のエントリーシグナル件数（`min_signals` 未満なら警告）
- 各リーフ条件（leaf condition）の `True` 日数とパーセント
- 条件間の相関係数（`corr_threshold` 超で警告）

### サンプル出力（テキスト）

```text
戦略: spy_sma_crossover_v1  [OK]

[動的チェック]
  シンボル: SPY  期間: 1y  総日数: 252
  エントリーシグナル: 87 日
  条件別 True 日数:
    sma_fast > sma_slow: 142 日 (56.3%)
    rsi < 70: 198 日 (78.6%)

✓ 問題は検出されませんでした
```

エラー検出時：

```text
戦略: my_v1  [NG]

[エラー]
  ✗ [E_INDICATOR_REF] 条件式の参照先 'sma_fast' が indicators に存在しません
    → indicators 配列に { "id": "sma_fast", "type": "SMA", ... } を追加してください

[警告]
  ⚠ [W_LOW_SIGNALS] エントリーシグナルが少なすぎます: 12 日（閾値 30）
    → 条件を緩めるか、データ期間を延ばしてください

  [相関分析]
    ⚠ rsi < 70 × close > sma_fast: 0.94
      → 高相関の条件を片方除去するか、独立性のある別条件に置き換えてください
```

### サンプル出力（`--json`）

静的チェックは `static_checks`、`--symbol` 指定時の動的チェックは `dynamic_checks` のネスト構造で返されます（`--symbol` 未指定時は `dynamic_checks` 自体が出力されません）。

```json
{
  "ok": false,
  "strategy_id": "my_v1",
  "static_checks": {
    "errors": [
      {"code": "E_INDICATOR_REF", "severity": "error", "message": "...", "suggestion": "..."}
    ],
    "warnings": []
  },
  "dynamic_checks": {
    "symbol": "SPY",
    "period": "1y",
    "total_days": 252,
    "entry_signal_days": 12,
    "signal_rate_pct": 4.8,
    "leaf_conditions": [
      {"description": "rsi < 30", "true_days": 18, "total_days": 252, "true_pct": 7.1}
    ],
    "hmm_regime_days": null,
    "warnings": [
      {"code": "W_LOW_SIGNALS", "severity": "warning", "message": "...", "suggestion": "..."}
    ],
    "correlations": []
  }
}
```

### 終了コード

- `result.ok = true` → `0`
- `result.ok = false`（エラー検出）→ `1`

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: 指定されたファイルが見つかりません - <path>` | `.json` 指定時に未存在 | パスを確認 |

---

## alpha-forge strategy signals

最適化・WFT を実行せず、デフォルトパラメータでエントリーシグナル数・推定取引数・WFT 窓カバレッジを素早く集計します（#321）。

```bash
alpha-forge strategy signals <SYMBOL> --strategy <NAME> [--period <PERIOD>] [--json]
```

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--strategy` | 戦略名（必須） | — |
| `--period` | データ期間 | `5y` |
| `--json` | JSON 形式で出力する | off |

#### 出力例（テキスト）

```
📊 シグナル集計: my_rsi_v1 / SPY (5y)
  ロングシグナル: 45 日
  推定取引数:     38
  年平均取引数:   7.6
  WFT 窓カバレッジ: 低 (5-10 取引/窓)
```

#### 出力 JSON の例

```json
{
  "strategy_id": "my_rsi_v1",
  "symbol": "SPY",
  "period": "5y",
  "total_days": 1260,
  "long_signals": 45,
  "short_signals": 0,
  "estimated_trades": 38,
  "avg_per_year": 7.6,
  "wft_window_coverage": "低 (5-10 取引/窓)"
}
```

| フィールド | 説明 |
|-----------|------|
| `long_signals` | ロングエントリーシグナルが立った日数 |
| `estimated_trades` | 連続シグナルをブロック単位でカウントした推定取引数 |
| `avg_per_year` | 年平均取引数 |
| `wft_window_coverage` | WFT 窓あたりの推定取引数に基づくカバレッジ判定 |

---

## alpha-forge strategy cost-presets

ビルトインのコストプリセット一覧を表示します（issue #785）。`alpha-forge strategy scaffold` / `alpha-forge backtest run` の `--cost-preset` に指定できるプリセット名（例: `moomoo-crypto-spot` / `binance-spot-vip0` / `oanda-fx-major` / `ibkr-us-stock-fixed`）を確認するために使います。

### 構文

```bash
alpha-forge strategy cost-presets [--json]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--json` | フラグ | false | JSON 形式で出力する |

### サンプル出力（テキスト）

```text
ビルトイン cost preset: 11 件
──────────────────────────────────────────────────────────────────────────────
  binance-spot-vip0
    commission=0.1%  slippage=0.05%
    ...
    source: ...
```

件数は同梱プリセット（binance / coinbase / ibkr / kraken / moomoo / oanda 系）の追加により変動します。最新の一覧はコマンドを実行して確認してください。

### サンプル出力（`--json`）

```json
{
  "binance-spot-vip0": {
    "commission_pct": 0.1,
    "slippage_pct": 0.05,
    "spread_pct": null,
    ...
  }
}
```

---

## 共通の挙動

- **ストレージ**: `config.strategies.use_db` が true なら `SQLiteStrategyRepository`、false ならファイルベース。`forge.yaml` で切り替え。
- **保存先**: `config.strategies.path`（戦略 JSON）、`config.report.output_path`（バックテスト・最適化結果）、`config.journal.journal_path`（ジャーナル）。
- **Journal 連携**: `config.journal.auto_record` が true の場合、`save` 実行時に Journal スナップショットが自動記録される。
- **`FORGE_CONFIG`**: 上記すべてのパスは環境変数 `FORGE_CONFIG` が指す `forge.yaml` で決まる。
- **終了コード**: 通常 `0`、`validate` でエラー検出時 `1`、エラー出力（ファイル不存在など）は通常 `1`、引数エラーは Click が `2` を返す。なお戦略・リソースが存在しないケース（`strategy show <未存在ID>` など）は、スクリプトが `json.load(stdout)` で落ちないよう意図的に終了コード `2` で統一されています（issue #782）。

---

<!-- 同期元: `alpha-forge/src/alpha_forge/commands/strategy.py` の Click decorator と `alpha-forge/src/alpha_forge/strategy/templates.py` の `_TEMPLATE_REGISTRY`。alpha-forge 側で引数追加・テンプレート追加があった場合、本ページも追従更新が必要。 -->
