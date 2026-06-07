# Python開発者向け

Pythonでデータ分析や戦略ロジックを書いており、AlphaForgeのCLI/JSON中心のワークフローに移行したい方向けです。

## AlphaForgeがPython開発者に合う理由

- **戦略定義はJSON** — コードを書かずにパラメータを宣言的に管理できる
- **CLIが構造化出力に対応** — `--json` フラグでJSONを返し、スクリプトやパイプラインに組み込みやすい
- **Optunaベースの最適化** — Pythonエコシステムと親和性が高い
- **uvプロジェクト構成** — モノレポ内に既存のPythonコードと共存できる

## 基本的な使い方

```bash
# バックテスト結果をJSONで取得してパイプ処理
alpha-forge backtest run QQQ --strategy my_strategy --json | python analyze.py

# Optuna最適化（Sharpe比を最大化）
alpha-forge optimize run QQQ --strategy my_strategy --trials 200 --metric sharpe_ratio

# ウォークフォワード検証
alpha-forge optimize walk-forward QQQ --strategy my_strategy --windows 5
```

## JSONとして戦略を管理する

AlphaForgeの戦略はJSONファイルで定義します。Gitで管理し、差分を追いやすい構造です。

```json
{
  "strategy_id": "my_strategy",
  "name": "My Strategy",
  "target_symbols": ["QQQ"],
  "indicators": [
    { "id": "rsi", "type": "RSI", "params": { "length": 14 } },
    { "id": "bb_lower", "type": "BBANDS", "params": { "length": 20, "std": 2.0, "line": "lower" } }
  ],
  "entry_conditions": {
    "long": { "logic": "AND", "conditions": [
      { "left": "rsi", "op": "<", "right": 30 },
      { "left": "close", "op": "<", "right": "bb_lower" }
    ] }
  },
  "exit_conditions": {
    "long": { "logic": "OR", "conditions": [
      { "left": "rsi", "op": ">", "right": 70 }
    ] }
  },
  "risk_management": { "position_size_pct": 100.0 }
}
```

## 関連ドキュメント

- [エンドツーエンド戦略開発ワークフロー](../guides/end-to-end-workflow.md) — 全体的な開発サイクル
- [戦略テンプレート](../templates.md) — JSONの完全サンプル（コピペ可）
- [戦略実例ギャラリー](../strategy-gallery.md) — 市場・目的別に戦略を選ぶ
- [CLI リファレンス](../cli-reference/index.md) — 全コマンドの詳細
