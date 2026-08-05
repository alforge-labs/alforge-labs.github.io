---
title: alpha-visualizer v1.5.0 リリース — GUI 化ウェーブ（データ管理・Pine 出力・AI 開発拡張・はじめる画面）
description: alpha-visualizer v1.5.0 は、データ取得から戦略作成・バックテスト・最適化・Pine 出力までを GUI で完結させる大型リリース。データ管理画面、TradingView への Pine Script 出力、AI 戦略開発の拡張（ゴールビルダー・派生開発）、セットアップチェックリストとはじめてガイドを追加します。
---

# alpha-visualizer v1.5.0 リリース — GUI 化ウェーブ

> **公開日**: 2026 年 8 月 5 日 / **バージョン**: v1.5.0 / **配布**: [PyPI](https://pypi.org/project/alpha-visualizer/)・[GitHub Release](https://github.com/alforge-labs/alpha-visualizer/releases/tag/v1.5.0)

[alpha-visualizer](index.md) は、`alpha-forge` が出力するバックテスト結果を Web ブラウザで可視化するスタンドアロンの OSS パッケージです。v1.5.0 は、投資初中級者が CLI をほぼ触らずに「**データ取得 → 戦略作成 → バックテスト → 最適化 → Pine 出力**」を GUI で完結できるようにする大型リリースです。

## ハイライト

### 1. データ管理画面

保有ヒストリカルデータの一覧・鮮度確認と、GUI からのデータ取得・一括差分更新ができる「データ」画面が加わりました。最終更新から 24 時間を超えたデータには「要更新」バッジが付き、取得・更新は非同期ジョブ（SSE 進捗・キャンセル対応）で実行されます。未取得銘柄でチャートが表示できない画面や AI 戦略開発ビューからは、銘柄プリセット付きでこの画面に遷移できます。詳細は[機能詳細のデータ管理画面](features.md#data)を参照してください。

### 2. TradingView への Pine Script 出力

詳細画面（戦略構成タブ）の「TradingView へ出力」カードから、戦略を Pine Script（v6）としてコピー / ダウンロードできます。生成前に非対応指標を事前チェックし、生成後は TradingView の Pine エディタへの貼り付け手順を案内します。Pine 出力は AlphaForge の有料プラン限定機能です（Trial 時はアップグレード導線を表示）。

### 3. AI 戦略開発（Agent Develop）の拡張

- **ゴールビルダー**: 戦略タイプ（トレンドフォロー / 平均回帰 / ブレイクアウト）と使いたい指標を選ぶだけでゴール文の下書きを自動生成。選べる指標は Pine 変換対応のものに限定されるため、後で TradingView に出力する予定でも安心です
- **完了後の次アクション導線**: ジョブ完了パネルから新戦略のバックテスト確認・最適化・既存戦略との比較へ直接遷移
- **既存戦略の AI 派生開発**: 詳細画面の「AI で改善」カードから改善指示（例: トレード頻度を下げて）を伝えると、**新しい ID の派生版**を作成します。元の戦略は変更されません

### 4. はじめる画面（セットアップチェックリスト + はじめてガイド）

初回セットアップの状態（forge CLI / EULA / workspace / 認証 / データ）を 1 画面に集約し、未完了項目にはコピー可能なコマンドまたは GUI 内リンクを提示する「はじめる」画面が加わりました。チェックリストの下には、実データに基づく完了判定付きの「はじめての戦略作成」5 ステップガイドを表示します。未セットアップが検出されている間はナビの「はじめる」に注意ドットが付きます。詳細は[機能詳細のはじめる画面](features.md#start)を参照してください。

### 5. その他

- 開発依存の脆弱性対応（undici 7.29.0 / postcss 8.5.25・本番バンドルへの影響なし）

## アップグレード方法

```bash
# pip
pip install -U alpha-visualizer

# uv
uv tool upgrade alpha-visualizer
```

データ取得・Pine 出力などの GUI 実行系機能は、サーバーと同じマシンに AlphaForge CLI（v1.3 系以降を推奨）がインストールされていることが前提です。閲覧のみの場合は従来どおり CLI なしで動作します。書き込み系の新機能（データ取得ジョブなど）は localhost バインドでのみ有効です。

## 関連リンク

- **PyPI**: <https://pypi.org/project/alpha-visualizer/>
- **GitHub Release**: <https://github.com/alforge-labs/alpha-visualizer/releases/tag/v1.5.0>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **機能詳細**: [alpha-visualizer / 機能詳細](features.md)
- **インストール手順**: [alpha-visualizer / インストール](installation.md)

不具合報告や機能要望は [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues) までお願いします。
