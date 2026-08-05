---
title: alpha-visualizer v1.3.0 リリース — UX 監査ウェーブ一括対応（実行一覧・レポート・ポートフォリオ合成ほか）
description: alpha-visualizer v1.3.0 は UX 総点検で挙がった 57 件を一括対応。全 run 横断の Runs ページ、印刷用フルレポート、Compare のポートフォリオ合成、指標・分析ビューの大幅拡充、IS/OOS の実分割計算化、アクセシビリティと堅牢性の底上げを含みます。
---

# alpha-visualizer v1.3.0 リリース — UX 監査ウェーブ一括対応

> **公開日**: 2026 年 8 月 1 日 / **バージョン**: v1.3.0（本ノートは v1.3.1〜v1.3.5 のパッチを含む累積） / **配布**: [PyPI](https://pypi.org/project/alpha-visualizer/)・[GitHub Release](https://github.com/alforge-labs/alpha-visualizer/releases/tag/v1.3.0)

[alpha-visualizer](index.md) は、`alpha-forge` が出力するバックテスト結果を Web ブラウザで可視化するスタンドアロンの OSS パッケージです。v1.3.0 は **UX 総点検（監査）で挙がった 57 件の指摘への一括対応**で、新しい画面の追加から指標の拡充・文言の平易化・アクセシビリティまで、リリースとしては過去最大の変更量です。

## ハイライト

### 1. 新しい画面・ビュー

- **Runs ページ**: 全戦略を横断してバックテスト run を検索・絞り込み（銘柄・期間・Sharpe 下限）・ソートできる一覧画面
- **フルレポート**: Detail 画面から遷移できる印刷用ビュー（ブラウザの印刷機能で PDF 保存可能）
- **ポートフォリオ合成**: Compare 画面でウェイトを指定して複数戦略の加重合成エクイティを描画し、分散効果を確認
- **Run History の比較ビュー**: 2 つの run を選んで指標差分と equity 重ね描きで比較

### 2. 指標・分析の拡充

- forge が計算済みで未表示だった指標（コスト実績・Kelly 基準・期待値・勝率信頼区間など）を UI に表示
- 保有期間分布ヒストグラム（勝敗色分け）、年別サマリテーブル、期間プリセット（YTD/1Y/3Y/5Y）のサブピリオド再計算
- 任意ベンチマーク銘柄のオーバーレイと対ベンチ指標（β / α / IR / 超過リターン）
- エクイティチャートの対数スケールトグル、rolling 年率ボラティリティ、最適化のパラメータ重要度（Spearman 順位相関）
- 戦略のお気に入り（スター + Starred レンズ）
- **IS/OOS 指標を按分疑似値から equity の実分割計算に変更**（表示値の正確性が向上）

### 3. 分かりやすさとアクセシビリティ

- 指標ツールチップを全指標に拡張（目安値付き・タッチ / キーボード対応）、アプリ内ヘルプ導線（IS/OOS・WFO の概念説明）
- UI 文言の平易化・統一（内部用語や CLI 前提の文言を排除）、CLI の help・起動メッセージを日英併記化
- ダイアログのフォーカストラップ、スクロール領域のキーボード操作、モバイル幅のレイアウト崩れ修正

### 4. 堅牢性・パフォーマンス

- 存在しない戦略 ID の 404 表示、描画例外を受ける共通エラー画面、ジョブ 404 の永久ポーリング解消
- GZip 圧縮・一覧 API の軽量化・sparkline の軽量 API 化
- 非 loopback バインド時の明示警告と TrustedHostMiddleware
- CI にカバレッジ基準と mypy を導入（既存型エラー 0 化）

### 5. パッチ（v1.3.1〜v1.3.5）

- **v1.3.1**: forge CLI の実行ファイル名を `alpha-forge` に修正し、GUI 実行系機能を復旧（**v1.3.0 の実行系はこの版で直っています。v1.3 系を使う場合は v1.3.1 以降へ**）
- **v1.3.2**: EULA 未同意で forge が中断した際に、同意手順を案内するようになりました
- **v1.3.3〜v1.3.5**: チャート凡例の追加・ライブ画面の系列色改善・チャート上ホイールの修正

## アップグレード方法

```bash
# pip
pip install -U alpha-visualizer

# uv
uv tool upgrade alpha-visualizer
```

`alpha-forge` v1.3.0 と組み合わせると、run の実行時パラメータが Detail 画面に表示されます（params_json 連携）。

## 関連リンク

- **PyPI**: <https://pypi.org/project/alpha-visualizer/>
- **GitHub Release**: <https://github.com/alforge-labs/alpha-visualizer/releases/tag/v1.3.0>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **機能詳細**: [alpha-visualizer / 機能詳細](features.md)

不具合報告や機能要望は [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues) までお願いします。
