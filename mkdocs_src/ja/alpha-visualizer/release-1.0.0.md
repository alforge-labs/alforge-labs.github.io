---
title: alpha-visualizer v1.0.0 GA — AlphaForge ファミリー同時 GA（+v1.0.1 / v1.1.0 の累積アップデート）
description: alpha-visualizer v1.0.0 は AlphaForge・alpha-strike・alpha-forge-mcp と同時の GA（安定版）リリース。以後のパッチ v1.0.1（EN 言語切替の全面反映・TradingView レンダラ一本化）と v1.1.0（レジーム背景バンド・チャート表示範囲の同期）の累積ハイライトをまとめます。
---

# alpha-visualizer v1.0.0 GA — AlphaForge ファミリー同時 GA

> **公開日**: 2026 年 7 月 21 日 / **バージョン**: v1.0.0（本ノートは v1.0.1 / v1.1.0 を含む累積） / **配布**: [PyPI](https://pypi.org/project/alpha-visualizer/)・[CHANGELOG](https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md)

[alpha-visualizer](index.md) は、`alpha-forge` が出力するバックテスト結果を Web ブラウザで可視化するスタンドアロンの OSS パッケージです。v1.0.0 は **AlphaForge 本体・[alpha-strike](https://github.com/alforge-labs/alpha-strike)・[alpha-forge-mcp](https://github.com/alforge-labs/alpha-forge-mcp) と同時の GA（安定版）リリース**で、v0.9.0 までに揃った機能セット（可視化・GUI 実行・パラメータチューニング）を安定版として宣言するマイルストーンです。

## ハイライト

### 1. GA（安定版）宣言（v1.0.0）

バージョニングはセマンティックバージョニングに従い、以後の破壊的変更はメジャーバージョンでのみ行います。機能面は v0.9.0 と同一で、GA に向けたドキュメント・配布まわりの整備が中心です。

### 2. EN 言語切替の全面反映（v1.0.1）

言語切替がナビゲーション・チャートの軸ロケール・データテーブル表記まで一貫して反映されるようになりました。残存していた素テキストのローディング表示も共有コンポーネントへ移行しています。

### 3. チャートレンダラの TradingView 一本化（v1.0.1）

v0.7.3 から段階的に切り替えてきた主要チャートのレンダラを TradingView lightweight-charts に一本化し、旧レンダラの残骸を整理しました。

### 4. レジーム背景バンドと表示範囲の同期（v1.1.0）

エクイティ / ドローダウンチャートに**レジーム背景バンド**（市場レジームの色分け表示）が復元されました。また、同一画面内の複数チャートで**表示範囲（viewport）が双方向に同期**するようになり、拡大・スクロールした期間を揃えたまま比較できます。TradingView チャートには Playwright によるビジュアル回帰テストも追加され、以後の描画劣化を CI で検出します。

## アップグレード方法

```bash
# pip
pip install -U alpha-visualizer

# uv
uv tool upgrade alpha-visualizer
```

同梱サンプルでの動作確認（AlphaForge 不要）:

```bash
alpha-vis serve --use-bundled-samples
```

`alpha-forge` プロジェクト側のデータを見る場合:

```bash
alpha-vis serve --forge-dir /path/to/your/alpha-strategies
```

## 関連リンク

- **PyPI**: <https://pypi.org/project/alpha-visualizer/>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **インストール手順**: [alpha-visualizer / インストール](installation.md)
- **機能詳細**: [alpha-visualizer / 機能詳細](features.md)

不具合報告や機能要望は [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues) までお願いします。
