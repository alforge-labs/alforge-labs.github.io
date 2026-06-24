# `--json` 出力リファレンス

このページは alpha-forge CLI の `--json` 出力の **契約（スキーマ）リファレンス**です。エージェントや MCP・パイプから出力をパースする際の安定した参照点として、主要コマンドのトップレベルフィールド・型・envelope 規約と、`schema_version` / `forge_version` の意味および増分ルールを定めます。

stdout 純度・envelope・終了コードの規約そのものは [エージェントから見た CLI 規約](./cli-conventions.md) を参照してください。本ページはそこに「実際に出るフィールドの一覧」を補完します。

!!! tip "実行時カタログ"
    全コマンドの **機械可読カタログ**（どのコマンドが `--json` を持つか・各オプションの型）は `alpha-forge system describe --json` で取得できます。本ページが「`--json` が返すフィールドの意味」、`system describe --json` が「どのコマンドに `--json` があるか」という役割分担です。

---

## envelope の 3 系統

出力形状はコマンドの性質ごとに 3 系統に分かれます。

- **一覧系**（`list` / `scan-all` 等）: `{"<複数形>": [...], "count": n}` の envelope。データ不在でも空配列 + 終了コード `0`。
- **単一実行系**（`backtest run` / `optimize walk-forward` / `backtest monte-carlo` 等）: envelope を持たない **生のオブジェクト**（トップレベルに指標やメタフィールドが並ぶ）。
- **エラー**: `{"error": ..., "code": ..., "id": ...}` の 3 キー固定（本ページ下部の「エラー出力」を参照）。

パーセント表記のフィールド（`*_pct`）は **既にパーセント単位の数値**です（例: `17.39` は +17.39%）。追加で 100 倍しないこと。

---

## `schema_version` / `forge_version`

`backtest run --json` の出力には次の 2 つのメタフィールドが含まれます。

| フィールド | 型 | 意味 |
|-----------|-----|------|
| `schema_version` | int | **CLI 出力 JSON のスキーマ世代**。現在 `1`。下記の増分ルールに従って bump する |
| `forge_version` | string | この出力を生成した alpha-forge のバージョン（例 `"0.15.0"`） |

!!! note "戦略 JSON 側の schema_version とは別物"
    ここでの `schema_version` は **CLI 出力 JSON の契約世代**であり、戦略 JSON ファイル側の `schema_version`（`strategy show --json` で見える戦略定義のスキーマ世代）とは別概念です。

### 増分ルール（いつ bump するか）

`schema_version` は **互換性を壊す変更**を入れたときにのみ +1 します。

| 変更内容 | bump するか |
|---------|------------|
| 既存フィールドの **削除** / **改名** | **する** |
| 既存フィールドの **型変更** / **意味変更** | **する** |
| **新規フィールドの追加**（既存は不変） | **しない**（追加は後方互換） |
| envelope 形状の変更 | **する** |
| 表示整形のみ（compact ↔ indent・キー順） | **しない** |

原則は **「追加は互換・削除/改名/型変更/意味変更は非互換」**。`forge_version` は毎リリースで自然に進むため、「いつ変わったか」の追跡は `forge_version`、「消費側コードを直す必要があるか」の判断は `schema_version` で行えます。

---

## `backtest run --json`

envelope なしの生オブジェクトで、メトリクスがトップレベルに並びます（実測で 60+ フィールド）。ここでは契約に関わる主要フィールドのみを示します。

| フィールド | 型 | 出力条件 | 意味 |
|-----------|-----|---------|------|
| `schema_version` | int | 常に | CLI 出力スキーマ世代 |
| `forge_version` | string | 常に | 生成元バージョン |
| `warnings` | array | 常に | 実行時の注意（少トレード等） |
| `freemium_limit_notices` | array | 常に | Trial 制限通知（`code` を含む） |
| `run_id` | string | 実 run があるとき | run の識別子 |
| `result_id` | string | 結果保存があるとき | 保存済み結果の識別子 |
| `pre_filter_pass` | bool | pre-filter 評価時 | 事前フィルタを通過したか |
| `pre_filter` | object | pre-filter 評価時 | 適用閾値（`sharpe_min` / `max_dd_max` / `monthly_volume_usd_min` / `min_trades` / `goal`） |
| `criteria_check` | object | 合否基準があるとき | 合否 verdict（本体にマージ） |
| `next_step` | array | 次アクション提示時 | 次コマンド候補（文字列配列） |

`--split` を付けると IS/OOS 比較メタが追加されます: `out_of_sample_metrics`（OOS メトリクス）・`overfitting_score`・`overfitting_risk`・`walk_forward_summary`（`is_sharpe` / `oos_sharpe` / `is_return_pct` / `oos_return_pct` / `overfitting_score` / `overfitting_risk`）。

`--summary` を付けると per-trade / per-bar 等の重い配列を除外した軽量 JSON になります（メタフィールドの契約は不変）。

---

## `optimize walk-forward --json`

envelope なしの生オブジェクト。

| フィールド | 型 | 意味 |
|-----------|-----|------|
| `symbol` / `strategy` / `metric` | string | 対象銘柄・戦略 ID・最適化メトリクス |
| `windows` | array | ウィンドウごとの結果（IS/OOS メトリクス・`skip_reason` 等） |
| `is_valid_windows` / `valid_oos_windows` / `total_windows` / `skipped_windows` | int | 各種ウィンドウ数 |
| `all_is_invalid` | bool | 全ウィンドウで IS 最適化が失敗したか |
| `freemium_limit_notices` | array | Trial 制限通知 |
| `pre_filter_pass` | bool \| null | 平均 OOS メトリクスが閾値以上か（判定不能なら `null`） |
| `pre_filter` | object | 適用閾値（`sharpe_min` / `max_dd_max` / `min_trades` / `goal`） |

`pre_filter_pass` / `pre_filter` は `--goal` を省略しても既定閾値で必ず載り、`backtest run` と命名・契約を揃えています。

---

## `backtest monte-carlo --json`

保存済みバックテスト結果のトレード履歴からモンテカルロシミュレーションを実行します。envelope なしの生オブジェクト。

| フィールド | 型 | 意味 |
|-----------|-----|------|
| `initial_capital` | number | 初期資産 |
| `simulations_run` | int | 試行回数 |
| `mean_final_equity` / `median_final_equity` / `worst_final_equity` / `best_final_equity` | number | 最終資産の統計 |
| `mean_max_drawdown_pct` / `max_drawdown_95pct` | number | 最大ドローダウン（平均・95 パーセンタイル） |
| `ruin_probability_pct` | number | 破産確率（%） |
| `pre_filter_pass` | bool \| null | 破産確率が既定閾値（5%）以下か |
| `pre_filter` | object | `max_ruin_pct`（既定 5.0） |

有効なトレードが 10 件未満の場合は stderr にエラーを出して終了コード `1` になります（純 JSON は出ません）。

---

## 一覧系の envelope

一覧・スキャン系は `{"<複数形>": [...], "count": n}` を返します。データ不在でも空配列 + 終了コード `0` です。

| コマンド | envelope キー | 要素の主なキー |
|---------|--------------|---------------|
| `strategy list --json` | `strategies` / `count` | `strategy_id` / `name` / `version` / `asset_type` / `timeframe` / `tags` / `notes` / `created_at` / `updated_at` |
| `backtest list --json` | `results` / `count` | 保存済み結果の行（`strategy_id` / `symbol` / 主要メトリクス） |
| `analyze indicator list --json` | `indicators` / `count` | `name` / `category`（`--detail` で `params` も） |
| `analyze pairs scan-all --json` | `pairs` / `count` | 共和分検定結果（加えて `cointegrated_count`） |
| `system describe --json` | `commands` / `count` | `command` / `path` / `options` / `json_supported` |

---

## エラー出力

存在しない ID を渡した等の not found 系エラーは、`--json` 指定時に stdout へ次の 3 キー固定の JSON を出し、終了コード `1` で終了します。

```json
{"error": "戦略 'does_not_exist' が見つかりません", "code": "strategy_not_found", "id": "does_not_exist"}
```

| フィールド | 型 | 意味 |
|-----------|-----|------|
| `error` | string | ローカライズ済みメッセージ |
| `code` | string | 機械判定用の安定コード（例 `strategy_not_found`） |
| `id` | string | 見つからなかったリソース ID |

`--json` を付けない場合は stderr に 1 行のメッセージを出して終了コード `1`（stdout は空）。引数エラー（Click `UsageError`）は終了コード `2` です。

---

## 関連リンク

- [エージェントから見た CLI 規約](./cli-conventions.md) — stdout 純度・envelope・終了コードの規約
- [alpha-forge-mcp リファレンス](./mcp-reference.md) — MCP 経由での利用
