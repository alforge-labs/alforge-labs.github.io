# alpha-visualizer

**alpha-visualizer** は、`alpha-forge backtest run` などが出力する **AlphaForge のバックテスト結果を Web ブラウザで可視化する OSS パッケージ** です。`alpha-forge` 本体に依存せず `backtest_results.db`（SQLite）と戦略 JSON を直接読み取るため、`alpha-forge` を未インストールの環境でも動作します。

!!! tip "AlphaForge とのつながり"
    `alpha-forge backtest run <SYMBOL> --strategy <id>` を実行すると、CLI 出力末尾に「📊 チャートは `alpha-vis serve` で確認できます」というメッセージが出ます。これは alpha-visualizer 経由で同じ結果を **ブラウザで Equity / Drawdown / 取引履歴・指標比較** として確認できることを意味します。AlphaForge 本体は商用クローズドソースですが、結果可視化レイヤーは OSS として切り出されています。最初の連携手順は [はじめに](../getting-started.md#next-steps-visualize) と [エンドツーエンド戦略開発ワークフロー](../guides/end-to-end-workflow.md) を参照してください。

![Browse 画面](assets/browse.png){ loading=lazy }

## できること

- 登録済み戦略の一覧・検索・複数選択
- バックテスト結果の Equity / Drawdown / 取引履歴・ベンチマーク指標可視化
- **バックテスト・最適化・Walk-Forward Test の GUI 実行**（非同期ジョブ・SSE 進捗・キャンセル）
- **パラメータチューニングループ**（編集 → 一時実行 → 比較 → 明示保存）と複製ベースの新規戦略作成
- 複数戦略の比較（指標の横断ビュー、Pearson 相関ヒートマップ）
- 最適化結果（WFO 合成エクイティカーブ・Grid 結果）の可視化
- ライブ実績とバックテストの期間整合 diff
- 探索アイデアの状態管理
- ダーク/ライトテーマ・日英バイリンガル UI
- CSV / PNG エクスポート、シェアカード・X 共有、URL 共有

## ドキュメント構成

| ページ | 内容 |
|---|---|
| [インストール](installation.md) | uv / pip / ソースからの 3 通りのインストール手順 |
| [機能詳細](features.md) | Browse / Detail / Compare / Optimize / Live / Ideas の各画面解説 |
| [設定](configuration.md) | CLI オプション・`forge.yaml` ・データパス仕様 |
| [FAQ・トラブルシューティング](faq.md) | よくある問題と対処法 |

## ライセンスとリポジトリ

- **License**: Apache-2.0
- **GitHub**: <https://github.com/alforge-labs/alpha-visualizer>
- **PyPI**: <https://pypi.org/project/alpha-visualizer/>
- **行動規範**: [Contributor Covenant v2.1](https://github.com/alforge-labs/alpha-visualizer/blob/main/CODE_OF_CONDUCT.md)

`alpha-forge` 本体は商用ライセンスですが、`alpha-visualizer` は OSS として独立して開発されています。
