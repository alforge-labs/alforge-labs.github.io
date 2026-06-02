# alpha-forge explore

戦略探索パイプラインの状態管理と一括実行を行います。AI エージェント（`/explore-strategies`）から利用されるコマンド群です。

| サブコマンド | 説明 |
|-------------|------|
| `run` | バックテスト→最適化→WFT→DB登録を一気通貫実行（**メインコマンド**） |
| `import` | 既存 Markdown ログを探索 DB へ投入 |
| `log` | 探索試行を DB に手動記録 |
| `status` | ゴールに対する網羅状況マップを表示 |
| `result` | 探索 DB に保存された最新試行の詳細を表示 |
| `diagnose` | WFT 不合格戦略のデータ期間延長シナリオを線形外挿で試算（issue #685） |
| `health` | 直近 N 件の試行から連続失敗・scaffold 固定化を検出（無人運転の品質ゲート） |
| `recommend` | 次の探索候補を `recommendations.yaml` へ出力 |
| `coverage` | パラメータカバレッジ（YAML）の更新・参照 |

## alpha-forge explore run

バリデーション → データ自動取得 → バックテスト → 最適化 → ウォークフォワードテスト（WFT）→ coverage 更新 → DB 登録を 1 コマンドで完結させます。不合格時は exit code 1 を返します（`--dry-run` / `--pre-check` 時を除く）。  
エージェントの `/explore-strategies` スキルから内部的に呼び出されます。

```bash
alpha-forge explore run <SYMBOL> --strategy <NAME> --goal <GOAL> [--no-cleanup] [--dry-run] [--pre-check] [--json] [--db <PATH>]
```

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--strategy` | 戦略名（必須） | — |
| `--goal` | ゴール名（`goals.yaml` の `pre_filter` / `target_metrics` を適用） | `default` |
| `--no-cleanup` | 不合格時もファイル・DB エントリを削除しない（デバッグ用） | off |
| `--dry-run` | 実行予定ステップを表示して終了（実際の処理は行わない） | off |
| `--pre-check` | バックテスト（デフォルトパラメータ）のみ実行し、最適化/WFT はスキップする（#321） | off |
| `--json` | 結果を JSON 形式で標準出力する（**非推奨**: `alpha-forge explore result show <id> --json` を使用してください） | off |
| `--db` | 探索 DB のパス（省略時は `forge.yaml` のデフォルトパス） | — |

### `--pre-check` の使い方

戦略設計段階のスクリーニングに使用します。最適化・WFT は実行されません。

```bash
alpha-forge explore run SPY --strategy my_rsi_v1 --pre-check
alpha-forge explore run SPY --strategy my_rsi_v1 --pre-check --json
```

`--pre-check` 実行時のテキスト出力例:

```
📊 Pre-check (バックテスト・デフォルトパラメータ)
  Sharpe:     0.821
  MaxDD:      19.9%
  Trades:     24 ⚠️ 少ない（WFT 窓に対して不十分な可能性）
  Signals:    31
  Pre-filter: FAIL ❌

→ 最適化・WFT はスキップされます。
```

### 出力 JSON の例

```json
{
  "symbol": "SPY",
  "strategy_id": "spy_hmm_rsi_v3",
  "passed": false,
  "backtest": {
    "sharpe": 0.82,
    "max_dd": 19.9,
    "trades": 42
  },
  "pre_filter_pass": true,
  "wft_avg_sharpe": 1.12,
  "wft_target": 1.5,
  "skip_reason": "wft_failed",
  "cleanup_done": true,
  "entry_signals": 31
}
```

| フィールド | 説明 |
|-----------|------|
| `passed` | WFT が `target_metrics` を満たした場合 `true` |
| `skip_reason` | スキップ・失敗理由（`validation_failed` / `no_signals` / `pre_filter_failed` / `wft_failed` / `pre_check_only` / `dry_run` / `null`） |
| `cleanup_done` | 不合格時に戦略 JSON / 結果 JSON が削除済みの場合 `true` |
| `entry_signals` | エントリーシグナルが立った日数（`--pre-check` 時に設定、後方互換で `null` になる場合あり） |

## alpha-forge explore result show

探索 DB に保存されている最新の探索結果を表示します。`alpha-forge explore run` 不合格時の詳細確認に使用します。

```bash
alpha-forge explore result show <STRATEGY_ID> [--goal <GOAL>] [--json] [--db <PATH>]
```

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--goal` | ゴール名で絞り込む | — |
| `--json` | 結果を JSON 形式で標準出力する | off |
| `--db` | 探索 DB のパス（省略時は `forge.yaml` のデフォルトパス） | — |

### 使用例

```bash
# 最新結果を人間可読形式で表示
alpha-forge explore result show gc_bb_hmm_rsi_v1

# ゴール絞り込みで JSON 出力（wft_diagnostics など診断情報を含む）
alpha-forge explore result show gc_bb_hmm_rsi_v1 --goal commodities --json
```

`alpha-forge explore run` が exit code 1 を返した場合の詳細確認フロー:

```bash
FORGE_CONFIG=forge.yaml alpha-forge explore run GC=F --strategy gc_bb_hmm_rsi_v1 --goal commodities
# exit code 1 → DB から詳細を取得
FORGE_CONFIG=forge.yaml alpha-forge explore result show gc_bb_hmm_rsi_v1 --goal commodities --json
```

`--json` 出力には `wft_diagnostics`・`pre_filter_diagnostics`・`opt_metrics` フィールドが含まれます。

### pre_filter_diagnostics の構造（issue #409）

`skip_reason: "pre_filter_failed"` のとき、`pre_filter_diagnostics` には各基準について
`{value, threshold, passed, gap}` の構造化情報が格納されます。自律探索エージェントが
「どの基準がどれだけ不足したか」を機械的に判断するために使用します。

```json
{
  "pre_filter_diagnostics": {
    "sharpe_ratio":      {"value": 0.716, "threshold": 1.0,  "passed": false, "gap": -0.284},
    "max_drawdown":      {"value": 1.66,  "threshold": 25.0, "passed": true,  "gap": 23.34},
    "trades":            {"value": 16,    "threshold": 30,   "passed": false, "gap": -14},
    "monthly_volume_usd":{"value": null,  "threshold": 0.0,  "passed": null,  "note": "未チェック"},
    "verdict": "failed",
    "failed_criteria": ["sharpe_ratio", "trades"]
  }
}
```

| フィールド | 説明 |
|-----------|------|
| `value` | バックテストでの実測値（`monthly_volume_usd` は現状計算しないため `null`） |
| `threshold` | goals.yaml の `pre_filter` セクションから解決した閾値 |
| `passed` | 基準を満たしているかどうか（`null` の場合は未チェック） |
| `gap` | 「実測値 − 閾値」（max_drawdown のみ「閾値 − 実測値」）。負なら不足量、正なら余裕量 |
| `verdict` | 全基準合格時 `"passed"`、いずれか不合格なら `"failed"` |
| `failed_criteria` | 不合格となった基準名のリスト（評価順: `sharpe_ratio` → `max_drawdown` → `trades`） |

### wft_diagnostics の構造（issue #684）

`skip_reason: "wft_insufficient_oos_data"` または `"wft_no_valid_oos_windows"` のとき、`wft_diagnostics` には WFT の各 OOS ウィンドウの判定結果と全体集計が構造化されて格納されます。`pre_filter_diagnostics` と同じ流儀で、エージェントが「どのウィンドウで何が不足したか」を機械的に判定できます。

```json
{
  "wft_diagnostics": {
    "total_oos_trades": 17,
    "oos_trades_by_window": [3, 3, 0, 6, 5],
    "valid_windows": 4,
    "required_valid_windows": 3,
    "min_oos_trades_per_window": 3,
    "windows": [
      {
        "window_index": 1,
        "oos_trades": 3,
        "oos_metric": -0.01,
        "valid": true,
        "skip_reason": null,
        "failed_criteria": [],
        "criteria": {
          "min_trades":     {"value": 3, "threshold": 3, "passed": true, "gap": 0},
          "metric_finite":  {"value": -0.01, "passed": true}
        }
      },
      {
        "window_index": 3,
        "oos_trades": 0,
        "oos_metric": null,
        "valid": false,
        "skip_reason": null,
        "failed_criteria": ["min_trades", "metric_finite"],
        "criteria": {
          "min_trades":     {"value": 0, "threshold": 3, "passed": false, "gap": -3},
          "metric_finite":  {"value": null, "passed": false}
        }
      }
    ],
    "summary": {
      "total_windows": 5,
      "valid_windows": 4,
      "required_valid_windows": 3,
      "min_required_trades": 3,
      "min_valid_windows_ratio": 0.6,
      "min_trades_violated_windows": [3],
      "metric_invalid_windows": [3],
      "skipped_windows": []
    }
  }
}
```

| フィールド | 説明 |
|-----------|------|
| `windows[].window_index` | 1 ベースのウィンドウ番号 |
| `windows[].oos_trades` | OOS 期間の取引数 |
| `windows[].oos_metric` | OOS の最適化メトリクス（NaN/inf は `null` に正規化） |
| `windows[].valid` | min_trades と metric_finite を両方満たすか |
| `windows[].failed_criteria` | 不合格基準のリスト（`min_trades`, `metric_finite`, `window_skip:<reason>`） |
| `windows[].criteria` | 各基準の `{value, threshold, passed, gap}` |
| `summary.min_trades_violated_windows` | min_trades 不足ウィンドウの 1 ベース index リスト |
| `summary.metric_invalid_windows` | metric が NaN/inf/None だったウィンドウの index リスト |
| `summary.skipped_windows` | engine 側でスキップされたウィンドウの index リスト |
| `summary.required_valid_windows` | 合格に必要な有効ウィンドウ数（`ceil(total × min_valid_windows_ratio)`） |

既存の後方互換フィールド（`total_oos_trades`, `oos_trades_by_window`, `valid_windows`, `required_valid_windows`, `min_oos_trades_per_window`）も並列で保持されます。

## alpha-forge explore diagnose

WFT 不合格戦略について、データ期間を延長すれば通過しそうかを線形外挿で試算するコマンド（issue #685）。`alpha-forge explore result show` で `wft_failed` を確認した直後の追加診断として使います。

```bash
alpha-forge explore diagnose <STRATEGY_ID> [--goal <GOAL>] [--periods 10y,20y,30y] \
                                    [--windows 5] [--min-oos-trades 3] \
                                    [--db <PATH>] [--json]
```

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--goal` | レコードを絞り込むゴール名 | DB に紐付く goal |
| `--periods` | 試算する期間（CSV、例: `10y,20y,30y`） | `10y,20y,30y` |
| `--windows` | WFT ウィンドウ数 | `goals.yaml` の wft 設定または `5` |
| `--min-oos-trades` | ウィンドウあたり必要な OOS trades | `goals.yaml` の wft 設定または `3` |
| `--json` | 結果を JSON で出力 | off |

### 試算ロジック

- `trade_rate = total_trades / current_period_years`
- 各シナリオで `expected = trade_rate × (period / windows)`
- `ratio = expected / min_oos_trades_per_window`
- `pass_probability`: ratio>=3 → 90%、>=2 → 70%、>=1.5 → 50%、>=1 → 30%、<1 → 0%
- `recommendation` は通過確率 0.7 以上を満たす **最小期間**。なければ 0.5、それも無ければ最高確率を返す（全シナリオ 0 なら `null`）

### サンプル出力

```
WFT 試算: nvda_ema_macd_supertrend_lt_v1 (symbol=NVDA, goal=long-term-stocks, skip_reason=wft_failed)

現状観測:
  backtest_period: 20.0y  total_trades: 1167  trade_rate: 58.35/y
  wft_windows: 5  min_oos_trades_per_window: 3

データ期間延長の試算:
  ✓ 10.0y / 2.0y/window → ~116.7 trades/window (req 3, ratio 38.9, pass_prob ≈ 90%)
  ✓ 20.0y / 4.0y/window → ~233.4 trades/window (req 3, ratio 77.8, pass_prob ≈ 90%)
  ✓ 30.0y / 6.0y/window → ~350.1 trades/window (req 3, ratio 116.7, pass_prob ≈ 90%)

推奨:
  goals.yaml: exploration.backtest_period: "10y"
  alpha-forge data fetch NVDA --provider yfinance --period 10y --interval 1d
  推定通過確率: ~90% (tier: high)
```

## alpha-forge explore health

直近 N 件の試行を集計して連続失敗・scaffold 固定化を自動検出します（issue #408）。
無人運転（`/explore-strategies --runs 0`）の各イテレーション開始前に呼び出し、
全敗ループや scaffold バグの早期検知に使用します。

```bash
alpha-forge explore health --goal <GOAL> [--last N] [--strict] [--json] [--db <PATH>]
```

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--goal` | 集計対象のゴール名 | `default` |
| `--last` | 分析対象とする直近件数 | `5` |
| `--strict` | `escalation: true` のとき終了コード `1` を返す（無人運転ループ停止用、`warning: true` のみのときは `0`） | off |
| `--json` | 結果を JSON 形式で標準出力する | off |
| `--db` | 探索 DB のパス（省略時は `forge.yaml` のデフォルトパス） | — |

### 出力 JSON の例

```json
{
  "goal": "default",
  "last_n": 5,
  "pass_rate": 0.0,
  "failure_breakdown": {"pre_filter_failed": 3, "no_signals": 2},
  "scaffold_transformation_rate": 1.0,
  "most_common_combo": "ATR+BB+RSI",
  "same_combo_streak": 5,
  "escalation": true,
  "warning": false,
  "escalation_type": "scaffold_degradation",
  "major_indicator_concentration": {"EMA": 0.8, "SUPERTREND": 0.4, "BB": 0.2},
  "recommended_actions": [
    "直近 5 件の合格率が 0% です。goals.yaml の pre_filter 閾値・対象銘柄・候補指標が現実的か再点検してください。",
    "直近すべての試行で scaffold が指標を変換しています。`alpha_forge.strategy.scaffold` の指標フィルタを点検してください（参考: alpha-forge issue #399, #400）。"
  ]
}
```

| フィールド | 説明 |
|-----------|------|
| `last_n` | 実際に集計対象となった件数（DB 件数 < `--last` の場合は実件数） |
| `pass_rate` | `passed=True` の比率（0.0〜1.0） |
| `failure_breakdown` | `skip_reason` 別の失敗件数 |
| `scaffold_transformation_rate` | scaffold で指標が変換された試行の比率（ATR 自動追加のみは除外） |
| `same_combo_streak` | 直近で連続して同一 `indicator_combo` だった件数 |
| `escalation` | `pass_rate==0` かつ scaffold バグ起因（`scaffold_transformation_rate>=0.5` もしくは中間域）のとき `true`。loop 即停止対象（issue #467） |
| `warning` | `pass_rate==0` かつ `same_combo_streak==last_n` で `scaffold_transformation_rate<=0.1` のとき `true`。`agent_selection_bias` のみ。loop は続行可能（exit 0）で、エージェントは次のランで他指標を選んで自動解消する（issue #467） |
| `escalation_type` | 原因種別（issue #436 / #467）。`"scaffold_degradation"`（escalation） / `"agent_selection_bias"`（warning） / `null` |
| `major_indicator_concentration` | 直近 N 件 scaffold trial の **indicator レベル濃度**（issue #858）。`{"EMA": 0.8, "SUPERTREND": 0.4, ...}` のように **指標 → 含有比率（0〜1）**。`dominant_combo` は完全一致 combo で集計するため `ATR+EMA+SUPERTREND` と `ATR+EMA+HMM+SMA` を別 combo 扱いするのに対し、本フィールドは indicator レベルで集計するため `EMA` 等の支配的指標を検出可能。`ATR` は scaffold 自動追加のため集計対象外 |
| `recommended_actions` | 検出された問題に対する人間向けの推奨アクション |

### エスカレーション判定

DB 件数が `--last` に満たない場合は観測のみ（`escalation: false` / `warning: false` 固定）でブロックしません。
`--last` 件以上の履歴がある場合のみ、以下のいずれかを返します。

- 合格率 `0%` かつ scaffold 変換率 `>=50%` → `escalation: true` / `escalation_type: "scaffold_degradation"`（即停止）
- 合格率 `0%` かつ直近 N 件すべての `indicator_combo` が同一：
  - scaffold 変換率 `<=10%` → `warning: true` / `escalation: false` / `escalation_type: "agent_selection_bias"`（エージェント側の選択バイアス、issue #467 で warning に格下げ。`--strict` でも exit 0）
  - 中間域（10% < 変換率 < 50%）→ 保守的に `escalation: true` / `"scaffold_degradation"` に倒す

### 無人運転スキルでの使用例

```bash
# /explore-strategies の各ラン冒頭で実行
FORGE_CONFIG=forge.yaml alpha-forge explore health \
  --goal default --last 5 --strict --json
# exit code 1 → recommended_actions を提示してループ停止
```

---

## alpha-forge explore recommend show

`recommendations.yaml`（auto-relax / analyze-exploration が生成する次の探索候補）を表示します。

```bash
alpha-forge explore recommend show [--recs <path>] [--json] [--validated-only]
```

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--recs <path>` | `recommendations.yaml` のパス | `data/explorer/recommendations.yaml` |
| `--json` | JSON で出力 | off |
| `--validated-only` | **consumable な `strategy_id` が DB に存在する候補のみ表示**（agent 消費向け厳格モード、issue #831） | off |

### Agent 消費時の注意（issue #831）

各候補には `strategy_id`（consumable な実体）と `variant_of`（派生元の参照）の 2 フィールドが含まれます。`explore run` や `backtest run` に渡すべきは **`strategy_id`** で、`variant_of` を渡すと DB / template に未登録のことが多く `ValueError: 未知のテンプレート名です` で停止します。

表示例（issue #831 修正後）:

```text
推薦候補 (auto-relax / 2026-05-19T13:10:59+00:00)
  #1 NVDA ATR+EMA+SUPERTREND (score=1.083) [strategy_id: nvda_ema_supertrend_v2_optimized] [variant of nvda_ema_supertrend_v2 (missing)]
     auto-relax variant
```

- `[strategy_id: ...]` が agent / ユーザーが実際に渡すべき ID
- `[variant of <id> (missing)]` の `(missing)` マーカーは派生元が DB 不在のときに付く（参考情報、実行には使わない）
- `strategy_id=None かつ variant_of が DB 不在` の候補は自動的にファイルから削除される
- `--validated-only` 指定時は `strategy_id` が DB に存在する候補のみ表示するため、agent は安全にそのまま `--strategy` へ転記可能

---
