# クオンツ・研究者向け

統計的な厳密性を重視し、戦略の堅牢性を定量的に評価したい研究者・クオンツアナリスト向けです。

## AlphaForgeが提供する定量評価

| 機能 | 詳細 |
|------|------|
| **ウォークフォワード検証** | In-sample/Out-of-sampleを自動分割し、過学習を検出 |
| **Optuna最適化** | ベイズ最適化でパラメータ空間を効率探索（200〜1000 trials） |
| **複数目的関数** | Sharpe比、最大ドローダウン、Calmar比などから選択 |
| **再現性保証** | シードと設定をJSONで固定し、実験を完全に再現可能 |
| **Journal記録** | すべての実験結果をJSON/CSVで自動記録 |

## 典型的な研究ワークフロー

```bash
# 1. 仮説をJSONで宣言
alpha-forge strategy create --template hmm_bb_pipeline_v1 --out regime_test.json

# 2. パラメータ空間を戦略 JSON の optimizer_config.param_ranges で宣言し、
#    グリッドサーチで網羅探索する
#    例: param_ranges に rsi_period: [10, 14, 20], bb_period: [15, 20, 25]
alpha-forge optimize grid QQQ --strategy regime_test --top-k 10

# 3. ウォークフォワード検証（5分割）
alpha-forge optimize walk-forward QQQ --strategy regime_test --windows 5

# 4. 実験結果をJournalに保存
alpha-forge journal note regime_test "HMM期間別の感度分析"
```

## 過学習リスクの評価

AlphaForgeはウォークフォワードテスト（WFT）を標準で提供します。出力は各ウィンドウの IS Score と OOS Score を並べた表で、IS から OOS への低下が大きい場合はオーバーフィットの可能性が高いと判断できます（劣化率は IS/OOS から各自で算出します）。

```
Window     IS Score   OOS Score  ベストパラメータ
1            1.8000     1.4000    {...}   ← 低下が小さく許容範囲
2            2.5000     0.3000    {...}   ← 大幅に低下し過学習疑い
```

## 関連ドキュメント

- [戦略テンプレート](../templates.md) — HMM・レジーム切り替え・マルチタイムフレームの完全JSON
- [戦略実例ギャラリー](../strategy-gallery.md) — 市場別の戦略比較と結果の読み方
- [エンドツーエンド戦略開発ワークフロー](../guides/end-to-end-workflow.md) — 最適化からWFT検証まで
- [optimize コマンド](../cli-reference/optimize.md) — 最適化オプションの詳細
