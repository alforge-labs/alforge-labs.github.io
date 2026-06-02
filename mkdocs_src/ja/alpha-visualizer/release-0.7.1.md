---
title: alpha-visualizer v0.7.1 リリース — TradingView チャート・Live SQLite 直読み・Apache-2.0 化（v0.2.0 以降の累積アップデート）
description: alpha-visualizer が v0.2.0 から v0.7.1 へ。CLI を vis → alpha-vis にリネーム、主要チャートを TradingView lightweight-charts へ移行、シグナル時系列チャートの追加、Live 実績の SQLite 直読み、ライセンスの Apache-2.0 化、依存関係の継続更新など、可視化の質と実運用適性を大きく高めました。
---

# alpha-visualizer v0.7.1 リリース — v0.2.0 以降の累積アップデート

> **公開日**: 2026 年 6 月 2 日 / **バージョン**: v0.7.1 / **配布**: [PyPI](https://pypi.org/project/alpha-visualizer/0.7.1/)・[GitHub Release](https://github.com/alforge-labs/alpha-visualizer/releases/tag/v0.7.1)

[alpha-visualizer](index.md) は、`alpha-forge` が出力するバックテスト結果を Web ブラウザで可視化するスタンドアロンの OSS パッケージです。v0.2.0（同梱サンプルで即体験）以降、**チャート描画の刷新と実運用適性の強化** を軸に v0.3.0〜v0.7.1 まで継続的にアップデートしてきました。本ノートでは v0.2.0 以降の累積ハイライトをまとめます。

> **破壊的変更が 2 点あります**: CLI コマンド名のリネーム（v0.3.0）とライセンス変更（v0.6.0）。詳細は各セクションを参照してください。

## ハイライト

### 1. CLI コマンドを `vis` → `alpha-vis` にリネーム（v0.3.0・破壊的変更）

macOS 標準の `/usr/bin/vis`（BSD 系テキスト可視化ユーティリティ）と衝突し、初学者が `vis serve` を実行すると `vis: serve: No such file or directory` 等で詰まる問題を解消するため、CLI コマンド名を **`alpha-vis`** にリネームしました。

```bash
# v0.3.0 以降
alpha-vis serve --use-bundled-samples --no-open
```

旧 `vis` コマンドは使えなくなります。スクリプトやシェルエイリアスを `alpha-vis` に更新してください。

### 2. 主要チャートを TradingView lightweight-charts へ移行（v0.3.0・v0.4.0）

エクイティ／ドローダウン、Rolling Metrics、WFO 合成エクイティ、Compare エクイティといった主要チャートを、業界標準の **TradingView lightweight-charts** ベースへ移行しました。ズーム・パン・クロスヘアなどのインタラクションが向上し、金融チャートとして見慣れた操作感になっています。

### 3. シグナル時系列チャート（v0.4.0）

Detail 画面の戦略構成タブに、**ローソク足＋売買マーカー＋価格ライン** を重ねた `StrategySignalChartTV` を追加しました。エントリー／イグジットのタイミングを価格チャート上で直接確認でき、レジーム変化のマーカー表示にも対応します。バックエンドに OHLC エンドポイント、フロントに OHLC API クライアントと `useStrategyHistorical` フックを追加しています。

### 4. Live 実績を SQLite から直読み（v0.7.0）

ライブ実績ビューのデータソースを、JSON ファイル経由から **`backtest_results.db`（SQLite）の直読み** へ移行しました。`alpha-forge` の実運用データとの突き合わせがより堅牢になり、`use_db=true` で DB が欠落している場合は JSON へ黙ってフォールバックせず **Fail Loud**（明示エラー）で気付けるようにしています。

### 5. ライセンスを Apache-2.0 に変更（v0.6.0）

v0.6.0 以降、ライセンスを **MIT から Apache-2.0** に変更しました。特許条項を含むより明示的なライセンスとして、商用・OSS 双方での利用条件を明確化しています。v0.5.0 以前のリリースは引き続き MIT ライセンスです。

### 6. セキュリティと依存関係の継続更新（v0.5.0・v0.7.1）

- **CodeQL** で検出されたセキュリティアラートを解消（v0.5.0）。
- **Dependabot** の Python エコシステムを `pip` から `uv` へ切り替え、`uv.lock` の推移的依存も含めて定期更新できるように（v0.7.1）。
- idna・SQLAlchemy・FastAPI・pandas・ruff・hypothesis・@vitejs/plugin-react などの依存を最新へ更新（v0.7.1）。

## アップグレード方法

```bash
# pip
pip install -U alpha-visualizer

# uv
uv add alpha-visualizer@latest        # プロジェクトに追加
uv tool install alpha-visualizer       # CLI として使う
```

最も簡単な動作確認方法は同梱サンプルの利用です（コマンド名が `alpha-vis` になった点に注意）：

```bash
alpha-vis serve --use-bundled-samples --no-open
# http://127.0.0.1:8000 を開く
```

`alpha-forge` プロジェクト側のデータを見る場合：

```bash
alpha-vis serve --forge-dir /path/to/your/alpha-strategies
```

設定ファイル（`forge.yaml`）に変更はありません。既存の alpha-forge プロジェクトはそのまま動作します。

## 関連リンク

- **PyPI**: <https://pypi.org/project/alpha-visualizer/0.7.1/>
- **GitHub Release（タグ）**: <https://github.com/alforge-labs/alpha-visualizer/releases/tag/v0.7.1>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **インストール手順**: [alpha-visualizer / インストール](installation.md)
- **機能詳細**: [alpha-visualizer / 機能詳細](features.md)
- **設定**: [alpha-visualizer / 設定](configuration.md)

不具合報告や機能要望は [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues) までお願いします。
