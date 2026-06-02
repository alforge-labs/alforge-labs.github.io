# TradingViewユーザー向け

TradingViewでPine Scriptを書いている方が、AlphaForgeを使ってバックテストと最適化を本格化させるための導線です。

## TradingViewとAlphaForgeの役割分担

| TradingView | AlphaForge |
|-------------|------------|
| チャート・インジケーター表示 | 統計的バックテスト・最適化 |
| Pine Scriptで素早くアイデア確認 | パラメータ最適化（Optuna/Bayesian） |
| アラート発火 | ウォークフォワード検証 |
| 視覚的なエントリー確認 | 定量的な戦略評価（Sharpe比・最大DD） |

## 典型的なワークフロー

```
1. TradingViewでアイデアをPine Scriptで試作
      ↓
2. AlphaForge JSON戦略として移植
      ↓
3. alpha-forge backtest run で本格バックテスト
      ↓
4. alpha-forge optimize run でパラメータ最適化
      ↓
5. alpha-forge pine generate でPine Script再エクスポート
      ↓
6. TradingViewアラート → Alpha Strikeで自動発注（オプション）
```

## はじめの一歩

```bash
# 戦略テンプレートを作成
alpha-forge strategy create --template hmm_bb_rsi --out my_strategy.json

# 日足データを取得（例：QQQ）
alpha-forge data fetch QQQ --period 5y

# バックテスト実行
alpha-forge backtest run QQQ --strategy my_strategy
```

## 関連ドキュメント

- [TradingView × Pine Script 統合ガイド（前編）](../guides/tradingview-pine-integration.md) — Pine ScriptロジックをAlphaForge JSONに移植する方法
- [TradingView × Alpha Strike 統合ガイド（後編）](../guides/tradingview-alpha-strike.md) — アラートから自動発注までの接続
- [エンドツーエンド戦略開発ワークフロー](../guides/end-to-end-workflow.md) — データ取得から発注まで全体像
- [戦略テンプレート](../templates.md) — コピペ可能なJSONテンプレート集
